import 'package:flutter/material.dart';

/// 浅色全局 [Theme] + **非壁纸** 的用户双色渐变背景（预设/自定）时使用。
///
/// [gradFg]/[DefaultTextStyle] 走白字链路与夜间渐变顶上一致；与浅灰实心 Material 页（墨色字）区分开。
///
/// **不**盖住壁纸分支（壁纸由 [WallpaperReadableScope] 决定）。
class UserThemeGradientForegroundScope extends InheritedWidget {
  const UserThemeGradientForegroundScope({
    super.key,
    required super.child,
  });

  static UserThemeGradientForegroundScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserThemeGradientForegroundScope>();
  }

  @override
  bool updateShouldNotify(UserThemeGradientForegroundScope oldWidget) =>
      false;
}
