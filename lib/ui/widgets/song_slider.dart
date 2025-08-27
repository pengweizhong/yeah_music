import 'package:flutter/material.dart';
import 'package:yeah_music/services/music_service.dart';

class SongSlider extends StatelessWidget {
  final MusicService service;

  const SongSlider({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = service.duration ?? Duration.zero;
        return Slider(
          value: pos.inMilliseconds.toDouble().clamp(
            0,
            dur.inMilliseconds.toDouble(),
          ),
          max: dur.inMilliseconds.toDouble().clamp(0, double.infinity),
          onChanged: (v) => service.seek(Duration(milliseconds: v.toInt())),
        );
      },
    );
  }
}
