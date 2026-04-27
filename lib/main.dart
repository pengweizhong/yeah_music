import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/pages/welcome_entry_page.dart';
import 'package:yeah_music/themes/app_material_themes.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/welcome/welcome_countdown_view.dart';
import 'package:yeah_music/welcome/welcome_fake_status.dart';

import 'app_scaffold_messenger.dart';
import 'compments/folder_provider.dart';
import 'navigation/app_route_observer.dart';
import 'compments/play_list_provider.dart';
import 'compments/theme_config_provider.dart';
import 'compments/user_playlist_provider.dart';

void main() {
  appLog.i('应用正在启动');

  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 500
    ..maximumSizeBytes = 200 << 20;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050608),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const AppStartupGate());
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
  int? _preHiveCountdownToPass;

  WelcomeFakeStatusRotator? _fake;
  AnimationController? _glow;
  int _secondsLeft = kWelcomeCountdownStart;
  Timer? _countdownTimer;

  void _initPreHiveVisuals() {
    _glow?.dispose();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fake = WelcomeFakeStatusRotator()..start();
  }

  @override
  void initState() {
    super.initState();
    _initPreHiveVisuals();
    _startCountdown();
    _bootstrap();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _glow?.dispose();
    _fake?.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = kWelcomeCountdownStart);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft -= 1;
        }
        if (_secondsLeft <= 0) {
          t.cancel();
        }
      });
    });
  }

  void _teardownPreHiveOnly() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _glow?.dispose();
    _glow = null;
    _fake?.dispose();
    _fake = null;
  }

  void _disposePreHiveResources(int captured) {
    _teardownPreHiveOnly();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _error = null;
      _preHiveCountdownToPass = captured;
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
    _disposePreHiveResources(_secondsLeft);
    appLog.i('应用启动成功');
  }

  void _retry() {
    _teardownPreHiveOnly();
    _initPreHiveVisuals();
    _startCountdown();
    if (mounted) {
      setState(() {
        _error = null;
        _ready = false;
        _preHiveCountdownToPass = null;
      });
    }
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E14),
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('启动失败: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _retry, child: const Text('重试')),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E14),
        ),
        home: WelcomeCountdownView(
          statusListenable: _fake!.hint,
          secondsLeft: _secondsLeft,
          dataReady: false,
          glow: _glow!,
          showEnterButton: false,
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeModeProvider()),
        ChangeNotifierProvider(create: (_) => PlayListProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final p = UserPlaylistProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => FolderProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeConfigProvider()),
      ],
      child: YeahMusicApp(
        preHiveCountdownLeft: _preHiveCountdownToPass,
      ),
    );
  }
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key, this.preHiveCountdownLeft});

  /// Hive 与欢迎页门控前已跑的倒计时剩余秒数，避免进入欢迎页时从 5 重计。
  final int? preHiveCountdownLeft;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
      builder: (context, appearance, _) {
        return MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          navigatorObservers: <NavigatorObserver>[appRouteObserver],
          debugShowCheckedModeBanner: false,
          home: WelcomeEntryPage(
            preHiveCountdownLeft: preHiveCountdownLeft,
          ),
          theme: AppMaterialThemes.light,
          darkTheme: AppMaterialThemes.dark,
          themeMode: appearance.themeMode,
        );
      },
    );
  }
}

