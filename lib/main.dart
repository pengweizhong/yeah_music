import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/themes/theme_provider.dart';

//SimplePrinter() 让日志以比较简洁的形式输出（不会带复杂的格式）
var log = Logger(printer: SimplePrinter());

void main() {
  log.i('应用启动成功');
  runApp(
    ChangeNotifierProvider(
      //把 ThemeProvider 注入到整个应用，后续所有子 Widget 都可以访问到它
      create: (context) => ThemeProvider(),
      //应用主 Widget
      child: YeahMusicApp(),
    ),
  );
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 去掉右上角的 "Debug" 标签
      debugShowCheckedModeBanner: false,
      // 设置应用的首页
      home: HomePage(),
      // 动态主题
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
