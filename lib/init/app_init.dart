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
import '../utils/hive_utils.dart';

bool _hiveOpenLikelyOutOfMemory(Object error) {
  if (error is OutOfMemoryError) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('out of memory') || msg.contains('out_of_memory');
}

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

  /// 初始化 Hive（顺序打开以降低峰值内存；folders 使用 LazyBox，避免整文件 readAsBytes OOM）。
  Future<void> initHive() async {
    appLog.d('Hive: 开始初始化');
    await Hive.initFlutter();
    appLog.d('Hive: HiveFlutter 已初始化');
    appLog.d('开始清理缓存');
    // await clearHiveCache();
    appLog.d('缓存清理完毕');
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(LyricSettingsAdapter());

    /// 多次重试后再删库重建，避免瞬时 IO / 文件锁导致误删音乐源。
    ///
    /// **顺序打开**：并行 [Future.wait] 会让多个 box 同时整文件读入内存，在低内存机型上易 OOM；
    /// [yeah_music_folders] 中还存有大量含 [Song.imageBytes] 的条目，峰值内存更高。
    Future<void> openWithRecovery(
      String name,
      Future<void> Function() open, {
      int attemptsBeforeDelete = 6,
      bool wipeDiskOnFirstOOM = false,
    }) async {
      for (var attempt = 0; attempt < attemptsBeforeDelete; attempt++) {
        try {
          await open();
          return;
        } catch (e) {
          final isOOM = wipeDiskOnFirstOOM && _hiveOpenLikelyOutOfMemory(e);
          final isLast = attempt == attemptsBeforeDelete - 1;
          appLog.w(
            '打开 Hive box 失败 (${attempt + 1}/$attemptsBeforeDelete): $name',
            error: e,
          );
          if (isOOM) {
            appLog.e(
              'Hive box 打开 OOM，删除磁盘文件后重建（通常因曲目过多且缓存了封面；需在「音乐源」重新扫描）: $name',
              error: e,
            );
            try {
              await Hive.deleteBoxFromDisk(name);
            } catch (del, st) {
              appLog.w('删除 Hive box 失败: $name', error: del, stackTrace: st);
            }
            await HiveUtils.deleteHiveBoxDiskFilesBestEffort(name);
            await Future<void>.delayed(const Duration(milliseconds: 160));
            try {
              await open();
              return;
            } catch (e2, st2) {
              appLog.e(
                'Hive box OOM 重建后仍失败，再次裸删并重试: $name',
                error: e2,
                stackTrace: st2,
              );
              await HiveUtils.deleteHiveBoxDiskFilesBestEffort(name);
              await Future<void>.delayed(const Duration(milliseconds: 160));
              await open();
              return;
            }
          }
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

    await openWithRecovery('settings', () async {
      await Hive.openBox('settings');
    });
    await openWithRecovery(Constant.hiveRootPath, () async {
      await Hive.openBox(Constant.hiveRootPath);
    });
    if (!Hive.isBoxOpen(Constant.hiveFolderBox)) {
      await openWithRecovery(
        Constant.hiveFolderBox,
        () async {
          await Hive.openLazyBox<Folder>(
            Constant.hiveFolderBox,
            compactionStrategy: hiveFolderLazyBoxCompactionStrategy,
          );
        },
        attemptsBeforeDelete: 8,
        wipeDiskOnFirstOOM: true,
      );
    }
    appLog.d('Hive: 已就绪');
  }

  /// 暂时在这里提供一个清理缓存的方法，在开发的时候临时调用
  Future<void> clearHiveCache() async {
    await Hive.deleteBoxFromDisk('settings');
    await Hive.deleteBoxFromDisk(Constant.hiveRootPath);
    await Hive.deleteBoxFromDisk(Constant.hiveFolderBox);
  }

}
