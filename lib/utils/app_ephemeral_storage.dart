import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/logging/app_log.dart';

/// 应用自管的临时文件（通知封面、用其他应用打开时的副本等）；用户无需手动清缓存。
abstract final class AppEphemeralStorage {
  AppEphemeralStorage._();

  static const _legacyArtPurgedKey = 'ephemeral_legacy_nm_art_purged_v1';

  /// 旧版在文件名末尾追加微秒时间戳，切歌一次生成一个新文件，数天可占数 GB。
  static final RegExp _legacyTimestampArtName = RegExp(
    r'^yeah_nm_art_.+_\d{13,}\.jpg$',
  );

  static int coverBytesFingerprint(List<int> bytes) {
    final len = bytes.length;
    if (len == 0) return 0;
    var h = len;
    final n = len < 4096 ? len : 4096;
    for (var i = 0; i < n; i++) {
      h = (h * 31 + bytes[i]) & 0x3fffffff;
    }
    h ^= bytes[len - 1];
    return h;
  }

  /// 每条曲目 + 封面内容对应唯一文件，重复写入覆盖，不无限增长。
  static String notificationArtBasename(String songPath, List<int> bytes) {
    final fp = coverBytesFingerprint(bytes);
    return 'yeah_nm_art_${songPath.hashCode}_${bytes.length}_$fp.jpg';
  }

  static Future<File> writeNotificationArtFile({
    required String songPath,
    required List<int> bytes,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, notificationArtBasename(songPath, bytes)));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 启动后后台执行：一次性清掉历史泄漏的 `yeah_nm_art_*`，并修剪其它过期临时目录。
  static Future<void> runStartupMaintenanceIfNeeded() async {
    if (kIsWeb) return;
    await _purgeLegacyNotificationArtOnce();
    await pruneLegacyTimestampNotificationArt();
    await _pruneStaleOneDriveDownloadParts();
    await _pruneStaleScratchFiles();
    await _pruneOrphanCloudRestoreScratchDirs();
    await _trimDirectoryOlderThan(
      name: 'open_with',
      maxAge: const Duration(days: 3),
    );
    await _trimCacheFilesOlderThan(
      namePrefix: 'music_tag_share_',
      maxAge: const Duration(days: 2),
    );
    await _trimCacheFilesOlderThan(
      namePrefix: 'yeah_theme_bg_',
      maxAge: const Duration(days: 2),
    );
    await _trimCacheFilesOlderThan(
      namePrefix: 'yeah_song_id_',
      maxAge: const Duration(hours: 12),
    );
    await _trimCacheFilesOlderThan(
      namePrefix: 'ym_playlist_cover_',
      maxAge: const Duration(days: 3),
    );
  }

  static Future<List<Directory>> _cacheLikeRoots() async {
    final roots = <Directory>[];
    final seen = <String>{};
    void add(Directory d) {
      final n = p.normalize(d.path);
      if (seen.add(n)) roots.add(d);
    }

    try {
      add(await getTemporaryDirectory());
    } catch (_) {}
    try {
      add(await getApplicationCacheDirectory());
    } catch (_) {}
    if (Platform.isAndroid) {
      try {
        final ext = await getExternalCacheDirectories();
        if (ext != null) {
          for (final d in ext) {
            add(d);
          }
        }
      } catch (_) {}
    }
    return roots;
  }

  static Future<void> _purgeLegacyNotificationArtOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyArtPurgedKey) == true) return;

    var deleted = 0;
    var freedBytes = 0;
    try {
      for (final root in await _cacheLikeRoots()) {
        if (!await root.exists()) continue;
        await for (final entity in root.list(recursive: true)) {
          if (entity is! File) continue;
          final base = p.basename(entity.path);
          if (!base.startsWith('yeah_nm_art_') || !base.endsWith('.jpg')) {
            continue;
          }
          try {
            freedBytes += await entity.length();
            await entity.delete();
            deleted++;
            if (deleted % 64 == 0) {
              await Future<void>.delayed(Duration.zero);
            }
          } catch (_) {}
        }
      }
      await prefs.setBool(_legacyArtPurgedKey, true);
      if (deleted > 0) {
        final mb = (freedBytes / (1024 * 1024)).toStringAsFixed(1);
        appLog.i('已清理历史通知封面临时文件 $deleted 个（约 $mb MB）');
      }
    } catch (e, st) {
      appLog.w('清理历史通知封面临时文件失败', error: e, stackTrace: st);
    }
  }

  /// 防止旧逻辑残留的时间戳文件名继续堆积（正常情况下不应再产生）。
  static Future<void> pruneLegacyTimestampNotificationArt() async {
    if (kIsWeb) return;
    try {
      for (final root in await _cacheLikeRoots()) {
        if (!await root.exists()) continue;
        await for (final entity in root.list(recursive: true)) {
          if (entity is! File) continue;
          final base = p.basename(entity.path);
          if (!_legacyTimestampArtName.hasMatch(base)) continue;
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<void> _trimDirectoryOlderThan({
    required String name,
    required Duration maxAge,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    for (final root in await _cacheLikeRoots()) {
      final dir = Directory(p.join(root.path, name));
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list()) {
          if (entity is! File) continue;
          try {
            final modified = await entity.lastModified();
            if (modified.isBefore(cutoff)) {
              await entity.delete();
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  static Future<void> _trimCacheFilesOlderThan({
    required String namePrefix,
    required Duration maxAge,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    for (final root in await _cacheLikeRoots()) {
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(recursive: false)) {
          if (entity is! File) continue;
          if (!p.basename(entity.path).startsWith(namePrefix)) continue;
          try {
            final modified = await entity.lastModified();
            if (modified.isBefore(cutoff)) {
              await entity.delete();
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  /// 下载中断/杀进程后残留的 `.part`（按目标路径 hash 命名，非用户曲库文件）。
  static Future<void> _pruneStaleOneDriveDownloadParts() async {
    try {
      final support = await getApplicationSupportDirectory();
      final partsRoot = Directory(
        p.join(support.path, 'onedrive_download_parts'),
      );
      if (!await partsRoot.exists()) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final entity in partsRoot.list()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.part')) continue;
        try {
          final modified = await entity.lastModified();
          if (modified.isBefore(cutoff)) {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 云恢复/主题侧车下载落在 temp 根目录的散落文件（正常路径会在 finally 删除）。
  static Future<void> _pruneStaleScratchFiles() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    final legacyPlaylistCover = RegExp(
      r'^ym_playlist_cover_\d+_\d+\.png$',
    );
    for (final root in await _cacheLikeRoots()) {
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(recursive: false)) {
          if (entity is! File) continue;
          final base = p.basename(entity.path);
          final isLegacyPlaylistTmp = legacyPlaylistCover.hasMatch(base);
          final isThemeTmp = base.startsWith('yeah_theme_bg_');
          if (!isLegacyPlaylistTmp && !isThemeTmp) continue;
          try {
            final modified = await entity.lastModified();
            if (modified.isBefore(cutoff)) {
              await entity.delete();
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  /// 云歌单封面批量下载的临时目录 `yeah_pl_cov_<ts>/`（崩溃时可能未 deleteRecursively）。
  static Future<void> _pruneOrphanCloudRestoreScratchDirs() async {
    final re = RegExp(r'^yeah_pl_cov_\d+$');
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    for (final root in await _cacheLikeRoots()) {
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(recursive: false)) {
          if (entity is! Directory) continue;
          if (!re.hasMatch(p.basename(entity.path))) continue;
          try {
            final modified = (await entity.stat()).modified;
            if (modified.isBefore(cutoff)) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
  }
}
