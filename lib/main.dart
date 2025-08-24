import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yeah Music Player',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      home: const MusicHomePage(),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final player = AudioPlayer();
  List<FileSystemEntity> songs = [];
  int currentIndex = -1;

  Future<void> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      final dir = Directory(path);
      final files = dir
          .listSync()
          .where(
            (f) =>
                f.path.endsWith(".mp3") ||
                f.path.endsWith(".flac") ||
                f.path.endsWith(".m4a") ||
                f.path.endsWith(".wav"),
          )
          .toList();
      setState(() {
        songs = files;
        currentIndex = -1;
      });
    }
  }

  Future<void> playSong(int index) async {
    final song = songs[index];
    try {
      await player.stop(); // 停止之前的
      await player.setFilePath(song.path); // 设置新文件
      await player.play();
      setState(() {
        currentIndex = index;
      });
      debugPrint("正在播放: ${song.path}");
    } catch (e, st) {
      debugPrint("播放失败: $e");
      debugPrint("$st");
    }
  }

  void playNext() {
    if (songs.isEmpty) return;
    final next = (currentIndex + 1) % songs.length;
    playSong(next);
  }

  void playPrev() {
    if (songs.isEmpty) return;
    final prev = (currentIndex - 1 + songs.length) % songs.length;
    playSong(prev);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = (currentIndex >= 0 && currentIndex < songs.length)
        ? songs[currentIndex].uri.pathSegments.last
        : "未播放";

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
                final name = songs[index].uri.pathSegments.last;
                return ListTile(
                  title: Text(name),
                  selected: index == currentIndex,
                  onTap: () => playSong(index),
                );
              },
            ),
          ),
          // 播放控制区
          Column(
            children: [
              Text(
                currentTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final dur = player.duration ?? Duration.zero;
                  return Slider(
                    value: pos.inMilliseconds.toDouble().clamp(
                      0,
                      dur.inMilliseconds.toDouble(),
                    ),
                    max: dur.inMilliseconds.toDouble().clamp(
                      0,
                      double.infinity,
                    ),
                    onChanged: (v) {
                      player.seek(Duration(milliseconds: v.toInt()));
                    },
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: playPrev,
                  ),
                  StreamBuilder<bool>(
                    stream: player.playingStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          playing ? player.pause() : player.play();
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: playNext,
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
