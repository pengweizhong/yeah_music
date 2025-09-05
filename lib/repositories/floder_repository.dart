import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';

class FolderRepository {
  static Box<Folder> get _box => Hive.box<Folder>(Constant.hiveFolderBox);

  /// 获取所有文件夹
  static List<Folder> getAllFolders() {
    return _box.values.toList();
  }

  /// 添加文件夹
  static Future<void> addFolder(Folder folder) async {
    await _box.add(folder);
  }

  /// 删除文件夹
  static Future<void> deleteFolder(Folder folder) async {
    await folder.delete();
  }

  /// 更新文件夹
  static Future<void> updateFolder(Folder folder) async {
    await folder.save();
  }
}
