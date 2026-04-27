import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题配置提供者
class ThemeConfigProvider extends ChangeNotifier {
  // 主题类型
  ThemeType _themeType = ThemeType.solidColor;
  Color _primaryColor = const Color(0xFF121212);
  Color _secondaryColor = const Color(0xFF1A1A1A);
  String? _backgroundImagePath;

  ThemeType get themeType => _themeType;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  String? get backgroundImagePath => _backgroundImagePath;

  // 预设颜色
  static const List<Color> presetColors = [
    Color(0xFF121212), // 纯黑
    Color(0xFF1A1A2E), // 深蓝
    Color(0xFF16213E), // 海军蓝
    Color(0xFF0F3460), // 深青
    Color(0xFF1F1F1F), // 深灰
    Color(0xFF2C1810), // 深棕
    Color(0xFF1A1520), // 深紫
    Color(0xFF0D1B2A), // 深蓝黑
  ];

  ThemeConfigProvider() {
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载主题类型
    final typeIndex = prefs.getInt('theme_type') ?? 0;
    _themeType = ThemeType.values[typeIndex];
    
    // 加载颜色
    final primaryColorValue = prefs.getInt('primary_color') ?? 0xFF121212;
    _primaryColor = Color(primaryColorValue);
    
    final secondaryColorValue = prefs.getInt('secondary_color') ?? 0xFF1A1A1A;
    _secondaryColor = Color(secondaryColorValue);
    
    // 加载背景图片路径
    _backgroundImagePath = prefs.getString('background_image_path');
    
    notifyListeners();
  }

  /// 设置主题类型
  Future<void> setThemeType(ThemeType type) async {
    _themeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type', type.index);
    notifyListeners();
  }

  /// 设置主色调
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.value);
    notifyListeners();
  }

  /// 设置次色调
  Future<void> setSecondaryColor(Color color) async {
    _secondaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondary_color', color.value);
    notifyListeners();
  }

  /// 设置背景图片
  Future<void> setBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('background_image_path', path);
    } else {
      await prefs.remove('background_image_path');
    }
    notifyListeners();
  }

  /// 获取背景渐变色列表
  List<Color> getGradientColors() {
    return [
      _primaryColor,
      _secondaryColor,
      _primaryColor.withOpacity(0.8),
      _secondaryColor.withOpacity(0.6),
    ];
  }

  /// 获取背景装饰
  BoxDecoration getBackgroundDecoration() {
    switch (_themeType) {
      case ThemeType.solidColor:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: getGradientColors(),
          ),
        );
      case ThemeType.customColor:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: getGradientColors(),
          ),
        );
      case ThemeType.backgroundImage:
        if (_backgroundImagePath != null && File(_backgroundImagePath!).existsSync()) {
          return BoxDecoration(
            image: DecorationImage(
              image: FileImage(File(_backgroundImagePath!)),
              fit: BoxFit.cover,
            ),
          );
        }
        // 如果图片不存在，回退到纯色
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: getGradientColors(),
          ),
        );
    }
  }
}

/// 主题类型枚举
enum ThemeType {
  solidColor,      // 纯色
  customColor,     // 自定义颜色
  backgroundImage, // 背景图片
}








