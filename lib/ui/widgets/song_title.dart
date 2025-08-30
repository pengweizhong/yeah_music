import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../models/song.dart';
import '../../services/music_service.dart';

var log = Logger(printer: SimplePrinter());

class SongTitle extends StatelessWidget {
  final MusicService service;

  const SongTitle({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: service.valueNotifierSong,
      builder: (context, song, _) {
        final title = song?.title ?? "暂无歌曲";
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
