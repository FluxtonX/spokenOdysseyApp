import '../../domain/entities/glasses_media_item.dart';

/// JSON mapping for [GlassesMediaItem] (local media index + platform events).
class GlassesMediaModel {
  GlassesMediaModel._();

  static GlassesMediaItem fromEvent(Map<String, dynamic> event) {
    final timestamp = (event['timestamp'] as num?)?.toInt() ?? 0;
    return GlassesMediaItem(
      fileName: event['fileName'] as String? ?? '',
      filePath: event['filePath'] as String? ?? '',
      fileType: (event['fileType'] as num?)?.toInt() ?? GlassesMediaType.image,
      durationSeconds: (event['duration'] as num?)?.toInt() ?? 0,
      importedAt: DateTime.now(),
      capturedAt: _parseTimestamp(timestamp),
      thumbnailPath: event['thumbnailPath'] as String? ?? '',
      sizeBytes: (event['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  static GlassesMediaItem fromJson(Map<String, dynamic> json) {
    return GlassesMediaItem(
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      fileType: (json['fileType'] as num?)?.toInt() ?? GlassesMediaType.image,
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> toJson(GlassesMediaItem item) => {
    'fileName': item.fileName,
    'filePath': item.filePath,
    'fileType': item.fileType,
    'duration': item.durationSeconds,
    'importedAt': item.importedAt.toIso8601String(),
    if (item.capturedAt != null)
      'capturedAt': item.capturedAt!.toIso8601String(),
    'thumbnailPath': item.thumbnailPath,
    'sizeBytes': item.sizeBytes,
  };

  /// SDK timestamps may be seconds or milliseconds.
  static DateTime? _parseTimestamp(int value) {
    if (value <= 0) return null;
    final ms = value < 100000000000 ? value * 1000 : value;
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    if (date.year < 2015 ||
        date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return null;
    }
    return date;
  }
}
