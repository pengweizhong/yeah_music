import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/themes/theme_provider.dart';

import 'compments/folder_provider.dart';
import 'compments/play_list_provider.dart';
import 'models/folder.dart';
import 'models/song.dart';

//SimplePrinter() 让日志以比较简洁的形式输出（不会带复杂的格式）
var log = Logger(printer: SimplePrinter());

void main() async {
  log.i('应用启动成功');
  await Hive.initFlutter();
  //Hive Adapter 注册（main.dart）
  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(SongAdapter());
  // clearCache();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayListProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()..init()),
      ],
      child: YeahMusicApp(),
    ),
  );
}

void clearCache() {
  log.i("清除缓存");
  Hive.deleteBoxFromDisk(Constant.hiveRootPath);
  Hive.deleteBoxFromDisk(Constant.hiveFolderBox);
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
