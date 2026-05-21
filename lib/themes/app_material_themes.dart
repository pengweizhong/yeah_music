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
import 'package:yeah_music/widgets/app_splash_chrome.dart';

const PageTransitionsTheme _kPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

/// 日间浅色底板（与自定义渐变主页协调），略提亮减轻与墨字之间的「发闷」感。
const Color _kLightScaffoldTone = Color(0xFFE8EDF5);

abstract final class AppMaterialThemes {
  static ThemeData get light {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D4A7C),
      brightness: Brightness.light,
    );
    final scheme = baseScheme.copyWith(
      surface: const Color(0xFFF8FAFC),
      onSurface: kGradLightInk,
      onSurfaceVariant: kGradLightInkMuted,
      surfaceContainerHighest: const Color(0xFFEEF1F6),
      outline: kGradLightInk.withValues(alpha: 0.28),
      outlineVariant: kGradLightInk.withValues(alpha: 0.18),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    );
    final theme = base.copyWith(
      scaffoldBackgroundColor: _kLightScaffoldTone,
      canvasColor: _kLightScaffoldTone,
      cardColor: const Color(0xFFFFFFFF),
      pageTransitionsTheme: _kPageTransitions,
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: kGradLightInk.withValues(alpha: 0.13),
      ),
      scrollbarTheme: const ScrollbarThemeData(interactive: true),
    );
    return PlatformTypography.apply(theme);
  }

  static ThemeData get dark {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E1E24),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppSplashChrome.gradientColors[1],
      canvasColor: AppSplashChrome.gradientColors[1],
      cardColor: const Color(0xFF0A0E14),
      pageTransitionsTheme: _kPageTransitions,
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1D24),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(interactive: true),
    );
    return PlatformTypography.apply(theme);
  }
}
