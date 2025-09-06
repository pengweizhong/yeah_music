import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/models/song.dart';

import '../models/folder.dart';
import 'folder_provider.dart';

var log = Logger(printer: SimplePrinter());

class PlayListProvider extends ChangeNotifier {
  //key是用户选择的根目录
  LinkedHashMap<String, List<Song>> folderPlaylistMap = LinkedHashMap();

  bool _initialized = false;

  bool get initialized => _initialized;

  /// 把所有文件夹里的歌曲合并成一个大列表
  List<Song> get playList => folderPlaylistMap.values.expand((list) => list).toList();

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
      // if (value.songList == null || value.songList!.isEmpty) {
      //   continue;
      // }
      putFolder(value);
    }
  }

  void putFolder(Folder folder) {
    folderPlaylistMap.putIfAbsent(folder.path, () => folder.songList ?? []);
  }

  ///新增
  void flushAddPlaylist(Folder folder) {
    List<Song>? addSongs = folder.songList;
    // if (addSongs == null || addSongs.isEmpty) {
    //   return;
    // }
    putFolder(folder);
    // for (var value in addSongs) {
    //   if (!playList.contains(value)) {
    //     playList.add(value);
    //   }
    // }
    notifyListeners();
  }

  ///删除
  void flushRemovePlaylist(Folder folder) {
    // List<Song>? removeSongs = folder.songList;
    // if (removeSongs == null || removeSongs.isEmpty) {
    //   return;
    // }
    // for (var value in removeSongs) {
    //   if (playList.contains(value)) {
    //     playList.remove(value);
    //   }
    // }
    folderPlaylistMap.remove(folder.path);
    notifyListeners();
  }

  ///可能新增，也可能删除
  void flushPlaylist(Folder folder) {
    // //不包含就直接新增
    // if (!folderPlaylistMap.containsKey(folder.path)) {
    //   putFolder(folder);
    //   return;
    // }
    // //不存在歌单就无脑删除
    // if (folder.songList == null || folder.songList!.isEmpty) {
    //   folderPlaylistMap.remove(folder.path);
    //   return;
    // }
    // //进行对比更新,新增或者删除
    // List<Song>? cacheList = folderPlaylistMap[folder.path];
    // List<Song>? updateList = folder.songList;
    //感觉应该可以无脑更新   不用这么麻烦
    folderPlaylistMap.remove(folder.path);
    putFolder(folder);
    notifyListeners();
  }
}
