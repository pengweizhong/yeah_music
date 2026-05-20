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

import 'package:yeah_music/models/lyric_entry.dart';

/// 歌词解析工具类
class LyricsUtils {
  /// 标准 LRC：`[mm:ss]`、`[mm:ss.ff]`（分:秒.毫秒/厘秒片段）。
  ///
  /// 另兼容不规范的 **点分** `[mm.ss]`、`[mm.ss.f]`：中间为 `.` 时表示仍为 **分·秒**，
  /// 第三段若仅为 `0` / `00` 等与 `[mm:ss]` 等价（后缀 `.0` 无额外精度）。
  static final RegExp _lrcTimestampLine = RegExp(
    r'\[(\d{2})([:.])(\d{2})(?:\.(\d{1,3}))?\]\s*(.*)',
  );

  /// 解析LRC格式歌词
  /// 支持格式：`[mm:ss.ff]`、`[mm:ss]`、`[mm.ss]`、`[mm.ss.f]` 或纯文本
  ///
  /// 多语言/翻译歌词常见形式：同一时间戳出现多行文本：
  /// [00:10.00]日文
  /// [00:10.00]中文翻译
  /// 这里会聚合成同一个条目（LyricEntry.lines = [日文, 中文翻译]）
  static List<LyricEntry> parseLyrics(String? rawLyrics) {
    final entries = <LyricEntry>[];

    if (rawLyrics == null || rawLyrics.trim().isEmpty) {
      return entries;
    }

    bool isLrcFormat = false;

    // 先检查是否包含 LRC 时间戳（冒号或点分，避免把 [ti:xxx] 等误判为时间轴）
    for (final line in rawLyrics.split('\n')) {
      if (_lrcTimestampLine.hasMatch(line.trim())) {
        isLrcFormat = true;
        break;
      }
    }

    if (isLrcFormat) {
      // 解析LRC格式，并按时间戳聚合多行
      final Map<Duration, List<String>> grouped = {};

      for (final line in rawLyrics.split('\n')) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        final matches = _lrcTimestampLine.allMatches(trimmedLine);
        if (matches.isEmpty) {
          // 可能是标签：[ar:], [ti:], [by:] 等，直接忽略
          continue;
        }

        // 一行可能含多个时间戳（例如 [00:01.00][00:02.00]同一句）
        // 这种情况下，同一句会被加入多个时间点
        String? text;
        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(3)!);
          final fracRaw = match.group(4);
          // 与历史实现一致：将 1～3 位片段 pad 成毫秒字段再取前三位
          final milliseconds = fracRaw != null && fracRaw.isNotEmpty
              ? int.parse(fracRaw.padRight(3, '0').substring(0, 3))
              : 0;

          text ??= (match.group(5)?.trim() ?? '');
          if (text.isEmpty) continue;

          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );
          grouped.putIfAbsent(timestamp, () => <String>[]).add(text);
        }
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
      for (final ts in sortedKeys) {
        final lines = grouped[ts] ?? const <String>[];
        if (lines.isEmpty) continue;
        entries.add(LyricEntry(timestamp: ts, lines: List<String>.from(lines)));
      }
    } else {
      // 纯文本格式，按行分割
      for (final line in rawLyrics.split('\n')) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty) {
          entries.add(LyricEntry(timestamp: null, lines: [trimmedLine]));
        }
      }
    }

    return entries;
  }

  /// 根据当前播放时间找到对应的歌词行索引
  static int findCurrentLyricIndex(
    List<LyricEntry> lyrics,
    Duration currentPosition,
  ) {
    if (lyrics.isEmpty) return -1;

    // 纯文本歌词：无时间戳，外部单行展示（系统通知等）固定用第一行
    if (!lyrics.any((e) => e.timestamp != null)) {
      return 0;
    }

    // 初始阶段：当前时间还没到第一句，也把索引定位到 0（保证首次进入就能高亮/滚动到第一句）
    final firstTs = lyrics.first.timestamp;
    if (firstTs != null && currentPosition < firstTs) {
      return 0;
    }

    // 找到最后一个时间戳小于等于当前时间的歌词行
    for (int i = lyrics.length - 1; i >= 0; i--) {
      final line = lyrics[i];
      if (line.timestamp != null && line.timestamp! <= currentPosition) {
        return i;
      }
    }

    return -1;
  }

  /// 格式化时间显示
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
