import 'package:flutter/material.dart';

import '../../services/music_service.dart';

class PlayerControls extends StatelessWidget {
  final MusicService service;

  const PlayerControls({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // final player = service.getAudioPlayer();
    final currentTitle =
        (service.currentIndex >= 0 &&
            service.currentIndex < service.songs.length)
        ? service.songs[service.currentIndex].uri.pathSegments.last
        : "未播放";

    return Column(
      children: [
        Text(currentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        // 进度条
        StreamBuilder<Duration>(
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
              onChanged: (v) {
                service.seek(Duration(milliseconds: v.toInt()));
              },
            );
          },
        ),
        // 播放控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: service.playPrev,
            ),
            StreamBuilder<bool>(
              stream: service.playingStream,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    playing ? service.pause() : service.resume();
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: service.playNext,
            ),
          ],
        ),
      ],
    );
  }
}
