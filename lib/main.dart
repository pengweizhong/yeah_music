import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/pages/welcome_entry_page.dart';
import 'package:yeah_music/themes/app_material_themes.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

import 'app_scaffold_messenger.dart';
import 'compments/folder_provider.dart';
import 'navigation/app_route_observer.dart';
import 'compments/play_list_provider.dart';
import 'compments/theme_config_provider.dart';
import 'compments/user_playlist_provider.dart';

//SimplePrinter() 让日志以比较简洁的形式输出（不会带复杂的格式）
var log = Logger(printer: SimplePrinter());

void main() {
  log.i('应用正在启动。。。');

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

class _AppStartupGateState extends State<AppStartupGate> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final appInit = AppInit();
    appInit.initJustAudioKit();
    try {
      await appInit.initHive();
    } catch (e, st) {
      log.e('initHive 失败: $e', error: e, stackTrace: st);
      if (mounted) setState(() => _error = e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      _error = null;
    });
    log.i('应用启动成功！');
  }

  void _retry() {
    setState(() {
      _error = null;
      _ready = false;
    });
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
        home: const AppSplashChrome(
          showProgress: true,
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
      child: const YeahMusicApp(),
    );
  }
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
      builder: (context, appearance, _) {
        return MaterialApp(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          navigatorObservers: <NavigatorObserver>[appRouteObserver],
          debugShowCheckedModeBanner: false,
          home: const WelcomeEntryPage(),
          theme: AppMaterialThemes.light,
          darkTheme: AppMaterialThemes.dark,
          themeMode: appearance.themeMode,
        );
      },
    );
  }
}

