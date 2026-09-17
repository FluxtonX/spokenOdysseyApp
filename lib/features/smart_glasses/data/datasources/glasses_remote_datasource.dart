import 'package:flutter/services.dart';

abstract class GlassesRemoteDataSource {
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
}

class GlassesRemoteDataSourceImpl implements GlassesRemoteDataSource {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.fluxtonx.spokenodyssey/glasses',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.fluxtonx.spokenodyssey/glasses_events',
  );

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
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {'isConnected': false};
  }

  @override
  Future<void> startScan() async {
    await _methodChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  @override
  Future<void> enableBluetooth() async {
    try {
      await _methodChannel.invokeMethod('enableBluetooth');
    } catch (_) {}
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> connectDevice(String address) async {
    await _methodChannel.invokeMethod('connectDevice', {'address': address});
  }

  @override
  Future<void> disconnectDevice() async {
    await _methodChannel.invokeMethod('disconnectDevice');
  }

  @override
  Future<void> syncTime() async {
    await _methodChannel.invokeMethod('syncTime');
  }

  @override
  Future<void> getBatteryLevel() async {
    await _methodChannel.invokeMethod('getBatteryLevel');
  }

  @override
  Future<void> takePhoto() async {
    await _methodChannel.invokeMethod('takePhoto');
  }

  @override
  Future<void> toggleRecording(bool start) async {
    await _methodChannel.invokeMethod('toggleRecording', {'start': start});
  }

  @override
  Future<void> toggleVoiceRecording(bool start) async {
    await _methodChannel.invokeMethod('toggleVoiceRecording', {'start': start});
  }

  @override
  Future<void> importAlbum() async {
    try {
      await _methodChannel.invokeMethod('importAlbum');
    } catch (_) {}
  }

  @override
  Stream<Map<String, dynamic>> get eventStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }
}
