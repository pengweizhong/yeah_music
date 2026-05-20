import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/concurrent_limiter.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';

/// 曲库「估算总时长」：汇总各曲 [Song.duration]，并可从文件补全缺失时长。
abstract final class LibraryDurationStatistics {
  LibraryDurationStatistics._();

  static final ConcurrentLimiter _limiter = ConcurrentLimiter(
    !kIsWeb && Platform.isAndroid ? 3 : 5,
  );

  static ({Duration sum, int withDuration, int total}) sum(List<Song> songs) {
    var totalMs = 0;
    var withDuration = 0;
    for (final s in songs) {
      final d = s.duration;
      if (d == null || d.inMilliseconds <= 0) continue;
      withDuration++;
      totalMs += d.inMilliseconds;
    }
    return (
      sum: Duration(milliseconds: totalMs),
      withDuration: withDuration,
      total: songs.length,
    );
  }

  /// 为 [songs] 中尚无有效时长的条目读取标签（无封面/歌词），再返回汇总。
  static Future<({Duration sum, int withDuration, int total})>
      refreshMissingAndSum(List<Song> songs) async {
    if (kIsWeb || songs.isEmpty) {
      return sum(songs);
    }
    final missing = <Song>[];
    for (final s in songs) {
      if (s.playlistEntryMissingOnDevice) continue;
      final d = s.duration;
      if (d == null || d.inMilliseconds <= 0) {
        missing.add(s);
      }
    }
    final updatedPaths = <String>{};
    if (missing.isNotEmpty) {
      var done = 0;
      await Future.wait(
        List<Future<void>>.generate(missing.length, (i) async {
          final song = missing[i];
          await _limiter.acquire();
          try {
            try {
              await FileUtils.loadSongMeta(
                song,
                loadEmbeddedAlbumArt: false,
                storeLyricsWithTrack: false,
              );
              if (song.durationMs != null && song.durationMs! > 0) {
                updatedPaths.add(song.path);
              }
            } catch (e) {
              appLog.d('统计补全时长失败: ${song.path}', error: e);
            }
          } finally {
            _limiter.release();
            done++;
            if (done % 16 == 0) {
              await Future<void>.delayed(Duration.zero);
            }
          }
        }),
      );
    }
    await persistDurationsToHive(songs, extraPaths: updatedPaths);
    return sum(songs);
  }

  /// 将内存曲库中已有时长写入 Hive（须 [inMemoryFoldersForPersist] 已注册）。
  static Future<void> persistDurationsToHive(
    List<Song> songs, {
    Set<String> extraPaths = const {},
  }) async {
    if (kIsWeb) return;
    final paths = <String>{...extraPaths};
    for (final s in songs) {
      if (s.durationMs != null && s.durationMs! > 0) {
        paths.add(s.path);
      }
    }
    if (paths.isEmpty) return;
    await EmbeddedSongMetadataPersistScheduler.flushPending();
    await persistEmbeddedSongPaths(paths);
  }
}
