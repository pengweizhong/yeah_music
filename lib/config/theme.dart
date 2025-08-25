import 'package:flutter/material.dart';

/// 全局主题配置
class AppTheme {
  static ThemeData get lightTheme =>
      ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey);
}
