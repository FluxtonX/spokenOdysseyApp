import AVFoundation
import Foundation
import ImageIO
import UIKit

/// Turns files downloaded from the glasses into normal, playable media
/// (Swift port of the Android `GlassesMediaUnpacker`).
///
/// The glasses send each capture as one extension-less file, e.g. `photo-20261118050337005`,
/// that may pack several files back to back followed by an index:
///
///   [media bytes][gyro-….txt][frame-….txt] … [entry × count][8 hex count]"Thisadir"
///
/// Each index entry is a fixed-width record (usually 40 bytes): the file name followed by its
/// size in hex, zero padded. The media (jpg / mp4 / opus) is the first media entry. Voice notes
/// are raw 40-byte Opus packets and are decoded to WAV through the SDK.
public enum GlassesMediaNormalizer {

    public static let typeImage = 1
    public static let typeVideo = 2
    public static let typeAudio = 3

    private static let magic = "Thisadir"
    private static let thumbDir = ".thumbs"
    private static let mediaExt: Set<String> = ["jpg", "jpeg", "png", "mp4", "avi", "mov", "opus", "ogg", "wav"]
    private static let recordWidths = [40, 48, 32, 56, 64]
    private static let pcmSampleRate = 16000
    private static let queue = DispatchQueue(label: "spokenodyssey.glasses.media", qos: .userInitiated)

    private struct Entry {
        let name: String
        let ext: String
        let size: Int
    }

    /// Album folder shared with the Dart side: `Documents/DCIM_1`.
    public static func albumDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DCIM_1", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Moves `source` into the album, unpacks/identifies it and returns the media description
    /// (the map the Dart side expects for `mediaImported`), or nil when it holds no media.
    public static func normalize(_ source: URL, completion: @escaping ([String: Any]?) -> Void) {
        queue.async {
            let dir = albumDirectory()
            guard let staged = stage(source, in: dir) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            extract(staged, in: dir) { media in
                let described = media.flatMap { describe($0, in: dir) }
                DispatchQueue.main.async { completion(described) }
            }
        }
    }

    // MARK: - Extraction

    /// Copies a file the SDK just downloaded into the album folder. Call it right inside the
    /// SDK callback: the SDK may reuse or clean its cache afterwards. (APFS makes it a clone.)
    public static func stage(_ source: URL) -> URL? {
        stage(source, in: albumDirectory())
    }

    private static func stage(_ source: URL, in dir: URL) -> URL? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.path) else { return nil }
        if source.deletingLastPathComponent().standardizedFileURL == dir.standardizedFileURL {
            return source
        }
        let target = dir.appendingPathComponent(source.lastPathComponent)
        try? fm.removeItem(at: target)
        do {
            try fm.copyItem(at: source, to: target)
            return target
        } catch {
            return nil
        }
    }

    private static func extract(_ src: URL, in dir: URL, completion: @escaping (URL?) -> Void) {
        let base = baseName(src)

        if let entries = readIndex(src) {
            var offset = 0
            let length = fileSize(src)
            for entry in entries {
                if mediaExt.contains(entry.ext.lowercased()) {
                    let ext = normalizedExt(entry.ext)
                    let size = min(entry.size, length - offset)
                    guard size > 0 else { return completion(nil) }
                    let out = dir.appendingPathComponent("\(base).\(ext)")
                    let part = dir.appendingPathComponent(".\(out.lastPathComponent).part")
                    guard copyRange(src, offset: offset, size: size, to: part) else { return completion(nil) }
                    if ext == "ogg", sniffExt(part) == nil {
                        // Raw Opus packets inside the bundle: decode like a voice note.
                        decodeVoice(part, base: base, in: dir) { wav in
                            try? FileManager.default.removeItem(at: part)
                            if wav != nil { try? FileManager.default.removeItem(at: src) }
                            completion(wav)
                        }
                        return
                    }
                    guard sniffExt(part) != nil else {
                        try? FileManager.default.removeItem(at: part)
                        return completion(nil)
                    }
                    try? FileManager.default.removeItem(at: out)
                    do {
                        try FileManager.default.moveItem(at: part, to: out)
                    } catch {
                        try? FileManager.default.removeItem(at: part)
                        return completion(nil)
                    }
                    if src.path != out.path { try? FileManager.default.removeItem(at: src) }
                    return completion(out)
                }
                offset += entry.size
            }
            return completion(nil)
        }

        // Voice notes: raw Opus packets. Decode them to a normal WAV file.
        if sniffExt(src) == nil, detectOpusPacketSize(src) != nil {
            decodeVoice(src, base: base, in: dir) { wav in
                if wav != nil { try? FileManager.default.removeItem(at: src) }
                completion(wav)
            }
            return
        }

        // Plain file (no index): identify by content and give it the right extension.
        guard let ext = sniffExt(src) else { return completion(nil) }
        if src.pathExtension.lowercased() == ext { return completion(src) }
        var out = dir.appendingPathComponent("\(base).\(ext)")
        if out.path == src.path { out = dir.appendingPathComponent("\(base)-1.\(ext)") }
        if FileManager.default.fileExists(atPath: out.path) {
            try? FileManager.default.removeItem(at: src)
            return completion(out)
        }
        do {
            try FileManager.default.moveItem(at: src, to: out)
            completion(out)
        } catch {
            completion(nil)
        }
    }

    private static func decodeVoice(_ src: URL, base: String, in dir: URL, completion: @escaping (URL?) -> Void) {
        let stamp = timestampDigits(base) ?? base
        let wav = dir.appendingPathComponent("voice-\(stamp).wav")
        let pcm = dir.appendingPathComponent(".voice-\(stamp).pcm")
        try? FileManager.default.removeItem(at: pcm)
        QCGlassesBridge.shared.opusToPcm(input: src.path, output: pcm.path) { ok in
            queue.async {
                defer { try? FileManager.default.removeItem(at: pcm) }
                guard ok, fileSize(pcm) > 0, writeWav(pcm: pcm, to: wav) else { return completion(nil) }
                completion(wav)
            }
        }
    }

    private static func readIndex(_ url: URL) -> [Entry]? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        let length = fileSize(url)
        guard length >= 32 else { return nil }
        handle.seek(toFileOffset: UInt64(length - 16))
        let footer = latin1(handle.readData(ofLength: 16))
        guard footer.hasSuffix(magic), let count = Int(footer.prefix(8), radix: 16), count > 0, count <= 32 else {
            return nil
        }
        for width in recordWidths {
            let tocLength = count * width
            guard length >= tocLength + 16 else { continue }
            handle.seek(toFileOffset: UInt64(length - 16 - tocLength))
            let toc = handle.readData(ofLength: tocLength)
            guard toc.count == tocLength else { continue }
            var entries: [Entry] = []
            for i in 0..<count {
                let record = latin1(toc.subdata(in: (i * width)..<((i + 1) * width)))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\u{0} "))
                guard let entry = parseRecord(record) else { break }
                entries.append(entry)
            }
            guard entries.count == count else { continue }
            // The record width is right only if everything adds up to the file length.
            if entries.reduce(0, { $0 + $1.size }) + tocLength + 16 == length { return entries }
        }
        return nil
    }

    private static let nameAndSize = try! NSRegularExpression(
        pattern: "^(.+?)\\.(jpeg|jpg|png|mp4|avi|mov|opus|ogg|wav|pcm|txt|log|json|bin|dat)([0-9A-Fa-f]+)$",
        options: [.caseInsensitive]
    )
    private static let genericNameAndSize = try! NSRegularExpression(pattern: "^(.*[^0-9A-Fa-f])([0-9A-Fa-f]+)$")

    private static func parseRecord(_ record: String) -> Entry? {
        let range = NSRange(record.startIndex..., in: record)
        if let m = nameAndSize.firstMatch(in: record, range: range),
           let name = group(m, 1, record), let ext = group(m, 2, record),
           let hex = group(m, 3, record), let size = Int(hex, radix: 16) {
            return Entry(name: name, ext: ext, size: size)
        }
        if let m = genericNameAndSize.firstMatch(in: record, range: range),
           let name = group(m, 1, record), let hex = group(m, 2, record), let size = Int(hex, radix: 16) {
            let ext = (name as NSString).pathExtension
            return Entry(name: (name as NSString).deletingPathExtension, ext: ext, size: size)
        }
        return nil
    }

    private static func group(_ match: NSTextCheckingResult, _ index: Int, _ text: String) -> String? {
        guard let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }

    private static func copyRange(_ src: URL, offset: Int, size: Int, to target: URL) -> Bool {
        guard let input = try? FileHandle(forReadingFrom: src) else { return false }
        defer { try? input.close() }
        FileManager.default.createFile(atPath: target.path, contents: nil)
        guard let output = try? FileHandle(forWritingTo: target) else { return false }
        defer { try? output.close() }
        input.seek(toFileOffset: UInt64(offset))
        var remaining = size
        while remaining > 0 {
            let chunk = input.readData(ofLength: min(remaining, 1 << 20))
            if chunk.isEmpty { break }
            output.write(chunk)
            remaining -= chunk.count
        }
        if remaining != 0 {
            try? FileManager.default.removeItem(at: target)
            return false
        }
        return true
    }

    // MARK: - Identification

    private static func sniffExt(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        let head = [UInt8](handle.readData(ofLength: 12))
        guard head.count >= 12 else { return nil }
        func text(_ from: Int, _ count: Int) -> String {
            latin1(Data(head[from..<(from + count)]))
        }
        if head[0] == 0xFF, head[1] == 0xD8, head[2] == 0xFF { return "jpg" }
        if head[0] == 0x89, head[1] == 0x50, head[2] == 0x4E { return "png" }
        if text(4, 4) == "ftyp" { return "mp4" }
        if text(0, 4) == "RIFF", text(8, 4) == "AVI " { return "avi" }
        if text(0, 4) == "RIFF", text(8, 4) == "WAVE" { return "wav" }
        if text(0, 4) == "OggS" { return "ogg" }
        return nil
    }

    private static func describe(_ file: URL, in dir: URL) -> [String: Any]? {
        let ext = file.pathExtension.lowercased()
        let name = file.deletingPathExtension().lastPathComponent
        let capturedAt = timestampFromName(name) ?? modifiedMs(file)
        switch ext {
        case "jpg", "jpeg", "png":
            guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
                  let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  (props[kCGImagePropertyPixelWidth] as? Int ?? 0) > 0 else { return nil }
            return media(file, type: typeImage, duration: 0, thumbnail: nil, capturedAt: capturedAt)
        case "mp4", "mov", "avi":
            let asset = AVURLAsset(url: file)
            let seconds = CMTimeGetSeconds(asset.duration)
            let hasVideo = !asset.tracks(withMediaType: .video).isEmpty
            guard hasVideo || seconds > 0 else { return nil }
            let thumbs = dir.appendingPathComponent(thumbDir, isDirectory: true)
            try? FileManager.default.createDirectory(at: thumbs, withIntermediateDirectories: true)
            let thumb = thumbs.appendingPathComponent("\(name).jpg")
            if !FileManager.default.fileExists(atPath: thumb.path) { saveThumbnail(asset, to: thumb) }
            let hasThumb = FileManager.default.fileExists(atPath: thumb.path)
            return media(file, type: typeVideo, duration: rounded(seconds),
                         thumbnail: hasThumb ? thumb : nil, capturedAt: capturedAt)
        case "wav", "ogg":
            let seconds = CMTimeGetSeconds(AVURLAsset(url: file).duration)
            return media(file, type: typeAudio, duration: rounded(seconds), thumbnail: nil, capturedAt: capturedAt)
        default:
            return nil
        }
    }

    private static func media(_ file: URL, type: Int, duration: Int, thumbnail: URL?, capturedAt: Int64) -> [String: Any] {
        [
            "fileName": file.lastPathComponent,
            "filePath": file.path,
            "fileType": type,
            "duration": duration,
            "thumbnailPath": thumbnail?.path ?? "",
            "timestamp": capturedAt,
            "fileDate": "",
            "sizeBytes": fileSize(file),
        ]
    }

    private static func saveThumbnail(_ asset: AVAsset, to url: URL) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        guard let cg = (try? generator.copyCGImage(at: time, actualTime: nil))
            ?? (try? generator.copyCGImage(at: .zero, actualTime: nil)),
            let data = UIImage(cgImage: cg).jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Voice notes (raw Opus)

    /// Voice notes are back-to-back fixed-size Opus packets (40 bytes on current firmware), all
    /// using the same Opus config (top 5 bits of the TOC byte). Returns the packet size, or nil.
    private static func detectOpusPacketSize(_ url: URL) -> Int? {
        guard let data = try? Data(contentsOf: url), data.count >= 40 else { return nil }
        let bytes = [UInt8](data)
        guard bytes[0] != 0 else { return nil }
        let config = bytes[0] >> 3
        for size in [40, 20, 60, 80, 100, 120, 160] where bytes.count % size == 0 {
            let packets = bytes.count / size
            if (0..<packets).allSatisfy({ bytes[$0 * size] >> 3 == config }) { return size }
        }
        return nil
    }

    private static func writeWav(pcm: URL, to wav: URL) -> Bool {
        guard let body = try? Data(contentsOf: pcm), !body.isEmpty else { return false }
        var header = Data()
        func append32(_ v: UInt32) { var le = v.littleEndian; header.append(Data(bytes: &le, count: 4)) }
        func append16(_ v: UInt16) { var le = v.littleEndian; header.append(Data(bytes: &le, count: 2)) }
        let rate = UInt32(pcmSampleRate)
        header.append("RIFF".data(using: .ascii)!)
        append32(UInt32(36 + body.count))
        header.append("WAVE".data(using: .ascii)!)
        header.append("fmt ".data(using: .ascii)!)
        append32(16)
        append16(1)          // PCM
        append16(1)          // mono
        append32(rate)
        append32(rate * 2)   // byte rate
        append16(2)          // block align
        append16(16)         // bits per sample
        header.append("data".data(using: .ascii)!)
        append32(UInt32(body.count))
        do {
            try (header + body).write(to: wav, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    /// ISO-8859-1: every byte maps to one character, so offsets stay byte offsets.
    private static func latin1(_ data: Data) -> String {
        String(data: data, encoding: .isoLatin1) ?? ""
    }

    private static func fileSize(_ url: URL) -> Int {
        ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber)?.intValue ?? 0
    }

    private static func modifiedMs(_ url: URL) -> Int64 {
        let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        return Int64((date ?? Date()).timeIntervalSince1970 * 1000)
    }

    private static func rounded(_ seconds: Double) -> Int {
        seconds.isFinite && seconds > 0 ? Int(seconds.rounded()) : 0
    }

    private static func baseName(_ url: URL) -> String {
        mediaExt.contains(url.pathExtension.lowercased())
            ? url.deletingPathExtension().lastPathComponent
            : url.lastPathComponent
    }

    private static func normalizedExt(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpeg": return "jpg"
        case "opus": return "ogg"
        default: return ext.lowercased()
        }
    }

    private static func timestampDigits(_ name: String) -> String? {
        guard let range = name.range(of: "\\d{17}", options: .regularExpression) else { return nil }
        return String(name[range])
    }

    /// `photo-20261118050337005` → capture time from yyyyMMddHHmmssSSS (milliseconds).
    private static func timestampFromName(_ name: String) -> Int64? {
        guard let digits = timestampDigits(name) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmssSSS"
        guard let date = formatter.date(from: digits) else { return nil }
        return Int64(date.timeIntervalSince1970 * 1000)
    }
}
