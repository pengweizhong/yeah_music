import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局 Material 主题：浅色 / 深色 / 跟随系统；持久化键 [prefsKey]。
class AppThemeModeProvider extends ChangeNotifier {
  static const String prefsKey = 'global_theme_mode';

  /// 0: 白天, 1: 夜晚, 2: 跟随系统
  static int themeModeToStorage(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  static ThemeMode themeModeFromStorage(int? v) {
    switch (v) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
      default:
        return ThemeMode.system;
    }
  }

  AppThemeModeProvider() {
    _load();
  }

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(prefsKey);
    final next = themeModeFromStorage(v);
    if (next == _themeMode) return;
    _themeMode = next;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, themeModeToStorage(mode));
  }
}
