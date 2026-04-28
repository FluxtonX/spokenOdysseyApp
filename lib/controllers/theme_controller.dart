import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  ThemeController({GetStorage? storage}) : _storage = storage ?? GetStorage();

  static const String _themeModeKey = 'theme_mode';

  final GetStorage _storage;
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    final storedValue = _storage.read<String>(_themeModeKey);
    switch (storedValue) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'light':
      default:
        themeMode.value = ThemeMode.light;
        break;
    }
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) {
      return;
    }

    themeMode.value = mode;
    _storage.write(_themeModeKey, mode.name);
  }
}
