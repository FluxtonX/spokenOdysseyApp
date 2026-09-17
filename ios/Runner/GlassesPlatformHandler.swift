import Flutter
import UIKit
import CoreBluetooth
import AVFoundation

@objc class GlassesPlatformHandler: NSObject, FlutterStreamHandler, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = GlassesPlatformHandler()
    private var eventSink: FlutterEventSink?
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var isScanning = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setupAudioSession()
    }
    
    func register(with binaryMessenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(name: "com.fluxtonx.spokenodyssey/glasses", binaryMessenger: binaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }
        
        let eventChannel = FlutterEventChannel(name: "com.fluxtonx.spokenodyssey/glasses_events", binaryMessenger: binaryMessenger)
        eventChannel.setStreamHandler(self)
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[GlassesPlatformHandler] AVAudioSession error: \(error)")
        }
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeSDK":
            result(true)
            
        case "getConnectedDevice":
            if let peripheral = connectedPeripheral, peripheral.state == .connected {
                result([
                    "isConnected": true,
                    "name": peripheral.name ?? "Spoken Glasses",
                    "address": peripheral.identifier.uuidString
                ])
            } else {
                result(["isConnected": false])
            }
            
        case "startScan":
            discoveredPeripherals.removeAll()
            isScanning = true
            if centralManager?.state == .poweredOn {
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            }
            result(true)
            
        case "enableBluetooth":
            result(true)

        case "isBluetoothEnabled":
            let isEnabled = centralManager?.state == .poweredOn
            result(isEnabled)
            
        case "stopScan":
            isScanning = false
            centralManager?.stopScan()
            result(true)
            
        case "connectDevice":
            let args = call.arguments as? [String: Any]
            let address = args?["address"] as? String ?? ""
            if let peripheral = discoveredPeripherals[address] {
                connectedPeripheral = peripheral
                peripheral.delegate = self
                sendEvent(name: "connectionStateChanged", data: ["state": "connecting", "address": address])
                centralManager?.connect(peripheral, options: nil)
            } else {
                sendEvent(name: "connectionStateChanged", data: ["state": "connecting", "address": address])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.sendEvent(name: "connectionStateChanged", data: ["state": "connected", "address": address])
                    self?.sendEvent(name: "batteryUpdated", data: ["battery": 90, "isCharging": false])
                }
            }
            result(true)
            
        case "disconnectDevice":
            if let peripheral = connectedPeripheral {
                centralManager?.cancelPeripheralConnection(peripheral)
                connectedPeripheral = nil
            }
            sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
            result(true)
            
        case "syncTime":
            result(true)
            
        case "getBatteryLevel":
            sendEvent(name: "batteryUpdated", data: ["battery": 90, "isCharging": false])
            result(true)
            
        case "takePhoto":
            result(true)
            
        case "toggleRecording":
            result(true)

        case "toggleVoiceRecording":
            result(true)

        case "importAlbum":
            sendEvent(name: "importProgress", data: ["status": "started"])
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.sendEvent(name: "importProgress", data: ["status": "complete"])
            }
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isScanning {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? ""
        if !name.isEmpty && (name.hasPrefix("O_") || name.hasPrefix("Q_") || name.localizedCaseInsensitiveContains("Cyan") || name.localizedCaseInsensitiveContains("Glass")) {
            let uuidStr = peripheral.identifier.uuidString
            discoveredPeripherals[uuidStr] = peripheral
            sendEvent(name: "scanResult", data: [
                "name": name,
                "address": uuidStr,
                "rssi": RSSI.intValue
            ])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let uuidStr = peripheral.identifier.uuidString
        sendEvent(name: "connectionStateChanged", data: [
            "state": "connected",
            "address": uuidStr
        ])
        sendEvent(name: "batteryUpdated", data: ["battery": 90, "isCharging": false])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        sendEvent(name: "connectionStateChanged", data: ["state": "disconnected"])
    }
    
    // MARK: - FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
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
