import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/pages/welcome_entry_page.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/themes/app_locale_provider.dart';
import 'package:yeah_music/themes/app_material_themes.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/welcome/app_startup_clock.dart';
import 'package:yeah_music/welcome/pre_hive_startup_view.dart';

import 'app_scaffold_messenger.dart';
import 'compments/folder_provider.dart';
import 'compments/onedrive_controller.dart';
import 'navigation/app_route_observer.dart';
import 'compments/play_list_provider.dart';
import 'compments/theme_config_provider.dart';
import 'compments/user_playlist_provider.dart';
import 'package:yeah_music/widgets/macos_menu_bar_lyrics_host.dart';

void main() {
  appLog.i('应用正在启动');

  WidgetsFlutterBinding.ensureInitialized();
  AppStartupClock.ensureStarted();
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 80);
  PaintingBinding.instance.imageCache
    ..maximumSize = 500
    ..maximumSizeBytes = 200 << 20;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050608),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeModeProvider()),
        ChangeNotifierProvider(create: (_) => AppLocaleProvider()),
      ],
      child: const AppStartupGate(),
    ),
  );
}

/// 先尽快出首帧（渐变/进度），再异步完成 Hive 后再挂载 [MultiProvider] + 主应用，避免冷启动长时间纯黑屏。
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate>
    with SingleTickerProviderStateMixin {
  Object? _error;
  bool _ready = false;

  AnimationController? _glow;

  void _initPreHiveVisuals() {
    _glow?.dispose();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void initState() {
    super.initState();
    _initPreHiveVisuals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  void _teardownPreHiveOnly() {
    _glow?.dispose();
    _glow = null;
  }

  void _disposePreHiveResources() {
    _teardownPreHiveOnly();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _error = null;
    });
  }

  void _onHiveInitError(Object e) {
    _teardownPreHiveOnly();
    if (mounted) setState(() => _error = e);
  }

  Future<void> _bootstrap() async {
    final appInit = AppInit();
    appInit.initJustAudioKit();
    try {
      await appInit.initHive();
    } catch (e, st) {
      appLog.e('initHive 失败', error: e, stackTrace: st);
      _onHiveInitError(e);
      return;
    }
    if (!mounted) return;
    _disposePreHiveResources();
    appLog.i('应用启动成功');
  }

  void _retry() {
    AppStartupClock.reset();
    _teardownPreHiveOnly();
    _initPreHiveVisuals();
    if (mounted) {
      setState(() {
        _error = null;
        _ready = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Consumer2<AppThemeModeProvider, AppLocaleProvider>(
        builder: (context, themeMode, locale, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale.resolvedLocale,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0E14),
            ),
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.startupFailed('$_error'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _retry,
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
    if (!_ready) {
      return Consumer2<AppThemeModeProvider, AppLocaleProvider>(
        builder: (context, themeMode, locale, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale.resolvedLocale,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0E14),
            ),
            home: PreHiveStartupView(
              glow: _glow!,
            ),
          );
        },
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayListProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final p = UserPlaylistProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => FolderProvider()..init()),
        ChangeNotifierProvider(
          create: (_) {
            final c = OneDriveController();
            c.loadFromStorage();
            return c;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeConfigProvider()),
      ],
      child: const YeahMusicApp(),
    );
  }
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppThemeModeProvider, AppLocaleProvider>(
      builder: (context, appearance, locale, _) {
        return MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          navigatorObservers: <NavigatorObserver>[appRouteObserver],
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale.resolvedLocale,
          builder: (context, child) {
            return MacosMenuBarLyricsHost(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const WelcomeEntryPage(),
          theme: AppMaterialThemes.light,
          darkTheme: AppMaterialThemes.dark,
          themeMode: appearance.themeMode,
        );
      },
    );
  }
}

