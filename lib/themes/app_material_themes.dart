import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

const PageTransitionsTheme _kPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

/// [MaterialApp] 的 [ThemeData]：与启动渐变深色页协调的 [dark]、浅色日间的 [light]。
abstract final class AppMaterialThemes {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D4A7C),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFC5CED9),
      canvasColor: const Color(0xFFC5CED9),
      cardColor: const Color(0xFFE0E4EA),
      pageTransitionsTheme: _kPageTransitions,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(interactive: true),
    );
  }

  static ThemeData get dark {
    return ThemeData(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(interactive: true),
    );
  }
}
