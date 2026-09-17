import '../datasources/glasses_local_datasource.dart';
import '../datasources/glasses_remote_datasource.dart';
import '../../domain/repositories/glasses_repository.dart';

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
  Future<void> enableBluetooth() => remoteDataSource.enableBluetooth();

  @override
  Future<bool> isBluetoothEnabled() => remoteDataSource.isBluetoothEnabled();

  @override
  Future<void> connectDevice(String address) async {
    await remoteDataSource.connectDevice(address);
    await localDataSource.saveDeviceAddress(address);
  }

  @override
  Future<void> disconnectDevice() async {
    await remoteDataSource.disconnectDevice();
  }

  @override
  Future<void> syncTime() => remoteDataSource.syncTime();

  @override
  Future<void> getBatteryLevel() => remoteDataSource.getBatteryLevel();

  @override
  Future<void> takePhoto() => remoteDataSource.takePhoto();

  @override
  Future<void> toggleRecording(bool start) =>
      remoteDataSource.toggleRecording(start);

  @override
  Future<void> toggleVoiceRecording(bool start) =>
      remoteDataSource.toggleVoiceRecording(start);

  @override
  Future<void> importAlbum() => remoteDataSource.importAlbum();

  @override
  Stream<Map<String, dynamic>> get eventStream => remoteDataSource.eventStream;

  @override
  Future<String?> getSavedDeviceAddress() =>
      localDataSource.getSavedDeviceAddress();

  @override
  Future<void> saveDeviceAddress(String address) =>
      localDataSource.saveDeviceAddress(address);

  @override
  Future<void> clearSavedDeviceAddress() =>
      localDataSource.clearSavedDeviceAddress();
}
