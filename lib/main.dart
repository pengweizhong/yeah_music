import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/config/app_product_info.dart';
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
import 'compments/onedrive_download_queue_controller.dart';
import 'navigation/app_route_observer.dart';
import 'compments/play_list_provider.dart';
import 'compments/playback_shortcut_controller.dart';
import 'compments/theme_config_provider.dart';
import 'compments/user_playlist_provider.dart';
import 'package:yeah_music/desktop_lyrics/desktop_lyrics_sub_window_app.dart';
import 'package:yeah_music/widgets/desktop_floating_lyrics_host.dart';
import 'package:yeah_music/widgets/desktop_playback_shortcuts_listener.dart';
import 'package:yeah_music/widgets/macos_menu_bar_lyrics_host.dart';
import 'package:yeah_music/services/android_media_session_bridge.dart';
import 'package:yeah_music/services/wire_remote_gesture_handler.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppProductInfo.load();

  if (!kIsWeb && Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.pengwz.yeah_music.channel.audio',
      androidNotificationChannelName: AppProductInfo.displayName,
      androidNotificationOngoing: true,
      preloadArtwork: true,
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
      notificationColor: const Color(0xFF1E1E2E),
      onAndroidLyricsSyncToggle:
          AndroidMediaSessionBridge.toggleLyricsSyncFromNotification,
    );
  }

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    try {
      final wc = await WindowController.fromCurrentEngine();
      if (wc.arguments.isNotEmpty) {
        final dynamic j = jsonDecode(wc.arguments);
        if (j is Map && j['role'] == 'desktop_lyrics') {
          await runDesktopLyricsSubWindow();
          return;
        }
      }
    } catch (_) {}
  }

  appLog.i('应用正在启动');

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
        ChangeNotifierProvider(
          create: (context) {
            final od = context.read<OneDriveController>();
            final pl = context.read<PlayListProvider>();
            final q = OneDriveDownloadQueueController(
              oneDrive: od,
              playListRef: pl,
            );
            unawaited(q.restorePersistedTasks());
            return q;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeConfigProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final c = PlaybackShortcutController();
            unawaited(c.loadFromStorage());
            return c;
          },
        ),
      ],
      child: const YeahMusicApp(),
    );
  }
}

class YeahMusicApp extends StatefulWidget {
  const YeahMusicApp({super.key});

  @override
  State<YeahMusicApp> createState() => _YeahMusicAppState();
}

class _YeahMusicAppState extends State<YeahMusicApp>
    with WidgetsBindingObserver {
  static bool _androidWireRemoteInited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // macOS 浏览器 OAuth 回跳后，偶发需等 resumed 再读 token，界面才与登录态一致。
    if (kIsWeb || !Platform.isMacOS) return;
    final od = context.read<OneDriveController>();
    unawaited(od.loadFromStorage());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppThemeModeProvider, AppLocaleProvider>(
      builder: (context, appearance, locale, _) {
        if (!_androidWireRemoteInited && !kIsWeb && Platform.isAndroid) {
          _androidWireRemoteInited = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WireRemoteGestureHandler.ensureInitialized();
            final shortcuts = Provider.of<PlaybackShortcutController>(
              context,
              listen: false,
            );
            unawaited(
              WireRemoteGestureHandler.syncNativeFromController(shortcuts),
            );
          });
        }
        return MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          navigatorObservers: <NavigatorObserver>[appRouteObserver],
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale.resolvedLocale,
          builder: (context, child) {
            return DesktopPlaybackShortcutsListener(
              controller: context.read<PlaybackShortcutController>(),
              child: DesktopFloatingLyricsHost(
                child: MacosMenuBarLyricsHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
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

