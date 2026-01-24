/// 一个时间戳对应的一组歌词（支持同一时间戳多语言/多行）
class LyricEntry {
  final Duration? timestamp;
  final List<String> lines;
  bool isActive;

  LyricEntry({
    required this.timestamp,
    required this.lines,
    this.isActive = false,
  });

  @override
  String toString() {
    return 'LyricEntry{timestamp: $timestamp, lines: $lines, isActive: $isActive}';
  }
}

