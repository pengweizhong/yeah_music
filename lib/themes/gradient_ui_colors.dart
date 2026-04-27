import 'package:flutter/material.dart';

/// 全屏中灰渐变上的主字色（与浅色底区分度足够）
const Color _kLightInk = Color(0xFF0D1117);
const Color _kLightInkMuted = Color(0xFF2D3542);

/// 与 [MaterialApp] 全局 [ThemeMode] 联动：全屏自定义渐变/背景图上的前景与边框色。
extension GradOnThemedBackground on BuildContext {
  /// 主文字/图标（白天：深墨，避免与浅底撞色）
  Color gradFg([double a = 1.0]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return _kLightInk.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: a);
  }

  /// 次一级说明文字（白天略浅但仍可读）
  Color gradFgMuted([double a = 0.75]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return _kLightInkMuted.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: 0.65);
  }

  /// 细边框/分割线/低调装饰
  Color gradBorder([double a = 0.12]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return _kLightInk.withValues(alpha: (a * 1.4).clamp(0.0, 1.0));
    }
    return Colors.white.withValues(alpha: a);
  }
}

/// 毛玻璃区域填充：白天底栏为深色条（配白字），侧栏/吸顶为浅冷灰（配 [gradFg] 深字）。
enum FrostedSurfaceKind { drawerOrPinned, bottomBar, sheet, dialog }

abstract final class FrostedPalette {
  static Color fill(BuildContext context, FrostedSurfaceKind kind) {
    if (Theme.of(context).brightness != Brightness.light) {
      return const Color(0x33FFFFFF);
    }
    switch (kind) {
      case FrostedSurfaceKind.bottomBar:
        return const Color(0xE028323D);
      case FrostedSurfaceKind.drawerOrPinned:
        return const Color(0xB8D0D6E0);
      case FrostedSurfaceKind.sheet:
        return const Color(0xE8E8EEF2);
      case FrostedSurfaceKind.dialog:
        return const Color(0xF0EEF2F4);
    }
  }

  /// 毛玻璃与页面分界描边
  static Color edgeLine(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return _kLightInk.withValues(alpha: 0.14);
    }
    return Colors.white.withValues(alpha: 0.2);
  }
}
