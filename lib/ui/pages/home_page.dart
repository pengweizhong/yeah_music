import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/config/app_config.dart';

import '../../services/music_service.dart';
import '../widgets/lyric_view.dart';
import '../widgets/player_controls.dart';
import '../widgets/song_cover.dart';
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
  bool _showLyrics = false;

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
          // 上半部分：歌曲列表 or 歌词
          Expanded(
            child: _showLyrics
                ? LyricView(valueNotifierSong: service.valueNotifierSong)
                : SongList(service),
          ),

          // 下半部分：封面 + 控件
          Container(
            height: AppConfig.bottomHeight,
            color: Colors.grey, // 背景色
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // 让封面高度跟右侧一致
                children: [
                  // 左侧封面，包 GestureDetector
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLyrics = !_showLyrics; //  切换显示状态
                      });
                    },
                    child: Container(
                      width: AppConfig.bottomCoverHeight,
                      margin: const EdgeInsets.all(8),
                      child: SongCover(
                        valueNotifierSong: service.valueNotifierSong,
                      ),
                    ),
                  ),

                  // 右侧控件
                  Expanded(
                    child: Column(
                      // 高度只包裹子控件，Column 高度 = 子控件总高度
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: SongTitle(service: service)),
                        // SongTitle(service: service),
                        SongSlider(service: service),
                        PlayerControls(service: service),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
