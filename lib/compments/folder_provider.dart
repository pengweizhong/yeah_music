import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';

import '../config/app_config.dart';
import '../models/folder.dart';

var log = Logger(printer: SimplePrinter());

class FolderProvider extends ChangeNotifier {
  //main 里调用了 ..init()，也不能保证 UI 构建时 _box 已经就绪。
  late Box<Folder>? _box;
  bool _initialized = false;

  List<Folder> get folders => _box?.values.toList() ?? [];

  bool get initialized => _initialized;

  /// 初始化 Hive Box
  Future<void> init() async {
    _box = await HiveUtils.openBox(Constant.hiveFolderBox);
    _initialized = true;
    notifyListeners();
  }

  /// 添加文件夹 ,添加成功就返回true
  Future<bool> addFolder(String folder) async {
    //检验文件夹是否已经存在
    if (await existFolder(_box!, folder)) {
      log.d("用户添加了重复的文件夹：$folder");
      return false;
    }
    String folderName = folder.split('/').last;
    final f = Folder(folder);
    f.name = folderName;
    f.createdAt = DateTime.now();
    await HiveUtils.add(_box!, f);
    flushSongToFolder(f, false);
    notifyListeners();
    return true;
  }

  /// 删除文件夹
  Future<void> deleteFolder(Folder folder) async {
    await folder.delete();
    notifyListeners();
  }

  /// 修改文件夹名称
  Future<void> renameFolder(Folder folder, String newName) async {
    folder.name = newName;
    await folder.save();
    notifyListeners();
  }

  /// 添加歌曲到文件夹
  Future<void> flushSongToFolder(Folder folder, bool listen) async {
    // folder.songPaths.add(songPath);
    //加载歌曲
    final dir = Directory(folder.path);
    // 筛选支持的音频文件格式
    final songFiles = dir.listSync().where((f) => AppConfig.supportedFormats.any((format) => f.path.endsWith(format)));
    log.d("文件夹${dir.path}下找到了${songFiles.length}首歌曲");
    List<Song> songlist = [];
    for (var value in songFiles) {
      Song song = new Song(value.path);
      FileUtils.loadSongMeta(song);
      songlist.add(song);
    }
    folder.songList = songlist;
    await folder.save();
    if (listen) {
      notifyListeners();
    }
  }

  ///文件夹是否已经存在
  ///存在 true，否则 false
  Future<bool> existFolder(Box box, String folder) async {
    return box.values.any((f) => f.path == folder);
  }
}
