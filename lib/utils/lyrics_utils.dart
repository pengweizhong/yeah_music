import 'package:yeah_music/models/lyric_entry.dart';

/// 歌词解析工具类
class LyricsUtils {
  /// 解析LRC格式歌词
  /// 支持格式：[mm:ss.ff] 或 [mm:ss] 或纯文本
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

    // 检查是否为LRC格式（包含时间戳）
    final lrcRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\]\s*(.*)');
    bool isLrcFormat = false;

    // 先检查是否包含LRC格式的时间戳
    for (final line in rawLyrics.split('\n')) {
      if (lrcRegex.hasMatch(line.trim())) {
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

        final matches = lrcRegex.allMatches(trimmedLine);
        if (matches.isEmpty) {
          // 可能是标签：[ar:], [ti:], [by:] 等，直接忽略
          continue;
        }

        // 一行可能含多个时间戳（例如 [00:01.00][00:02.00]同一句）
        // 这种情况下，同一句会被加入多个时间点
        String? text;
        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final milliseconds = match.group(3) != null
              ? int.parse(match.group(3)!.padRight(3, '0').substring(0, 3))
              : 0;

          text ??= (match.group(4)?.trim() ?? '');
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
  static int findCurrentLyricIndex(List<LyricEntry> lyrics, Duration currentPosition) {
    if (lyrics.isEmpty) return -1;

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
