import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/glasses_audio_status_model.dart';
import '../../data/models/glasses_media_model.dart';
import '../../domain/entities/bluetooth_enable_result.dart';
import '../../domain/entities/glasses_audio_status.dart';
import '../../domain/entities/glasses_device.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../../domain/entities/glasses_work_mode.dart';
import '../../domain/repositories/glasses_repository.dart';
import 'glasses_state.dart';

enum GlassesVolumeChannel { music, call, system }

class GlassesCubit extends Cubit<GlassesState> {
  final GlassesRepository repository;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  Timer? _scanTimer;
  Timer? _connectTimer;
  Timer? _importWatchdog;
  Timer? _pendingRefreshTimer;
  Timer? _settingsTimer;
  bool _autoReconnecting = false;
  bool _awaitingBluetooth = false;

  static const _scanDuration = Duration(seconds: 15);
  static const _connectTimeout = Duration(seconds: 20);
  static const _importIdleTimeout = Duration(seconds: 90);

  /// iOS: the iPhone couldn't switch from its current Wi‑Fi to the glasses' hotspot.
  static const _couldNotLeaveWiFiCode = 2012;

  GlassesCubit({required this.repository}) : super(const GlassesState()) {
    _init();
  }

  // ───────────────────────────── Init ─────────────────────────────

  Future<void> _init() async {
    loadLocalMedia();
    loadCameraSettings();
    await repository.initializeSDK();
    _listenToEvents();

    final info = await repository.getConnectedDevice();
    if (info['isConnected'] == true) {
      final savedName = await repository.getSavedDeviceName();
      _onConnected(
        address: info['address'] as String? ?? '',
        name: _firstNonEmpty([info['name'] as String?, savedName]),
        announce: false,
      );
      return;
    }

    // Quietly reconnect to the last paired glasses.
    final savedAddress = await repository.getSavedDeviceAddress();
    if (savedAddress != null && savedAddress.isNotEmpty) {
      if (await repository.isBluetoothEnabled()) {
        _autoReconnecting = true;
        final savedName = await repository.getSavedDeviceName();
        connectDevice(savedAddress, name: savedName);
      }
    }
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = repository.eventStream.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> event) {
    switch (event['event'] as String?) {
      case 'scanResult':
        _onScanResult(event);
        break;
      case 'scanState':
        if (event['scanning'] == false && event['error'] != null) {
          _finishScan();
        }
        break;
      case 'connectionStateChanged':
        _onConnectionEvent(event);
        break;
      case 'bluetoothStateChanged':
        if (event['enabled'] == false && !state.isConnected) {
          _scanTimer?.cancel();
          emit(state.copyWith(status: GlassesConnectionStatus.bluetoothOff));
        } else if (event['enabled'] == true &&
            (state.status == GlassesConnectionStatus.bluetoothOff ||
                state.status == GlassesConnectionStatus.permissionRequired)) {
          if (_awaitingBluetooth) {
            // Bluetooth just became usable while the pairing sheet was waiting
            // for it (Control Center, Settings or the system alert): scan now.
            _awaitingBluetooth = false;
            startScan();
          } else {
            emit(state.copyWith(status: GlassesConnectionStatus.disconnected));
          }
        }
        break;
      case 'batteryUpdated':
        final device = state.connectedDevice;
        if (device != null) {
          emit(
            state.copyWith(
              connectedDevice: device.copyWith(
                batteryLevel: (event['battery'] as num?)?.toInt() ?? 0,
                isCharging: event['isCharging'] as bool? ?? false,
              ),
            ),
          );
        }
        break;
      case 'workState':
        final mode = (event['mode'] as num?)?.toInt() ?? 0;
        if (mode == GlassesWorkMode.transfer || mode == GlassesWorkMode.idle) {
          emit(state.copyWith(glassesMode: mode));
        }
        break;
      case 'audioState':
        _onAudioStatus(GlassesAudioStatusModel.fromMap(event));
        break;
      case 'volumeChanged':
        final s = state.deviceSettings;
        if (s != null) {
          emit(
            state.copyWith(
              deviceSettings: s.copyWith(
                musicVolume: s.musicVolume?.copyWith(
                  value: (event['music'] as num?)?.toInt(),
                ),
                callVolume: s.callVolume?.copyWith(
                  value: (event['call'] as num?)?.toInt(),
                ),
                systemVolume: s.systemVolume?.copyWith(
                  value: (event['system'] as num?)?.toInt(),
                ),
              ),
            ),
          );
        }
        break;
      case 'deviceAlert':
        if (event['type'] == 'storageFull') {
          _notify('Glasses storage is full. Import your media to free space.');
        }
        break;
      case 'importProgress':
        _onImportProgress(event);
        break;
      case 'mediaImported':
        _onMediaImported(event);
        break;
    }
  }

  // ───────────────────────────── Scanning ─────────────────────────────

  Future<void> startScan() async {
    if (state.isConnecting) return;
    _scanTimer?.cancel();
    emit(
      state.copyWith(
        status: GlassesConnectionStatus.scanning,
        discoveredDevices: const [],
        scanFinished: false,
        errorMessage: '',
      ),
    );

    if (!await _ensureBluetoothPermissions()) {
      _awaitingBluetooth = Platform.isIOS;
      emit(state.copyWith(status: GlassesConnectionStatus.permissionRequired));
      return;
    }

    if (!await repository.isBluetoothEnabled()) {
      // iOS can't switch Bluetooth on for us; scanning resumes by itself as
      // soon as the user turns it on (see `bluetoothStateChanged`).
      _awaitingBluetooth = Platform.isIOS;
      emit(state.copyWith(status: GlassesConnectionStatus.bluetoothOff));
      return;
    }

    try {
      await repository.startScan();
      _scanTimer = Timer(_scanDuration, _finishScan);
    } catch (e) {
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.error,
          errorMessage: 'Could not start scanning. Please try again.',
          scanFinished: true,
        ),
      );
    }
  }

  Future<bool> _ensureBluetoothPermissions() async {
    if (Platform.isIOS) {
      // iOS has one CoreBluetooth permission; the Android scan/connect
      // permissions always read as permanently denied there.
      return (await Permission.bluetooth.request()).isGranted;
    }
    if (!Platform.isAndroid) return true;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    final scan = statuses[Permission.bluetoothScan];
    final connect = statuses[Permission.bluetoothConnect];
    if (scan?.isGranted == true && connect?.isGranted == true) return true;

    // Android 11 and below: BLE scanning is gated by location instead.
    if (scan?.isPermanentlyDenied != true &&
        connect?.isPermanentlyDenied != true) {
      final location = await Permission.locationWhenInUse.request();
      return location.isGranted;
    }
    return false;
  }

  void _onScanResult(Map<String, dynamic> event) {
    if (!state.isScanning) return;
    final address = event['address'] as String? ?? '';
    if (address.isEmpty) return;
    final device = GlassesDevice(
      name: event['name'] as String? ?? 'Smart Glasses',
      address: address,
      rssi: (event['rssi'] as num?)?.toInt() ?? -90,
    );
    final list = List<GlassesDevice>.from(state.discoveredDevices);
    final index = list.indexWhere((d) => d.address == address);
    if (index >= 0) {
      if ((list[index].rssi - device.rssi).abs() < 6) return;
      list[index] = device;
    } else {
      list.add(device);
    }
    list.sort((a, b) {
      if (a.isLikelyGlasses != b.isLikelyGlasses) {
        return a.isLikelyGlasses ? -1 : 1;
      }
      return b.rssi.compareTo(a.rssi);
    });
    emit(state.copyWith(discoveredDevices: list));
  }

  void _finishScan() {
    _scanTimer?.cancel();
    repository.stopScan().catchError((_) {});
    if (state.isScanning) {
      emit(
        state.copyWith(
          status: state.connectedDevice != null
              ? GlassesConnectionStatus.connected
              : GlassesConnectionStatus.disconnected,
          scanFinished: true,
        ),
      );
    }
  }

  void stopScan() => _finishScan();

  Future<void> enableBluetoothPrompt() async {
    final outcome = await repository.enableBluetooth();
    switch (outcome) {
      case BluetoothEnableResult.alreadyOn:
        startScan();
        return;
      case BluetoothEnableResult.unsupported:
        emit(
          state.copyWith(status: GlassesConnectionStatus.bluetoothUnavailable),
        );
        return;
      case BluetoothEnableResult.denied:
        _awaitingBluetooth = true;
        emit(
          state.copyWith(status: GlassesConnectionStatus.permissionRequired),
        );
        return;
      case BluetoothEnableResult.prompted:
        break;
    }
    if (Platform.isIOS) {
      // iOS showed its own "Turn On Bluetooth" alert; the user can also use
      // Control Center. `bluetoothStateChanged` resumes the scan when it's on.
      _awaitingBluetooth = true;
      return;
    }
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await repository.isBluetoothEnabled()) {
        startScan();
        return;
      }
    }
    emit(state.copyWith(status: GlassesConnectionStatus.bluetoothOff));
  }

  void openAppSettingsPage() => openAppSettings();

  // ───────────────────────────── Connection ─────────────────────────────

  Future<void> connectDevice(String address, {String? name}) async {
    _scanTimer?.cancel();
    _connectTimer?.cancel();
    emit(
      state.copyWith(
        status: GlassesConnectionStatus.connecting,
        connectingAddress: address,
        errorMessage: '',
      ),
    );
    final deviceName = _firstNonEmpty([name, _discovered(address)?.name]);
    try {
      await repository.saveDevice(address, name: deviceName);
      await repository.connectDevice(address, name: deviceName);
      _connectTimer = Timer(_connectTimeout, () {
        if (!state.isConnecting) return;
        repository.stopScan().catchError((_) {});
        final wasAuto = _autoReconnecting;
        _autoReconnecting = false;
        emit(
          state.copyWith(
            status: wasAuto
                ? GlassesConnectionStatus.disconnected
                : GlassesConnectionStatus.error,
            clearConnectingAddress: true,
            errorMessage: wasAuto
                ? ''
                : 'Couldn\'t connect. Make sure the glasses are on, charged and close to your phone.',
          ),
        );
      });
    } catch (e) {
      _autoReconnecting = false;
      emit(
        state.copyWith(
          status: GlassesConnectionStatus.error,
          clearConnectingAddress: true,
          errorMessage: 'Connection failed. Please try again.',
        ),
      );
    }
  }

  void _onConnectionEvent(Map<String, dynamic> event) {
    switch (event['state'] as String?) {
      case 'connecting':
        if (!state.isConnected) {
          emit(
            state.copyWith(
              status: GlassesConnectionStatus.connecting,
              connectingAddress: event['address'] as String?,
            ),
          );
        }
        break;
      case 'connected':
        _onConnected(
          address:
              _firstNonEmpty([
                event['address'] as String?,
                state.connectingAddress,
              ]) ??
              '',
          name: event['name'] as String?,
        );
        break;
      case 'unbound':
        repository.clearSavedDevice();
        _onDisconnected();
        _notify('Your glasses were unpaired from the app.');
        break;
      case 'disconnected':
        // The SDK reports transient disconnects while it is still retrying;
        // the connect timer decides when a connection attempt has failed.
        if (state.isConnecting) return;
        final wasConnected = state.isConnected;
        _onDisconnected();
        if (wasConnected) _notify('Smart glasses disconnected');
        break;
    }
  }

  Future<void> _onConnected({
    required String address,
    String? name,
    bool announce = true,
  }) async {
    _connectTimer?.cancel();
    _scanTimer?.cancel();
    _autoReconnecting = false;
    final savedName = await repository.getSavedDeviceName();
    final resolvedName =
        _firstNonEmpty([name, _discovered(address)?.name, savedName]) ??
        'Smart Glasses';
    if (address.isNotEmpty) {
      repository.saveDevice(address, name: resolvedName);
    }
    final previous = state.connectedDevice;
    emit(
      state.copyWith(
        status: GlassesConnectionStatus.connected,
        connectedDevice: GlassesDevice(
          name: resolvedName,
          address: address,
          rssi: _discovered(address)?.rssi ?? -60,
          isConnected: true,
          batteryLevel: previous?.address == address
              ? previous!.batteryLevel
              : 0,
          isCharging: previous?.address == address && previous!.isCharging,
          firmwareVersion: previous?.address == address
              ? previous!.firmwareVersion
              : '',
        ),
        clearConnectingAddress: true,
        errorMessage: '',
      ),
    );
    if (announce) _notify('Connected to $resolvedName');
    repository.getBatteryLevel().catchError((_) {});
    _schedulePendingRefresh();
    _settingsTimer?.cancel();
    _settingsTimer = Timer(
      const Duration(milliseconds: 4500),
      loadDeviceSettings,
    );
  }

  void _onDisconnected() {
    _connectTimer?.cancel();
    emit(
      state.copyWith(
        status: GlassesConnectionStatus.disconnected,
        clearConnectedDevice: true,
        clearConnectingAddress: true,
        isRecordingVideo: false,
        isRecordingVoice: false,
        clearRecordingStartedAt: true,
        clearPendingCommand: true,
        clearDeviceSettings: true,
        audio: const GlassesAudioStatus(),
        glassesMode: GlassesWorkMode.idle,
        importPhase: state.isImporting ? GlassesImportPhase.failed : null,
        importStatusText: state.isImporting
            ? 'The glasses disconnected during the import.'
            : null,
      ),
    );
    _importWatchdog?.cancel();
  }

  Future<void> disconnectDevice() async {
    try {
      await repository.disconnectDevice();
    } catch (_) {}
    await repository.clearSavedDevice();
    _onDisconnected();
  }

  void dismissError() {
    emit(
      state.copyWith(
        errorMessage: '',
        status: state.status == GlassesConnectionStatus.error
            ? GlassesConnectionStatus.disconnected
            : state.status,
      ),
    );
  }

  // ───────────────────────────── Capture ─────────────────────────────

  Future<void> takePhoto() async {
    if (!state.canCapture || state.isRecording) return;
    final result = await _runCommand(
      GlassesPendingCommand.photo,
      GlassesWorkMode.photo,
    );
    if (result.ok) {
      _notify('Photo captured on your glasses. Import to see it here.');
      _schedulePendingRefresh();
    } else {
      _reportRefusal(result, 'take a photo');
    }
  }

  Future<void> toggleVideoRecording() async {
    if (!state.canCapture || state.isRecordingVoice) return;
    final start = !state.isRecordingVideo;
    final result = await _runCommand(
      GlassesPendingCommand.video,
      start ? GlassesWorkMode.video : GlassesWorkMode.videoStop,
    );
    if (start) {
      // Refused because it is already recording = it IS recording.
      final alreadyRecording =
          !result.ok && result.busyMode == GlassesWorkMode.video;
      if (result.ok || alreadyRecording) {
        emit(
          state.copyWith(
            isRecordingVideo: true,
            recordingStartedAt: DateTime.now(),
            glassesMode: GlassesWorkMode.video,
          ),
        );
      } else {
        _reportRefusal(result, 'start recording');
      }
    } else {
      if (result.ok ||
          (!result.timedOut && result.busyMode != GlassesWorkMode.video)) {
        // Accepted, or the glasses already stopped on their own (e.g. time limit reached).
        emit(
          state.copyWith(
            isRecordingVideo: false,
            clearRecordingStartedAt: true,
            glassesMode: GlassesWorkMode.idle,
          ),
        );
        _notify('Video saved on your glasses. Import to watch it here.');
        _schedulePendingRefresh();
      } else {
        _reportRefusal(result, 'stop recording');
      }
    }
  }

  Future<void> toggleVoiceRecording() async {
    if (!state.canCapture || state.isRecordingVideo) return;
    final start = !state.isRecordingVoice;
    final result = await _runCommand(
      GlassesPendingCommand.audio,
      start ? GlassesWorkMode.audio : GlassesWorkMode.audioStop,
    );
    if (start) {
      final alreadyRecording =
          !result.ok && result.busyMode == GlassesWorkMode.audio;
      if (result.ok || alreadyRecording) {
        emit(
          state.copyWith(
            isRecordingVoice: true,
            recordingStartedAt: DateTime.now(),
            glassesMode: GlassesWorkMode.audio,
          ),
        );
      } else {
        _reportRefusal(result, 'start recording');
      }
    } else {
      if (result.ok ||
          (!result.timedOut && result.busyMode != GlassesWorkMode.audio)) {
        emit(
          state.copyWith(
            isRecordingVoice: false,
            clearRecordingStartedAt: true,
            glassesMode: GlassesWorkMode.idle,
          ),
        );
        _notify('Voice note saved on your glasses. Import to listen here.');
        _schedulePendingRefresh();
      } else {
        _reportRefusal(result, 'stop recording');
      }
    }
  }

  Future<void> findGlasses() async {
    if (!state.canCapture) return;
    final result = await _runCommand(
      GlassesPendingCommand.find,
      GlassesWorkMode.findDevice,
    );
    if (result.ok) {
      _notify('Your glasses are playing a sound.');
    } else {
      _reportRefusal(result, 'find them');
    }
  }

  /// Sends one mode command at a time and tracks it as pending for the UI.
  Future<GlassesCommandResult> _runCommand(
    GlassesPendingCommand command,
    int mode,
  ) async {
    emit(state.copyWith(pendingCommand: command));
    try {
      return await repository.setDeviceMode(mode);
    } catch (_) {
      return const GlassesCommandResult.failed();
    } finally {
      emit(state.copyWith(clearPendingCommand: true));
    }
  }

  void _reportRefusal(GlassesCommandResult result, String action) {
    if (result.timedOut) {
      _notify('The glasses didn\'t respond. Keep them close and try again.');
      return;
    }
    final busy = result.busyMode;
    if (busy == null || busy == GlassesWorkMode.idle) {
      _notify('The glasses couldn\'t $action right now. Try again.');
      return;
    }
    emit(state.copyWith(glassesMode: busy));
    // Keep the recording flags in sync with what the glasses report.
    if (busy == GlassesWorkMode.video && !state.isRecordingVideo) {
      emit(
        state.copyWith(
          isRecordingVideo: true,
          recordingStartedAt: DateTime.now(),
        ),
      );
    } else if (busy == GlassesWorkMode.audio && !state.isRecordingVoice) {
      emit(
        state.copyWith(
          isRecordingVoice: true,
          recordingStartedAt: DateTime.now(),
        ),
      );
    }
    _notify(
      'Can\'t $action — the glasses are ${GlassesWorkMode.describe(busy)}.',
    );
  }

  void _schedulePendingRefresh() {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = Timer(
      const Duration(seconds: 3),
      refreshPendingMedia,
    );
  }

  // ───────────────────────────── Media import ─────────────────────────────

  Future<void> refreshPendingMedia() async {
    if (!state.isConnected || state.isImporting || state.isRecording) return;
    if (state.pendingCommand != null) {
      _schedulePendingRefresh();
      return;
    }
    final pending = await repository.getPendingMedia();
    if (pending != null) emit(state.copyWith(pendingMedia: pending));
  }

  Future<void> importAlbum() async {
    if (!state.isConnected) {
      _notify('Connect your smart glasses first.');
      return;
    }
    if (state.isImporting || state.pendingCommand != null) return;
    if (state.isRecording) {
      _notify('Stop recording on the glasses before importing.');
      return;
    }
    _pendingRefreshTimer?.cancel();

    if (!await _ensureWifiPermissions()) {
      emit(
        state.copyWith(
          importPhase: GlassesImportPhase.failed,
          importStatusText:
              'Allow Nearby devices / Location access so the app can reach the glasses over Wi‑Fi.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        importPhase: GlassesImportPhase.connecting,
        importStatusText: Platform.isIOS
            ? 'Getting ready… Allow "Local Network" if your iPhone asks.'
            : 'Connecting to glasses Wi‑Fi…',
        importCurrentFile: '',
        importFileProgress: 0,
        importIndex: 0,
        importTotal: 0,
        importSessionCount: 0,
        importSkippedCount: 0,
        importNeedsWifiDisconnect: false,
        recentImports: const [],
        wifiSpeed: '',
      ),
    );
    _armImportWatchdog();
    try {
      await repository.importAlbum();
    } catch (e) {
      _failImport('Could not start the import. Please try again.');
    }
  }

  Future<bool> _ensureWifiPermissions() async {
    if (!Platform.isAndroid) return true;
    final nearby = await Permission.nearbyWifiDevices.request();
    if (nearby.isGranted) return true;
    // Below Android 13 the nearby permission doesn't exist; Wi‑Fi P2P needs location.
    final location = await Permission.locationWhenInUse.request();
    return location.isGranted;
  }

  void _armImportWatchdog() {
    _importWatchdog?.cancel();
    _importWatchdog = Timer(_importIdleTimeout, () {
      if (state.isImporting) {
        _failImport(
          'The glasses stopped responding. Keep them close to your phone and try again.',
        );
      }
    });
  }

  void _failImport(String message, {bool endTransfer = true}) {
    _importWatchdog?.cancel();
    emit(
      state.copyWith(
        importPhase: GlassesImportPhase.failed,
        importStatusText: message,
        importNeedsWifiDisconnect: false,
        glassesMode: GlassesWorkMode.idle,
      ),
    );
    // Make sure the glasses leave transfer mode so capture works again.
    if (endTransfer) repository.endTransfer();
    if (state.importSessionCount > 0) loadLocalMedia();
  }

  /// Stops an import in progress and returns the glasses to normal mode.
  Future<void> cancelImport() async {
    if (!state.isImporting) return;
    _importWatchdog?.cancel();
    await repository.endTransfer();
    final saved = state.importSessionCount;
    emit(
      state.copyWith(
        importPhase: GlassesImportPhase.failed,
        importNeedsWifiDisconnect: false,
        importStatusText: saved > 0
            ? 'Import stopped. $saved ${saved == 1 ? 'item was' : 'items were'} saved.'
            : 'Import stopped.',
        glassesMode: GlassesWorkMode.idle,
      ),
    );
    loadLocalMedia();
  }

  void _onImportProgress(Map<String, dynamic> event) {
    final status = event['status'] as String?;
    if (status != 'fail' && status != 'complete') _armImportWatchdog();

    switch (status) {
      // iOS: the app joins the glasses' hotspot step by step.
      case 'openingWifi':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importStatusText: 'Turning on the glasses\' Wi‑Fi…',
          ),
        );
        break;
      case 'waitingHotspot':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importStatusText: 'Waiting for the glasses\' Wi‑Fi to start…',
          ),
        );
        break;
      case 'disconnectWifi':
        // iOS can't switch from the phone's Wi‑Fi to the glasses; the banner shows
        // how to disconnect, and the import continues by itself once they do.
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importNeedsWifiDisconnect: true,
            importStatusText: 'Disconnect your iPhone from Wi‑Fi to continue',
          ),
        );
        break;
      case 'wifiDisconnected':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importNeedsWifiDisconnect: false,
            importStatusText: 'Wi‑Fi disconnected. Connecting to your glasses…',
          ),
        );
        break;
      case 'joiningWifi':
        final attempt = (event['attempt'] as num?)?.toInt() ?? 1;
        final total = (event['total'] as num?)?.toInt() ?? 1;
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importNeedsWifiDisconnect: false,
            importStatusText: attempt > 1
                ? 'Connecting to the glasses\' Wi‑Fi… (try $attempt of $total)'
                : 'Connecting to the glasses\' Wi‑Fi… Tap "Join" when your iPhone asks.',
          ),
        );
        break;
      case 'wifiJoined':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.connecting,
            importStatusText: 'Connected to your glasses. Finding your media…',
          ),
        );
        break;
      case 'started':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.downloading,
            importStatusText: 'Connected. Preparing your media…',
          ),
        );
        break;
      case 'count':
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.downloading,
            importIndex: (event['index'] as num?)?.toInt() ?? 0,
            importTotal: (event['total'] as num?)?.toInt() ?? 0,
            importFileProgress: 0,
          ),
        );
        break;
      case 'downloading':
        final progress = (event['progress'] as num?)?.toInt() ?? 0;
        final file = event['file'] as String? ?? '';
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.downloading,
            importCurrentFile: file,
            importFileProgress: (progress / 100).clamp(0.0, 1.0),
            importStatusText: state.importTotal > 0
                ? 'Downloading ${state.importIndex} of ${state.importTotal}'
                : 'Downloading media…',
          ),
        );
        break;
      case 'speed':
        emit(state.copyWith(wifiSpeed: event['speed'] as String? ?? ''));
        break;
      case 'complete':
        _importWatchdog?.cancel();
        final count = state.importSessionCount;
        final skipped = state.importSkippedCount;
        emit(
          state.copyWith(
            importPhase: GlassesImportPhase.completed,
            importFileProgress: 1,
            importStatusText: count > 0
                ? 'Imported $count new ${count == 1 ? 'item' : 'items'}'
                      '${skipped > 0 ? ' · $skipped couldn\'t be saved' : ''}'
                : skipped > 0
                ? '$skipped ${skipped == 1 ? 'file' : 'files'} couldn\'t be saved. Try importing again.'
                : 'Everything is up to date',
            pendingMedia: const GlassesPendingMedia(),
            glassesMode: GlassesWorkMode.idle,
          ),
        );
        loadLocalMedia();
        break;
      case 'fileError':
        // A single file failed; the SDK continues with the rest.
        emit(state.copyWith(importSkippedCount: state.importSkippedCount + 1));
        break;
      case 'fail':
        // The bridge already ends the transfer after a failure.
        final code = (event['code'] as num?)?.toInt();
        final detail = (event['detail'] as String?)?.trim() ?? '';
        final message = _importErrorMessage(code);
        // 2012 already tells the user exactly what to do; its detail stays in the log.
        final showDetail = detail.isNotEmpty && code != _couldNotLeaveWiFiCode;
        _failImport(
          // iOS sends what it observed (iOS error, current Wi‑Fi, IP) so the
          // cause is visible on screen, not only in the console.
          showDetail ? '$message\n($detail)' : message,
          endTransfer: false,
        );
        break;
    }
  }

  String _importErrorMessage(int? code) {
    switch (code) {
      case 1:
        return 'The glasses are taking a photo. Try again in a moment.';
      case 2:
        return 'The glasses are recording video. Stop recording first.';
      case 5:
        return 'The glasses are updating firmware. Try again later.';
      case 7:
        return 'The glasses are in AI voice mode. Exit it and try again.';
      case 8:
        return 'The glasses are recording audio. Stop recording first.';
      // iOS QCSDK Wi‑Fi errors.
      case 2000:
      case 2001:
      case 2002:
        return 'Couldn\'t connect to the glasses\' Wi‑Fi. Keep Wi‑Fi on and the glasses close to your iPhone, then try again.';
      case _couldNotLeaveWiFiCode:
        return 'Your iPhone couldn\'t switch from your Wi‑Fi to the glasses. '
            'Open Control Center, tap the Wi‑Fi icon once to disconnect, then tap Retry.';
      case 2010:
        return 'Import cancelled. Tap "Join" when your iPhone asks to join the glasses\' Wi‑Fi.';
      case 2011:
        return 'The glasses didn\'t turn on their Wi‑Fi. Make sure they\'re charged and close, then try again.';
      case 2003:
        return 'Allow Local Network for Spoken Odyssey in Settings › Privacy › Local Network, then try again.';
      case 2004:
        return 'Connected to the glasses, but they didn\'t send the media list. Try again.';
      case 2005:
        return 'The download was interrupted. Keep the glasses close to your phone and try again.';
      default:
        return 'Import failed. Keep Wi‑Fi on, stay close to the glasses and try again.';
    }
  }

  Future<void> _onMediaImported(Map<String, dynamic> event) async {
    final item = GlassesMediaModel.fromEvent(event);
    if (item.filePath.isEmpty) return;
    await repository.saveMedia(item);
    final list = List<GlassesMediaItem>.from(state.importedMedia)
      ..removeWhere((m) => m.filePath == item.filePath)
      ..insert(0, item);
    emit(
      state.copyWith(
        importedMedia: list,
        importSessionCount: state.importSessionCount + 1,
        recentImports: [
          item,
          ...state.recentImports.where((m) => m.filePath != item.filePath),
        ],
      ),
    );
  }

  Future<void> loadLocalMedia() async {
    emit(state.copyWith(isMediaLoading: true));
    // Unpack anything still in the glasses' raw bundle format (also fixes older imports).
    if (!state.isImporting) {
      try {
        await repository.repairMedia();
      } catch (_) {}
    }
    try {
      final media = await repository.loadMedia();
      emit(state.copyWith(importedMedia: media, isMediaLoading: false));
    } catch (_) {
      emit(state.copyWith(isMediaLoading: false));
    }
  }

  Future<void> deleteMedia(GlassesMediaItem item) async {
    await repository.deleteMedia(item);
    emit(
      state.copyWith(
        importedMedia: state.importedMedia
            .where((m) => m.filePath != item.filePath)
            .toList(),
      ),
    );
  }

  void resetImportStatus() {
    if (state.isImporting) return;
    emit(
      state.copyWith(
        importPhase: GlassesImportPhase.idle,
        importStatusText: '',
      ),
    );
  }

  // ───────────────────────────── Device settings ─────────────────────────────

  Future<void> loadDeviceSettings() async {
    if (!state.isConnected || state.isSettingsLoading) return;
    emit(state.copyWith(isSettingsLoading: true));
    final settings = await repository.getDeviceSettings();
    if (settings == null) {
      emit(state.copyWith(isSettingsLoading: false));
      return;
    }
    final device = state.connectedDevice;
    emit(
      state.copyWith(
        isSettingsLoading: false,
        deviceSettings: settings,
        connectedDevice: device != null && settings.firmwareVersion.isNotEmpty
            ? device.copyWith(firmwareVersion: settings.firmwareVersion)
            : null,
      ),
    );
  }

  Future<void> setWearDetection(bool enabled) async {
    final current = state.deviceSettings;
    if (current == null) return;
    emit(
      state.copyWith(deviceSettings: current.copyWith(wearDetection: enabled)),
    );
    final confirmed = await repository.setWearDetection(enabled);
    if (confirmed == null) {
      emit(state.copyWith(deviceSettings: current));
      _notify('Couldn\'t update wearing detection. Try again.');
    } else {
      emit(
        state.copyWith(
          deviceSettings: state.deviceSettings?.copyWith(
            wearDetection: confirmed,
          ),
        ),
      );
    }
  }

  Future<void> setVoiceWakeup(bool enabled) async {
    final current = state.deviceSettings;
    if (current == null) return;
    emit(
      state.copyWith(deviceSettings: current.copyWith(voiceWakeup: enabled)),
    );
    final confirmed = await repository.setVoiceWakeup(enabled);
    if (confirmed == null) {
      emit(state.copyWith(deviceSettings: current));
      _notify('Couldn\'t update voice wake-up. Try again.');
    } else {
      emit(
        state.copyWith(
          deviceSettings: state.deviceSettings?.copyWith(
            voiceWakeup: confirmed,
          ),
        ),
      );
    }
  }

  /// Updates the slider position locally while dragging.
  void previewVolume(GlassesVolumeChannel channel, int value) {
    final s = state.deviceSettings;
    if (s == null) return;
    emit(state.copyWith(deviceSettings: _withVolume(s, channel, value)));
  }

  /// Sends the final volume to the glasses when the user lets go of the slider.
  Future<void> commitVolume(GlassesVolumeChannel channel, int value) async {
    final ok = await repository.setVolume(
      music: channel == GlassesVolumeChannel.music ? value : null,
      call: channel == GlassesVolumeChannel.call ? value : null,
      system: channel == GlassesVolumeChannel.system ? value : null,
    );
    if (!ok) _notify('Couldn\'t change the volume. Try again.');
  }

  GlassesDeviceSettings _withVolume(
    GlassesDeviceSettings s,
    GlassesVolumeChannel c,
    int v,
  ) {
    switch (c) {
      case GlassesVolumeChannel.music:
        return s.copyWith(musicVolume: s.musicVolume?.copyWith(value: v));
      case GlassesVolumeChannel.call:
        return s.copyWith(callVolume: s.callVolume?.copyWith(value: v));
      case GlassesVolumeChannel.system:
        return s.copyWith(systemVolume: s.systemVolume?.copyWith(value: v));
    }
  }

  Future<void> syncTimeNow() async {
    try {
      await repository.syncTime();
      _notify('Glasses clock synced with your phone.');
    } catch (_) {
      _notify('Couldn\'t sync the time. Try again.');
    }
  }

  // ───────────────────────────── Glasses audio ─────────────────────────────

  /// Checks whether sound currently plays through the glasses.
  Future<void> refreshAudioStatus() async {
    if (!state.isConnected) return;
    final status = await repository.getAudioStatus();
    if (status.state != GlassesAudioState.failed)
      _onAudioStatus(status, announce: false);
  }

  /// Pairs / reconnects the glasses' speaker and microphone with the phone.
  Future<void> connectAudio() async {
    if (!state.isConnected || state.audio.isBusy) return;
    emit(
      state.copyWith(
        audio: const GlassesAudioStatus(state: GlassesAudioState.connecting),
      ),
    );
    final status = await repository.connectAudio();
    _onAudioStatus(status);
  }

  Future<void> openBluetoothSettings() => repository.openBluetoothSettings();

  void _onAudioStatus(GlassesAudioStatus status, {bool announce = true}) {
    final before = state.audio.state;
    // Keep the known name/address when an event omits them.
    final merged = GlassesAudioStatus(
      state: status.state,
      name: status.name.isNotEmpty ? status.name : state.audio.name,
      address: status.address.isNotEmpty ? status.address : state.audio.address,
      media: status.media,
      calls: status.calls,
      failReason: status.failReason,
    );
    emit(state.copyWith(audio: merged));
    if (!announce || before == status.state) return;
    switch (status.state) {
      case GlassesAudioState.connected:
        _notify('Sound now plays through your glasses.');
        break;
      case GlassesAudioState.pairing:
        _notify('Accept the Bluetooth pairing request on your phone.');
        break;
      case GlassesAudioState.failed:
        _notify(switch (status.failReason) {
          'notFound' =>
            'Couldn\'t find the glasses\' audio. Keep them on and close, then try again.',
          'pairingRejected' =>
            'Pairing was cancelled. Tap "Connect audio" to try again.',
          'bluetoothOff' => 'Turn on Bluetooth to connect the glasses\' audio.',
          _ => 'Couldn\'t connect the glasses\' audio. Try again.',
        });
        break;
      default:
        break;
    }
  }

  // ───────────────────────────── Camera settings ─────────────────────────────

  Future<void> loadCameraSettings() async {
    try {
      final settings = await repository.getCameraSettings();
      emit(state.copyWith(cameraSettings: settings));
    } catch (_) {}
  }

  Future<void> updateCameraSettings(GlassesCameraSettings newSettings) async {
    emit(
      state.copyWith(
        cameraSettings: newSettings,
        deviceSettings: state.deviceSettings?.copyWith(
          cameraSettings: newSettings,
        ),
      ),
    );
    await repository.saveCameraSettings(newSettings);
    if (state.isConnected) {
      await repository.syncCameraSettingsToDevice(newSettings);
    }
  }

  Future<void> toggleCameraLock() async {
    final next = !state.cameraSettings.isLocked;
    await updateCameraSettings(state.cameraSettings.copyWith(isLocked: next));
    _notify(next ? 'Camera settings locked' : 'Camera settings unlocked');
  }

  Future<void> setVideoResolution(VideoResolution res) async {
    if (state.cameraSettings.isLocked) {
      _notify('Camera settings are locked. Tap the lock icon to adjust.');
      return;
    }
    await updateCameraSettings(
      state.cameraSettings.copyWith(videoResolution: res),
    );
    _notify('Resolution set to ${res.label} (${res.dimensions})');
  }

  Future<void> setVideoDurationLimit(VideoDurationLimit limit) async {
    if (state.cameraSettings.isLocked) {
      _notify('Camera settings are locked. Tap the lock icon to adjust.');
      return;
    }
    await updateCameraSettings(
      state.cameraSettings.copyWith(durationLimit: limit),
    );
    _notify('Clip duration set to ${limit.label}');
  }

  Future<void> toggleAntiShakeEis() async {
    if (state.cameraSettings.isLocked) {
      _notify('Camera settings are locked. Tap the lock icon to adjust.');
      return;
    }
    final next = !state.cameraSettings.antiShakeEis;
    await updateCameraSettings(
      state.cameraSettings.copyWith(antiShakeEis: next),
    );
    _notify(next ? 'EIS Anti-shake enabled' : 'EIS Anti-shake disabled');
  }

  Future<void> setPhotoResolution(PhotoResolution res) async {
    if (state.cameraSettings.isLocked) {
      _notify('Camera settings are locked. Tap the lock icon to adjust.');
      return;
    }
    await updateCameraSettings(
      state.cameraSettings.copyWith(photoResolution: res),
    );
    _notify('Photo quality set to ${res.label}');
  }

  Future<void> toggleWatermark() async {
    if (state.cameraSettings.isLocked) {
      _notify('Camera settings are locked. Tap the lock icon to adjust.');
      return;
    }
    final next = !state.cameraSettings.watermark;
    await updateCameraSettings(state.cameraSettings.copyWith(watermark: next));
    _notify(next ? 'Time watermark enabled' : 'Time watermark disabled');
  }

  // ───────────────────────────── Helpers ─────────────────────────────

  GlassesDevice? _discovered(String address) {
    for (final d in state.discoveredDevices) {
      if (d.address == address) return d;
    }
    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  void _notify(String message) {
    emit(state.copyWith(notice: message, noticeId: state.noticeId + 1));
  }

  @override
  void emit(GlassesState state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _scanTimer?.cancel();
    _connectTimer?.cancel();
    _importWatchdog?.cancel();
    _pendingRefreshTimer?.cancel();
    _settingsTimer?.cancel();
    return super.close();
  }
}
