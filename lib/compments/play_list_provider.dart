import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';

import '../models/folder.dart';
import 'folder_provider.dart';

class PlayListProvider extends ChangeNotifier {
  final List<Song> playList = [];

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
