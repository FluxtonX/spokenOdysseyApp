import '../../domain/entities/glasses_device.dart';
import '../../domain/entities/glasses_media_item.dart';

enum GlassesConnectionStatus {
  disconnected,
  bluetoothOff,
  permissionRequired,
  scanning,
  connecting,
  connected,
  error,
}

class GlassesState {
  final GlassesConnectionStatus status;
  final List<GlassesDevice> discoveredDevices;
  final GlassesDevice? connectedDevice;
  final String errorMessage;
  final bool wearingDetection;
  final bool voiceWakeup;
  final bool isRecordingVideo;
  final bool isRecordingVoice;
  final List<GlassesMediaItem> importedMedia;
  final bool isImporting;
  final String importStatusText;
  final double musicVolume;
  final double callVolume;
  final double systemVolume;

  const GlassesState({
    this.status = GlassesConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.errorMessage = '',
    this.wearingDetection = true,
    this.voiceWakeup = true,
    this.isRecordingVideo = false,
    this.isRecordingVoice = false,
    this.importedMedia = const [],
    this.isImporting = false,
    this.importStatusText = '',
    this.musicVolume = 80.0,
    this.callVolume = 80.0,
    this.systemVolume = 80.0,
  });

  GlassesState copyWith({
    GlassesConnectionStatus? status,
    List<GlassesDevice>? discoveredDevices,
    GlassesDevice? connectedDevice,
    String? errorMessage,
    bool? wearingDetection,
    bool? voiceWakeup,
    bool? isRecordingVideo,
    bool? isRecordingVoice,
    List<GlassesMediaItem>? importedMedia,
    bool? isImporting,
    String? importStatusText,
    double? musicVolume,
    double? callVolume,
    double? systemVolume,
  }) {
    return GlassesState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage ?? this.errorMessage,
      wearingDetection: wearingDetection ?? this.wearingDetection,
      voiceWakeup: voiceWakeup ?? this.voiceWakeup,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      importedMedia: importedMedia ?? this.importedMedia,
      isImporting: isImporting ?? this.isImporting,
      importStatusText: importStatusText ?? this.importStatusText,
      musicVolume: musicVolume ?? this.musicVolume,
      callVolume: callVolume ?? this.callVolume,
      systemVolume: systemVolume ?? this.systemVolume,
    );
  }
}
