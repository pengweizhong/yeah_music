// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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

  /// SharedPreferences 被外部写入后刷新明暗模式。
  Future<void> reloadFromStorage() async {
    await _load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, themeModeToStorage(mode));
  }
}
