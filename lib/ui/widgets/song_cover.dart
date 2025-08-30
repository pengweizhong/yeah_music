import 'package:flutter/material.dart';

import '../../models/song.dart';

class SongCover extends StatelessWidget {
  final ValueNotifier<Song?> valueNotifierSong;
  final double width;

  const SongCover({
    super.key,
    required this.valueNotifierSong,
    this.width = 150,
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
    return AspectRatio(
      aspectRatio: 1,
      child: Image.memory(coverBytes, fit: BoxFit.cover),
    );
  }
}
