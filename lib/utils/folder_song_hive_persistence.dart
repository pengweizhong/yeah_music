import 'dart:async';

import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/folder.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/folder_hive_lightweight.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 由 [FolderProvider] 注册：持久化时必须写入内存里已更新的 [Folder]/[Song]，
/// 不能仅从 LazyBox 再 get（会得到未含最新 [Song.durationMs]/[Song.bitrate] 等的磁盘副本）。
Iterable<Folder> Function()? inMemoryFoldersForPersist;

/// 批量把受影响曲目写入 Hive（单次遍历文件夹）；防抖合并短时密集写入，避免滑动列表时每首歌阻塞磁盘。
class EmbeddedSongMetadataPersistScheduler {
  EmbeddedSongMetadataPersistScheduler._();

  static Timer? _timer;
  static const Duration _debounce = Duration(milliseconds: 420);
  static final Set<String> _queuedPaths = {};

  /// 合并防抖写入（Hydrator / 列表滑动常用）。
  static void schedule(Song song) {
    final p = song.path.trim();
    if (p.isEmpty) return;
    _queuedPaths.add(p);
    _timer?.cancel();
    _timer = Timer(_debounce, _flushQueuedSync);
  }

  static void _flushQueuedSync() {
    _timer = null;
    final paths = Set<String>.from(_queuedPaths);
    _queuedPaths.clear();
    if (paths.isEmpty) return;
    Future<void>(() async {
      try {
        await persistEmbeddedSongPaths(paths);
      } catch (_) {}
    });
  }

  /// 供退出进程前的钩子如需手动冲刷（可选）。
  static Future<void> flushPending() async {
    _timer?.cancel();
    _timer = null;
    final paths = Set<String>.from(_queuedPaths);
    _queuedPaths.clear();
    if (paths.isEmpty) return;
    await persistEmbeddedSongPaths(paths);
  }
}

/// 立即写入包含任一给定路径的 [Folder]（每文件夹至多一次）。
Future<void> persistEmbeddedSongPaths(Iterable<String> paths) async {
  final trimmed = paths.map((p) => p.trim()).where((p) => p.isNotEmpty).toSet();
  if (trimmed.isEmpty) return;
  try {
    final memoryFolders = inMemoryFoldersForPersist?.call();
    if (memoryFolders != null) {
      for (final folder in memoryFolders) {
        final list = folder.songList;
        if (list == null || list.isEmpty) continue;
        if (!list.any((s) => trimmed.contains(s.path))) continue;
        await FolderHiveLightweight.saveFolder(folder);
      }
      return;
    }

    final box = await HiveUtils.openFolderBox();
    final toSave = <Folder>{};
    for (final key in box.keys) {
      final f = await box.get(key);
      if (f == null) continue;
      final list = f.songList;
      if (list == null || list.isEmpty) continue;
      if (!list.any((s) => trimmed.contains(s.path))) continue;
      toSave.add(f);
    }
    for (final folder in toSave) {
      await FolderHiveLightweight.saveFolder(folder);
    }
  } catch (e, st) {
    appLog.w('persistEmbeddedSongPaths failed', error: e, stackTrace: st);
  }
}

Future<void> persistEmbeddedSongMetadataIfInFolderHive(Song song) async {
  await persistEmbeddedSongPaths({song.path});
}

void scheduleEmbeddedSongMetadataPersist(Song song) {
  EmbeddedSongMetadataPersistScheduler.schedule(song);
}
