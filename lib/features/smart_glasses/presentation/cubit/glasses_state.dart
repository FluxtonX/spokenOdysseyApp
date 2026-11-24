import '../../domain/entities/glasses_audio_status.dart';
import '../../domain/entities/glasses_device.dart';
import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../../domain/entities/glasses_work_mode.dart';

enum GlassesConnectionStatus {
  disconnected,
  bluetoothOff,

  /// The device has no Bluetooth radio (e.g. the iOS Simulator).
  bluetoothUnavailable,
  permissionRequired,
  scanning,
  connecting,
  connected,
  error,
}

enum GlassesImportPhase { idle, connecting, downloading, completed, failed }

/// A capture command waiting for the glasses to answer.
enum GlassesPendingCommand { photo, video, audio, find }

class GlassesState {
  final GlassesConnectionStatus status;
  final List<GlassesDevice> discoveredDevices;
  final bool scanFinished;
  final GlassesDevice? connectedDevice;
  final String? connectingAddress;
  final String errorMessage;

  /// Last known activity of the glasses (a [GlassesWorkMode] value, 0 = ready).
  final int glassesMode;
  final GlassesPendingCommand? pendingCommand;
  final bool isRecordingVideo;
  final bool isRecordingVoice;
  final DateTime? recordingStartedAt;

  final GlassesDeviceSettings? deviceSettings;

  /// Whether sound plays through the glasses (classic Bluetooth audio link).
  final GlassesAudioStatus audio;
  final bool isSettingsLoading;
  final GlassesCameraSettings cameraSettings;

  final List<GlassesMediaItem> importedMedia;
  final bool isMediaLoading;
  final GlassesPendingMedia? pendingMedia;

  final GlassesImportPhase importPhase;
  final String importStatusText;
  final String importCurrentFile;
  final double importFileProgress;
  final int importIndex;
  final int importTotal;
  final int importSessionCount;
  final int importSkippedCount;

  /// iOS: the iPhone can't switch from its Wi‑Fi to the glasses; the user is asked to
  /// disconnect (Control Center → Wi‑Fi) and the import continues by itself afterwards.
  final bool importNeedsWifiDisconnect;

  /// Items saved by the current/last import, newest first.
  final List<GlassesMediaItem> recentImports;
  final String wifiSpeed;

  /// One-off message for snackbars; [noticeId] changes each time.
  final String notice;
  final int noticeId;

  const GlassesState({
    this.status = GlassesConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.scanFinished = false,
    this.connectedDevice,
    this.connectingAddress,
    this.errorMessage = '',
    this.glassesMode = GlassesWorkMode.idle,
    this.pendingCommand,
    this.isRecordingVideo = false,
    this.isRecordingVoice = false,
    this.recordingStartedAt,
    this.deviceSettings,
    this.audio = const GlassesAudioStatus(),
    this.isSettingsLoading = false,
    this.cameraSettings = const GlassesCameraSettings(),
    this.importedMedia = const [],
    this.isMediaLoading = false,
    this.pendingMedia,
    this.importPhase = GlassesImportPhase.idle,
    this.importStatusText = '',
    this.importCurrentFile = '',
    this.importFileProgress = 0,
    this.importIndex = 0,
    this.importTotal = 0,
    this.importSessionCount = 0,
    this.importSkippedCount = 0,
    this.importNeedsWifiDisconnect = false,
    this.recentImports = const [],
    this.wifiSpeed = '',
    this.notice = '',
    this.noticeId = 0,
  });

  bool get isConnected => status == GlassesConnectionStatus.connected;
  bool get isScanning => status == GlassesConnectionStatus.scanning;
  bool get isConnecting => status == GlassesConnectionStatus.connecting;
  bool get isImporting =>
      importPhase == GlassesImportPhase.connecting ||
      importPhase == GlassesImportPhase.downloading;
  bool get isRecording => isRecordingVideo || isRecordingVoice;

  /// Capture buttons are usable (connected, not importing, no command in flight).
  bool get canCapture => isConnected && !isImporting && pendingCommand == null;

  /// Short status of the glasses for the UI.
  String get activityLabel {
    if (!isConnected) return '';
    if (isImporting || glassesMode == GlassesWorkMode.transfer) {
      return 'Transferring media';
    }
    if (isRecordingVideo) return 'Recording video';
    if (isRecordingVoice) return 'Recording audio';
    if (glassesMode == GlassesWorkMode.ota) return 'Updating firmware';
    return 'Ready';
  }

  /// Overall import progress 0..1 (null when indeterminate).
  double? get importOverallProgress {
    if (importTotal <= 0) return null;
    final done = (importIndex - 1).clamp(0, importTotal);
    return ((done + importFileProgress) / importTotal).clamp(0.0, 1.0);
  }

  List<GlassesMediaItem> get photos =>
      importedMedia.where((m) => m.isImage).toList();
  List<GlassesMediaItem> get videos =>
      importedMedia.where((m) => m.isVideo).toList();
  List<GlassesMediaItem> get audios =>
      importedMedia.where((m) => m.isAudio).toList();

  GlassesState copyWith({
    GlassesConnectionStatus? status,
    List<GlassesDevice>? discoveredDevices,
    bool? scanFinished,
    GlassesDevice? connectedDevice,
    bool clearConnectedDevice = false,
    String? connectingAddress,
    bool clearConnectingAddress = false,
    String? errorMessage,
    int? glassesMode,
    GlassesPendingCommand? pendingCommand,
    bool clearPendingCommand = false,
    bool? isRecordingVideo,
    bool? isRecordingVoice,
    DateTime? recordingStartedAt,
    bool clearRecordingStartedAt = false,
    GlassesDeviceSettings? deviceSettings,
    GlassesAudioStatus? audio,
    bool clearDeviceSettings = false,
    bool? isSettingsLoading,
    GlassesCameraSettings? cameraSettings,
    List<GlassesMediaItem>? importedMedia,
    bool? isMediaLoading,
    GlassesPendingMedia? pendingMedia,
    GlassesImportPhase? importPhase,
    String? importStatusText,
    String? importCurrentFile,
    double? importFileProgress,
    int? importIndex,
    int? importTotal,
    int? importSessionCount,
    int? importSkippedCount,
    bool? importNeedsWifiDisconnect,
    List<GlassesMediaItem>? recentImports,
    String? wifiSpeed,
    String? notice,
    int? noticeId,
  }) {
    return GlassesState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      scanFinished: scanFinished ?? this.scanFinished,
      connectedDevice: clearConnectedDevice
          ? null
          : (connectedDevice ?? this.connectedDevice),
      connectingAddress: clearConnectingAddress
          ? null
          : (connectingAddress ?? this.connectingAddress),
      errorMessage: errorMessage ?? this.errorMessage,
      glassesMode: glassesMode ?? this.glassesMode,
      pendingCommand: clearPendingCommand
          ? null
          : (pendingCommand ?? this.pendingCommand),
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      recordingStartedAt: clearRecordingStartedAt
          ? null
          : (recordingStartedAt ?? this.recordingStartedAt),
      deviceSettings: clearDeviceSettings
          ? null
          : (deviceSettings ?? this.deviceSettings),
      audio: audio ?? this.audio,
      isSettingsLoading: isSettingsLoading ?? this.isSettingsLoading,
      cameraSettings: cameraSettings ?? this.cameraSettings,
      importedMedia: importedMedia ?? this.importedMedia,
      isMediaLoading: isMediaLoading ?? this.isMediaLoading,
      pendingMedia: pendingMedia ?? this.pendingMedia,
      importPhase: importPhase ?? this.importPhase,
      importStatusText: importStatusText ?? this.importStatusText,
      importCurrentFile: importCurrentFile ?? this.importCurrentFile,
      importFileProgress: importFileProgress ?? this.importFileProgress,
      importIndex: importIndex ?? this.importIndex,
      importTotal: importTotal ?? this.importTotal,
      importSessionCount: importSessionCount ?? this.importSessionCount,
      importSkippedCount: importSkippedCount ?? this.importSkippedCount,
      importNeedsWifiDisconnect:
          importNeedsWifiDisconnect ?? this.importNeedsWifiDisconnect,
      recentImports: recentImports ?? this.recentImports,
      wifiSpeed: wifiSpeed ?? this.wifiSpeed,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }
}
