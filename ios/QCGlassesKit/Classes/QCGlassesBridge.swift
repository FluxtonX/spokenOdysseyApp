import CoreBluetooth
import Foundation
import NetworkExtension

#if !targetEnvironment(simulator) && canImport(QCSDK)
import QCSDK
#endif

/// Thin Swift wrapper around the vendor QCSDK (glasses protocol over BLE + Wi‑Fi media download).
///
/// The SDK only ships a device slice, so on the Simulator every call reports failure and
/// `isSupported` is false. All completions are delivered on the main queue exactly once
/// (SDK callbacks that never fire are turned into a failure after a timeout).
public final class QCGlassesBridge: NSObject {

    public static let shared = QCGlassesBridge()

    /// True when the QCSDK is compiled in (real device builds).
    public static var isSupported: Bool {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        return true
        #else
        return false
        #endif
    }

    /// GATT services the glasses expose; used to find glasses the system is already connected to.
    public static var serviceUUIDs: [CBUUID] {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        return [CBUUID(string: QCSDKSERVERUUID1), CBUUID(string: QCSDKSERVERUUID2)]
        #else
        return []
        #endif
    }

    /// Battery pushed by the glasses (percent, charging).
    public var onBattery: ((Int, Bool) -> Void)?
    /// Media counters pushed by the glasses (photos, videos, audio).
    public var onMediaCount: ((Int, Int, Int) -> Void)?

    private override init() {
        super.init()
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKManager.shareInstance().delegate = self
        // SDK logs ([QCLog] …) go to the device console; they make field issues diagnosable.
        QCSDKManager.shareInstance().debug = true
        #endif
    }

    // MARK: - Peripheral

    /// Hands a connected peripheral to the SDK (service discovery + protocol handshake).
    public func attach(_ peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        let reply = Once(timeout: 20, fallback: false, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        let manager = QCSDKManager.shareInstance()
        manager.remove(peripheral)
        manager.add(peripheral) { success in reply(success) }
        #else
        reply(false)
        #endif
    }

    public func detach(_ peripheral: CBPeripheral) {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKManager.shareInstance().remove(peripheral)
        #endif
    }

    public func detachAll() {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKManager.shareInstance().removeAllPeripheral()
        #endif
    }

    // MARK: - Commands

    /// Sends a QCOperatorDeviceMode. `busyMode` is the mode the glasses are stuck in when they refuse.
    public func setMode(_ mode: Int, completion: @escaping (_ ok: Bool, _ timedOut: Bool, _ busyMode: Int?) -> Void) {
        let reply = Once<(Bool, Bool, Int?)>(timeout: 8, fallback: (false, true, nil)) { completion($0.0, $0.1, $0.2) }
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        guard let value = QCOperatorDeviceMode(rawValue: mode) else {
            reply((false, false, nil))
            return
        }
        QCSDKCmdCreator.setDeviceMode(value, success: {
            reply((true, false, nil))
        }, fail: { busy in
            reply((false, false, busy))
        })
        #else
        reply((false, false, nil))
        #endif
    }

    public func battery(_ completion: @escaping (_ level: Int?, _ charging: Bool) -> Void) {
        let reply = Once<(Int?, Bool)>(timeout: 6, fallback: (nil, false)) { completion($0.0, $0.1) }
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.getDeviceBattery({ level, charging in
            reply((level, charging))
        }, fail: {
            reply((nil, false))
        })
        #else
        reply((nil, false))
        #endif
    }

    public func syncTime(_ completion: @escaping (Bool) -> Void) {
        let reply = Once(timeout: 6, fallback: false, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.setupDeviceDateTime { ok, _ in reply(ok) }
        #else
        reply(false)
        #endif
    }

    /// Photo / video / audio counts stored on the glasses.
    public func mediaCount(_ completion: @escaping ([String: Int]?) -> Void) {
        let reply = Once<[String: Int]?>(timeout: 6, fallback: nil, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.getDeviceMedia({ photos, videos, audio, _ in
            reply(["images": photos, "videos": videos, "audio": audio])
        }, fail: {
            reply(nil)
        })
        #else
        reply(nil)
        #endif
    }

    public func videoConfig(_ completion: @escaping ([String: Int]?) -> Void) {
        let reply = Once<[String: Int]?>(timeout: 6, fallback: nil, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.getVideoInfoSuccess({ angle, duration in
            reply(["angle": angle, "duration": duration])
        }, fail: {
            reply(nil)
        })
        #else
        reply(nil)
        #endif
    }

    public func setVideoConfig(angle: Int, duration: Int, completion: @escaping (Bool) -> Void) {
        let reply = Once(timeout: 6, fallback: false, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.setVideoInfo(angle, duration: duration, success: {
            reply(true)
        }, fail: {
            reply(false)
        })
        #else
        reply(false)
        #endif
    }

    public func setWearDetection(_ on: Bool, completion: @escaping (_ ok: Bool, _ enabled: Bool) -> Void) {
        let reply = Once<(Bool, Bool)>(timeout: 6, fallback: (false, on)) { completion($0.0, $0.1) }
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.setWearingDetection(on) { ok, _, result in
            reply((ok, QCGlassesBridge.parseSwitch(result) ?? on))
        }
        #else
        reply((false, on))
        #endif
    }

    public func setVoiceWakeup(_ on: Bool, completion: @escaping (_ ok: Bool, _ enabled: Bool) -> Void) {
        let reply = Once<(Bool, Bool)>(timeout: 6, fallback: (false, on)) { completion($0.0, $0.1) }
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.setVoiceWakeup(on) { ok, _, result in
            reply((ok, QCGlassesBridge.parseSwitch(result) ?? on))
        }
        #else
        reply((false, on))
        #endif
    }

    /// Volume levels for music / call / system (with their min/max).
    public func volume(_ completion: @escaping ([String: Int]?) -> Void) {
        let reply = Once<[String: Int]?>(timeout: 6, fallback: nil, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.getVolumeWithFinished { [weak self] ok, _, result in
            guard ok, let model = result as? QCVolumeInfoModel else {
                reply(nil)
                return
            }
            self?.lastVolume = model
            reply([
                "musicMin": model.musicMin, "musicMax": model.musicMax, "music": model.musicCurrent,
                "callMin": model.callMin, "callMax": model.callMax, "call": model.callCurrent,
                "systemMin": model.systemMin, "systemMax": model.systemMax, "system": model.systemCurrent,
                "mode": model.mode.rawValue,
            ])
        }
        #else
        reply(nil)
        #endif
    }

    public func setVolume(music: Int?, call: Int?, system: Int?, completion: @escaping (Bool) -> Void) {
        let reply = Once(timeout: 6, fallback: false, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        guard let current = lastVolume else {
            reply(false)
            return
        }
        let model = QCVolumeInfoModel()
        model.musicMin = current.musicMin
        model.musicMax = current.musicMax
        model.musicCurrent = clamp(music ?? current.musicCurrent, current.musicMin, current.musicMax)
        model.callMin = current.callMin
        model.callMax = current.callMax
        model.callCurrent = clamp(call ?? current.callCurrent, current.callMin, current.callMax)
        model.systemMin = current.systemMin
        model.systemMax = current.systemMax
        model.systemCurrent = clamp(system ?? current.systemCurrent, current.systemMin, current.systemMax)
        model.mode = current.mode
        QCSDKCmdCreator.setVolume(model) { [weak self] ok, _, _ in
            if ok { self?.lastVolume = model }
            reply(ok)
        }
        #else
        reply(false)
        #endif
    }

    /// Reads everything the settings page shows. Steps run one after another (the SDK keeps a
    /// single command in flight) and each one is skipped if the glasses don't answer.
    public func deviceSettings(_ completion: @escaping ([String: Any]) -> Void) {
        var out: [String: Any] = [:]
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        let steps: [(@escaping () -> Void) -> Void] = [
            { next in
                let done = Once<Void>(timeout: 4, fallback: (), { next() })
                QCSDKCmdCreator.getWearingDetection { ok, _, result in
                    if ok {
                        out["wearSupported"] = true
                        if let on = QCGlassesBridge.parseSwitch(result) { out["wearDetection"] = on }
                    }
                    done(())
                }
            },
            { next in
                let done = Once<Void>(timeout: 4, fallback: (), { next() })
                QCSDKCmdCreator.getVoiceWakeup { ok, _, result in
                    if ok, let on = QCGlassesBridge.parseSwitch(result) { out["voiceWakeup"] = on }
                    done(())
                }
            },
            { [weak self] next in
                guard let self = self else { return next() }
                self.volume { levels in
                    if let levels = levels {
                        out["volume"] = levels
                        out["volumeSupported"] = true
                    }
                    next()
                }
            },
            { next in
                let done = Once<Void>(timeout: 4, fallback: (), { next() })
                QCSDKCmdCreator.getDeviceVersionInfoSuccess({ hardware, firmware, hardwareWifi, firmwareWifi in
                    out["hardwareVersion"] = hardware
                    out["firmwareVersion"] = firmware
                    out["wifiHardwareVersion"] = hardwareWifi
                    out["wifiFirmwareVersion"] = firmwareWifi
                    done(())
                }, fail: {
                    done(())
                })
            },
        ]
        func run(_ index: Int) {
            guard index < steps.count else {
                DispatchQueue.main.async { completion(out) }
                return
            }
            let step = steps[index]
            step { DispatchQueue.main.async { run(index + 1) } }
        }
        run(0)
        #else
        DispatchQueue.main.async { completion(out) }
        #endif
    }

    // MARK: - Media download (Wi‑Fi)

    /// SSID of the glasses' Wi‑Fi hotspot, known once the SDK opened it for a download.
    public var glassesWiFiName: String? {
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        let manager = QCSDKManager.shareInstance()
        guard manager.responds(to: NSSelectorFromString("wifiName")) else { return nil }
        let name = manager.value(forKey: "wifiName") as? String
        return (name?.isEmpty ?? true) ? nil : name
        #else
        return nil
        #endif
    }

    /// Leaves the glasses' hotspot so the iPhone goes back to its usual Wi‑Fi (and internet).
    public func leaveGlassesWiFi() {
        let joined = GlassesWiFiLink.currentSSID
        GlassesWiFiLink.leave()
        if let ssid = glassesWiFiName, ssid != joined {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        }
    }

    /// The glasses' address on their Wi‑Fi hotspot (only known once their Wi‑Fi is up).
    public func wifiIPAddress(_ completion: @escaping (String?) -> Void) {
        let reply = Once<String?>(timeout: 4, fallback: nil, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKCmdCreator.getDeviceWifiIPSuccess({ address in
            reply(address)
        }, failed: {
            reply(nil)
        })
        #else
        reply(nil)
        #endif
    }

    /// The QCSDK's own media download (`startToDownloadMediaResource`): the SDK opens the
    /// glasses' Wi‑Fi itself and joins it with its own hotspot manager (`QCSDKWiFiManager` —
    /// NEHotspotConfiguration with retries and its own association timeout), then downloads
    /// every file from the glasses' HTTP server. This is the flow the vendor demo (and the
    /// official app) uses, and the one that manages the switch away from the phone's current
    /// Wi‑Fi by itself.
    ///
    /// The peripheral must already be handed to the SDK (`attach`), which the app does on
    /// connect; no transfer-mode command is needed first — the SDK runs the whole flow.
    ///
    /// - `progress`: overall download percent (0–100), sent only when it changes.
    /// - `file`: one finished file, still in the glasses' raw packed format (unpack it with
    ///   `GlassesMediaNormalizer`), with its 1-based index and the total file count.
    /// - `finish`: called exactly once — nil when every file downloaded, otherwise the SDK's
    ///   error code (QCErrorCode 2000–2006), or -1 when the SDK never answered (30 min) or is
    ///   not available (Simulator). The SDK has no cancel API; after `finish` the caller just
    ///   ignores any late callbacks.
    /// All callbacks run on the main queue.
    public func downloadMedia(progress: @escaping (_ percent: Int) -> Void,
                              file: @escaping (_ url: URL, _ index: Int, _ total: Int) -> Void,
                              finish: @escaping (_ errorCode: Int?) -> Void) {
        let reply = Once<Int?>(timeout: 30 * 60, fallback: -1) { finish($0) }
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        var lastPercent = -1
        QCSDKManager.shareInstance().startToDownloadMediaResource(progress: { _, _, fraction in
            let percent = min(100, max(0, Int((fraction * 100).rounded())))
            guard percent != lastPercent else { return }
            lastPercent = percent
            DispatchQueue.main.async { progress(percent) }
        }, completion: { filePath, error, index, count in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    GlassesLog.log("SDK download failed: \(nsError.domain) \(nsError.code)")
                    reply(nsError.code)
                    return
                }
                if let filePath = filePath, !filePath.isEmpty {
                    GlassesLog.log("SDK downloaded file \(index + 1)/\(count): \((filePath as NSString).lastPathComponent)")
                    file(URL(fileURLWithPath: filePath), index + 1, count)
                }
                if count <= 0 || index >= count - 1 {
                    reply(nil)
                }
            }
        })
        #else
        reply(-1)
        #endif
    }

    /// Decodes the glasses' raw Opus voice notes to 16 kHz / 16-bit / mono PCM.
    public func opusToPcm(input: String, output: String, completion: @escaping (Bool) -> Void) {
        let reply = Once(timeout: 120, fallback: false, completion)
        #if !targetEnvironment(simulator) && canImport(QCSDK)
        QCSDKHelper.shareInstance().convertOpus(toPcm: input, outputPath: output, progress: nil) { ok in
            reply(ok)
        }
        #else
        reply(false)
        #endif
    }

    // MARK: - Helpers

    #if !targetEnvironment(simulator) && canImport(QCSDK)
    private var lastVolume: QCVolumeInfoModel?
    #endif

    private func clamp(_ value: Int, _ low: Int, _ high: Int) -> Int {
        guard high >= low else { return value }
        return min(max(value, low), high)
    }

    /// The SDK reports on/off switches as an untyped value; accept the common shapes.
    static func parseSwitch(_ value: Any?) -> Bool? {
        switch value {
        case let number as NSNumber:
            return number.boolValue
        case let text as String:
            return ["1", "true", "on", "yes"].contains(text.lowercased())
        case let dict as [AnyHashable: Any]:
            for key in ["isOn", "isOpen", "open", "on", "enable", "enabled", "status", "state"] {
                if let found = dict[key], let parsed = parseSwitch(found) { return parsed }
            }
            return nil
        default:
            return nil
        }
    }
}

#if !targetEnvironment(simulator) && canImport(QCSDK)
extension QCGlassesBridge: QCSDKManagerDelegate {
    public func didUpdateBatteryLevel(_ battery: Int, charging: Bool) {
        DispatchQueue.main.async { self.onBattery?(battery, charging) }
    }

    public func didUpdateMedia(withPhotoCount photo: Int, videoCount video: Int, audioCount audio: Int, type: Int) {
        DispatchQueue.main.async { self.onMediaCount?(photo, video, audio) }
    }
}
#endif

/// Calls `completion` exactly once on the main queue: with the first value delivered or with
/// `fallback` after `timeout` seconds.
final class Once<Value> {
    private var fired = false
    private let lock = NSLock()
    private let completion: (Value) -> Void

    init(timeout: TimeInterval, fallback: Value, _ completion: @escaping (Value) -> Void) {
        self.completion = completion
        // Strong capture on purpose: the SDK may drop a callback it never calls, and the
        // fallback must still fire.
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.fire(fallback)
        }
    }

    func callAsFunction(_ value: Value) { fire(value) }

    private func fire(_ value: Value) {
        lock.lock()
        let first = !fired
        fired = true
        lock.unlock()
        guard first else { return }
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async { self.completion(value) }
        }
    }
}
