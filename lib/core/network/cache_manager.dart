import 'package:flutter/foundation.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};

  /// Retrieves cached item if present and within TTL.
  T? get<T>(String key, {Duration? ttl}) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (ttl != null && entry.isExpired(ttl)) {
      _cache.remove(key);
      debugPrint('⚡ [CacheManager] Expired key: $key');
      return null;
    }
    debugPrint('⚡ [CacheManager] Hit key: $key');
    return entry.data as T?;
  }

  /// Sets or updates cache item.
  void set<T>(String key, T data) {
    _cache[key] = CacheEntry<T>(data);
    debugPrint('⚡ [CacheManager] Set key: $key');
  }

  /// Invalidates a specific key or keys matching prefix.
  void invalidate(String keyOrPrefix) {
    _cache.removeWhere((k, _) => k == keyOrPrefix || k.startsWith(keyOrPrefix));
    debugPrint('⚡ [CacheManager] Invalidated key/prefix: $keyOrPrefix');
  }

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
    debugPrint('⚡ [CacheManager] Cache cleared');
  }
}
