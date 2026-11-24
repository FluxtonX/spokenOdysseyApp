import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_work_mode.dart';

class GlassesDeviceSettingsModel {
  GlassesDeviceSettingsModel._();

  static GlassesDeviceSettings fromMap(Map<String, dynamic> map) {
    final volume = map['volume'] is Map
        ? Map<String, dynamic>.from(map['volume'] as Map)
        : const <String, dynamic>{};

    GlassesVolumeLevel? level(String key) {
      final min = (volume['${key}Min'] as num?)?.toInt();
      final max = (volume['${key}Max'] as num?)?.toInt();
      final value = (volume[key] as num?)?.toInt();
      if (min == null || max == null || value == null) return null;
      return GlassesVolumeLevel(min: min, max: max, value: value);
    }

    GlassesCameraSettings cameraSettings = const GlassesCameraSettings();
    if (map['cameraSettings'] is Map) {
      try {
        cameraSettings = GlassesCameraSettings.fromJson(
          Map<String, dynamic>.from(map['cameraSettings'] as Map),
        );
      } catch (_) {}
    }

    return GlassesDeviceSettings(
      wearSupported:
          map['wearSupported'] as bool? ?? map.containsKey('wearDetection'),
      wearDetection: map['wearDetection'] as bool?,
      voiceWakeup: map['voiceWakeup'] as bool?,
      musicVolume: level('music'),
      callVolume: level('call'),
      systemVolume: level('system'),
      firmwareVersion: map['firmwareVersion'] as String? ?? '',
      hardwareVersion: map['hardwareVersion'] as String? ?? '',
      wifiFirmwareVersion: map['wifiFirmwareVersion'] as String? ?? '',
      address: map['address'] as String? ?? '',
      cameraSettings: cameraSettings,
    );
  }
}

class GlassesCommandResultModel {
  GlassesCommandResultModel._();

  static GlassesCommandResult fromMap(Object? raw) {
    if (raw is! Map) return const GlassesCommandResult.failed();
    final map = Map<String, dynamic>.from(raw);
    return GlassesCommandResult(
      ok: map['ok'] == true,
      busyMode: (map['busyMode'] as num?)?.toInt(),
      timedOut: map['timeout'] == true,
    );
  }
}
