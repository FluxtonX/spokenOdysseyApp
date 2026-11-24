import 'package:flutter/services.dart';

import '../../domain/entities/bluetooth_enable_result.dart';
import '../../domain/entities/glasses_audio_status.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_work_mode.dart';
import '../models/glasses_audio_status_model.dart';
import '../models/glasses_device_settings_model.dart';

abstract class GlassesRemoteDataSource {
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

  /// Sends a mode command (photo, video start/stop, audio start/stop, find…).
  Future<GlassesCommandResult> setDeviceMode(int mode);
  Future<void> endTransfer();

  Future<void> importAlbum();
  Future<Map<String, int>?> getMediaCount();

  /// Unpacks raw glasses bundles already on the phone; returns recovered media as maps.
  Future<List<Map<String, dynamic>>> repairAlbum();

  Future<GlassesDeviceSettings?> getDeviceSettings();
  Future<bool?> setWearDetection(bool enabled);
  Future<bool?> setVoiceWakeup(bool enabled);
  Future<bool> setVolume({int? music, int? call, int? system});

  Future<Map<String, int>?> getVideoConfig();
  Future<bool> setVideoConfig({required int angle, required int duration});

  // Audio link (classic Bluetooth so sound plays through the glasses)
  Future<GlassesAudioStatus> getAudioStatus();
  Future<GlassesAudioStatus> connectAudio();
  Future<void> openBluetoothSettings();

  Stream<Map<String, dynamic>> get eventStream;
}

class GlassesRemoteDataSourceImpl implements GlassesRemoteDataSource {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.fluxtonx.spokenodyssey/glasses',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.fluxtonx.spokenodyssey/glasses_events',
  );

  Stream<Map<String, dynamic>>? _events;

  @override
  Future<void> initializeSDK() async {
    try {
      await _methodChannel.invokeMethod('initializeSDK');
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> getConnectedDevice() async {
    try {
      final res = await _methodChannel.invokeMethod('getConnectedDevice');
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return {'isConnected': false};
  }

  @override
  Future<void> startScan() => _methodChannel.invokeMethod('startScan');

  @override
  Future<void> stopScan() => _methodChannel.invokeMethod('stopScan');

  @override
  Future<BluetoothEnableResult> enableBluetooth() async {
    try {
      return BluetoothEnableResult.fromPlatform(
        await _methodChannel.invokeMethod<Object?>('enableBluetooth'),
      );
    } catch (_) {
      return BluetoothEnableResult.prompted;
    }
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isBluetoothEnabled') ??
          true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> connectDevice(String address, {String? name}) async {
    await _methodChannel.invokeMethod('connectDevice', {
      'address': address,
      if (name != null) 'name': name,
    });
  }

  @override
  Future<void> disconnectDevice() =>
      _methodChannel.invokeMethod('disconnectDevice');

  @override
  Future<void> syncTime() => _methodChannel.invokeMethod('syncTime');

  @override
  Future<void> getBatteryLevel() =>
      _methodChannel.invokeMethod('getBatteryLevel');

  @override
  Future<GlassesCommandResult> setDeviceMode(int mode) async {
    try {
      final res = await _methodChannel.invokeMethod('setDeviceMode', {
        'mode': mode,
      });
      return GlassesCommandResultModel.fromMap(res);
    } on MissingPluginException {
      return const GlassesCommandResult.failed();
    } catch (_) {
      return const GlassesCommandResult.failed();
    }
  }

  @override
  Future<void> endTransfer() async {
    try {
      await _methodChannel.invokeMethod('endTransfer');
    } catch (_) {}
  }

  @override
  Future<void> importAlbum() => _methodChannel.invokeMethod('importAlbum');

  @override
  Future<List<Map<String, dynamic>>> repairAlbum() async {
    try {
      final res = await _methodChannel.invokeMethod('repairAlbum');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<Map<String, int>?> getMediaCount() async {
    try {
      final res = await _methodChannel.invokeMethod('getMediaCount');
      if (res is Map) {
        return res.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<GlassesDeviceSettings?> getDeviceSettings() async {
    try {
      final res = await _methodChannel.invokeMethod('getDeviceSettings');
      if (res is Map) {
        return GlassesDeviceSettingsModel.fromMap(
          Map<String, dynamic>.from(res),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<bool?> _setToggle(String method, bool enabled) async {
    try {
      final res = await _methodChannel.invokeMethod(method, {
        'enabled': enabled,
      });
      if (res is Map && res['ok'] == true) {
        return res['enabled'] as bool? ?? enabled;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool?> setWearDetection(bool enabled) =>
      _setToggle('setWearDetection', enabled);

  @override
  Future<bool?> setVoiceWakeup(bool enabled) =>
      _setToggle('setVoiceWakeup', enabled);

  @override
  Future<bool> setVolume({int? music, int? call, int? system}) async {
    try {
      final res = await _methodChannel.invokeMethod('setVolume', {
        if (music != null) 'music': music,
        if (call != null) 'call': call,
        if (system != null) 'system': system,
      });
      return res is Map && res['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, int>?> getVideoConfig() async {
    try {
      final res = await _methodChannel.invokeMethod('getVideoConfig');
      if (res is Map) {
        return {
          'angle': (res['angle'] as num?)?.toInt() ?? 0,
          'duration': (res['duration'] as num?)?.toInt() ?? 180,
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> setVideoConfig({
    required int angle,
    required int duration,
  }) async {
    try {
      final res = await _methodChannel.invokeMethod('setVideoConfig', {
        'angle': angle,
        'duration': duration,
      });
      return res is Map && res['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<GlassesAudioStatus> _audioCall(String method) async {
    try {
      final res = await _methodChannel.invokeMethod(method);
      if (res is Map) {
        return GlassesAudioStatusModel.fromMap(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return const GlassesAudioStatus(
      state: GlassesAudioState.failed,
      failReason: 'unavailable',
    );
  }

  @override
  Future<GlassesAudioStatus> getAudioStatus() => _audioCall('getAudioStatus');

  @override
  Future<GlassesAudioStatus> connectAudio() => _audioCall('connectAudio');

  @override
  Future<void> openBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  @override
  Stream<Map<String, dynamic>> get eventStream {
    return _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) return Map<String, dynamic>.from(event);
      return <String, dynamic>{};
    });
  }
}
