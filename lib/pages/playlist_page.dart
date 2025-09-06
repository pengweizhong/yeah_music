import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/models/song.dart';

import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/folder.dart';

class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> {
  @override
  Widget build(BuildContext context) {
    PlayListProvider playListProvider = context.watch<PlayListProvider>();
    return Scaffold(
      appBar: AppBar(title: Text("歌曲列表")),
      body: ListView.builder(
        itemCount: playListProvider.playList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.music_note),
            title: Text(playListProvider.playList[index].title ?? "未知音乐"),
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
}
