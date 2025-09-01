import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/config/app_config.dart';

import '../../services/bookmark_service.dart';
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
  late final Box settingsBox;
  String _searchQuery = "";
  String _sortOrder = "original"; // 默认按名称升序

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // 自动请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _restoreAndLoadSongs();
    });
    settingsBox = Hive.box('settings');
  }

  /// 加载上次保存的文件夹
  Future<void> _restoreAndLoadSongs() async {
    String? restoredPath;
    if (Platform.isMacOS) {
      // 恢复之前的书签
      restoredPath = await BookmarkService.restoreBookmark();
    } else {
      restoredPath = settingsBox.get('lastFolder') as String?;
    }
    log.d("上次打开的文件夹：$restoredPath");
    if (restoredPath != null) {
      await service.loadSongs(restoredPath);
      await service.flushPlaylist(service.audioSources);
      setState(() {});
    }
  }

  Future<void> pickFolder() async {
    final folderPath;
    if (Platform.isMacOS) {
      // 让用户选择目录，并在 Swift 侧保存书签
      folderPath = await BookmarkService.pickDirectory();
    } else {
      folderPath = await FilePicker.platform.getDirectoryPath();
    }
    if (folderPath != null) {
      await service.loadSongs(folderPath);
      await service.flushPlaylist(service.audioSources);
      // 保存到 Hive
      await settingsBox.put('lastFolder', folderPath);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistOverride = _getFilteredSongs();
    log.d("1111111111当前播放列表长度：${playlistOverride.length}");
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 搜索框
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "搜索歌曲...",
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.blueGrey,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      log.d("用户输入的搜索关键词：$val");
                      setState(() {
                        log.d("用户输入的搜索关键词：$val");
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 排序菜单
                DropdownButton<String>(
                  value: _sortOrder,
                  items: const [
                    DropdownMenuItem(value: "original", child: Text("默认")),
                    DropdownMenuItem(value: "nameAsc", child: Text("名称 ↑")),
                    DropdownMenuItem(value: "nameDesc", child: Text("名称 ↓")),
                    DropdownMenuItem(value: "durationAsc", child: Text("时长 ↑")),
                    DropdownMenuItem(
                      value: "durationDesc",
                      child: Text("时长 ↓"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      log.d("用户选择的排序方式：$val");
                      setState(() {
                        log.d("用户选择的排序方式：$val");
                        _sortOrder = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 上半部分：歌曲列表 or 歌词
          Expanded(
            child: _showLyrics
                ? LyricsView(
                    valueNotifierSong: service.valueNotifierSong,
                    valueNotifierDuration: service.valueNotifierDuration,
                  )
                : SongList(service, currentPlaylist: playlistOverride),
          ),

          // 下半部分：封面 + 控件
          Container(
            height: AppConfig.bottomHeight,
            color: Colors.grey, // 背景色
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // 让封面高度跟右侧一致
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
                        // Flexible(child: SongTitle(service: service)),
                        SongTitle(service: service),
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

  // 过滤 + 排序逻辑
  List<UriAudioSource> _getFilteredSongs() {
    var songs = service.audioSources;
    if (_searchQuery == "" && _sortOrder == "original") {
      return songs; // 不做排序，返回原列表副本
    }
    if (_searchQuery.isNotEmpty) {
      songs = songs
          .where(
            (s) =>
                s.tag.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    switch (_sortOrder) {
      case "original":
        break;
      case "nameAsc":
        songs.sort((a, b) => a.tag.title.compareTo(b.tag.title));
        break;
      case "nameDesc":
        songs.sort((a, b) => b.tag.title.compareTo(a.tag.title));
        break;
      case "durationAsc":
        songs.sort((a, b) => a.tag.duration.compareTo(b.tag.duration));
        break;
      case "durationDesc":
        songs.sort((a, b) => b.tag.duration.compareTo(a.tag.duration));
        break;
    }
    log.d("_getFilteredSongs 筛选后的播放列表长度：${songs.length}");
    Future.wait([service.flushPlaylist(songs)]);
    return songs;
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}
