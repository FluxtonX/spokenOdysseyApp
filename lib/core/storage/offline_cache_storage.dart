import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value store for data kept so the app can show something while
/// offline. Everything here belongs to the signed-in user and is wiped by
/// [clearAll] on sign-out, so the next account never sees it.
class OfflineCacheStorage {
  final SharedPreferences _prefs;

  OfflineCacheStorage({required SharedPreferences sharedPreferences})
    : _prefs = sharedPreferences;

  static const String _prefix = 'offline_cache_';

  String? read(String key) => _prefs.getString('$_prefix$key');

  Future<void> write(String key, String value) =>
      _prefs.setString('$_prefix$key', value);

  Future<void> remove(String key) => _prefs.remove('$_prefix$key');

  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
