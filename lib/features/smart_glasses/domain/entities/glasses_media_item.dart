/// Media type codes used by the glasses SDK (GlassesControl.identifyFileType).
class GlassesMediaType {
  GlassesMediaType._();

  static const int image = 1;
  static const int video = 2;
  static const int audio = 3;
}

class GlassesMediaItem {
  final String fileName;
  final String filePath;
  final int fileType; // 1 = Image, 2 = Video, 3 = Audio
  final int durationSeconds;
  final DateTime importedAt;
  final DateTime? capturedAt;
  final String thumbnailPath;
  final int sizeBytes;

  const GlassesMediaItem({
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.durationSeconds = 0,
    required this.importedAt,
    this.capturedAt,
    this.thumbnailPath = '',
    this.sizeBytes = 0,
  });

  String get _lower => fileName.toLowerCase();

  bool get isVideo =>
      fileType == GlassesMediaType.video ||
      _lower.endsWith('.mp4') ||
      _lower.endsWith('.avi');

  bool get isAudio =>
      !isVideo &&
      (fileType == GlassesMediaType.audio ||
          _lower.endsWith('.wav') ||
          _lower.endsWith('.opus') ||
          _lower.endsWith('.pcm'));

  bool get isImage => !isVideo && !isAudio;

  /// Best date to show/group by: capture time from the glasses, else import time.
  DateTime get displayDate => capturedAt ?? importedAt;

  bool get hasThumbnail => thumbnailPath.isNotEmpty;

  GlassesMediaItem copyWith({
    int? durationSeconds,
    String? thumbnailPath,
    int? sizeBytes,
  }) {
    return GlassesMediaItem(
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      importedAt: importedAt,
      capturedAt: capturedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}

/// Number of items still stored on the glasses (not yet imported).
class GlassesPendingMedia {
  final int images;
  final int videos;
  final int audio;

  const GlassesPendingMedia({this.images = 0, this.videos = 0, this.audio = 0});

  int get total => images + videos + audio;
}
