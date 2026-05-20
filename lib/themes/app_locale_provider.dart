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

/// 应用界面语言（与 [AppLocalizations.supportedLocales] 一致）。
enum AppLanguageOption {
  /// 跟随 [WidgetsBinding.instance.platformDispatcher.locale]
  system,
  en,
  ja,
  zhHans,
  zhHant,
}

String _optionStorageName(AppLanguageOption o) => o.name;

AppLanguageOption? _optionFromName(String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  for (final o in AppLanguageOption.values) {
    if (o.name == name) {
      return o;
    }
  }
  return null;
}

/// 若不为 null，则 [MaterialApp.locale] 使用该值；为 null 时跟随系统。
Locale? resolveLocaleForOption(AppLanguageOption o) {
  switch (o) {
    case AppLanguageOption.system:
      return null;
    case AppLanguageOption.en:
      return const Locale('en');
    case AppLanguageOption.ja:
      return const Locale('ja');
    case AppLanguageOption.zhHans:
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    case AppLanguageOption.zhHant:
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
}

/// 持久化键 [prefsKey]；与 [AppThemeModeProvider] 类似供设置页与 [MaterialApp] 使用。
class AppLocaleProvider extends ChangeNotifier {
  static const String prefsKey = 'app_language_option';

  AppLocaleProvider() {
    _load();
  }

  AppLanguageOption _option = AppLanguageOption.system;

  AppLanguageOption get option => _option;

  /// [MaterialApp] 使用：`locale` 为 null 表示由系统决定。
  Locale? get resolvedLocale => resolveLocaleForOption(_option);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    final fromStorage = _optionFromName(raw) ?? AppLanguageOption.system;
    _option = fromStorage;
    notifyListeners();
  }

  /// SharedPreferences 被外部写入（如云端恢复界面语言）后刷新。
  Future<void> reloadFromStorage() async {
    await _load();
  }

  Future<void> setOption(AppLanguageOption value) async {
    if (value == _option) {
      return;
    }
    _option = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, _optionStorageName(value));
  }
}
