class GlassesMediaItem {
  final String fileName;
  final String filePath;
  final int fileType; // 1 = Image, 2 = Video, 3 = Audio
  final int durationSeconds;
  final DateTime importedAt;

  const GlassesMediaItem({
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.durationSeconds = 0,
    required this.importedAt,
  });

  bool get isVideo => fileType == 2 || fileName.toLowerCase().endsWith('.mp4');
  bool get isImage => fileType == 1 || fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.png');
  bool get isAudio => fileType == 3 || fileName.toLowerCase().endsWith('.opus') || fileName.toLowerCase().endsWith('.pcm');
}
