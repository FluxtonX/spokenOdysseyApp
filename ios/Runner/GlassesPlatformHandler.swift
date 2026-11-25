import AVFoundation
import CoreBluetooth
import Flutter
import QCGlassesKit
import UIKit

/// Flutter bridge for the smart glasses on iOS.
///
/// Mirrors the Android `GlassesPlatformPlugin` channel contract:
/// - Scanning and connecting happen inside the app with CoreBluetooth. Glasses that iOS is
///   already connected to (e.g. paired in Settings) are listed too, via their GATT services.
/// - Once connected, the peripheral is handed to the vendor QCSDK (`QCGlassesBridge`), which
///   runs the glasses protocol: capture modes, battery, settings and Wi‑Fi media download.
@objc class GlassesPlatformHandler: NSObject, FlutterStreamHandler, CBCentralManagerDelegate {

    static let shared = GlassesPlatformHandler()

    // QCOperatorDeviceMode values used here.
    private enum Mode {
        static let transfer = 0x04
        static let transferStop = 0x09
    }

    private static let lastDeviceKey = "glasses.lastPeripheralIdentifier"

    private var eventSink: FlutterEventSink?
    private var centralManager: CBCentralManager?
    private var pendingStateResults: [FlutterResult] = []

    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var isScanning = false

    /// The glasses we are connected (or connecting) to.
    private var targetPeripheral: CBPeripheral?
    /// True once the SDK finished its handshake with `targetPeripheral`.
    private var sdkReady = false
    /// Set while the user unbinds, so the disconnect isn't followed by a reconnect.
    private var unbinding = false

    // Media import
    private var importing = false
    private var importGeneration = 0
    /// When the glasses were last told to leave transfer mode (see `transferRestartGap`).
    private var lastTransferStop: Date?
    private var importStarted = false
    private var pendingNormalizations = 0
    private var downloadFinished = false
    private var currentImportFile = ""
    private var downloader: GlassesMediaDownloader?

    override init() {
        super.init()
        setupAudioSession()
        // Mirror the native glasses diagnostics to Dart so they print in the
        // Flutter debug console as `[GlassesImport] …` lines.
        GlassesLog.forwarder = { [weak self] message in
            self?.sendEvent(name: "log", data: ["message": message])
        }
        QCGlassesBridge.shared.onBattery = { [weak self] level, charging in
            self?.sendEvent(name: "batteryUpdated", data: ["battery": level, "isCharging": charging])
        }
    }

    func register(with binaryMessenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(name: "com.fluxtonx.spokenodyssey/glasses", binaryMessenger: binaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }

        let eventChannel = FlutterEventChannel(name: "com.fluxtonx.spokenodyssey/glasses_events", binaryMessenger: binaryMessenger)
        eventChannel.setStreamHandler(self)
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[GlassesPlatformHandler] AVAudioSession error: \(error)")
        }
    }

    /// Created lazily so iOS shows the Bluetooth permission prompt only when the
    /// user starts pairing, not at app launch before any explanation is shown.
    @discardableResult
    private func ensureCentralManager(showPowerAlert: Bool = false) -> CBCentralManager {
        if let manager = centralManager { return manager }
        let manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: showPowerAlert]
        )
        centralManager = manager
        return manager
    }

    private var isConnected: Bool {
        sdkReady && targetPeripheral?.state == .connected
    }

    // MARK: - Method channel

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "initializeSDK":
            result(true)

        case "getConnectedDevice":
            if isConnected, let peripheral = targetPeripheral {
                result([
                    "isConnected": true,
                    "name": peripheral.name ?? "Smart Glasses",
                    "address": peripheral.identifier.uuidString,
                ])
            } else {
                result(["isConnected": false])
            }

        case "startScan":
            startScan()
            result(true)

        case "stopScan":
            stopScan()
            result(true)

        case "enableBluetooth":
            enableBluetooth(result: result)

        case "isBluetoothEnabled":
            let manager = ensureCentralManager()
            if manager.state == .unknown || manager.state == .resetting {
                // State isn't known until the first delegate callback (and, on
                // first use, until the user answers the permission prompt).
                pendingStateResults.append(result)
            } else {
                result(manager.state == .poweredOn)
            }

        case "connectDevice":
            let address = args?["address"] as? String ?? ""
            connect(address: address, result: result)

        case "disconnectDevice":
            unbind()
            result(true)

        case "syncTime":
            guard isConnected else { return result(false) }
            QCGlassesBridge.shared.syncTime { ok in result(ok) }

        case "getBatteryLevel":
            guard isConnected else { return result(false) }
            refreshBattery()
            result(true)

        case "setDeviceMode":
            guard let mode = args?["mode"] as? Int else {
                return result(FlutterError(code: "INVALID_MODE", message: "mode is required", details: nil))
            }
            setMode(mode, result: result)

        case "endTransfer":
            endTransfer { result(true) }

        case "getMediaCount":
            guard isConnected, !importing else { return result(nil) }
            QCGlassesBridge.shared.mediaCount { counts in result(counts) }

        case "importAlbum":
            importAlbum(result: result)

        case "getAlbumDirectory":
            result(GlassesMediaNormalizer.albumDirectory().path)

        case "repairAlbum":
            // Media is unpacked while it downloads, so there is nothing left to repair.
            result([[String: Any]]())

        case "getDeviceSettings":
            guard isConnected, let peripheral = targetPeripheral else { return result(nil) }
            QCGlassesBridge.shared.deviceSettings { settings in
                var out = settings
                out["address"] = peripheral.identifier.uuidString
                out["name"] = peripheral.name ?? ""
                result(out)
            }

        case "setWearDetection":
            let on = args?["enabled"] as? Bool ?? true
            guard isConnected else { return result(["ok": false]) }
            QCGlassesBridge.shared.setWearDetection(on) { ok, enabled in
                result(["ok": ok, "enabled": enabled])
            }

        case "setVoiceWakeup":
            let on = args?["enabled"] as? Bool ?? true
            guard isConnected else { return result(["ok": false]) }
            QCGlassesBridge.shared.setVoiceWakeup(on) { ok, enabled in
                result(["ok": ok, "enabled": enabled])
            }

        case "setVolume":
            guard isConnected else { return result(["ok": false]) }
            QCGlassesBridge.shared.setVolume(
                music: args?["music"] as? Int,
                call: args?["call"] as? Int,
                system: args?["system"] as? Int
            ) { ok in result(["ok": ok]) }

        case "getVideoConfig":
            guard isConnected else { return result(nil) }
            QCGlassesBridge.shared.videoConfig { config in result(config) }

        case "setVideoConfig":
            guard isConnected else { return result(["ok": false]) }
            QCGlassesBridge.shared.setVideoConfig(
                angle: args?["angle"] as? Int ?? 0,
                duration: args?["duration"] as? Int ?? 180
            ) { ok in result(["ok": ok]) }

        case "getAudioStatus", "connectAudio":
            result(audioStatus())

        case "openBluetoothSettings":
            // iOS has no public link to the Bluetooth page; open the app's Settings page.
            openAppSettings()
            result(true)

        // Legacy method names kept for compatibility.
        case "takePhoto":
            setMode(0x01, result: result)
        case "toggleRecording":
            setMode((args?["start"] as? Bool ?? true) ? 0x02 : 0x03, result: result)
        case "toggleVoiceRecording":
            setMode((args?["start"] as? Bool ?? true) ? 0x08 : 0x0c, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Bluetooth state

    /// iOS never lets an app switch Bluetooth on itself. The supported way is
    /// Apple's "Turn On Bluetooth" system alert (its Settings button opens the
    /// Bluetooth page), shown when a central manager starts while powered off.
    /// Result: "on" | "alert" | "denied" | "unsupported".
    private func enableBluetooth(result: @escaping FlutterResult) {
        let manager = ensureCentralManager()
        switch manager.state {
        case .poweredOn:
            result("on")
        case .unsupported:
            // e.g. the iOS Simulator, which has no Bluetooth radio.
            result("unsupported")
        case .unauthorized:
            // Bluetooth access was turned off for the app. Only the user can re-enable it in
            // Settings; the app explains that and offers an "Open Settings" button.
            result("denied")
        case .poweredOff:
            // Re-create the manager with the power alert enabled so iOS shows it.
            manager.delegate = nil
            manager.stopScan()
            centralManager = nil
            discoveredPeripherals.removeAll()
            ensureCentralManager(showPowerAlert: true)
            result("alert")
        default:
            result("alert")
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    private static func stateName(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        case .resetting: return "resetting"
        default: return "unknown"
        }
    }

    // MARK: - Scanning

    private func startScan() {
        let manager = ensureCentralManager()
        discoveredPeripherals.removeAll()
        isScanning = true
        sendEvent(name: "scanState", data: ["scanning": true])
        if manager.state == .poweredOn { beginScan(manager) }
        // Otherwise centralManagerDidUpdateState starts it once Bluetooth is ready.
    }

    private func beginScan(_ manager: CBCentralManager) {
        // Glasses already connected to this iPhone (paired in Settings, or by another app)
        // don't advertise, so list them from the system first.
        let services = QCGlassesBridge.serviceUUIDs
        if !services.isEmpty {
            for peripheral in manager.retrieveConnectedPeripherals(withServices: services) {
                report(peripheral, rssi: -40)
            }
        }
        // The saved glasses can be reconnected directly even if they aren't advertising yet.
        if let saved = savedIdentifier(),
           let peripheral = manager.retrievePeripherals(withIdentifiers: [saved]).first,
           peripheral.state == .connected {
            report(peripheral, rssi: -45)
        }
        manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    private func stopScan() {
        isScanning = false
        centralManager?.stopScan()
        sendEvent(name: "scanState", data: ["scanning": false])
    }

    private func report(_ peripheral: CBPeripheral, rssi: Int, advertisedName: String? = nil) {
        let name = advertisedName ?? peripheral.name ?? ""
        guard !name.isEmpty else { return }
        let id = peripheral.identifier.uuidString
        discoveredPeripherals[id] = peripheral
        sendEvent(name: "scanResult", data: ["name": name, "address": id, "rssi": rssi])
    }

    // MARK: - Connection

    private func connect(address: String, result: @escaping FlutterResult) {
        let manager = ensureCentralManager()
        guard manager.state == .poweredOn else {
            sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
            return result(FlutterError(code: "BLUETOOTH_OFF", message: "Bluetooth is not available", details: nil))
        }
        guard let peripheral = peripheral(for: address, manager: manager) else {
            sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
            return result(FlutterError(code: "NOT_FOUND", message: "Glasses not found. Scan again.", details: nil))
        }

        if isScanning { stopScan() }
        // Drop any earlier attempt to a different device.
        if let previous = targetPeripheral, previous.identifier != peripheral.identifier {
            QCGlassesBridge.shared.detach(previous)
            manager.cancelPeripheralConnection(previous)
        }
        unbinding = false
        sdkReady = false
        targetPeripheral = peripheral
        sendEvent(name: "connectionStateChanged", data: ["state": "connecting", "address": address])

        // Even glasses the system is already connected to (paired in Settings) must be
        // connected by the app; didConnect then fires right away and runs the SDK handshake.
        manager.connect(peripheral, options: connectOptions())
        result(true)
    }

    private func connectOptions() -> [String: Any] {
        var options: [String: Any] = [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]
        if #available(iOS 13.0, *) {
            // Lets iOS bring up the glasses' classic (audio) link together with BLE.
            options[CBConnectPeripheralOptionEnableTransportBridgingKey] = true
        }
        return options
    }

    private func peripheral(for address: String, manager: CBCentralManager) -> CBPeripheral? {
        if let known = discoveredPeripherals[address] { return known }
        guard let uuid = UUID(uuidString: address) else { return nil }
        if let known = manager.retrievePeripherals(withIdentifiers: [uuid]).first { return known }
        let services = QCGlassesBridge.serviceUUIDs
        if !services.isEmpty {
            return manager.retrieveConnectedPeripherals(withServices: services).first { $0.identifier == uuid }
        }
        return nil
    }

    private func attachSDK(_ peripheral: CBPeripheral) {
        QCGlassesBridge.shared.attach(peripheral) { [weak self] success in
            guard let self = self, self.targetPeripheral?.identifier == peripheral.identifier else { return }
            if success {
                self.sdkReady = true
                UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: Self.lastDeviceKey)
                self.sendEvent(name: "connectionStateChanged", data: [
                    "state": "connected",
                    "address": peripheral.identifier.uuidString,
                    "name": peripheral.name ?? "Smart Glasses",
                ])
                self.refreshBattery()
                QCGlassesBridge.shared.syncTime { _ in }
                self.sendEvent(name: "audioState", data: self.audioStatus())
            } else {
                // The handshake failed: drop the link so the next attempt starts clean.
                self.sdkReady = false
                QCGlassesBridge.shared.detach(peripheral)
                self.centralManager?.cancelPeripheralConnection(peripheral)
                self.targetPeripheral = nil
                self.sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
            }
        }
    }

    private func unbind() {
        unbinding = true
        if importing { cancelImport() }
        sdkReady = false
        QCGlassesBridge.shared.detachAll()
        if let peripheral = targetPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        targetPeripheral = nil
        UserDefaults.standard.removeObject(forKey: Self.lastDeviceKey)
        sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
    }

    private func savedIdentifier() -> UUID? {
        guard let text = UserDefaults.standard.string(forKey: Self.lastDeviceKey) else { return nil }
        return UUID(uuidString: text)
    }

    private func refreshBattery() {
        QCGlassesBridge.shared.battery { [weak self] level, charging in
            guard let level = level else { return }
            self?.sendEvent(name: "batteryUpdated", data: ["battery": level, "isCharging": charging])
        }
    }

    // MARK: - Commands

    private func setMode(_ mode: Int, result: @escaping FlutterResult) {
        guard isConnected else {
            return result(["ok": false, "timeout": false, "busyMode": NSNull()])
        }
        QCGlassesBridge.shared.setMode(mode) { [weak self] ok, timedOut, busyMode in
            if ok { self?.sendEvent(name: "workState", data: ["mode": mode, "source": "command"]) }
            result(["ok": ok, "timeout": timedOut, "busyMode": busyMode.map { $0 as Any } ?? NSNull()])
        }
    }

    private func endTransfer(_ done: @escaping () -> Void) {
        if importing { cancelImport() }
        guard isConnected else { return done() }
        QCGlassesBridge.shared.setMode(Mode.transferStop) { [weak self] _, _, _ in
            self?.sendEvent(name: "workState", data: ["mode": 0, "source": "transferStop"])
            done()
        }
    }

    // MARK: - Media import (Wi‑Fi)
    //
    // Same flow as the Android SDK, adapted to iOS (no Wi‑Fi Direct):
    // 1. Local Network permission (asked in the app, up front).
    // 2. GlassesWiFiLink: open the glasses' Wi‑Fi over Bluetooth, wait until their hotspot is
    //    really up, join it and confirm the join.
    // 3. GlassesMediaDownloader: media.config + each file over HTTP from the glasses.
    // 4. GlassesMediaNormalizer: unpack each file into a playable photo / video / voice note.
    // 5. Glasses back to normal mode, phone back to its usual Wi‑Fi.

    private func importAlbum(result: @escaping FlutterResult) {
        guard isConnected else {
            return result(FlutterError(code: "NOT_CONNECTED", message: "Connect your glasses first", details: nil))
        }
        if importing { return result(true) }
        importing = true
        importStarted = false
        downloadFinished = false
        pendingNormalizations = 0
        currentImportFile = ""
        importGeneration += 1
        let generation = importGeneration

        GlassesLog.log("import started")
        LocalNetworkAuthorization.request { [weak self] status in
            guard let self = self, self.isCurrentImport(generation) else { return }
            GlassesLog.log("local network permission: \(status)")
            if status == .denied {
                self.failImport(code: 2003, detail: "Local Network permission is off") // Local Network access is off for the app
                return
            }
            // Measured: asking for the hotspot 2 s after a transfer stop, the glasses accepted but
            // their hotspot took ~55 s to appear (normally ~17 s). Give them a short break.
            let sinceStop = self.lastTransferStop.map { Date().timeIntervalSince($0) } ?? .infinity
            let wait = max(0, Self.transferRestartGap - sinceStop)
            if wait > 0 {
                GlassesLog.log("glasses left transfer mode \(Int(sinceStop)) s ago; waiting \(Int(wait.rounded(.up))) s before asking again")
                self.sendEvent(name: "importProgress", data: ["status": "openingWifi"])
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.joinGlassesWiFi(generation: generation)
            }
        }
        result(true)
    }

    /// Minimum time between ending a transfer and asking the glasses for their hotspot again.
    private static let transferRestartGap: TimeInterval = 10

    private func isCurrentImport(_ generation: Int) -> Bool {
        importing && generation == importGeneration
    }

    private func joinGlassesWiFi(generation: Int) {
        GlassesWiFiLink.connect(peripheral: targetPeripheral, step: { [weak self] step in
            guard let self = self, self.isCurrentImport(generation) else { return }
            // Every step also keeps the Flutter import watchdog alive.
            switch step {
            case .openingWiFi:
                self.sendEvent(name: "importProgress", data: ["status": "openingWifi"])
            case .waitingForHotspot:
                // Same as Android: keep the glasses in transfer mode while their hotspot starts.
                if let peripheral = self.targetPeripheral {
                    GlassesTransferHeartbeat.start(peripheral: peripheral)
                }
                self.sendEvent(name: "importProgress", data: ["status": "waitingHotspot"])
            case .needsWiFiDisconnect:
                // iOS can't switch from the phone's Wi‑Fi: the app asks the user to disconnect.
                self.sendEvent(name: "importProgress", data: ["status": "disconnectWifi"])
            case .wifiDisconnected:
                self.sendEvent(name: "importProgress", data: ["status": "wifiDisconnected"])
            case .joining(let attempt, let total):
                self.sendEvent(name: "importProgress", data: ["status": "joiningWifi", "attempt": attempt, "total": total])
            }
        }, completion: { [weak self] outcome in
            guard let self = self, self.isCurrentImport(generation) else { return }
            switch outcome {
            case .joined(_, let host):
                // Keep the heartbeat running for the whole download. The Android SDK sends it until
                // the transfer is ended; without it the glasses drop out of transfer mode and their
                // HTTP server stops answering (media.config → NSURLErrorDomain -1001 timed out).
                // `restoreAfterTransfer()` stops it.
                self.sendEvent(name: "importProgress", data: ["status": "wifiJoined"])
                self.startDownload(host: host, generation: generation)
            case .declined:
                self.failImport(code: 2010, detail: "Join was cancelled")
            case .busy(let mode):
                self.failImport(code: mode, detail: "glasses busy in mode \(mode)")
            case .noResponse:
                self.failImport(code: 2011, detail: "no answer to the open-Wi-Fi command")
            case .joinFailed(let detail):
                self.failImport(code: 2000, detail: detail)
            case .couldNotLeaveWiFi(let detail):
                self.failImport(code: 2012, detail: detail)
            case .unsupported:
                self.failImport(code: -1, detail: "not supported on this device")
            }
        })
    }

    private func startDownload(host: String, generation: Int) {
        let callbacks = GlassesMediaDownloader.Callbacks(
            onCount: { [weak self] index, total in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.markImportStarted()
                self.sendEvent(name: "importProgress", data: ["status": "count", "index": index, "total": total])
            },
            onProgress: { [weak self] file, percent in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.currentImportFile = file
                self.sendEvent(name: "importProgress", data: ["status": "downloading", "file": file, "progress": percent])
            },
            onSpeed: { [weak self] speed in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.sendEvent(name: "importProgress", data: ["status": "speed", "speed": speed])
            },
            onFile: { [weak self] file in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.pendingNormalizations += 1
                GlassesMediaNormalizer.normalize(file) { [weak self] media in
                    guard let self = self else { return }
                    self.pendingNormalizations -= 1
                    guard generation == self.importGeneration else { return }
                    if let media = media {
                        self.sendEvent(name: "mediaImported", data: media)
                    } else {
                        self.sendEvent(name: "importProgress", data: [
                            "status": "fileError", "fileType": 0, "file": file.lastPathComponent,
                        ])
                    }
                    self.finishImportIfDone()
                }
            },
            onFileError: { [weak self] file, code in
                guard let self = self, self.isCurrentImport(generation) else { return }
                self.sendEvent(name: "importProgress", data: [
                    "status": "fileError", "fileType": 0, "file": file, "code": code,
                ])
            },
            onFinish: { [weak self] errorCode in
                guard let self = self, self.isCurrentImport(generation) else { return }
                let detail = self.downloader?.lastError
                self.downloader = nil
                if let code = errorCode {
                    self.failImport(code: code, detail: detail)
                } else {
                    self.markImportStarted()
                    self.downloadFinished = true
                    self.finishImportIfDone()
                }
            }
        )
        let downloader = GlassesMediaDownloader(
            host: host,
            directory: GlassesMediaNormalizer.albumDirectory(),
            callbacks: callbacks
        )
        self.downloader = downloader
        downloader.start()
    }

    private func markImportStarted() {
        guard !importStarted else { return }
        importStarted = true
        sendEvent(name: "workState", data: ["mode": Mode.transfer, "source": "import"])
        sendEvent(name: "importProgress", data: ["status": "started"])
    }

    private func finishImportIfDone() {
        guard importing, downloadFinished, pendingNormalizations <= 0 else { return }
        finishImport()
    }

    private func finishImport() {
        importing = false
        GlassesLog.log("import complete")
        sendEvent(name: "importProgress", data: ["status": "complete"])
        restoreAfterTransfer()
    }

    private func failImport(code: Int, detail: String? = nil) {
        importing = false
        downloader?.cancel()
        downloader = nil
        GlassesLog.log("import failed: code \(code)\(detail.map { " — \($0)" } ?? "")")
        var data: [String: Any] = ["status": "fail", "code": code]
        if let detail = detail { data["detail"] = detail }
        sendEvent(name: "importProgress", data: data)
        restoreAfterTransfer()
    }

    private func cancelImport() {
        importing = false
        importGeneration += 1
        downloader?.cancel()
        downloader = nil
        restoreAfterTransfer()
    }

    /// Glasses back to normal mode (so capture works again), phone back to its usual Wi‑Fi.
    private func restoreAfterTransfer() {
        GlassesTransferHeartbeat.stop()
        GlassesWiFiLink.leave()
        QCGlassesBridge.shared.leaveGlassesWiFi()
        guard isConnected else { return }
        lastTransferStop = Date()
        QCGlassesBridge.shared.setMode(Mode.transferStop) { [weak self] _, _, _ in
            self?.sendEvent(name: "workState", data: ["mode": 0, "source": "transferStop"])
        }
    }

    // MARK: - Glasses audio

    /// iOS routes audio to the glasses once they are connected as a Bluetooth audio device.
    private func audioStatus() -> [String: Any] {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        let bluetooth: [AVAudioSession.Port] = [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE]
        if let port = outputs.first(where: { bluetooth.contains($0.portType) }) {
            return [
                "state": "connected",
                "name": port.portName,
                "address": port.uid,
                "media": port.portType != .bluetoothHFP,
                "calls": port.portType == .bluetoothHFP,
            ]
        }
        return ["state": isConnected ? "paired" : "notPaired"]
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state != .unknown, central.state != .resetting else { return }
        sendEvent(name: "bluetoothStateChanged", data: [
            "enabled": central.state == .poweredOn,
            "state": GlassesPlatformHandler.stateName(central.state),
        ])
        if !pendingStateResults.isEmpty {
            let isEnabled = central.state == .poweredOn
            let waiting = pendingStateResults
            pendingStateResults.removeAll()
            waiting.forEach { $0(isEnabled) }
        }
        if central.state == .poweredOn {
            if isScanning { beginScan(central) }
            // Bluetooth came back: quietly reconnect the glasses we were using.
            if let peripheral = targetPeripheral, !unbinding, peripheral.state != .connected {
                central.connect(peripheral, options: connectOptions())
            }
        } else {
            if sdkReady {
                sdkReady = false
                QCGlassesBridge.shared.detachAll()
                sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard isScanning else { return }
        let advertised = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let rssi = RSSI.intValue == 127 ? -90 : RSSI.intValue
        report(peripheral, rssi: rssi, advertisedName: advertised)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard targetPeripheral?.identifier == peripheral.identifier else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        attachSDK(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard targetPeripheral?.identifier == peripheral.identifier else { return }
        sdkReady = false
        targetPeripheral = nil
        sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard targetPeripheral?.identifier == peripheral.identifier else { return }
        let wasReady = sdkReady
        sdkReady = false
        QCGlassesBridge.shared.detach(peripheral)
        if importing { failImport(code: -1, detail: "glasses Bluetooth disconnected") }
        sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
        if unbinding || !wasReady {
            targetPeripheral = nil
            return
        }
        // Out of range / powered off: iOS keeps this request open and reconnects when the
        // glasses come back, then didConnect runs the SDK handshake again.
        central.connect(peripheral, options: connectOptions())
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func sendEvent(name: String, data: [String: Any]) {
        var payload = data
        payload["event"] = name
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(payload)
        }
    }
}
