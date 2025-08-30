import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/song.dart';

class SongCover extends StatelessWidget {
  final ValueNotifier<Song?> valueNotifierSong;

  //固定高度
  final double coverHeight;

  const SongCover({
    super.key,
    required this.valueNotifierSong,
    this.coverHeight = AppConfig.bottomCoverHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: valueNotifierSong,
      builder: (context, song, _) {
        return buildCover(song);
      },
    );
  }

  Widget buildCover(Song? song) {
    if (song == null || song.pictures == null || song.pictures!.isEmpty) {
      return const Icon(Icons.music_note, size: 100);
    }
    final coverBytes = song.pictures!.first.bytes;
    return SizedBox(
      height: coverHeight,
      width: coverHeight, // 正方形
      child: Image.memory(coverBytes, fit: BoxFit.cover),
    );
  }
}
