import CoreBluetooth
import Foundation

/// Keeps the glasses in Wi‑Fi transfer mode while the phone joins their hotspot.
///
/// The Android SDK (`GlassesControl.importAlbum`) sends `LargeDataHandler.syncHeartBeat(0x04)`
/// every 5 s from the moment the glasses accept the transfer command until the download starts.
/// The iOS QCSDK has no such call, so the packet is written here directly:
///
///   0xBC, cmd 0x45, length (UInt16 LE), CRC‑16/MODBUS of payload (UInt16 LE), payload [0x04, 0x01]
///
/// on the large-data serial service `de5bf728…`, write characteristic `de5bf72a…` (same as Android's
/// `SERIAL_PORT_SERVICE` / `SERIAL_PORT_CHARACTER_WRITE`, and the channel the QCSDK itself uses).
public final class GlassesTransferHeartbeat {

    private static let serviceUUID = CBUUID(string: "de5bf728-d711-4e47-af26-65e3012a5dc7")
    private static let writeUUID = CBUUID(string: "de5bf72a-d711-4e47-af26-65e3012a5dc7")
    private static let interval: TimeInterval = 5

    private static var timer: Timer?
    private static weak var peripheral: CBPeripheral?

    /// Starts sending the heartbeat (first one right away). Safe to call repeatedly.
    public static func start(peripheral: CBPeripheral) {
        stop()
        self.peripheral = peripheral
        send()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in send() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        GlassesLog.log("heartbeat started (every \(Int(interval)) s)")
    }

    public static func stop() {
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
        GlassesLog.log("heartbeat stopped")
    }

    private static func send() {
        guard let peripheral = peripheral else {
            GlassesLog.log("heartbeat skipped: glasses not connected")
            return
        }
        if !write(command: 0x45, payload: [0x04, 0x01], to: peripheral) {
            GlassesLog.log("heartbeat skipped: glasses not connected or write characteristic not found")
        }
    }

    /// Writes one large-data frame (`0xBC`, command, length, CRC, payload) to the glasses.
    /// Returns false when the glasses aren't connected or the characteristic isn't there.
    @discardableResult
    static func write(command: UInt8, payload: [UInt8], to peripheral: CBPeripheral) -> Bool {
        guard peripheral.state == .connected,
              let characteristic = peripheral.services?
                .first(where: { $0.uuid == serviceUUID })?
                .characteristics?
                .first(where: { $0.uuid == writeUUID }) else {
            return false
        }
        let type: CBCharacteristicWriteType =
            characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        peripheral.writeValue(packet(command: command, payload: payload), for: characteristic, type: type)
        return true
    }

    /// Glasses large-data frame (same as Android `LargeDataHandler.addHeader`).
    static func packet(command: UInt8, payload: [UInt8]) -> Data {
        let length = UInt16(payload.count)
        let crc = crc16Modbus(payload)
        var bytes: [UInt8] = [0xBC, command]
        bytes += [UInt8(length & 0xFF), UInt8(length >> 8)]
        bytes += [UInt8(crc & 0xFF), UInt8(crc >> 8)]
        bytes += payload
        return Data(bytes)
    }

    /// CRC‑16/MODBUS (init 0xFFFF, reflected poly 0xA001), as in Android `CRC16.calcCrc16`.
    static func crc16Modbus(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in bytes {
            crc ^= UInt16(byte)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1
            }
        }
        return crc
    }
}

/// Import diagnostics. Lines start with `[GlassesImport]` in the Xcode / `flutter run` console.
public enum GlassesLog {
    public static func log(_ message: String) {
        NSLog("[GlassesImport] %@", message)
    }
}
