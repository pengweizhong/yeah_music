class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);

  @override
  String toString() {
    return 'time: $time, text: $text ';
  }
}
