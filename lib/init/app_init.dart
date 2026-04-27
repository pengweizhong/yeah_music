import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:logger/logger.dart';

import '../models/constants.dart';
import '../models/folder.dart';
import '../models/song.dart';
import '../models/lyric_settings.dart';

var log = Logger(printer: SimplePrinter());

class AppInit {
  ///初始化JustAudio 音频播放插件
  void initJustAudioKit() {
    if (!Platform.isLinux) {
      return;
    }
    log.d("初始化 Linux setlocale C");
    // 强制设置 locale
    ffi.DynamicLibrary.process();
    // 仅在 Linux 桌面需要
    // 很多 Linux 系统（尤其是中文环境，LANG=zh_CN.UTF-8 之类）会把小数点当作逗号 ，而 FFmpeg 只认 .
    try {
      ffi.DynamicLibrary.open("libc.so.6").lookupFunction<
        ffi.Pointer<ffi.Int8> Function(ffi.Int32, ffi.Pointer<ffi.Int8>),
        ffi.Pointer<ffi.Int8> Function(int, ffi.Pointer<ffi.Int8>)
      >("setlocale")(6, "C".toNativeUtf8().cast()); // 6 = LC_NUMERIC
    } catch (_) {}
    log.d("初始化 just_audio_media_kit");
    //初始化AudioPlayer
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      // default: true  - dependency: media_kit_libs_linux
      windows: true,
      // default: true  - dependency: media_kit_libs_windows_audio
      android: true,
      // default: false - dependency: media_kit_libs_android_audio
      iOS: true,
      // default: false - dependency: media_kit_libs_ios_audio
      macOS: false, // default: false - dependency: media_kit_libs_macos_audio
    );
  }

  ///初始化hive数据库
  Future<void> initHive() async {
    log.d("Hive Init.");
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    
    // 必须先注册适配器，再打开 box
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(LyricSettingsAdapter());
    
    // 打开 box，如果遇到未知 typeId 错误，则删除并重新创建
    try {
      await Hive.openBox('settings');
    } catch (e) {
      log.w("打开 settings box 失败，尝试删除并重新创建: $e");
      try {
        await Hive.deleteBoxFromDisk('settings');
        await Hive.openBox('settings');
      } catch (_) {
        // 忽略删除失败的错误
      }
    }
    
    try {
      await Hive.openBox(Constant.hiveRootPath);
    } catch (e) {
      log.w("打开 ${Constant.hiveRootPath} box 失败，尝试删除并重新创建: $e");
      try {
        await Hive.deleteBoxFromDisk(Constant.hiveRootPath);
        await Hive.openBox(Constant.hiveRootPath);
      } catch (_) {
        // 忽略删除失败的错误
      }
    }
    
    // 与 FolderProvider 使用同一泛型，避免已打开时因类型再 close/reopen
    if (!Hive.isBoxOpen(Constant.hiveFolderBox)) {
      try {
        await Hive.openBox<Folder>(Constant.hiveFolderBox);
      } catch (e) {
        log.w("打开 ${Constant.hiveFolderBox} box 失败，尝试删除并重新创建: $e");
        try {
          await Hive.deleteBoxFromDisk(Constant.hiveFolderBox);
          await Hive.openBox<Folder>(Constant.hiveFolderBox);
        } catch (_) {
          // 忽略删除失败的错误
        }
      }
    }
  }

  void _clearCache() {
    log.i("清除缓存");
    Hive.deleteBoxFromDisk(Constant.hiveRootPath);
    Hive.deleteBoxFromDisk(Constant.hiveFolderBox);
  }
}
