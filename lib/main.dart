import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/themes/theme_provider.dart';

import 'app_scaffold_messenger.dart';
import 'compments/folder_provider.dart';
import 'compments/play_list_provider.dart';
import 'compments/theme_config_provider.dart';
import 'compments/user_playlist_provider.dart';

//SimplePrinter() 让日志以比较简洁的形式输出（不会带复杂的格式）
var log = Logger(printer: SimplePrinter());

void main() async {
  log.i('应用正在启动。。。');
  
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI样式，避免白色闪光
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  AppInit appInit = AppInit();
  appInit.initJustAudioKit();
  appInit.initHive();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      child: YeahMusicApp(),
    ),
  );
  log.i('应用启动成功！');
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      // 去掉右上角的 "Debug" 标签
      debugShowCheckedModeBanner: false,
      // 设置应用的首页
      home: HomePage(),
      // 动态主题 - 使用深色主题避免白色闪光
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.black,
        dialogBackgroundColor: Colors.black87,
        // 完全不设置 textTheme 和 fontFamily，让 Flutter 使用系统默认字体
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.black,
        dialogBackgroundColor: Colors.black87,
        // 完全不设置 textTheme 和 fontFamily，让 Flutter 使用系统默认字体
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}

