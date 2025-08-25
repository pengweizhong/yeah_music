import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/audio_provider.dart';
import '../../repositories/song_repository.dart';
import '../widgets/song_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final repo = SongRepository();

  Future<void> pickFolder() async {
    final songs = await repo.pickFolder();
    ref.read(songListProvider.notifier).state = songs;
    ref.read(currentIndexProvider.notifier).state = -1;
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(songListProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final currentSong = (currentIndex >= 0 && currentIndex < songs.length)
        ? songs[currentIndex]
        : null;
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🍎 MacOS 音乐播放器 MVP"),
        actions: [
          IconButton(
            onPressed: pickFolder,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return SongTile(
                  song: songs[index],
                  selected: index == currentIndex,
                  onTap: () async {
                    await audioService.playSong(songs[index]);
                    ref.read(currentIndexProvider.notifier).state = index;
                  },
                );
              },
            ),
          ),
          if (currentSong != null)
            Column(
              children: [
                Text(
                  currentSong.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                StreamBuilder(
                  stream: audioService.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = audioService.duration ?? Duration.zero;
                    return Slider(
                      value: pos.inMilliseconds.toDouble().clamp(
                        0,
                        dur.inMilliseconds.toDouble(),
                      ),
                      max: dur.inMilliseconds.toDouble().clamp(
                        0,
                        double.infinity,
                      ),
                      onChanged: (v) =>
                          audioService.seek(Duration(milliseconds: v.toInt())),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        if (songs.isEmpty) return;
                        final prev =
                            (currentIndex - 1 + songs.length) % songs.length;
                        audioService.playSong(songs[prev]);
                        ref.read(currentIndexProvider.notifier).state = prev;
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: audioService.playingStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          onPressed: () => playing
                              ? audioService.pause()
                              : audioService.resume(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        if (songs.isEmpty) return;
                        final next = (currentIndex + 1) % songs.length;
                        audioService.playSong(songs[next]);
                        ref.read(currentIndexProvider.notifier).state = next;
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
