import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../services/music_service.dart';
import '../widgets/player_controls.dart';
import '../widgets/song_list.dart';
import '../widgets/song_slider.dart';
import '../widgets/song_title.dart';

var log = Logger(printer: SimplePrinter());

class MusicHomePage extends StatefulWidget {
  final MusicService service;

  const MusicHomePage({super.key, required this.service});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  MusicService get service => widget.service;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // 自动请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> pickFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
    // final folderPath = "/Users/rocky/Music/yeah_music";
    if (folderPath != null) {
      await service.loadSongs(folderPath);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown,
      appBar: AppBar(
        title: const Text("音乐播放器"),
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
          Expanded(child: SongList(service)),
          SongTitle(service: service),
          SongSlider(service: service),
          PlayerControls(service: service),
        ],
      ),
    );
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}
