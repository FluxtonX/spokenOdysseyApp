import '../entities/bluetooth_enable_result.dart';
import '../entities/glasses_audio_status.dart';
import '../entities/glasses_device_settings.dart';
import '../entities/glasses_media_item.dart';
import '../entities/glasses_work_mode.dart';

abstract class GlassesRepository {
  // Connection
  Future<void> initializeSDK();
  Future<Map<String, dynamic>> getConnectedDevice();
  Future<void> startScan();
  Future<void> stopScan();
  Future<BluetoothEnableResult> enableBluetooth();
  Future<bool> isBluetoothEnabled();
  Future<void> connectDevice(String address, {String? name});
  Future<void> disconnectDevice();
  Future<void> syncTime();
  Future<void> getBatteryLevel();
  Stream<Map<String, dynamic>> get eventStream;

  // Saved device
  Future<String?> getSavedDeviceAddress();
  Future<String?> getSavedDeviceName();
  Future<void> saveDevice(String address, {String? name});
  Future<void> clearSavedDevice();

  // Capture / device modes
  Future<GlassesCommandResult> setDeviceMode(int mode);
  Future<void> endTransfer();

  // Device settings (stored on the glasses)
  Future<GlassesDeviceSettings?> getDeviceSettings();
  Future<bool?> setWearDetection(bool enabled);
  Future<bool?> setVoiceWakeup(bool enabled);
  Future<bool> setVolume({int? music, int? call, int? system});

  // Camera settings (stored locally & synced to glasses)
  Future<GlassesCameraSettings> getCameraSettings();
  Future<void> saveCameraSettings(GlassesCameraSettings settings);
  Future<bool> syncCameraSettingsToDevice(GlassesCameraSettings settings);

  // Audio link (sound through the glasses)
  Future<GlassesAudioStatus> getAudioStatus();
  Future<GlassesAudioStatus> connectAudio();
  Future<void> openBluetoothSettings();

  // Media
  Future<void> importAlbum();
  Future<GlassesPendingMedia?> getPendingMedia();
  Future<List<GlassesMediaItem>> loadMedia();

  /// Converts media imported in the glasses' raw bundle format into normal files.
  Future<int> repairMedia();
  Future<void> saveMedia(GlassesMediaItem item);
  Future<void> deleteMedia(GlassesMediaItem item);
}
