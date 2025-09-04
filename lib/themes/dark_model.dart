import 'package:flutter/material.dart';

/// 定义全局主题配置
ThemeData darkTheme = ThemeData(
  // 设置颜色方案
  colorScheme: ColorScheme.dark(
    /// 主色调（应用的核心颜色，比如 AppBar、按钮）
    primary: Colors.grey.shade600,

    /// 主要用于文本、图标、分隔线等绘制在表面上的颜色
    /// 一般应用在背景或卡片表面上方的文字/图标
    /// 要保证对比度足够高（建议至少 4.5:1），保证可读性和无障碍可以是黑色、白色或高对比度颜色
    onSurface: Colors.grey.shade900,
    ///作为组件表面的背景色
    ///使用场景：Scaffold、Card、Dialog、BottomSheet 等组件的背景
    ///通常是主背景色之外的“层级背景色”，不影响主背景，但用于分隔内容
    ///白天模式：浅灰或白色
    ///夜间模式：深灰或黑色
    surface: Colors.grey.shade800,

    /// 次要颜色（辅助色，一般用于按钮、悬浮按钮、强调元素）
    secondary: Color.from(alpha: 255, red: 50, green: 50, blue: 50),

    /// 反向主色调（用于深色区域的对比色，例如状态栏、底部导航栏）
    inversePrimary: Colors.grey.shade300,
  ),
  scaffoldBackgroundColor: Colors.grey.shade800,
  // 页面整体背景
  cardColor: Colors.grey.shade700,
  // 对话框背景
  iconTheme: const IconThemeData(color: Colors.grey),
  // 图标颜色
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.grey), // 正文文字
  ),
);
