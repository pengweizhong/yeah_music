import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/folder.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/hive_utils.dart';

class _SongHeavyFields {
  const _SongHeavyFields({
    this.imageBytes,
    this.pictures,
    this.lyrics,
  });

  final Uint8List? imageBytes;
  final List<Picture>? pictures;
  final String? lyrics;
}

/// Hive 中 [Folder] 只存路径与文本元数据（曲名、歌手、专辑、时间等）；
/// 封面与歌词由 [SongLibraryMetadataHydrator] / 播放时按需从音频文件读取。
///
/// 持久化 [Song.imageBytes] 或歌词全文会使 `yeah_music_folders.hive` 在数天内膨胀到数百 MB，
/// 启动时 LazyBox 扫描与逐条反序列化在 Android 上可达数十秒～一分钟。
abstract final class FolderHiveLightweight {
  FolderHiveLightweight._();

  static const _stripEmbeddedArtMigrationKey =
      'hive_folder_stripped_embedded_art_v1';
  static const _stripEmbeddedLyricsMigrationKey =
      'hive_folder_stripped_embedded_lyrics_v1';

  /// 写入 Hive 前丢弃内嵌图与歌词全文（仅保留曲名、歌手、专辑、时间等轻量字段）。
  static void stripHeavySongFieldsForHive(Folder folder) {
    final list = folder.songList;
    if (list == null || list.isEmpty) return;
    for (final s in list) {
      s.imageBytes = null;
      s.pictures = null;
      s.lyrics = null;
    }
  }

  /// 写入 Hive 时临时剥离重字段；完成后恢复内存中的封面/歌词，避免统计等持久化冲掉会话内已加载的封面。
  static Future<void> saveFolder(Folder folder) async {
    final backups = <Song, _SongHeavyFields>{};
    final list = folder.songList;
    if (list != null) {
      for (final s in list) {
        if (s.imageBytes == null && s.pictures == null && s.lyrics == null) {
          continue;
        }
        backups[s] = _SongHeavyFields(
          imageBytes: s.imageBytes,
          pictures: s.pictures,
          lyrics: s.lyrics,
        );
      }
    }
    stripHeavySongFieldsForHive(folder);
    try {
      await folder.save();
    } finally {
      for (final e in backups.entries) {
        final b = e.value;
        e.key.imageBytes = b.imageBytes;
        e.key.pictures = b.pictures;
        e.key.lyrics = b.lyrics;
      }
    }
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

  /// 首次升级后后台重写各 [Folder]，从 `.hive` 中清除历史持久化的歌词全文。
  static Future<void> runStripEmbeddedLyricsMigrationIfNeeded() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_stripEmbeddedLyricsMigrationKey) == true) return;

    try {
      final box = await HiveUtils.openFolderBox();
      var n = 0;
      for (final key in box.keys) {
        final f = await box.get(key);
        if (f == null) continue;
        final hadLyrics = f.songList?.any(
              (s) => (s.lyrics?.trim().isNotEmpty ?? false),
            ) ??
            false;
        if (!hadLyrics) continue;
        stripHeavySongFieldsForHive(f);
        await f.save();
        n++;
        if (n % 2 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      await prefs.setBool(_stripEmbeddedLyricsMigrationKey, true);
      if (n > 0) {
        appLog.i('Hive 音乐源已瘦身：重写 $n 个目录条目（已移除持久化歌词）');
      }
    } catch (e, st) {
      appLog.w('Hive 歌词瘦身迁移失败（下次启动会重试）', error: e, stackTrace: st);
    }
  }
}
