import '../../domain/entities/bluetooth_enable_result.dart';
import '../../domain/entities/glasses_audio_status.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../../domain/entities/glasses_work_mode.dart';
import '../../domain/repositories/glasses_repository.dart';
import '../datasources/glasses_local_datasource.dart';
import '../datasources/glasses_remote_datasource.dart';
import '../models/glasses_media_model.dart';

class GlassesRepositoryImpl implements GlassesRepository {
  final GlassesRemoteDataSource remoteDataSource;
  final GlassesLocalDataSource localDataSource;

  GlassesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<void> initializeSDK() => remoteDataSource.initializeSDK();

  @override
  Future<Map<String, dynamic>> getConnectedDevice() =>
      remoteDataSource.getConnectedDevice();

  @override
  Future<void> startScan() => remoteDataSource.startScan();

  @override
  Future<void> stopScan() => remoteDataSource.stopScan();

  @override
  Future<BluetoothEnableResult> enableBluetooth() =>
      remoteDataSource.enableBluetooth();

  @override
  Future<bool> isBluetoothEnabled() => remoteDataSource.isBluetoothEnabled();

  @override
  Future<void> connectDevice(String address, {String? name}) =>
      remoteDataSource.connectDevice(address, name: name);

  @override
  Future<void> disconnectDevice() => remoteDataSource.disconnectDevice();

  @override
  Future<void> syncTime() => remoteDataSource.syncTime();

  @override
  Future<void> getBatteryLevel() => remoteDataSource.getBatteryLevel();

  @override
  Stream<Map<String, dynamic>> get eventStream => remoteDataSource.eventStream;

  @override
  Future<String?> getSavedDeviceAddress() =>
      localDataSource.getSavedDeviceAddress();

  @override
  Future<String?> getSavedDeviceName() => localDataSource.getSavedDeviceName();

  @override
  Future<void> saveDevice(String address, {String? name}) =>
      localDataSource.saveDevice(address, name: name);

  @override
  Future<void> clearSavedDevice() => localDataSource.clearSavedDevice();

  @override
  Future<GlassesCommandResult> setDeviceMode(int mode) =>
      remoteDataSource.setDeviceMode(mode);

  @override
  Future<void> endTransfer() => remoteDataSource.endTransfer();

  @override
  Future<GlassesDeviceSettings?> getDeviceSettings() =>
      remoteDataSource.getDeviceSettings();

  @override
  Future<bool?> setWearDetection(bool enabled) =>
      remoteDataSource.setWearDetection(enabled);

  @override
  Future<bool?> setVoiceWakeup(bool enabled) =>
      remoteDataSource.setVoiceWakeup(enabled);

  @override
  Future<bool> setVolume({int? music, int? call, int? system}) =>
      remoteDataSource.setVolume(music: music, call: call, system: system);

  @override
  Future<GlassesCameraSettings> getCameraSettings() =>
      localDataSource.getCameraSettings();

  @override
  Future<void> saveCameraSettings(GlassesCameraSettings settings) =>
      localDataSource.saveCameraSettings(settings);

  @override
  Future<bool> syncCameraSettingsToDevice(
    GlassesCameraSettings settings,
  ) async {
    final duration = settings.durationLimit.seconds;
    final angle = settings.videoResolution == VideoResolution.res4K
        ? 0
        : (settings.videoResolution == VideoResolution.res3K ? 1 : 2);
    return remoteDataSource.setVideoConfig(angle: angle, duration: duration);
  }

  @override
  Future<GlassesAudioStatus> getAudioStatus() =>
      remoteDataSource.getAudioStatus();

  @override
  Future<GlassesAudioStatus> connectAudio() => remoteDataSource.connectAudio();

  @override
  Future<void> openBluetoothSettings() =>
      remoteDataSource.openBluetoothSettings();

  @override
  Future<void> importAlbum() => remoteDataSource.importAlbum();

  @override
  Future<GlassesPendingMedia?> getPendingMedia() async {
    final counts = await remoteDataSource.getMediaCount();
    if (counts == null) return null;
    return GlassesPendingMedia(
      images: counts['images'] ?? 0,
      videos: counts['videos'] ?? 0,
      audio: counts['audio'] ?? 0,
    );
  }

  @override
  Future<List<GlassesMediaItem>> loadMedia() => localDataSource.loadMedia();

  @override
  Future<int> repairMedia() async {
    final recovered = await remoteDataSource.repairAlbum();
    for (final map in recovered) {
      final item = GlassesMediaModel.fromEvent(map);
      if (item.filePath.isNotEmpty) await localDataSource.saveMedia(item);
    }
    return recovered.length;
  }

  @override
  Future<void> saveMedia(GlassesMediaItem item) =>
      localDataSource.saveMedia(item);

  @override
  Future<void> deleteMedia(GlassesMediaItem item) =>
      localDataSource.deleteMedia(item);
}
