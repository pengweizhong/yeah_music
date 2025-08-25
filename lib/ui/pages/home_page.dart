import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/music_service.dart';

class MusicHomePage extends StatefulWidget {
  final MusicService service;

  const MusicHomePage({super.key, required this.service});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  MusicService get service => widget.service;

  Future<void> pickFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null) {
      await service.loadSongs(folderPath);
      setState(() {});
    }
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = service.currentSong?.title ?? "未播放";

    return Scaffold(
      appBar: AppBar(
        title: const Text("🍎 Yeah Music Player"),
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
              itemCount: service.songs.length,
              itemBuilder: (context, index) {
                final song = service.songs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  selected: index == service.currentIndex,
                  onTap: () =>
                      service.playSong(index).then((_) => setState(() {})),
                );
              },
            ),
          ),
          Column(
            children: [
              Text(
                currentTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                    max: dur.inMilliseconds.toDouble().clamp(
                      0,
                      double.infinity,
                    ),
                    onChanged: (v) =>
                        service.seek(Duration(milliseconds: v.toInt())),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => setState(() => service.playPrev()),
                  ),
                  StreamBuilder<bool>(
                    stream: service.playingStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () => setState(
                          () => playing ? service.pause() : service.resume(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => setState(() => service.playNext()),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
