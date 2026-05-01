import 'package:flutter/material.dart';

/// 自定义壁纸模式下，由 [ThemeConfigProvider] 注入的「读得清」前景色（主字 / 次级字）。
///
/// 非壁纸页不挂此 [InheritedWidget]；[GradOnThemedBackground] 回退为按 [Theme] 亮暗取色。
class WallpaperReadableScope extends InheritedWidget {
  const WallpaperReadableScope({
    super.key,
    required this.foreground,
    required this.foregroundMuted,
    required super.child,
  });

  final Color foreground;
  final Color foregroundMuted;

  static WallpaperReadableScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WallpaperReadableScope>();
  }

  @override
  bool updateShouldNotify(WallpaperReadableScope oldWidget) {
    return foreground != oldWidget.foreground ||
        foregroundMuted != oldWidget.foregroundMuted;
  }
}
