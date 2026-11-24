import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/glasses_device_settings.dart';
import '../../domain/entities/glasses_media_item.dart';
import '../models/glasses_media_model.dart';

abstract class GlassesLocalDataSource {
  Future<String?> getSavedDeviceAddress();
  Future<String?> getSavedDeviceName();
  Future<void> saveDevice(String address, {String? name});
  Future<void> clearSavedDevice();

  Future<GlassesCameraSettings> getCameraSettings();
  Future<void> saveCameraSettings(GlassesCameraSettings settings);

  /// All media imported from the glasses that is still on this phone.
  Future<List<GlassesMediaItem>> loadMedia();
  Future<void> saveMedia(GlassesMediaItem item);
  Future<void> deleteMedia(GlassesMediaItem item);
}

class GlassesLocalDataSourceImpl implements GlassesLocalDataSource {
  static const String _keySavedAddress = 'smart_glasses_saved_address';
  static const String _keySavedName = 'smart_glasses_saved_name';
  static const String _keyMediaIndex = 'smart_glasses_media_index_v1';
  static const String _keyCameraSettings = 'smart_glasses_camera_settings_v1';
  static const String albumFolder = 'DCIM_1';

  static const _imageExt = ['.jpg', '.jpeg', '.png'];
  static const _videoExt = ['.mp4', '.avi'];
  // Raw .opus/.pcm voice files are converted to .wav by the bridge; only list the .wav.
  static const _audioExt = ['.wav', '.ogg'];

  /// Prefixes of helper files the SDK writes into the album folder.
  static const _ignoredPrefixes = ['tmp_', 'first_frame_', 'download_file'];

  final SharedPreferences sharedPreferences;

  GlassesLocalDataSourceImpl({required this.sharedPreferences});

  // ── Device ────────────────────────────────────────────────────────────────

  @override
  Future<String?> getSavedDeviceAddress() async =>
      sharedPreferences.getString(_keySavedAddress);

  @override
  Future<String?> getSavedDeviceName() async =>
      sharedPreferences.getString(_keySavedName);

  @override
  Future<void> saveDevice(String address, {String? name}) async {
    await sharedPreferences.setString(_keySavedAddress, address);
    if (name != null && name.isNotEmpty) {
      await sharedPreferences.setString(_keySavedName, name);
    }
  }

  @override
  Future<void> clearSavedDevice() async {
    await sharedPreferences.remove(_keySavedAddress);
    await sharedPreferences.remove(_keySavedName);
  }

  // ── Camera Settings ────────────────────────────────────────────────────────

  @override
  Future<GlassesCameraSettings> getCameraSettings() async {
    final raw = sharedPreferences.getString(_keyCameraSettings);
    if (raw == null || raw.isEmpty) return const GlassesCameraSettings();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GlassesCameraSettings.fromJson(map);
    } catch (_) {
      return const GlassesCameraSettings();
    }
  }

  @override
  Future<void> saveCameraSettings(GlassesCameraSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await sharedPreferences.setString(_keyCameraSettings, raw);
  }

  // ── Media ─────────────────────────────────────────────────────────────────

  Future<Directory?> _albumDir() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    return Directory('${base.path}/$albumFolder');
  }

  List<GlassesMediaItem> _readIndex() {
    final raw = sharedPreferences.getString(_keyMediaIndex);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => GlassesMediaModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(List<GlassesMediaItem> items) async {
    final raw = jsonEncode(items.map(GlassesMediaModel.toJson).toList());
    await sharedPreferences.setString(_keyMediaIndex, raw);
  }

  int? _typeFromExtension(String path) {
    final lower = path.toLowerCase();
    if (_imageExt.any(lower.endsWith)) return GlassesMediaType.image;
    if (_videoExt.any(lower.endsWith)) return GlassesMediaType.video;
    if (_audioExt.any(lower.endsWith)) return GlassesMediaType.audio;
    return null;
  }

  bool _isIgnoredName(String name) {
    final lower = name.toLowerCase();
    return _ignoredPrefixes.any(lower.startsWith) || lower.contains('thumb');
  }

  /// True when an image file is complete: valid JPEG/PNG header and, for JPEG,
  /// an end-of-image marker. Catches half-written or zero-filled files.
  bool _isCompleteImage(File file) {
    RandomAccessFile? raf;
    try {
      final length = file.lengthSync();
      if (length < 1024) return false;
      raf = file.openSync();
      final head = raf.readSync(4);
      if (head.length < 4) return false;
      final isPng =
          head[0] == 0x89 &&
          head[1] == 0x50 &&
          head[2] == 0x4E &&
          head[3] == 0x47;
      if (isPng) return true;
      final isJpeg = head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF;
      if (!isJpeg) return false;
      final tailSize = length < 64 ? length : 64;
      raf.setPositionSync(length - tailSize);
      final tail = raf.readSync(tailSize);
      for (var i = tail.length - 2; i >= 0; i--) {
        if (tail[i] == 0xFF && tail[i + 1] == 0xD9) return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      raf?.closeSync();
    }
  }

  bool _isUsable(GlassesMediaItem item, File file) {
    if (!file.existsSync() || file.lengthSync() == 0) return false;
    if (_isIgnoredName(item.fileName)) return false;
    if (item.isImage) return _isCompleteImage(file);
    if (item.isAudio) {
      return _audioExt.any(item.filePath.toLowerCase().endsWith);
    }
    return true;
  }

  @override
  Future<List<GlassesMediaItem>> loadMedia() async {
    final indexed = <String, GlassesMediaItem>{};
    for (final item in _readIndex()) {
      if (item.filePath.isEmpty) continue;
      final file = File(item.filePath);
      if (!_isUsable(item, file)) continue;
      indexed[item.filePath] = item.copyWith(sizeBytes: file.lengthSync());
    }

    // Video cover frames written by the SDK must not show up as photos.
    final thumbnails = indexed.values
        .where((m) => m.hasThumbnail)
        .map((m) => m.thumbnailPath)
        .toSet();

    // Pick up files that landed in the album folder without an index entry
    // (e.g. imported before this index existed).
    try {
      final dir = await _albumDir();
      if (dir != null && dir.existsSync()) {
        // Not recursive: video cover images live in the hidden ".thumbs" sub-folder.
        for (final entity in dir.listSync()) {
          if (entity is! File) continue;
          final path = entity.path;
          if (entity.uri.pathSegments.last.startsWith('.')) continue;
          if (indexed.containsKey(path) || thumbnails.contains(path)) continue;
          final type = _typeFromExtension(path);
          if (type == null) continue;
          final name = entity.uri.pathSegments.last;
          final stat = entity.statSync();
          if (_isIgnoredName(name)) {
            // Leftover SDK temp files from an interrupted photo rewrite.
            if (name.toLowerCase().startsWith('tmp_') &&
                DateTime.now().difference(stat.modified) >
                    const Duration(minutes: 10)) {
              try {
                entity.deleteSync();
              } catch (_) {}
            }
            continue;
          }
          final item = GlassesMediaItem(
            fileName: name,
            filePath: path,
            fileType: type,
            importedAt: stat.modified,
            sizeBytes: stat.size,
          );
          if (!_isUsable(item, entity)) continue;
          indexed[path] = item;
        }
      }
    } catch (_) {}

    final items = indexed.values.toList()
      ..sort((a, b) => b.displayDate.compareTo(a.displayDate));
    await _writeIndex(items);
    return items;
  }

  @override
  Future<void> saveMedia(GlassesMediaItem item) async {
    if (item.filePath.isEmpty) return;
    final items = _readIndex()..removeWhere((m) => m.filePath == item.filePath);
    final file = File(item.filePath);
    items.insert(
      0,
      file.existsSync() ? item.copyWith(sizeBytes: file.lengthSync()) : item,
    );
    await _writeIndex(items);
  }

  @override
  Future<void> deleteMedia(GlassesMediaItem item) async {
    for (final path in [item.filePath, item.thumbnailPath]) {
      if (path.isEmpty) continue;
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
    final items = _readIndex()..removeWhere((m) => m.filePath == item.filePath);
    await _writeIndex(items);
  }
}
