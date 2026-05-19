import 'dart:async' show unawaited;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yeah_music/compments/bookmark_service.dart';
import 'package:yeah_music/utils/concurrent_limiter.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/folder_paths_backup.dart';
import 'package:yeah_music/utils/folder_hive_lightweight.dart';
import 'package:yeah_music/utils/hive_utils.dart';

import '../config/app_config.dart';
import '../models/folder.dart';

/// 目录重扫生成的新 [Song] 不含内嵌封面/歌词（见 [_loadSongBatch]）；合并旧列表中已补全的
/// [Song.imageBytes]（仅内存，不入 Hive），避免刷新目录把同会话内后台补全的封面写没。
void mergeEmbeddedFieldsFromPreviousSongList({
  required List<Song> freshList,
  required List<Song>? previousList,
}) {
  if (previousList == null || previousList.isEmpty) return;
  final prevByPath = <String, Song>{
    for (final s in previousList) s.path: s,
  };
  for (final fresh in freshList) {
    final prev = prevByPath[fresh.path];
    if (prev == null) continue;
    if ((fresh.imageBytes == null || fresh.imageBytes!.isEmpty) &&
        prev.imageBytes != null &&
        prev.imageBytes!.isNotEmpty) {
      fresh.imageBytes = prev.imageBytes;
    }
  }
}

class FolderProvider extends ChangeNotifier {
  /// 目录扫描时的并行读标签上限（无封面/歌词写 Hive，主要耗时在 readMetadata）。
  static final ConcurrentLimiter _scanMetaLimiter = ConcurrentLimiter(
    Platform.isAndroid ? 3 : 6,
  );

  //main 里调用了 ..init()，也不能保证 UI 构建时 _box 已经就绪。
  LazyBox<Folder>? _box;
  final List<Folder> _foldersCache = [];
  bool _initialized = false;

  List<Folder> get folders {
    if (_box == null || !_box!.isOpen) return [];
    return List<Folder>.unmodifiable(_foldersCache);
  }

  bool get initialized => _initialized;

  /// 初始化 Hive Box
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) {
      return;
    }
    final box = await HiveUtils.openFolderBox();
    final list = <Folder>[];
    var i = 0;
    for (final key in box.keys) {
      final f = await box.get(key);
      if (f != null) {
        FolderHiveLightweight.stripHeavySongFieldsForHive(f);
        list.add(f);
      }
      i++;
      if (i % 2 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    _foldersCache
      ..clear()
      ..addAll(list);
    _box = box;
    unawaited(FolderHiveLightweight.runStripEmbeddedArtMigrationIfNeeded());
    unawaited(FolderHiveLightweight.runStripEmbeddedLyricsMigrationIfNeeded());
    if (_foldersCache.isEmpty) {
      await _restoreFoldersFromBackupIfNeeded();
    }
    await FolderPathsBackup.save(_foldersCache);
    _initialized = true;
    if (Platform.isMacOS) {
      try {
        await BookmarkService.restoreAllBookmarks();
        appLog.d('macOS: 已恢复音乐目录安全作用域书签');
      } catch (e) {
        appLog.w('macOS 恢复书签失败（可尝试在「音乐源」中刷新）', error: e);
      }
    }
    notifyListeners();
  }

  /// Hive 被清空（如 OOM 重建）时从 [FolderPathsBackup] 拉回路径。
  Future<void> _restoreFoldersFromBackupIfNeeded() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    final entries = await FolderPathsBackup.load();
    if (entries.isEmpty) return;
    appLog.w(
      '音乐源 Hive 为空，从轻量备份恢复 ${entries.length} 条路径（不含曲目数据，扫描可能在稍后完成）',
    );
    for (final e in entries) {
      final folderPath = e.path.trim();
      if (folderPath.isEmpty) continue;
      if (await existFolder(box, folderPath)) continue;
      final displayName = e.name ?? p.basename(folderPath);
      final f = Folder(folderPath);
      f.name = displayName;
      f.createdAt = DateTime.now();
      try {
        await flushSongToFolder(f, false, save: false);
      } catch (err) {
        appLog.w(
          '备份恢复：目录暂时无法扫描（仍保留音乐源条目）: $folderPath',
          error: err,
        );
      }
      try {
        await HiveUtils.add(box, f);
        _foldersCache.add(f);
      } catch (err) {
        appLog.w('备份恢复：写入 Hive 失败: $folderPath', error: err);
      }
    }
  }

  /// 添加文件夹 ,添加成功就返回Folder（优化版本，支持大量歌曲）
  Future<Folder?> addFolder(String folder) async {
    final box = _box;
    if (box == null || !box.isOpen) return null;
    //检验文件夹是否已经存在
    if (await existFolder(box, folder)) {
      appLog.d("用户添加了重复的文件夹：$folder");
      return null;
    }
    String folderName = folder.split('/').last;
    final f = Folder(folder);
    f.name = folderName;
    f.createdAt = DateTime.now();
    
    try {
      await flushSongToFolder(f, false, save: false);
      await HiveUtils.add(box, f);
      _foldersCache.add(f);
      await FolderPathsBackup.save(_foldersCache);
      notifyListeners();
      return f;
    } catch (e) {
      appLog.e('添加文件夹失败: $folder', error: e);
      // 如果添加失败，不保存到数据库
      rethrow;
    }
  }

  /// 删除文件夹
  Future<void> deleteFolder(Folder folder) async {
    final removedPaths = folder.songList?.map((s) => s.path) ?? const <String>[];
    if (removedPaths.isNotEmpty) {
      SongLibraryMetadataHydrator.invalidatePaths(removedPaths);
    }
    await folder.delete();
    _foldersCache.removeWhere(
      (x) => identical(x, folder) || x.path == folder.path,
    );
    await FolderPathsBackup.save(_foldersCache);
    notifyListeners();
  }

  /// 修改文件夹名称
  Future<void> renameFolder(Folder folder, String newName) async {
    folder.name = newName;
    await FolderHiveLightweight.saveFolder(folder);
    await FolderPathsBackup.save(_foldersCache);
    notifyListeners();
  }

  /// 添加歌曲到文件夹（优化版本，支持大量歌曲）
  Future<void> flushSongToFolder(Folder folder, bool listen, {bool save = true}) async {
    String folderPath = folder.path;
    if (Platform.isMacOS) {
      // macOS需要先恢复权限，如果失败则记录错误
      try {
        final restored = await BookmarkService.restoreBookmark(folderPath);
        if (restored == null) {
          appLog.w("无法恢复macOS权限，路径：$folderPath");
          // 即使权限恢复失败，也尝试访问，可能会触发系统权限请求
        }
      } catch (e) {
        appLog.e('恢复 macOS 权限失败', error: e);
      }
    } else if (Platform.isAndroid) {
      // 筛选支持的音频文件格式
      // 获取当前目录及子目录下所有文件
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        // Android 13+
        await [Permission.audio, Permission.photos, Permission.videos].request();
      } else {
        // Android 12 及以下
        await Permission.storage.request().isGranted;
      }
    }
    //加载歌曲
    try {
      final dir = Directory(folderPath);
      var exists = await dir.exists();
      if (!exists) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        exists = await dir.exists();
      }
      // 路径短时不可用时不覆盖 Hive 内已有列表，避免 SD 卡卸载等偶发情况丢库
      if (!exists) {
        appLog.w('文件夹暂时不可访问（保留已缓存曲目列表）: $folderPath');
        if (listen) notifyListeners();
        return;
      }

      // 使用异步方式列出文件，避免阻塞UI
      final songFiles = await _listAudioFilesAsync(dir);
      appLog.d("文件夹${dir.path}下找到了${songFiles.length}首歌曲");
      
      // 批量处理：不解析内嵌封面（列表页 [SongListCover] 后台按需加载），不写歌词，降低内存/Hive
      List<Song> songlist = [];
      const batchSize = 28;

      for (int i = 0; i < songFiles.length; i += batchSize) {
        final end = (i + batchSize < songFiles.length)
            ? i + batchSize
            : songFiles.length;
        final batch = songFiles.sublist(i, end);

        final batchSongs = await _loadSongBatch(batch);
        songlist.addAll(batchSongs);

        await Future.delayed(Duration.zero);
      }
      if (songFiles.isNotEmpty) {
        appLog.d('目录已扫描: ${dir.path} → ${songlist.length} 首');
      }

      final previousPaths = <String>{
        for (final s in folder.songList ?? const <Song>[]) s.path,
      };

      mergeEmbeddedFieldsFromPreviousSongList(
        freshList: songlist,
        previousList: folder.songList,
      );

      folder.songList = songlist;

      previousPaths.removeAll(songlist.map((s) => s.path));
      if (previousPaths.isNotEmpty) {
        SongLibraryMetadataHydrator.invalidatePaths(previousPaths);
      }
      if (save) {
        await FolderHiveLightweight.saveFolder(folder);
      }
      if (listen) {
        notifyListeners();
      }
    } catch (e) {
      appLog.e('访问文件夹失败（未清空已持久化的曲目列表）: $folderPath', error: e);
      if (listen) {
        notifyListeners();
      }
      rethrow;
    }
  }

  /// 异步列出音频文件
  Future<List<File>> _listAudioFilesAsync(Directory dir) async {
    final List<File> audioFiles = [];
    
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path;
          if (AppConfig.supportedFormats.any((format) => path.endsWith(format))) {
            audioFiles.add(entity);
          }
        }
        
        // 每处理100个文件，让出控制权
        if (audioFiles.length % 100 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    } catch (e) {
      appLog.e('列出目录内文件失败', error: e);
    }
    
    return audioFiles;
  }

  /// 批量加载歌曲元数据（有限并行）；不写内嵌封面/歌词，列表与播放时按需补全。
  Future<List<Song>> _loadSongBatch(List<File> files) async {
    if (files.isEmpty) return [];
    final slots = List<Song?>.filled(files.length, null);
    var done = 0;
    await Future.wait(
      List<Future<void>>.generate(files.length, (i) async {
        final file = files[i];
        await _scanMetaLimiter.acquire();
        try {
          try {
            final song = Song(file.path);
            await FileUtils.loadSongMeta(
              song,
              loadEmbeddedAlbumArt: false,
              storeLyricsWithTrack: false,
            );
            slots[i] = song;
          } catch (e) {
            appLog.w('歌曲元数据读取失败', error: e);
            try {
              final song = Song(file.path);
              song.title = p.basenameWithoutExtension(file.path);
              slots[i] = song;
            } catch (_) {}
          }
        } finally {
          _scanMetaLimiter.release();
          done++;
          if (done % 12 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }),
    );
    return slots.whereType<Song>().toList();
  }

  ///文件夹是否已经存在
  ///存在 true，否则 false
  Future<bool> existFolder(LazyBox<Folder> box, String folder) async {
    for (final key in box.keys) {
      final f = await box.get(key);
      if (f?.path == folder) return true;
    }
    return false;
  }

  /// 外部工具改写曲目文件后 [Song] 已更新（Hive），通知目录列表等 UI。
  void notifySongMetadataChangedRemote() {
    notifyListeners();
  }
}
