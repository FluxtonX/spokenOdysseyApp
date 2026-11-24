import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/offline_cache_storage.dart';
import '../../domain/entities/memory_entity.dart';
import '../models/memory_model.dart';

/// Keeps a tiny offline copy of the newest memories (text + media URLs only,
/// no media files) so the timeline can show something without internet.
abstract class MemoriesLocalDataSource {
  /// Stores the [maxCachedMemories] newest of [memories], replacing the old copy.
  Future<void> cacheLatestMemories(List<MemoryEntity> memories);

  /// Newest first; empty when nothing was cached yet.
  Future<List<MemoryModel>> getCachedMemories();

  Future<void> removeCachedMemory(String memoryId);
}

class MemoriesLocalDataSourceImpl implements MemoriesLocalDataSource {
  final OfflineCacheStorage storage;

  MemoriesLocalDataSourceImpl({required this.storage});

  /// Deliberately small: only the latest few memories are kept offline.
  static const int maxCachedMemories = 5;
  static const String _key = 'latest_memories';

  @override
  Future<void> cacheLatestMemories(List<MemoryEntity> memories) async {
    final latest = _newestFirst(memories).take(maxCachedMemories);
    final encoded = jsonEncode(
      latest.map((m) => MemoryModel.fromEntity(m).toJson()).toList(),
    );
    await storage.write(_key, encoded);
  }

  @override
  Future<List<MemoryModel>> getCachedMemories() async {
    final raw = storage.read(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((json) => MemoryModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [MemoriesLocal] Discarding unreadable cache: $e');
      await storage.remove(_key);
      return [];
    }
  }

  @override
  Future<void> removeCachedMemory(String memoryId) async {
    final cached = await getCachedMemories();
    final remaining = cached.where((m) => m.id != memoryId).toList();
    if (remaining.length == cached.length) return;
    await storage.write(
      _key,
      jsonEncode(remaining.map((m) => m.toJson()).toList()),
    );
  }

  /// Sorts by createdAt (newest first). Memories without a readable date
  /// keep their server order after the dated ones.
  List<MemoryEntity> _newestFirst(List<MemoryEntity> memories) {
    final indexed = memories.asMap().entries.toList();
    indexed.sort((a, b) {
      final da = DateTime.tryParse(a.value.createdAt ?? '');
      final db = DateTime.tryParse(b.value.createdAt ?? '');
      if (da != null && db != null) {
        final byDate = db.compareTo(da);
        if (byDate != 0) return byDate;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }
}
