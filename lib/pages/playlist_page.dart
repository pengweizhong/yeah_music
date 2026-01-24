import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';

import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/folder.dart';
import '../utils/application_utils.dart';

var log = Logger(printer: SimplePrinter());

@immutable
class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key}); // 这里可以保持 immutable

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> {
  @override
  void initState() {
    super.initState();
    // 使用postFrameCallback避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folderProvider = context.read<FolderProvider>();
      final playListProvider = context.read<PlayListProvider>();
      if (!playListProvider.initialized) {
        log.d("初始化全部歌单列表");
        playListProvider.init(folderProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    PlayListProvider playListProvider = context.watch<PlayListProvider>();
    return Scaffold(
      appBar: AppBar(title: Text("歌曲列表")),
      body: ListView.builder(
        itemCount: playListProvider.playList.length,
        itemBuilder: (context, index) {
          Song song = playListProvider.playList[index];
          return ListTile(
            leading: ClipRRect(
              child: Container(
                width: 48, // 固定大小
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white, // 背景填充白色
                  borderRadius: BorderRadius.circular(10), // 圆角
                ),
                child: Image(fit: BoxFit.cover, image: ApplicationUtils.getImageCoverProvider(song)),
              ),
            ),
            title: Text(song.title ?? "未知音乐"),
            subtitle: Text(showSecondTitle(song), style: TextStyle(color: Colors.grey.shade600)),
            onTap: () => navToSongPage(index, playListProvider),
          );
        },
      ),
    );
  }

  void addPlayList(List<Song> playList, FolderProvider folderProvider) {
    //所有的文件夹
    List<Folder> folders = folderProvider.folders;
    for (var value in folders) {
      log.d("添加了目录：${value.name}，共${value.songList?.length}首歌曲");
      if (value.songList == null || value.songList!.isEmpty) {
        continue;
      }
      playList.addAll(value.songList as Iterable<Song>);
    }
  }

  void navToSongPage(int index, PlayListProvider playListProvider) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SongPage(index: index)));
  }

  String showSecondTitle(Song song) {
    if (song.title == null) {
      return song.album ?? "";
    }
    if (song.album == null) {
      return song.title!;
    }
    return "${song.title} - ${song.album}";
  }
}
