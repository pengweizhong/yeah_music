import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../models/lyric.dart';
import '../../models/song.dart';

var log = Logger(printer: SimplePrinter());

class LyricsView extends StatefulWidget {
  final ValueNotifier<Song?> valueNotifierSong; //歌曲
  final ValueNotifier<Duration> valueNotifierDuration; //播放进度
  const LyricsView({
    super.key,
    required this.valueNotifierSong,
    required this.valueNotifierDuration,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  late List<LyricLine> lyricsLines = []; //歌曲文件
  int _currentLine = 0;

  @override
  void initState() {
    super.initState();
    widget.valueNotifierDuration.addListener(_updateCurrentLine);
  }

  void _updateCurrentLine() {
    final pos = widget.valueNotifierDuration.value.inMilliseconds;
    int newIndex = 0;
    for (int i = 0; i < lyricsLines.length; i++) {
      if (lyricsLines[i].time.inMilliseconds <= pos) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (_currentLine != newIndex) {
      _currentLine = newIndex;
      _scrollToCurrentLine();
      setState(() {});
    }
  }

  void _scrollToCurrentLine() {
    final itemHeight = 40.0; // 每行高度，可以根据实际调整
    final targetOffset = (_currentLine * itemHeight) - 100; // 让当前行稍微居中
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    widget.valueNotifierDuration.removeListener(_updateCurrentLine);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: widget.valueNotifierSong,
      builder: (context, song, _) {
        log.d("刷新歌词");
        lyricsLines = parseLrc(widget.valueNotifierSong.value?.lyrics);
        if (lyricsLines.isEmpty) {
          return const Center(
            child: Text(
              "暂无歌词",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          itemCount: lyricsLines.length,
          itemBuilder: (context, index) {
            final line = lyricsLines[index];
            final isCurrent = index == _currentLine;
            return Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                line.text,
                style: TextStyle(
                  color: isCurrent ? Colors.blue : Colors.white,
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
