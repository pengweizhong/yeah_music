import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/models/song.dart';

import '../models/folder.dart';
import 'folder_provider.dart';

var log = Logger(printer: SimplePrinter());

class PlayListProvider extends ChangeNotifier {
  final List<Song> playList = [];
  bool _initialized = false;

  bool get initialized => _initialized;

  /// 从 FolderProvider 加载歌曲
  Future<void> init(FolderProvider folderProvider) async {
    //若本身已经被初始化
    if (_initialized) {
      return;
    }
    // 等待 FolderProvider 初始化
    if (!folderProvider.initialized) {
      await folderProvider.init();
    }
    // 遍历所有文件夹
    _addPlayList(folderProvider);
    _initialized = true;
    notifyListeners();
  }

  void _addPlayList(FolderProvider folderProvider) {
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

  void flushAddPlaylist(Folder folder) {
    List<Song>? addSongs = folder.songList;
    if (addSongs == null || addSongs.isEmpty) {
      return;
    }
    for (var value in addSongs) {
      if (!playList.contains(value)) {
        playList.add(value);
      }
    }
    notifyListeners();
  }

  void flushRemovePlaylist(Folder folder) {
    List<Song>? removeSongs = folder.songList;
    if (removeSongs == null || removeSongs.isEmpty) {
      return;
    }
    for (var value in removeSongs) {
      if (playList.contains(value)) {
        playList.remove(value);
      }
    }
    notifyListeners();
  }
}
