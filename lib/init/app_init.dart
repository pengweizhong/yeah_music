import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:yeah_music/logging/app_log.dart';

import '../models/constants.dart';
import '../models/folder.dart';
import '../models/song.dart';
import '../models/lyric_settings.dart';

class AppInit {
  ///初始化JustAudio 音频播放插件
  void initJustAudioKit() {
    if (!Platform.isLinux) {
      return;
    }
    appLog.d('Linux: 初始化 setlocale C');
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
    appLog.d('just_audio_media_kit 已初始化');
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

  ///初始化hive数据库（各 box 无依赖，并行打开以压缩冷启动时间）
  Future<void> initHive() async {
    appLog.d('Hive: 开始初始化');
    await Hive.initFlutter();

    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(LyricSettingsAdapter());

    /// 多次重试后再删库重建，避免瞬时 IO / 文件锁导致误删音乐源。
    Future<void> openWithRecovery(
      String name,
      Future<void> Function() open, {
      int attemptsBeforeDelete = 6,
    }) async {
      for (var attempt = 0; attempt < attemptsBeforeDelete; attempt++) {
        try {
          await open();
          return;
        } catch (e) {
          final isLast = attempt == attemptsBeforeDelete - 1;
          appLog.w(
            '打开 Hive box 失败 (${attempt + 1}/$attemptsBeforeDelete): $name',
            error: e,
          );
          if (!isLast) {
            await Future<void>.delayed(
              Duration(milliseconds: 60 * (1 << attempt)),
            );
            continue;
          }
          appLog.e(
            'Hive box 多次打开失败，删除损坏文件并重建（仅此路径会清空该 box）: $name',
            error: e,
          );
          try {
            await Hive.deleteBoxFromDisk(name);
          } catch (del, st) {
            appLog.w('删除 Hive box 失败: $name', error: del, stackTrace: st);
          }
          await open();
        }
      }
    }

    await Future.wait<void>([
      openWithRecovery('settings', () async {
        await Hive.openBox('settings');
      }),
      openWithRecovery(
        Constant.hiveRootPath,
        () async {
          await Hive.openBox(Constant.hiveRootPath);
        },
      ),
      if (!Hive.isBoxOpen(Constant.hiveFolderBox))
        openWithRecovery(
          Constant.hiveFolderBox,
          () async {
            await Hive.openBox<Folder>(Constant.hiveFolderBox);
          },
          attemptsBeforeDelete: 10,
        )
      else
        Future<void>.value(),
    ]);
    appLog.d('Hive: 已就绪');
  }
}
