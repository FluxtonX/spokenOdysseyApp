import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spokenodyssey/features/smart_glasses/domain/entities/glasses_media_item.dart';
import '../../domain/entities/glasses_device.dart';
import '../../domain/repositories/glasses_repository.dart';
import 'glasses_state.dart';

class GlassesCubit extends Cubit<GlassesState> {
  final GlassesRepository repository;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  GlassesCubit({required this.repository}) : super(const GlassesState()) {
    _init();
  }

  void _init() async {
    loadLocalMedia();
    await repository.initializeSDK();
    _listenToEvents();

    final connectedInfo = await repository.getConnectedDevice();
    if (connectedInfo['isConnected'] == true) {
      final name = connectedInfo['name'] as String? ?? 'Spoken Glasses';
      final address = connectedInfo['address'] as String? ?? '';
      final connected = GlassesDevice(
        name: name,
        address: address,
        rssi: -55,
        isConnected: true,
        batteryLevel: 88,
      );
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.connected,
          connectedDevice: connected,
        ),
      );
      repository.syncTime();
      repository.getBatteryLevel();
    } else {
      final savedAddress = await repository.getSavedDeviceAddress();
      if (savedAddress != null && savedAddress.isNotEmpty) {
        connectDevice(savedAddress);
      }
    }
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = repository.eventStream.listen((event) {
      final eventName = event['event'] as String?;
      switch (eventName) {
        case 'scanResult':
          final name = event['name'] as String? ?? 'Smart Glasses';
          final address = event['address'] as String? ?? '';
          final rssi = (event['rssi'] as num?)?.toInt() ?? -70;

          final device = GlassesDevice(
            name: name,
            address: address,
            rssi: rssi,
          );
          final currentList = List<GlassesDevice>.from(state.discoveredDevices);
          if (!currentList.any((d) => d.address == address)) {
            currentList.add(device);
            emit(
              state.copyWith(
                status: GlassesConnectionStatus.scanning,
                discoveredDevices: currentList,
              ),
            );
          }
          break;

        case 'connectionStateChanged':
          final stateStr = event['state'] as String?;
          if (stateStr == 'connected') {
            final address =
                event['address'] as String? ??
                state.connectedDevice?.address ??
                '';
            final connected = GlassesDevice(
              name: 'Spoken Glasses',
              address: address,
              rssi: -55,
              isConnected: true,
              batteryLevel: 90,
            );
            emit(
              state.copyWith(
                status: GlassesConnectionStatus.connected,
                connectedDevice: connected,
              ),
            );
            repository.syncTime();
          } else if (stateStr == 'connecting') {
            emit(state.copyWith(status: GlassesConnectionStatus.connecting));
          } else if (stateStr == 'disconnected') {
            emit(
              state.copyWith(
                status: GlassesConnectionStatus.disconnected,
                connectedDevice: null,
              ),
            );
          }
          break;

        case 'batteryUpdated':
          final battery = (event['battery'] as num?)?.toInt() ?? 80;
          final isCharging = event['isCharging'] as bool? ?? false;
          if (state.connectedDevice != null) {
            final updated = state.connectedDevice!.copyWith(
              batteryLevel: battery,
              isCharging: isCharging,
            );
            emit(state.copyWith(connectedDevice: updated));
          }
          break;

        case 'importProgress':
          final status = event['status'] as String?;
          final file = event['file'] as String? ?? '';
          final progress = (event['progress'] as num?)?.toInt() ?? 0;
          if (status == 'started') {
            emit(
              state.copyWith(
                isImporting: true,
                importStatusText: 'Connecting to Glasses Wi-Fi...',
              ),
            );
          } else if (status == 'downloading') {
            emit(
              state.copyWith(
                isImporting: true,
                importStatusText: 'Downloading $file ($progress%)',
              ),
            );
          } else if (status == 'complete') {
            emit(
              state.copyWith(
                isImporting: false,
                importStatusText: 'Import Complete!',
              ),
            );
          } else if (status == 'fail') {
            final code = (event['code'] as num?)?.toInt();
            String errorMsg = 'Import failed. Ensure photos/videos are recorded on glasses first.';
            if (code == 1) {
              errorMsg = 'Glasses is currently taking a photo.';
            } else if (code == 2) {
              errorMsg = 'Glasses is currently recording video. Stop recording first.';
            } else if (code == 7) {
              errorMsg = 'Glasses is in AI voice mode.';
            } else if (code == 8) {
              errorMsg = 'Glasses is recording audio.';
            }
            emit(
              state.copyWith(
                isImporting: false,
                importStatusText: errorMsg,
              ),
            );
          }
          break;

        case 'mediaImported':
          final fileName = event['fileName'] as String? ?? '';
          final filePath = event['filePath'] as String? ?? '';
          final fileType = (event['fileType'] as num?)?.toInt() ?? 1;
          final duration = (event['duration'] as num?)?.toInt() ?? 0;

          final item = GlassesMediaItem(
            fileName: fileName,
            filePath: filePath,
            fileType: fileType,
            durationSeconds: duration,
            importedAt: DateTime.now(),
          );

          final updatedList = List<GlassesMediaItem>.from(state.importedMedia);
          if (!updatedList.any((m) => m.filePath == filePath)) {
            updatedList.insert(0, item);
          }
          emit(state.copyWith(importedMedia: updatedList));
          break;
      }
    });
  }

  void startScan() async {
    emit(
      state.copyWith(
        status: GlassesConnectionStatus.scanning,
        discoveredDevices: [],
      ),
    );

    try {
      // 1. Request Bluetooth Scan & Connect Permissions FIRST (Android 12+)
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect
          .request();

      if (bluetoothScanStatus.isPermanentlyDenied ||
          bluetoothConnectStatus.isPermanentlyDenied) {
        emit(
          state.copyWith(status: GlassesConnectionStatus.permissionRequired),
        );
        return;
      }

      // 2. Only request Location for legacy Android (< 12) if bluetoothScan is denied or not supported
      if (bluetoothScanStatus.isDenied) {
        final locationStatus = await Permission.locationWhenInUse.request();
        if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
          emit(
            state.copyWith(status: GlassesConnectionStatus.permissionRequired),
          );
          return;
        }
      }

      // 3. Check if Bluetooth hardware is turned ON
      final isBtOn = await repository.isBluetoothEnabled();
      if (!isBtOn) {
        emit(state.copyWith(status: GlassesConnectionStatus.bluetoothOff));
        return;
      }

      await repository.startScan();
    } catch (e) {
      await repository.startScan();
    }
  }

  void enableBluetoothPrompt() async {
    await repository.enableBluetooth();
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final isBtOn = await repository.isBluetoothEnabled();
      if (isBtOn) {
        startScan();
        return;
      }
    }
    final isBtOn = await repository.isBluetoothEnabled();
    if (isBtOn) {
      startScan();
    } else {
      emit(state.copyWith(status: GlassesConnectionStatus.bluetoothOff));
    }
  }

  void openAppSettingsPage() {
    openAppSettings();
  }

  void stopScan() async {
    try {
      await repository.stopScan();
      if (state.status == GlassesConnectionStatus.scanning) {
        emit(
          state.copyWith(
            status: state.connectedDevice != null
                ? GlassesConnectionStatus.connected
                : GlassesConnectionStatus.disconnected,
          ),
        );
      }
    } catch (_) {}
  }

  void connectDevice(String address) async {
    emit(state.copyWith(status: GlassesConnectionStatus.connecting));
    try {
      await repository.connectDevice(address);
    } catch (e) {
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void disconnectDevice() async {
    try {
      await repository.disconnectDevice();
      await repository.clearSavedDeviceAddress();
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.disconnected,
          connectedDevice: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void takePhoto() async {
    try {
      await repository.takePhoto();
    } catch (_) {}
  }

  void toggleVideoRecording([bool? start]) async {
    final newState = start ?? !state.isRecordingVideo;
    emit(state.copyWith(isRecordingVideo: newState));
    try {
      await repository.toggleRecording(newState);
    } catch (_) {}
  }

  void toggleVoiceRecording([bool? start]) async {
    final newState = start ?? !state.isRecordingVoice;
    emit(state.copyWith(isRecordingVoice: newState));
    try {
      await repository.toggleVoiceRecording(newState);
    } catch (_) {}
  }

  void importAlbum() async {
    try {
      await repository.importAlbum();
    } catch (_) {}
  }

  void toggleWearingDetection(bool enable) {
    emit(state.copyWith(wearingDetection: enable));
  }

  void toggleVoiceWakeup(bool enable) {
    emit(state.copyWith(voiceWakeup: enable));
  }

  void updateMusicVolume(double val) {
    emit(state.copyWith(musicVolume: val));
  }

  void loadLocalMedia() async {
    try {
      Directory? extDir;
      if (Platform.isAndroid) {
        extDir = await getExternalStorageDirectory();
      } else {
        extDir = await getApplicationDocumentsDirectory();
      }
      if (extDir == null) return;
      final dcimDir = Directory('${extDir.path}/DCIM_1');
      if (!await dcimDir.exists()) return;

      final files = dcimDir.listSync();
      final mediaList = <GlassesMediaItem>[];
      for (final entity in files) {
        if (entity is File) {
          final path = entity.path;
          final lower = path.toLowerCase();
          if (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.mp4')) {
            final isVideo = lower.endsWith('.mp4');
            final stat = entity.statSync();
            mediaList.add(
              GlassesMediaItem(
                fileName: entity.uri.pathSegments.last,
                filePath: path,
                fileType: isVideo ? 1 : 2,
                durationSeconds: isVideo ? 15 : 0,
                importedAt: stat.modified,
              ),
            );
          }
        }
      }
      mediaList.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      emit(state.copyWith(importedMedia: mediaList));
    } catch (_) {}
  }

  @override
  void emit(GlassesState state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
