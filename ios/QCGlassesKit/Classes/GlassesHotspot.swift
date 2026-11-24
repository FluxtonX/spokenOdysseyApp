import CoreBluetooth
import Foundation

/// Turns on the glasses' Wi‑Fi **hotspot** (access point) for a media transfer.
///
/// The glasses have two transfer modes, chosen by the 4th byte of the "transfer" control command
/// (`0x41`, payload `02 01 04 xx`), as used by the official HeyCyan app:
/// - `02 01 04 01`: Wi‑Fi Direct (P2P). Android's default; an iPhone can't join it.
/// - `02 01 04 02`: hotspot. The official app's "Compatibility transfer" ("connect your phone to
///   the glasses hotspot"). This is the only mode an iPhone can join.
///
/// The iOS QCSDK's `openWifi(.transfer)` sends `02 01 04` without the 4th byte, which starts
/// Wi‑Fi Direct: the glasses accept and report an SSID, but no network ever appears for iOS
/// ("Unable to join the network"). So the hotspot command is written here directly.
///
/// Reply (same frame as every `0x41` reply): `02 01 04 <accepted> …`. `accepted == 0` means the
/// glasses refused and the next bytes are the mode they are busy in (666 = hotspot already on,
/// treated as success like the official app does).
enum GlassesHotspot {

    enum Reply {
        /// Hotspot is on. The reply may carry the network name and password.
        case accepted(ssid: String?, password: String?)
        /// The glasses refused; `mode` is what they are busy with (QCOperatorDeviceMode value).
        case busy(mode: Int)
        /// No reply seen (the command may still have worked).
        case noReply
    }

    private static let hotspotPayload: [UInt8] = [0x02, 0x01, 0x04, 0x02]
    private static let alreadyOnMode = 666

    /// Sends the hotspot command and waits for the glasses' answer. Completion on the main queue.
    static func request(peripheral: CBPeripheral, completion: @escaping (Reply) -> Void) {
        let reply = Once<Reply>(timeout: 8, fallback: .noReply) { result in
            GlassesNotifyTap.stop()
            completion(result)
        }
        var buffer: [UInt8] = []
        let tapped = GlassesNotifyTap.start(on: peripheral) { chunk in
            DispatchQueue.main.async {
                let bytes = [UInt8](chunk)
                if bytes.first == 0xBC {
                    buffer = bytes
                } else if !buffer.isEmpty {
                    buffer += bytes
                } else {
                    return
                }
                guard buffer.count >= 6 else { return }
                let length = Int(buffer[2]) | Int(buffer[3]) << 8
                guard buffer.count >= 6 + length else { return }
                let frame = Array(buffer.prefix(6 + length))
                buffer = []
                guard frame[1] == 0x41 else { return }
                let payload = Array(frame.dropFirst(6))
                guard payload.count >= 4, payload[0] == 0x02, payload[1] == 0x01, payload[2] == 0x04 else { return }
                reply(parse(payload))
            }
        }
        if !tapped {
            GlassesLog.log("couldn't listen for the hotspot reply; sending the command anyway")
        }
        guard GlassesTransferHeartbeat.write(command: 0x41, payload: hotspotPayload, to: peripheral) else {
            GlassesLog.log("couldn't send the hotspot command: glasses not connected")
            reply(.busy(mode: -1))
            return
        }
        GlassesLog.log("sent hotspot command 02 01 04 02")
    }

    private static func parse(_ payload: [UInt8]) -> Reply {
        let hex = payload.prefix(12).map { String(format: "%02x", $0) }.joined(separator: " ")
        GlassesLog.log("hotspot reply: \(hex)\(payload.count > 12 ? " …" : "")")
        if payload[3] == 0 {
            var mode = payload.count > 4 ? Int(payload[4]) : 0
            if payload.count > 5 { mode |= Int(payload[5]) << 8 }
            if mode == alreadyOnMode { return .accepted(ssid: nil, password: nil) }
            return .busy(mode: mode)
        }
        // Same layout as the Wi‑Fi Direct reply: name length, password length (UInt16 LE each),
        // then the name and the password.
        guard payload.count >= 8 else { return .accepted(ssid: nil, password: nil) }
        let ssidLength = Int(payload[4]) | Int(payload[5]) << 8
        let passwordLength = Int(payload[6]) | Int(payload[7]) << 8
        guard ssidLength > 0, 8 + ssidLength + passwordLength <= payload.count else {
            return .accepted(ssid: nil, password: nil)
        }
        let ssid = String(bytes: payload[8..<(8 + ssidLength)], encoding: .utf8)
        let password = String(bytes: payload[(8 + ssidLength)..<(8 + ssidLength + passwordLength)], encoding: .utf8)
        return .accepted(ssid: ssid, password: password)
    }

    // MARK: - Saved credentials (the official app saves them too)

    struct Credentials {
        let ssid: String
        let password: String
    }

    private static func key(_ peripheral: CBPeripheral) -> String {
        "GlassesHotspotCredentials.\(peripheral.identifier.uuidString)"
    }

    static func savedCredentials(for peripheral: CBPeripheral) -> Credentials? {
        guard let value = UserDefaults.standard.dictionary(forKey: key(peripheral)),
              let ssid = value["ssid"] as? String, !ssid.isEmpty,
              let password = value["password"] as? String else { return nil }
        return Credentials(ssid: ssid, password: password)
    }

    static func save(_ credentials: Credentials, for peripheral: CBPeripheral) {
        UserDefaults.standard.set(["ssid": credentials.ssid, "password": credentials.password],
                                  forKey: key(peripheral))
    }

    static func forgetCredentials(for peripheral: CBPeripheral) {
        UserDefaults.standard.removeObject(forKey: key(peripheral))
    }
}

/// Lets us read the glasses' Bluetooth notifications for a moment without taking them away from
/// the QCSDK: it sits in front of the SDK's peripheral delegate and forwards every call to it.
final class GlassesNotifyTap: NSObject, CBPeripheralDelegate {

    private static var active: GlassesNotifyTap?

    private weak var peripheral: CBPeripheral?
    private weak var original: CBPeripheralDelegate?
    private let handler: (Data) -> Void

    private init(peripheral: CBPeripheral, original: CBPeripheralDelegate, handler: @escaping (Data) -> Void) {
        self.peripheral = peripheral
        self.original = original
        self.handler = handler
        super.init()
    }

    /// Returns false when there is no delegate to sit in front of.
    static func start(on peripheral: CBPeripheral, handler: @escaping (Data) -> Void) -> Bool {
        stop()
        guard let original = peripheral.delegate else { return false }
        let tap = GlassesNotifyTap(peripheral: peripheral, original: original, handler: handler)
        peripheral.delegate = tap
        active = tap
        return true
    }

    /// Gives the delegate back to the SDK.
    static func stop() {
        guard let tap = active else { return }
        active = nil
        if let peripheral = tap.peripheral, peripheral.delegate === tap {
            peripheral.delegate = tap.original
        }
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return original?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original = original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil, let value = characteristic.value {
            handler(value)
        }
        original?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
    }
}
