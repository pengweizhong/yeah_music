import 'package:flutter/material.dart';
import 'package:yeah_music/themes/user_theme_gradient_foreground_scope.dart';
import 'package:yeah_music/themes/wallpaper_readable_scope.dart';

/// 白昼渐变底上的主字色（与浅色 [Theme] 正文一致，纯黑以保证对比）。
const Color kGradLightInk = Color(0xFF000000);

/// 次一级说明、辅助图标
const Color kGradLightInkMuted = Color(0xFF424242);

/// 嵌在浅色实色毛玻璃 sheet / dialog 内的子树：优先用当前 [Theme.colorScheme] 墨色，盖住外层亮色渐变强加的白。
class FrostedSheetForegroundScope extends InheritedWidget {
  const FrostedSheetForegroundScope({super.key, required super.child});

  static FrostedSheetForegroundScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FrostedSheetForegroundScope>();
  }

  @override
  bool updateShouldNotify(FrostedSheetForegroundScope oldWidget) => false;
}

/// 抽屉、迷你播放器条等深色实板毛玻璃内侧：与白字链路对齐，独立于外壳「墨色渐变」样式。
class FrostedDeepTintChromeScope extends InheritedWidget {
  const FrostedDeepTintChromeScope({super.key, required super.child});

  static FrostedDeepTintChromeScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FrostedDeepTintChromeScope>();
  }

  @override
  bool updateShouldNotify(FrostedDeepTintChromeScope oldWidget) => false;
}

/// 与 [MaterialApp] 全局 [ThemeMode] 联动：全屏自定义渐变/背景图上的前景与边框色。
extension GradOnThemedBackground on BuildContext {
  /// 主文字/图标
  Color gradFg([double a = 1.0]) {
    if (FrostedDeepTintChromeScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: a);
    }
    if (FrostedSheetForegroundScope.maybeOf(this) != null) {
      final on = Theme.of(this).colorScheme.onSurface;
      return on.withValues(alpha: a);
    }
    final wp = WallpaperReadableScope.maybeOf(this);
    if (wp != null) {
      return wp.foreground.withValues(alpha: a);
    }
    if (UserThemeGradientForegroundScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: a);
    }
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInk.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: a);
  }

  /// 次一级说明文字
  Color gradFgMuted([double a = 1.0]) {
    if (FrostedDeepTintChromeScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: 0.65 * a.clamp(0.0, 1.0));
    }
    if (FrostedSheetForegroundScope.maybeOf(this) != null) {
      final v = Theme.of(this).colorScheme.onSurfaceVariant;
      return v.withValues(alpha: (0.88 * a).clamp(0.0, 1.0));
    }
    final wp = WallpaperReadableScope.maybeOf(this);
    if (wp != null) {
      return wp.foregroundMuted.withValues(alpha: a);
    }
    if (UserThemeGradientForegroundScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: 0.78 * a.clamp(0.0, 1.0));
    }
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInkMuted.withValues(alpha: a);
    }
    return Colors.white.withValues(alpha: 0.65);
  }

  /// 细边框/分割线/低调装饰
  Color gradBorder([double a = 0.12]) {
    if (FrostedDeepTintChromeScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: a);
    }
    if (FrostedSheetForegroundScope.maybeOf(this) != null) {
      final ink = Theme.of(this).colorScheme.onSurface;
      return ink.withValues(alpha: (a * 1.72).clamp(0.0, 1.0));
    }
    final wp = WallpaperReadableScope.maybeOf(this);
    if (wp != null) {
      return wp.foreground.withValues(alpha: (a * 1.72).clamp(0.0, 1.0));
    }
    if (UserThemeGradientForegroundScope.maybeOf(this) != null) {
      return Colors.white.withValues(alpha: a);
    }
    if (Theme.of(this).brightness == Brightness.light) {
      return kGradLightInk.withValues(alpha: (a * 1.72).clamp(0.0, 1.0));
    }
    return Colors.white.withValues(alpha: a);
  }
}

/// 渐变 / 壁纸底上的 [Switch]：避免白天关态拇指与轨道同为白色。
SwitchThemeData gradOnBackgroundSwitchTheme(BuildContext context) {
  final t = Theme.of(context);
  final scheme = t.colorScheme;
  if (t.brightness == Brightness.light) {
    final whiteShell =
        UserThemeGradientForegroundScope.maybeOf(context) != null;
    if (whiteShell) {
      return SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF5C6B7A);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white.withValues(alpha: 0.48);
          }
          return Colors.white.withValues(alpha: 0.26);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return Colors.white.withValues(alpha: 0.42);
        }),
      );
    }
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return const Color(0xFF616161);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary.withValues(alpha: 0.42);
        }
        return kGradLightInk.withValues(alpha: 0.18);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return kGradLightInk.withValues(alpha: 0.30);
      }),
    );
  }
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white.withValues(alpha: 0.95);
      }
      return Colors.white.withValues(alpha: 0.52);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white.withValues(alpha: 0.35);
      }
      return Colors.white.withValues(alpha: 0.16);
    }),
  );
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
        /// 白昼与底栏同色实板：与白字链路一致（避免浅色雾面 + 白字发糊）。
        return const Color(0xEE28323D);
      case FrostedSurfaceKind.sheet:
        return Colors.white;
      case FrostedSurfaceKind.dialog:
        return Colors.white;
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
