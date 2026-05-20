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

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/config/app_product_info.dart';
import 'package:yeah_music/logging/diagnostic_log_store.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/platform/open_with_bridge.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/themes/app_locale_provider.dart';
import 'package:yeah_music/themes/app_material_themes.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/welcome/app_startup_clock.dart';
import 'package:yeah_music/welcome/startup_hive_loading_splash.dart';
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
import 'package:yeah_music/utils/android_notification_permission.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/widgets/desktop_playback_shortcuts_listener.dart';
import 'package:yeah_music/widgets/linux_taskbar_progress_host.dart';
import 'package:yeah_music/widgets/linux_tray_host.dart';
import 'package:yeah_music/widgets/macos_menu_bar_lyrics_host.dart';
import 'package:yeah_music/services/android_media_session_bridge.dart';
import 'package:yeah_music/services/android_media_session_lyrics_channel.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/wire_remote_gesture_handler.dart';
import 'package:yeah_music/platform/wire_remote_native.dart';
import 'package:yeah_music/utils/app_ephemeral_storage.dart';
import 'package:yeah_music/utils/file_utils.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppProductInfo.load();

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
  VisibilityDetectorController.instance.updateInterval = const Duration(
    milliseconds: 166,
  );
  PaintingBinding.instance.imageCache
    ..maximumSize = 500
    ..maximumSizeBytes = 200 << 20;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050608),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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

/// Hive 就绪前先展示 [StartupHiveLoadingSplash]（可换 GIF），再挂载 [MultiProvider] + 主应用。
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  void _disposePreHiveResources() {
    if (!mounted) return;
    setState(() {
      _ready = true;
      _error = null;
    });
  }

  void _onHiveInitError(Object e) {
    if (mounted) setState(() => _error = e);
  }

  Future<void> _initAndroidPlaybackBackground() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.pengwz.yeah_music.channel.audio',
      androidNotificationChannelName: AppProductInfo.displayName,
      androidNotificationIcon: 'drawable/ic_stat_yeah_music',
      androidNotificationOngoing: true,
      preloadArtwork: true,
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
      notificationColor: const Color(0xFF1E1E2E),
      onAndroidLyricsSyncToggle:
          AndroidMediaSessionBridge.toggleLyricsSyncFromNotification,
    );
    JustAudioBackground.setFadeOutVolumeHandler(
      MusicService.fadeOutVolumeWhilePlaying,
    );
  }

  Future<void> _bootstrap() async {
    final appInit = AppInit();
    appInit.initJustAudioKit();
    try {
      await Future.wait<void>([
        appInit.initHive(),
        _initAndroidPlaybackBackground(),
      ]);
    } catch (e, st) {
      appLog.e('initHive 失败', error: e, stackTrace: st);
      _onHiveInitError(e);
      return;
    }
    if (!mounted) return;
    MusicService.attachListeningTimeTracker();
    MusicService.attachAndroidSoundPresetSessionListener();
    MusicService.attachAndroidNotificationCoverSync();
    unawaited(MusicService.applyStoredPlaybackSpeed());
    if (!kIsWeb && Platform.isAndroid) {
      final carNotify = await SettingsService.loadAndroidCarLyricsEnabled();
      await AndroidMediaSessionLyricsChannel.setCarNotificationEnabled(carNotify);
    }
    _disposePreHiveResources();
    unawaited(AppEphemeralStorage.runStartupMaintenanceIfNeeded());
    appLog.i(
      '应用启动成功（Hive 门控 ${AppStartupClock.formatSeconds2()}s）',
    );
  }

  void _retry() {
    AppStartupClock.reset();
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
            home: const StartupHiveLoadingSplash(),
          );
        },
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayListProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final p = UserPlaylistProvider();
            final pl = context.read<PlayListProvider>();
            p.onPersistedRequestLibraryPlaylistOverlayRefresh = () async {
              if (!pl.initialized) return;
              await pl.refreshUserPlaylistLibraryOverlay(p);
            };
            unawaited(p.init());
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
  static bool _diagnosticPrefsPrimed = false;

  Timer? _oneDriveAutoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _oneDriveAutoSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _kickOneDriveAutoSyncCheck();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickOneDriveAutoSyncCheck();
      _tryConsumeAndroidOpenWith();
    });
  }

  @override
  void dispose() {
    _oneDriveAutoSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _kickOneDriveAutoSyncCheck() {
    unawaited(_maybeRunOneDriveAutoSync());
  }

  Future<void> _tryConsumeAndroidOpenWith() async {
    if (kIsWeb || !Platform.isAndroid) return;
    for (;;) {
      if (!mounted) return;
      final path = await OpenWithBridge.consumePendingPath();
      if (path == null) return;
      if (!mounted) return;
      final folder = context.read<FolderProvider>();
      final play = context.read<PlayListProvider>();
      final od = context.read<OneDriveController>();
      //播放队列
      final userPl = context.read<UserPlaylistProvider>();
      final file = File(path);
      if (!await file.exists()) continue;
      if (!mounted) return;
      try {
        if (!play.initialized) {
          await play.init(folder, oneDrive: od, userPlaylists: userPl);
        }
        if (!mounted) return;
        final song = Song(path);
        await FileUtils.loadSongMeta(song, loadEmbeddedAlbumArt: false);
        if (!mounted) return;
        await play.setPlaybackQueueAndPlay(
          [song],
          0,
          session: PlaybackSessionSurface.adHoc,
        );
      } catch (e, st) {
        appLog.e('打开外部音频失败', error: e, stackTrace: st);
        return;
      }
    }
  }

  Future<void> _maybeRunOneDriveAutoSync() async {
    if (!mounted) return;
    final od = context.read<OneDriveController>();
    final sync = od.syncSettings;
    if (!sync.cloudSyncEnabled) return;
    final interval = oneDriveSyncFrequencyAutoInterval(sync.frequency);
    if (interval == null) return;
    if (!sync.hasConfigurableSlices) return;
    if (!od.signedIn || od.effectiveClientId.isEmpty) return;
    final parent = od.cloudAppDataFolderId?.trim();
    if (parent == null || parent.isEmpty) return;
    if (od.isImmediateSyncBusy || od.isImmediateRestoreBusy) return;

    final last = await SettingsService.loadOneDriveLastConfigSyncAt();
    if (!mounted) return;
    final now = DateTime.now();
    if (last != null && now.difference(last) < interval) return;

    final userPl = context.read<UserPlaylistProvider>();
    if (!userPl.initialized) {
      await userPl.init();
    }
    if (!mounted) return;
    try {
      await od.performSyncNow(userPlaylistProvider: userPl);
    } catch (e, st) {
      assert(() {
        debugPrint('OneDrive auto sync failed: $e\n$st');
        return true;
      }());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(EmbeddedSongMetadataPersistScheduler.flushPending());
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    // macOS：浏览器 OAuth 回跳时 keychain 写入与 resumed 几乎同时发生，立刻 loadFromStorage
    // 会偶发读不到新令牌并把 _signedIn 刷成 false（Android 无此窗口）。稍晚再读并配合控制器内重试。
    if (!kIsWeb && Platform.isMacOS) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final od = context.read<OneDriveController>();
        unawaited(od.loadFromStorage());
      });
    }
    _kickOneDriveAutoSyncCheck();
    _tryConsumeAndroidOpenWith();
  }

  @override
  void didChangePlatformBrightness() {
    // 系统深浅色变化时确保 [MaterialApp]/[Theme]/[MediaQuery] 子树重建（避免仅依赖 Inherited 时偶发不刷新）。
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppThemeModeProvider, AppLocaleProvider>(
      builder: (context, appearance, locale, _) {
        if (!_diagnosticPrefsPrimed) {
          _diagnosticPrefsPrimed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              DiagnosticLogStore.loadEnabledFromPrefs().then((enabled) {
                if (!kIsWeb && Platform.isAndroid) {
                  unawaited(WireRemoteNative.setDiagnosticsEnabled(enabled));
                }
              }),
            );
          });
        }
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
            unawaited(ensureAndroidPostNotificationsPermissionIfNeeded());
          });
        }
        return MaterialApp(
          navigatorKey: appNavigatorKey,
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
                child: LinuxTaskbarProgressHost(
                  child: LinuxTrayHost(
                    child: MacosMenuBarLyricsHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            );
          },
          home: const HomePage(),
          theme: AppMaterialThemes.light,
          darkTheme: AppMaterialThemes.dark,
          themeMode: appearance.themeMode,
        );
      },
    );
  }
}
