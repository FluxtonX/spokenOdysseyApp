class GlassesVolumeLevel {
  final int min;
  final int max;
  final int value;

  const GlassesVolumeLevel({
    required this.min,
    required this.max,
    required this.value,
  });

  bool get isValid => max > min;

  /// 0..1 position of [value] between [min] and [max].
  double get fraction =>
      isValid ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0;

  GlassesVolumeLevel copyWith({int? value}) =>
      GlassesVolumeLevel(min: min, max: max, value: value ?? this.value);
}

/// Video resolution modes for smart glasses recording.
enum VideoResolution {
  res4K('4K', '3840 × 2160', 'Ultra HD crisp recording with maximum detail'),
  res3K(
    '3K',
    '2880 × 2160',
    'Cinematic balance of sharpness and fast transfer',
  ),
  res1080P('1080P', '1920 × 1080', 'Full HD 60fps smooth & battery-efficient');

  final String label;
  final String dimensions;
  final String subtitle;
  const VideoResolution(this.label, this.dimensions, this.subtitle);
}

/// Video segment length limit.
enum VideoDurationLimit {
  sec30('30s', 30),
  min1('1m', 60),
  min3('3m', 180),
  min5('5m', 300),
  continuous('Max', 0);

  final String label;
  final int seconds;
  const VideoDurationLimit(this.label, this.seconds);
}

/// Photo resolution modes.
enum PhotoResolution {
  ultra('12 MP', '4032 × 3024', 'Super clear ultra-detail'),
  standard('8 MP', '3264 × 2448', 'Fast shutter & smaller file size');

  final String label;
  final String dimensions;
  final String subtitle;
  const PhotoResolution(this.label, this.dimensions, this.subtitle);
}

/// Camera & recording settings for the smart glasses.
class GlassesCameraSettings {
  final VideoResolution videoResolution;
  final VideoDurationLimit durationLimit;
  final int frameRate; // 30 or 60
  final bool antiShakeEis; // Electronic Image Stabilization
  final PhotoResolution photoResolution;
  final bool watermark; // Date/Time watermark
  final bool isLocked; // Quick-lock settings

  const GlassesCameraSettings({
    this.videoResolution = VideoResolution.res4K,
    this.durationLimit = VideoDurationLimit.min3,
    this.frameRate = 30,
    this.antiShakeEis = true,
    this.photoResolution = PhotoResolution.ultra,
    this.watermark = false,
    this.isLocked = false,
  });

  /// Short summary badge for Studio/Header (e.g. "4K • 3m • EIS ON").
  String get summaryBadge {
    final res = videoResolution.label;
    final dur = durationLimit.label;
    final eis = antiShakeEis ? 'EIS' : '';
    return [res, dur, if (eis.isNotEmpty) eis].join(' • ');
  }

  GlassesCameraSettings copyWith({
    VideoResolution? videoResolution,
    VideoDurationLimit? durationLimit,
    int? frameRate,
    bool? antiShakeEis,
    PhotoResolution? photoResolution,
    bool? watermark,
    bool? isLocked,
  }) {
    return GlassesCameraSettings(
      videoResolution: videoResolution ?? this.videoResolution,
      durationLimit: durationLimit ?? this.durationLimit,
      frameRate: frameRate ?? this.frameRate,
      antiShakeEis: antiShakeEis ?? this.antiShakeEis,
      photoResolution: photoResolution ?? this.photoResolution,
      watermark: watermark ?? this.watermark,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() => {
    'videoResolution': videoResolution.name,
    'durationLimit': durationLimit.name,
    'frameRate': frameRate,
    'antiShakeEis': antiShakeEis,
    'photoResolution': photoResolution.name,
    'watermark': watermark,
    'isLocked': isLocked,
  };

  factory GlassesCameraSettings.fromJson(Map<String, dynamic> json) {
    VideoResolution res = VideoResolution.res4K;
    if (json['videoResolution'] != null) {
      res = VideoResolution.values.firstWhere(
        (v) => v.name == json['videoResolution'],
        orElse: () => VideoResolution.res4K,
      );
    }

    VideoDurationLimit dur = VideoDurationLimit.min3;
    if (json['durationLimit'] != null) {
      dur = VideoDurationLimit.values.firstWhere(
        (v) => v.name == json['durationLimit'],
        orElse: () => VideoDurationLimit.min3,
      );
    }

    PhotoResolution photo = PhotoResolution.ultra;
    if (json['photoResolution'] != null) {
      photo = PhotoResolution.values.firstWhere(
        (v) => v.name == json['photoResolution'],
        orElse: () => PhotoResolution.ultra,
      );
    }

    return GlassesCameraSettings(
      videoResolution: res,
      durationLimit: dur,
      frameRate: (json['frameRate'] as num?)?.toInt() ?? 30,
      antiShakeEis: json['antiShakeEis'] as bool? ?? true,
      photoResolution: photo,
      watermark: json['watermark'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}

/// Settings read from the glasses themselves (not app-only preferences).
class GlassesDeviceSettings {
  final bool wearSupported;
  final bool? wearDetection;
  final bool? voiceWakeup;
  final GlassesVolumeLevel? musicVolume;
  final GlassesVolumeLevel? callVolume;
  final GlassesVolumeLevel? systemVolume;
  final String firmwareVersion;
  final String hardwareVersion;
  final String wifiFirmwareVersion;
  final String address;
  final GlassesCameraSettings cameraSettings;

  const GlassesDeviceSettings({
    this.wearSupported = false,
    this.wearDetection,
    this.voiceWakeup,
    this.musicVolume,
    this.callVolume,
    this.systemVolume,
    this.firmwareVersion = '',
    this.hardwareVersion = '',
    this.wifiFirmwareVersion = '',
    this.address = '',
    this.cameraSettings = const GlassesCameraSettings(),
  });

  bool get hasVolume =>
      (musicVolume?.isValid ?? false) ||
      (callVolume?.isValid ?? false) ||
      (systemVolume?.isValid ?? false);

  GlassesDeviceSettings copyWith({
    bool? wearDetection,
    bool? voiceWakeup,
    GlassesVolumeLevel? musicVolume,
    GlassesVolumeLevel? callVolume,
    GlassesVolumeLevel? systemVolume,
    GlassesCameraSettings? cameraSettings,
  }) {
    return GlassesDeviceSettings(
      wearSupported: wearSupported,
      wearDetection: wearDetection ?? this.wearDetection,
      voiceWakeup: voiceWakeup ?? this.voiceWakeup,
      musicVolume: musicVolume ?? this.musicVolume,
      callVolume: callVolume ?? this.callVolume,
      systemVolume: systemVolume ?? this.systemVolume,
      firmwareVersion: firmwareVersion,
      hardwareVersion: hardwareVersion,
      wifiFirmwareVersion: wifiFirmwareVersion,
      address: address,
      cameraSettings: cameraSettings ?? this.cameraSettings,
    );
  }
}
