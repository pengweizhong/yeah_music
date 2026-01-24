import 'package:flutter/material.dart';

/// 白天模式主题配置（Light Theme）
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  // 明确白天模式

  // 设置颜色方案
  colorScheme: ColorScheme.light(
    /// 主色调：AppBar、按钮等
    primary: Colors.blue.shade700,

    /// 前景色：文字、图标
    onSurface: Colors.grey.shade900,
    // 在 surface 上显示的文字/图标

    /// 组件表面背景色：Scaffold、Card、Dialog
    surface: Colors.grey.shade50,
    // 白色偏灰，更柔和

    /// 次要颜色：辅助元素、按钮、强调色
    secondary: Colors.blue.shade200,

    /// 反向主色调：深色区域对比色
    inversePrimary: Colors.blue.shade800,
  ),

  // Scaffold 背景色
  scaffoldBackgroundColor: Colors.grey.shade50,

  // 卡片、Dialog 背景色
  cardColor: Colors.white,

  // 不设置 textTheme，使用系统默认字体

  // 图标颜色
  iconTheme: const IconThemeData(color: Colors.black87),

  // AppBar 主题
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white, // 文字、图标颜色
    elevation: 1,
  ),

  // 按钮主题
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
  ),
);
