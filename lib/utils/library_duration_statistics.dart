// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/concurrent_limiter.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';

/// 统计页曲库元数据：时长汇总、从文件补全标签，并写入 Hive。
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

  /// 是否需从文件补读标签（时长和/或码率/采样率，后者用于音质分布）。
  static bool _needsMetadataRefresh(Song song) {
    if (song.playlistEntryMissingOnDevice) return false;
    final needsDuration =
        song.durationMs == null || song.durationMs! <= 0;
    final needsQuality = song.bitrate == null && song.sampleRate == null;
    return needsDuration || needsQuality;
  }

  static bool _metadataChanged(Song before, Song after) {
    if (before.durationMs != after.durationMs) return true;
    if (before.bitrate != after.bitrate) return true;
    if (before.sampleRate != after.sampleRate) return true;
    return false;
  }

  /// 补全缺失标签后汇总时长，并把 [durationMs]/[bitrate]/[sampleRate] 写入 Hive。
  static Future<({Duration sum, int withDuration, int total})>
      refreshMissingAndSum(List<Song> songs) async {
    if (kIsWeb || songs.isEmpty) {
      return sum(songs);
    }
    final missing = <Song>[];
    for (final s in songs) {
      if (_needsMetadataRefresh(s)) {
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
            final before = Song(song.path)
              ..durationMs = song.durationMs
              ..bitrate = song.bitrate
              ..sampleRate = song.sampleRate;
            try {
              await FileUtils.loadSongMeta(
                song,
                loadEmbeddedAlbumArt: false,
                storeLyricsWithTrack: false,
              );
              if (_metadataChanged(before, song)) {
                updatedPaths.add(song.path);
                invalidateSongAudioQualityCacheForPath(song.path);
              }
            } catch (e) {
              appLog.d('统计补全曲目标签失败: ${song.path}', error: e);
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
    await persistStatisticsMetadataToHive(songs, extraPaths: updatedPaths);
    return sum(songs);
  }

  /// 将内存曲库中已补全的统计相关字段写入 Hive（须 [inMemoryFoldersForPersist] 已注册）。
  static Future<void> persistStatisticsMetadataToHive(
    List<Song> songs, {
    Set<String> extraPaths = const {},
  }) async {
    if (kIsWeb) return;
    final paths = <String>{...extraPaths};
    for (final s in songs) {
      if (s.durationMs != null && s.durationMs! > 0) {
        paths.add(s.path);
      } else if (s.bitrate != null || s.sampleRate != null) {
        paths.add(s.path);
      }
    }
    if (paths.isEmpty) return;
    await EmbeddedSongMetadataPersistScheduler.flushPending();
    await persistEmbeddedSongPaths(paths);
  }

  @Deprecated('Use persistStatisticsMetadataToHive')
  static Future<void> persistDurationsToHive(
    List<Song> songs, {
    Set<String> extraPaths = const {},
  }) =>
      persistStatisticsMetadataToHive(songs, extraPaths: extraPaths);
}
