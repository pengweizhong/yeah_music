import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/init/app_init.dart';
import 'package:yeah_music/services/music_service.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'ui/pages/home_page.dart';
import 'utils/platform_utils.dart';

var log = Logger(printer: SimplePrinter());

void main() async {
  log.i('正在启动应用');
  log.i('当前运行的平台：${PlatformUtils().getPlatformName()}');
  var init = AppInit();
  init.initJustAudio();
  runApp(const AppEntry());
  log.i('应用完成');
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 关闭右上角 Debug 横幅
      title: AppConfig.appTitle,
      theme: AppTheme.lightTheme,
      home: MusicHomePage(service: MusicService()),
    );
  }
}
