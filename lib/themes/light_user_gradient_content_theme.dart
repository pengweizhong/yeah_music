// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:flutter/material.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/themes/platform_typography.dart';

/// 渐变 / 壁纸 / 毛玻璃面板上的局部 [Theme]：以平台 [TextTheme] 为基底，避免 Roboto 渗入。
ThemeData themeForGradientForeground(
  BuildContext context, {
  required Color onSurface,
  required Color onSurfaceVariant,
}) {
  final t = Theme.of(context);
  final platformBase = PlatformTypography.textThemeForBrightness(t.brightness);
  final merged = PlatformTypography.mergeTextThemePreferPlatformFont(
    platformBase,
    t.textTheme,
  );
  final textTheme = PlatformTypography.patchTextTheme(
    merged.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
      decorationColor: onSurface,
    ),
  );
  final primaryMerged = PlatformTypography.mergeTextThemePreferPlatformFont(
    platformBase,
    t.primaryTextTheme,
  );
  final primaryTextTheme = PlatformTypography.patchTextTheme(
    primaryMerged.apply(bodyColor: onSurface, displayColor: onSurface),
  );
  final titleMedium = textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  final bodySmall = textTheme.bodySmall ?? const TextStyle(fontSize: 13);
  final titleLarge = textTheme.titleLarge ?? const TextStyle(fontSize: 20);
  return PlatformTypography.patchButtonThemes(
    t.copyWith(
      colorScheme: t.colorScheme.copyWith(
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      iconTheme: t.iconTheme.copyWith(color: onSurface),
      listTileTheme: t.listTileTheme.copyWith(
        iconColor: onSurface,
        textColor: onSurface,
        titleTextStyle: PlatformTypography.merge(
          titleMedium.copyWith(color: onSurface),
        ),
        subtitleTextStyle: PlatformTypography.merge(
          bodySmall.copyWith(color: onSurfaceVariant),
        ),
      ),
      appBarTheme: t.appBarTheme.copyWith(
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: PlatformTypography.merge(
          titleLarge.copyWith(color: onSurface),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.18),
        thickness: 1,
        space: 1,
      ),
      switchTheme: gradOnBackgroundSwitchTheme(context),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            const Color(0xE02C2C2C),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: PlatformTypography.merge(
          (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
            color: onSurface,
          ),
        ),
      ),
      dialogTheme: t.dialogTheme.copyWith(
        titleTextStyle: PlatformTypography.merge(
          titleLarge.copyWith(color: onSurface),
        ),
        contentTextStyle: PlatformTypography.merge(
          (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: t.inputDecorationTheme.copyWith(
        hintStyle: PlatformTypography.merge(
          TextStyle(color: onSurfaceVariant.withValues(alpha: 0.85)),
        ),
        labelStyle: PlatformTypography.merge(TextStyle(color: onSurface)),
      ),
    ),
  );
}

ThemeData themeForFrostedDeepChrome(BuildContext context) {
  return themeForGradientForeground(
    context,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white.withValues(alpha: 0.72),
  );
}

ThemeData themeForLightUserGradientShell(BuildContext context) {
  return themeForGradientForeground(
    context,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white.withValues(alpha: 0.72),
  );
}

ThemeData themeForBrightLightGradientOverlay(BuildContext context) {
  return themeForGradientForeground(
    context,
    onSurface: kGradLightInk,
    onSurfaceVariant: kGradLightInkMuted.withValues(alpha: 0.88),
  );
}
