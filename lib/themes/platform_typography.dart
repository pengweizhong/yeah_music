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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 桌面端系统 UI 字体（Material 3 默认 Roboto，与 Windows/macOS/Linux 系统观感不一致）。
abstract final class PlatformTypography {
  PlatformTypography._();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Windows：Segoe UI 与系统/Flutter 一致；中文由雅黑回退（比单独用 UI 字面量更稳）。
  static const String windowsFontFamily = 'Segoe UI';
  static const List<String> windowsFontFamilyFallback = [
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Segoe UI Variable',
    'Segoe UI Symbol',
  ];

  static const String macOSFontFamily = '.AppleSystemUIFont';

  static const String linuxFontFamily = 'Cantarell';
  static const List<String> linuxFontFamilyFallback = [
    'Noto Sans CJK SC',
    'Noto Sans',
    'Ubuntu',
  ];

  static TargetPlatform get _typographyPlatform {
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    return TargetPlatform.linux;
  }

  static String? get fontFamily {
    if (!isDesktop) return null;
    if (Platform.isWindows) return windowsFontFamily;
    if (Platform.isMacOS) return macOSFontFamily;
    if (Platform.isLinux) return linuxFontFamily;
    return null;
  }

  static List<String>? get fontFamilyFallback {
    if (!isDesktop) return null;
    if (Platform.isWindows) return windowsFontFamilyFallback;
    if (Platform.isLinux) return linuxFontFamilyFallback;
    return null;
  }

  /// 在已有 [TextStyle] 上合并平台字体（勿以 [Theme.textTheme] 为基底，易带入 Roboto）。
  static TextStyle merge(TextStyle style) {
    final family = fontFamily;
    if (family == null) return style;
    return style.copyWith(
      fontFamily: family,
      fontFamilyFallback: fontFamilyFallback,
    );
  }

  static TextStyle bodyBaseFrom(ThemeData theme) {
    return merge(theme.textTheme.bodyMedium ?? const TextStyle());
  }

  static bool get preferSharpDesktopMetrics => isDesktop && Platform.isWindows;

  static FontWeight get listTitleWeight =>
      preferSharpDesktopMetrics ? FontWeight.w400 : FontWeight.w500;

  static FontWeight get listTitleCurrentWeight =>
      preferSharpDesktopMetrics ? FontWeight.w600 : FontWeight.w700;

  static FontWeight get appBarTitleWeight =>
      preferSharpDesktopMetrics ? FontWeight.w600 : FontWeight.w700;

  static double get listLineHeight => preferSharpDesktopMetrics ? 1.22 : 1.3;

  static double get subtitleLineHeight =>
      preferSharpDesktopMetrics ? 1.18 : 1.25;

  static TextStyle gradListTitle(
    BuildContext context, {
    required Color color,
    double fontSize = 16,
    FontWeight? fontWeight,
  }) {
    return merge(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight ?? listTitleWeight,
        height: listLineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  static TextStyle gradListSubtitle(
    BuildContext context, {
    required Color color,
    double fontSize = 13,
  }) {
    return merge(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: subtitleLineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  static TextStyle gradAppBarTitle(
    BuildContext context, {
    required Color color,
    double fontSize = 20,
  }) {
    return merge(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: appBarTitleWeight,
        height: 1.2,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  static TextStyle lyricLine({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double height = 1.35,
    double letterSpacing = 0.2,
  }) {
    return merge(
      TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight:
            fontWeight ??
            (preferSharpDesktopMetrics ? FontWeight.w400 : FontWeight.w500),
        height: height,
        letterSpacing: letterSpacing,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  static TextStyle? _patchStyle(TextStyle? style) {
    if (style == null) return null;
    return merge(style);
  }

  static TextTheme patchTextTheme(TextTheme theme) {
    if (!isDesktop) return theme;
    return TextTheme(
      displayLarge: _patchStyle(theme.displayLarge),
      displayMedium: _patchStyle(theme.displayMedium),
      displaySmall: _patchStyle(theme.displaySmall),
      headlineLarge: _patchStyle(theme.headlineLarge),
      headlineMedium: _patchStyle(theme.headlineMedium),
      headlineSmall: _patchStyle(theme.headlineSmall),
      titleLarge: _patchStyle(theme.titleLarge),
      titleMedium: _patchStyle(theme.titleMedium),
      titleSmall: _patchStyle(theme.titleSmall),
      labelLarge: _patchStyle(theme.labelLarge),
      labelMedium: _patchStyle(theme.labelMedium),
      labelSmall: _patchStyle(theme.labelSmall),
      bodyLarge: _patchStyle(theme.bodyLarge),
      bodyMedium: _patchStyle(theme.bodyMedium),
      bodySmall: _patchStyle(theme.bodySmall),
    );
  }

  /// Material 2021 平台档位（已带系统 fontFamily）。
  static TextTheme textThemeForBrightness(Brightness brightness) {
    final root = Typography.material2021(platform: _typographyPlatform);
    final base = brightness == Brightness.dark ? root.white : root.black;
    return patchTextTheme(
      base.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
    );
  }

  static TextStyle? _mergeStyleKeepPlatformFont(
    TextStyle? platform,
    TextStyle? app,
  ) {
    final p = merge(platform ?? const TextStyle());
    if (app == null) return p;
    return merge(app).copyWith(
      fontFamily: p.fontFamily,
      fontFamilyFallback: p.fontFamilyFallback,
    );
  }

  /// 保留应用主题的字号/字重/颜色，但强制平台 fontFamily。
  static TextTheme mergeTextThemePreferPlatformFont(
    TextTheme platform,
    TextTheme app,
  ) {
    return TextTheme(
      displayLarge: _mergeStyleKeepPlatformFont(
        platform.displayLarge,
        app.displayLarge,
      ),
      displayMedium: _mergeStyleKeepPlatformFont(
        platform.displayMedium,
        app.displayMedium,
      ),
      displaySmall: _mergeStyleKeepPlatformFont(
        platform.displaySmall,
        app.displaySmall,
      ),
      headlineLarge: _mergeStyleKeepPlatformFont(
        platform.headlineLarge,
        app.headlineLarge,
      ),
      headlineMedium: _mergeStyleKeepPlatformFont(
        platform.headlineMedium,
        app.headlineMedium,
      ),
      headlineSmall: _mergeStyleKeepPlatformFont(
        platform.headlineSmall,
        app.headlineSmall,
      ),
      titleLarge: _mergeStyleKeepPlatformFont(
        platform.titleLarge,
        app.titleLarge,
      ),
      titleMedium: _mergeStyleKeepPlatformFont(
        platform.titleMedium,
        app.titleMedium,
      ),
      titleSmall: _mergeStyleKeepPlatformFont(
        platform.titleSmall,
        app.titleSmall,
      ),
      labelLarge: _mergeStyleKeepPlatformFont(
        platform.labelLarge,
        app.labelLarge,
      ),
      labelMedium: _mergeStyleKeepPlatformFont(
        platform.labelMedium,
        app.labelMedium,
      ),
      labelSmall: _mergeStyleKeepPlatformFont(
        platform.labelSmall,
        app.labelSmall,
      ),
      bodyLarge: _mergeStyleKeepPlatformFont(platform.bodyLarge, app.bodyLarge),
      bodyMedium: _mergeStyleKeepPlatformFont(
        platform.bodyMedium,
        app.bodyMedium,
      ),
      bodySmall: _mergeStyleKeepPlatformFont(platform.bodySmall, app.bodySmall),
    );
  }

  static Typography _platformTypography() {
    final root = Typography.material2021(platform: _typographyPlatform);
    final applyTo = (TextTheme t) => patchTextTheme(
      t.apply(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
    );
    return Typography.material2021(
      platform: _typographyPlatform,
      black: applyTo(root.black),
      white: applyTo(root.white),
      englishLike: applyTo(root.englishLike),
      dense: applyTo(root.dense),
      tall: applyTo(root.tall),
    );
  }

  /// 让 [TextButton] / [FilledButton] / [OutlinedButton] 等使用已合并平台字体的 [labelLarge]。
  static ThemeData patchButtonThemes(ThemeData theme) {
    final label = merge(
      theme.textTheme.labelLarge ??
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );

    ButtonStyle withLabel(ButtonStyle? base) {
      final patch = ButtonStyle(textStyle: WidgetStatePropertyAll(label));
      if (base == null) return patch;
      return base.merge(patch);
    }

    return theme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: withLabel(theme.textButtonTheme.style),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: withLabel(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: withLabel(theme.outlinedButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: withLabel(theme.elevatedButtonTheme.style),
      ),
      dropdownMenuTheme: theme.dropdownMenuTheme.copyWith(
        textStyle: merge(
          theme.dropdownMenuTheme.textStyle ??
              theme.textTheme.bodyLarge ??
              const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData apply(ThemeData theme) {
    final family = fontFamily;
    if (family == null) return theme;

    final typography = _platformTypography();
    final platformText = textThemeForBrightness(theme.brightness);
    final mergedText = patchTextTheme(
      mergeTextThemePreferPlatformFont(platformText, theme.textTheme),
    );
    final mergedPrimary = patchTextTheme(
      mergeTextThemePreferPlatformFont(platformText, theme.primaryTextTheme),
    );

    TextStyle? withFont(TextStyle? s) => s == null ? null : merge(s);

    final defaultTitle = mergedText.titleLarge;
    final defaultToolbar = mergedText.bodyLarge;

    return patchButtonThemes(
      theme.copyWith(
      typography: typography,
      textTheme: mergedText,
      primaryTextTheme: mergedPrimary,
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            withFont(theme.appBarTheme.titleTextStyle) ?? defaultTitle,
        toolbarTextStyle:
            withFont(theme.appBarTheme.toolbarTextStyle) ?? defaultToolbar,
      ),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        selectedLabelStyle: withFont(
          theme.bottomNavigationBarTheme.selectedLabelStyle,
        ),
        unselectedLabelStyle: withFont(
          theme.bottomNavigationBarTheme.unselectedLabelStyle,
        ),
      ),
      navigationBarTheme: theme.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStatePropertyAll(
          withFont(mergedText.labelMedium) ?? mergedText.labelMedium,
        ),
      ),
      tabBarTheme: theme.tabBarTheme.copyWith(
        labelStyle:
            withFont(theme.tabBarTheme.labelStyle) ?? mergedText.labelLarge,
        unselectedLabelStyle:
            withFont(theme.tabBarTheme.unselectedLabelStyle) ??
            mergedText.labelMedium,
      ),
      dialogTheme: theme.dialogTheme.copyWith(
        titleTextStyle: withFont(theme.dialogTheme.titleTextStyle),
        contentTextStyle: withFont(theme.dialogTheme.contentTextStyle),
      ),
      listTileTheme: theme.listTileTheme.copyWith(
        titleTextStyle:
            withFont(theme.listTileTheme.titleTextStyle) ??
            mergedText.titleMedium,
        subtitleTextStyle:
            withFont(theme.listTileTheme.subtitleTextStyle) ??
            mergedText.bodySmall,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: withFont(theme.inputDecorationTheme.hintStyle),
        labelStyle: withFont(theme.inputDecorationTheme.labelStyle),
        helperStyle: withFont(theme.inputDecorationTheme.helperStyle),
        errorStyle: withFont(theme.inputDecorationTheme.errorStyle),
      ),
      ),
    );
  }

  /// 首页 / 渐变页：局部 [Theme] + [DefaultTextStyle]，保证子树全部走系统字体。
  static Widget desktopFontScope({
    required BuildContext context,
    required Widget child,
    Color? defaultColor,
    double defaultFontSize = 14,
  }) {
    if (!isDesktop) return child;
    final color = defaultColor ?? Theme.of(context).colorScheme.onSurface;
    final baseStyle = merge(
      TextStyle(
        color: color,
        fontSize: defaultFontSize,
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
    );
    return DefaultTextStyle(style: baseStyle, child: child);
  }
}

extension PlatformTextStyleMerge on TextStyle {
  TextStyle get withPlatformFont => PlatformTypography.merge(this);
}
