import 'package:flutter/material.dart';

/// 白昼渐变底上的主字色（对齐 [AppMaterialThemes.light].colorScheme.onSurface）。
/// 偏冷的近黑墨，略高于夜间白字的「感知对比」需求（浅灰底易发灰晕）。
const Color kGradLightInk = Color(0xFF050A12);

/// 次一级说明、辅助图标（比早期 #2B3441 更深，避免在 scaffold 灰底上发虚）
const Color kGradLightInkMuted = Color(0xFF192433);

/// 与 [MaterialApp] 全局 [ThemeMode] 联动：全屏自定义渐变/背景图上的前景与边框色。
extension GradOnThemedBackground on BuildContext {
  /// 主文字/图标（白天：深蓝墨）
  Color gradFg([double a = 1.0]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInk.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: a);
  }

  /// 次一级说明文字（白天默认全不透明；夜间为高亮白半透明）
  Color gradFgMuted([double a = 1.0]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInkMuted.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: 0.65);
  }

  /// 细边框/分割线/低调装饰
  Color gradBorder([double a = 0.12]) {
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInk.withValues(alpha: (a * 1.72).clamp(0.0, 1.0));
    }
    return Colors.white.withValues(alpha: a);
  }
}

/// 毛玻璃区域填充：白天用近实地浅板（提高与页面渐变的分界与字对比）；夜间保持半透明。
enum FrostedSurfaceKind { drawerOrPinned, bottomBar, sheet, dialog }

abstract final class FrostedPalette {
  static Color fill(BuildContext context, FrostedSurfaceKind kind) {
    if (Theme.of(context).brightness != Brightness.light) {
      return const Color(0x33FFFFFF);
    }
    switch (kind) {
      case FrostedSurfaceKind.bottomBar:
        return const Color(0xEE28323D);
      case FrostedSurfaceKind.drawerOrPinned:
        return const Color(0xF2F5F8FC);
      case FrostedSurfaceKind.sheet:
        return const Color(0xFBF8FAFC);
      case FrostedSurfaceKind.dialog:
        return const Color(0xFFF8FAFC);
    }
  }

  /// 毛玻璃与页面分界描边（日间略加深）
  static Color edgeLine(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return kGradLightInk.withValues(alpha: 0.18);
    }
    return Colors.white.withValues(alpha: 0.2);
  }
}
