import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:yeah_music/services/music_service.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'ui/pages/home_page.dart';

void main() async {
  // // 确保 Flutter 绑定初始化
  // WidgetsFlutterBinding.ensureInitialized();
  // 打印当前运行的平台名称
  String platformName = getPlatformName();
  print('当前运行的平台：$platformName');
  // // 如果需要 FFmpeg 初始化，仅在 Android、iOS、macOS 上执行
  // if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
  //   // 如果仍保留 ffmpeg_kit_flutter_new，初始化代码放这里
  //   // await initializeFFmpeg();
  // }
  // if (Platform.isMacOS || Platform.isLinux) {
  //   // 初始化托盘
  //   await trayManager.setIcon('./assets/icons/icon_32x32@2x.png');
  //   // 添加托盘点击事件
  //   trayManager.addListener(MyTrayListener());
  // }
  // if (Platform.isWindows) {
  //   // 初始化托盘Ï
  //   await trayManager.setIcon('./assets/icons/icon_16x16@2x.png');
  //   // 添加托盘点击事件
  //   trayManager.addListener(MyTrayListener());
  // }
  runApp(const AppEntry());
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

Future<void> initializeFFmpeg() async {
  try {
    await FFmpegKitConfig.init();
    print('FFmpegKit initialized successfully');
  } catch (e) {
    print('FFmpegKit initialization failed: $e');
  }
}

// 获取平台名称
String getPlatformName() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isFuchsia) return 'Fuchsia';
  return 'Unknown';
}

class MyTrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    print("托盘图标被点击了！");
    // 可以在这里显示主窗口，或弹出菜单
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yeah Music',
      home: Scaffold(
        appBar: AppBar(title: const Text('Yeah Music')),
        body: const Center(child: Text('Hello Yeah Music')),
      ),
    );
  }
}
