import 'package:flutter/material.dart';

import '../../services/music_service.dart';

class PlayerControls extends StatelessWidget {
  final MusicService service;

  const PlayerControls({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: () => service.playPrev(),
        ),
        StreamBuilder<bool>(
          stream: service.playingStream,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return IconButton(
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () => playing ? service.pause() : service.resume(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: () => service.playNext(),
        ),
      ],
    );
  }
}
