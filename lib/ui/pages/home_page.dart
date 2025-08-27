import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/music_service.dart';
import '../widgets/player_controls.dart';
import '../widgets/song_list.dart';
import '../widgets/song_slider.dart';
import '../widgets/song_tile.dart';

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
    // final folderPath = "/Users/rocky/Music/yeah_music";
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
      backgroundColor: Colors.brown,
      appBar: AppBar(
        title: const Text("歌曲"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            onPressed: pickFolder,
            icon: const Icon(Icons.folder_open),
            tooltip: "选择文件夹",
            color: Colors.green,
          ),
        ],
      ),
      body: Column(
        children: [
          SongList(service),
          SongTitle(title: currentTitle),
          SongSlider(service: service),
          PlayerControls(service: service),
        ],
      ),
    );
  }
}
