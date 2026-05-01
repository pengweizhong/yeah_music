import 'package:flutter/material.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

/// 浅色全局 [Theme] +「用户双色渐变 / 回落渐变」（非壁纸）全页外壳上的局部 [Theme]，与夜间渐变页的观感对齐。
///
/// 解决：仅用 [DefaultTextStyle] 仍会漏掉 [ListTile] / [ExpansionTile] 等合并 [Theme.textTheme] 墨色的问题。
ThemeData themeForLightUserGradientShell(BuildContext context) {
  final t = Theme.of(context);
  const on = Colors.white;
  final muted = Colors.white.withValues(alpha: 0.6);
  final scheme = t.colorScheme.copyWith(
    onSurface: on,
    onSurfaceVariant: muted,
    outline: Colors.white.withValues(alpha: 0.28),
    outlineVariant: Colors.white.withValues(alpha: 0.18),
  );
  final titleBase = t.listTileTheme.titleTextStyle ??
      TextStyle(
        fontSize: t.textTheme.titleMedium?.fontSize ?? 16,
        fontWeight:
            t.textTheme.titleMedium?.fontWeight ?? FontWeight.w500,
      );
  final subtitleBase = t.listTileTheme.subtitleTextStyle ??
      TextStyle(
        fontSize: 13,
        fontWeight:
            t.textTheme.bodySmall?.fontWeight ?? FontWeight.w400,
      );
  final textThemeApply = t.textTheme.apply(
    bodyColor: on,
    displayColor: on,
    decorationColor: on,
  );
  return t.copyWith(
    colorScheme: scheme,
    textTheme: textThemeApply,
    iconTheme: t.iconTheme.copyWith(color: on),
    listTileTheme: t.listTileTheme.copyWith(
      iconColor: on,
      textColor: on,
      titleTextStyle: titleBase.copyWith(color: on),
      subtitleTextStyle: subtitleBase.copyWith(color: muted),
    ),
    appBarTheme: t.appBarTheme.copyWith(
      foregroundColor: on,
      iconTheme: IconThemeData(color: on),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.18),
      thickness: 1,
      space: 1,
    ),
  );
}

/// 浅色模式 + 双色渐变，但主/辅色整体偏亮时用墨色前景（避免白字与白调渐变糊成一片）。
ThemeData themeForBrightLightGradientOverlay(BuildContext context) {
  final t = Theme.of(context);
  final on = kGradLightInk;
  final muted = kGradLightInkMuted.withValues(alpha: 0.88);
  final scheme = t.colorScheme.copyWith(
    onSurface: on,
    onSurfaceVariant: muted,
    outline: kGradLightInk.withValues(alpha: 0.35),
    outlineVariant: kGradLightInk.withValues(alpha: 0.20),
  );
  final titleBase = t.listTileTheme.titleTextStyle ??
      TextStyle(
        fontSize: t.textTheme.titleMedium?.fontSize ?? 16,
        fontWeight:
            t.textTheme.titleMedium?.fontWeight ?? FontWeight.w500,
      );
  final subtitleBase = t.listTileTheme.subtitleTextStyle ??
      TextStyle(
        fontSize: 13,
        fontWeight:
            t.textTheme.bodySmall?.fontWeight ?? FontWeight.w400,
      );
  final textThemeApply = t.textTheme.apply(
    bodyColor: on,
    displayColor: on,
    decorationColor: on,
  );
  return t.copyWith(
    colorScheme: scheme,
    textTheme: textThemeApply,
    iconTheme: t.iconTheme.copyWith(color: on),
    listTileTheme: t.listTileTheme.copyWith(
      iconColor: on,
      textColor: on,
      titleTextStyle: titleBase.copyWith(color: on),
      subtitleTextStyle: subtitleBase.copyWith(color: muted),
    ),
    appBarTheme: t.appBarTheme.copyWith(
      foregroundColor: on,
      iconTheme: IconThemeData(color: on),
    ),
    dividerTheme: DividerThemeData(
      color: kGradLightInk.withValues(alpha: 0.14),
      thickness: 1,
      space: 1,
    ),
  );
}
