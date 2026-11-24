/// Device modes understood by the glasses (QCOperatorDeviceMode in the vendor SDK).
class GlassesWorkMode {
  GlassesWorkMode._();

  static const int idle = 0x00;
  static const int photo = 0x01;
  static const int video = 0x02;
  static const int videoStop = 0x03;
  static const int transfer = 0x04;
  static const int ota = 0x05;
  static const int aiPhoto = 0x06;
  static const int speech = 0x07;
  static const int audio = 0x08;
  static const int transferStop = 0x09;
  static const int audioStop = 0x0c;
  static const int findDevice = 0x0d;

  /// What the glasses are doing, phrased for people.
  static String describe(int mode) {
    switch (mode) {
      case photo:
      case aiPhoto:
        return 'taking a photo';
      case video:
        return 'recording a video';
      case transfer:
        return 'transferring media';
      case ota:
        return 'updating firmware';
      case speech:
        return 'talking to the AI assistant';
      case audio:
        return 'recording audio';
      default:
        return 'busy';
    }
  }
}

/// Result of a mode command sent to the glasses.
class GlassesCommandResult {
  /// The glasses accepted the command.
  final bool ok;

  /// When refused: the mode the glasses are busy in.
  final int? busyMode;

  /// No answer from the glasses in time.
  final bool timedOut;

  const GlassesCommandResult({
    required this.ok,
    this.busyMode,
    this.timedOut = false,
  });

  const GlassesCommandResult.failed()
    : ok = false,
      busyMode = null,
      timedOut = true;
}
