abstract class GlassesRepository {
  Future<void> initializeSDK();
  Future<Map<String, dynamic>> getConnectedDevice();
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> enableBluetooth();
  Future<bool> isBluetoothEnabled();
  Future<void> connectDevice(String address);
  Future<void> disconnectDevice();
  Future<void> syncTime();
  Future<void> getBatteryLevel();
  Future<void> takePhoto();
  Future<void> toggleRecording(bool start);
  Future<void> toggleVoiceRecording(bool start);
  Future<void> importAlbum();
  Stream<Map<String, dynamic>> get eventStream;
  Future<String?> getSavedDeviceAddress();
  Future<void> saveDeviceAddress(String address);
  Future<void> clearSavedDeviceAddress();
}
