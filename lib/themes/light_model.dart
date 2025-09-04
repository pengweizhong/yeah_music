import 'package:flutter/material.dart';

/// 定义全局主题配置
ThemeData lightTheme = ThemeData(
  // 设置颜色方案（浅色主题）
  colorScheme: ColorScheme.light(
    /// 主色调（应用的核心颜色，比如 AppBar、按钮）
    primary: Colors.grey.shade500,

    /// 主要用于文本、图标、分隔线等绘制在表面上的颜色
    /// 一般应用在背景或卡片表面上方的文字/图标
    onSurface: Colors.grey.shade300,

    /// 次要颜色（辅助色，一般用于按钮、悬浮按钮、强调元素）
    secondary: Colors.grey.shade200,

    /// 反向主色调（用于深色区域的对比色，例如状态栏、底部导航栏）
    inversePrimary: Colors.grey.shade900,
  ),
);
