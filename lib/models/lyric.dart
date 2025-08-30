class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

List<LyricLine> parseLrc(String? rawLyrics) {
  final lines = <LyricLine>[];
  if (rawLyrics == null) {
    return lines;
  }
  final regex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
  for (final line in rawLyrics.split('\n')) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final min = int.parse(match.group(1)!);
      final sec = double.parse(match.group(2)!);
      final text = match.group(3)!;
      lines.add(
        LyricLine(
          Duration(minutes: min, milliseconds: (sec * 1000).toInt()),
          text,
        ),
      );
    }
  }
  return lines;
}
