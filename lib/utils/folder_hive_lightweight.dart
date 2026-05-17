import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/folder.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// Hive 中 [Folder] 只存路径与文本元数据；封面由 [SongLibraryMetadataHydrator] 按需从文件读取。
///
/// 持久化 [Song.imageBytes] 会使 `yeah_music_folders.hive` 在数天内膨胀到数百 MB，
/// 启动时 LazyBox 扫描与逐条反序列化在 Android 上可达数十秒～一分钟。
abstract final class FolderHiveLightweight {
  FolderHiveLightweight._();

  static const _stripEmbeddedArtMigrationKey =
      'hive_folder_stripped_embedded_art_v1';

  /// 写入 Hive 前丢弃内嵌图（仍保留标题/歌词等轻量字段）。
  static void stripHeavySongFieldsForHive(Folder folder) {
    final list = folder.songList;
    if (list == null || list.isEmpty) return;
    for (final s in list) {
      s.imageBytes = null;
      s.pictures = null;
    }
  }

  static Future<void> saveFolder(Folder folder) async {
    stripHeavySongFieldsForHive(folder);
    await folder.save();
  }

  /// 首次升级后后台重写各 [Folder]，缩小 `.hive` 体积（不阻塞 UI 构建）。
  static Future<void> runStripEmbeddedArtMigrationIfNeeded() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_stripEmbeddedArtMigrationKey) == true) return;

    try {
      final box = await HiveUtils.openFolderBox();
      var n = 0;
      for (final key in box.keys) {
        final f = await box.get(key);
        if (f == null) continue;
        final hadArt = f.songList?.any(
              (s) =>
                  (s.imageBytes != null && s.imageBytes!.isNotEmpty) ||
                  (s.pictures != null && s.pictures!.isNotEmpty),
            ) ??
            false;
        if (!hadArt) continue;
        stripHeavySongFieldsForHive(f);
        await f.save();
        n++;
        if (n % 2 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      await prefs.setBool(_stripEmbeddedArtMigrationKey, true);
      if (n > 0) {
        appLog.i('Hive 音乐源已瘦身：重写 $n 个目录条目（已移除持久化封面字节）');
      }
    } catch (e, st) {
      appLog.w('Hive 音乐源瘦身迁移失败（下次启动会重试）', error: e, stackTrace: st);
    }
  }
}
