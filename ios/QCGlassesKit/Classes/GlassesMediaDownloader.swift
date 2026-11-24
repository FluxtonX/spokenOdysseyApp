import Foundation

/// Downloads the media from the glasses' HTTP server once the phone is on their Wi‑Fi.
///
/// Same protocol as the Android SDK (`GlassesControl`):
/// 1. `GET http://<glasses>/files/media.config` → one file name per line.
/// 2. `GET http://<glasses>/files/<name>` for each line, one at a time (`.log` files are skipped).
///
/// Files are written into the album folder; each finished file is handed to `onFile` (for
/// unpacking), empty files are dropped. All callbacks run on the main queue.
public final class GlassesMediaDownloader: NSObject, URLSessionDownloadDelegate {

    public struct Callbacks {
        /// (1-based index of the file being downloaded, total files)
        public var onCount: (Int, Int) -> Void
        /// (file name, percent 0–100)
        public var onProgress: (String, Int) -> Void
        /// Human-readable transfer speed, e.g. "2.4 MB/s".
        public var onSpeed: (String) -> Void
        /// A file finished downloading (raw, still to be unpacked).
        public var onFile: (URL) -> Void
        /// (file name, error code) — that file is skipped, the rest continue.
        public var onFileError: (String, Int) -> Void
        /// nil when every file was processed; otherwise an error code for the whole import
        /// (2004 = couldn't get the file list, 2003 = iOS blocked Local Network access).
        public var onFinish: (Int?) -> Void

        public init(onCount: @escaping (Int, Int) -> Void,
                    onProgress: @escaping (String, Int) -> Void,
                    onSpeed: @escaping (String) -> Void,
                    onFile: @escaping (URL) -> Void,
                    onFileError: @escaping (String, Int) -> Void,
                    onFinish: @escaping (Int?) -> Void) {
            self.onCount = onCount
            self.onProgress = onProgress
            self.onSpeed = onSpeed
            self.onFile = onFile
            self.onFileError = onFileError
            self.onFinish = onFinish
        }
    }

    public static let configErrorCode = 2004
    public static let localNetworkDeniedCode = 2003

    /// What went wrong last (for logs and the error shown to the user).
    public private(set) var lastError: String?

    private static let configFileName = "media.config"
    /// How long to keep asking for the file list. Right after the join iOS can still report the
    /// network as unreachable (-1009 / -1004) for several seconds, and the glasses' HTTP server
    /// starts a little after their hotspot.
    private static let configWindow: TimeInterval = 40
    private static let configMinAttempts = 3
    private static let configRetryDelay: TimeInterval = 2
    private static let configRequestTimeout: TimeInterval = 10
    private static let fileAttempts = 2

    private let host: String
    private let directory: URL
    private let callbacks: Callbacks
    private var session: URLSession!

    private var files: [String] = []
    private var index = 0
    private var fileAttempt = 0
    private var cancelled = false
    private var finished = false
    private var configDeadline = Date()

    // Progress / speed reporting
    private var lastPercent = -1
    private var speedWindowStart = Date()
    private var speedWindowBytes: Int64 = 0

    public init(host: String, directory: URL, callbacks: Callbacks) {
        self.host = host
        self.directory = directory
        self.callbacks = callbacks
        super.init()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30 * 60
        configuration.waitsForConnectivity = false
        // The glasses are only reachable over their Wi‑Fi; never try cellular.
        configuration.allowsCellularAccess = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }

    public func start() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        configDeadline = Date().addingTimeInterval(1 + Self.configWindow)
        // Android waits a second after the link is up before the first request.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.fetchConfig(attempt: 1)
        }
    }

    public func cancel() {
        cancelled = true
        session.invalidateAndCancel()
    }

    // MARK: - File list

    private func fetchConfig(attempt: Int) {
        guard !cancelled, let url = url(for: Self.configFileName) else { return }
        GlassesLog.log("step 4: GET \(url.absoluteString) (attempt \(attempt), phone Wi-Fi IP "
                       + "\(GlassesWiFiLink.wifiIPv4Address() ?? "none"))")
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.configRequestTimeout
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self, !self.cancelled else { return }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard error == nil, status == 200, let data = data,
                      let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                    let reason = error.map { Self.describe($0) } ?? "HTTP \(status)"
                    GlassesLog.log("media list request failed (\(reason))")
                    if let error = error, Self.isLocalNetworkDenied(error) {
                        // iOS reports a blocked Local Network permission as -1009 "offline".
                        self.lastError = "Local Network access is off for Spoken Odyssey"
                        self.finish(Self.localNetworkDeniedCode)
                        return
                    }
                    self.lastError = "media list request failed (\(Self.shortReason(error, status: status)))"
                    if attempt < Self.configMinAttempts || Date() < self.configDeadline {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.configRetryDelay) { [weak self] in
                            self?.fetchConfig(attempt: attempt + 1)
                        }
                    } else {
                        self.finish(Self.configErrorCode)
                    }
                    return
                }
                self.files = text
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && !$0.lowercased().hasSuffix(".log") }
                GlassesLog.log("media list: \(self.files.count) files")
                self.index = 0
                self.downloadNext()
            }
        }.resume()
    }

    // MARK: - Files

    private func downloadNext() {
        guard !cancelled else { return }
        guard index < files.count else {
            finish(nil)
            return
        }
        let name = files[index]
        guard let url = url(for: name) else {
            callbacks.onFileError(name, -1)
            index += 1
            downloadNext()
            return
        }
        if fileAttempt == 0 { callbacks.onCount(index + 1, files.count) }
        lastPercent = -1
        speedWindowStart = Date()
        speedWindowBytes = 0
        let task = session.downloadTask(with: url)
        task.taskDescription = name
        task.resume()
    }

    private func fileDone(name: String, savedTo file: URL?, errorCode: Int?) {
        guard !cancelled else { return }
        if let file = file {
            fileAttempt = 0
            GlassesLog.log("downloaded \(name)")
            callbacks.onFile(file)
        } else if fileAttempt + 1 < Self.fileAttempts {
            fileAttempt += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.downloadNext() }
            return
        } else {
            fileAttempt = 0
            GlassesLog.log("failed to download \(name) (code \(errorCode ?? -1))")
            callbacks.onFileError(name, errorCode ?? -1)
        }
        index += 1
        downloadNext()
    }

    private func skipFile() {
        guard !cancelled else { return }
        fileAttempt = 0
        index += 1
        downloadNext()
    }

    private func finish(_ errorCode: Int?) {
        guard !finished else { return }
        finished = true
        session.finishTasksAndInvalidate()
        callbacks.onFinish(errorCode)
    }

    private func url(for fileName: String) -> URL? {
        let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        return URL(string: "http://\(host)/files/\(encoded)")
    }

    // MARK: - URLSessionDownloadDelegate (delegate queue)

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        let name = downloadTask.taskDescription ?? ""
        var percent: Int?
        if totalBytesExpectedToWrite > 0 {
            let value = Int(totalBytesWritten * 100 / totalBytesExpectedToWrite)
            if value > lastPercent {
                lastPercent = value
                percent = value
            }
        }
        speedWindowBytes += bytesWritten
        let elapsed = Date().timeIntervalSince(speedWindowStart)
        var speed: String?
        if elapsed >= 0.5 {
            let bytesPerSecond = Double(speedWindowBytes) / elapsed
            speed = Self.formatSpeed(bytesPerSecond)
            speedWindowStart = Date()
            speedWindowBytes = 0
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.cancelled else { return }
            if let percent = percent { self.callbacks.onProgress(name, percent) }
            if let speed = speed { self.callbacks.onSpeed(speed) }
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        // The temporary file is deleted when this method returns: move it now.
        let name = downloadTask.taskDescription ?? location.lastPathComponent
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        var saved: URL?
        var empty = false
        if status == 200 {
            let target = directory.appendingPathComponent((name as NSString).lastPathComponent)
            let fm = FileManager.default
            try? fm.removeItem(at: target)
            if (try? fm.moveItem(at: location, to: target)) != nil {
                let size = ((try? fm.attributesOfItem(atPath: target.path))?[.size] as? NSNumber)?.intValue ?? 0
                if size > 0 {
                    saved = target
                } else {
                    // Android drops empty files silently; so do we.
                    empty = true
                    try? fm.removeItem(at: target)
                }
            }
        }
        let code = status == 200 ? nil : status
        DispatchQueue.main.async { [weak self] in
            self?.pendingResult = (name, saved, code, empty)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task is URLSessionDownloadTask else { return }
        let name = task.taskDescription ?? ""
        let errorCode = (error as NSError?)?.code
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let result = self.pendingResult
            self.pendingResult = nil
            if let result = result, result.name == name, error == nil, result.empty {
                self.skipFile()
            } else if let result = result, result.name == name, error == nil {
                self.fileDone(name: name, savedTo: result.file, errorCode: result.code)
            } else {
                self.fileDone(name: name, savedTo: nil, errorCode: errorCode ?? result?.code)
            }
        }
    }

    /// Result of `didFinishDownloadingTo`, read when the task completes.
    private var pendingResult: (name: String, file: URL?, code: Int?, empty: Bool)?

    // MARK: - Errors

    /// Full error text for the log, including iOS's network path (it says *why* a request
    /// was considered offline, e.g. "unsatisfied (Local network prohibited)").
    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        var text = "\(nsError.domain) \(nsError.code): \(nsError.localizedDescription)"
        if let path = networkPath(of: nsError) { text += " [path: \(path)]" }
        return text
    }

    private static func shortReason(_ error: Error?, status: Int) -> String {
        guard let nsError = error as NSError? else { return "HTTP \(status)" }
        return "\(nsError.domain) \(nsError.code): \(nsError.localizedDescription)"
    }

    private static func networkPath(of error: NSError) -> String? {
        if let path = error.userInfo["_NSURLErrorNWPathKey"] { return String(describing: path) }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           let path = underlying.userInfo["_NSURLErrorNWPathKey"] {
            return String(describing: path)
        }
        return nil
    }

    private static func isLocalNetworkDenied(_ error: Error) -> Bool {
        guard let path = networkPath(of: error as NSError)?.lowercased() else { return false }
        return path.contains("local network prohibited") || path.contains("local network denied")
    }

    private static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1024 / 1024)
        }
        return String(format: "%.0f KB/s", bytesPerSecond / 1024)
    }
}
