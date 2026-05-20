// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:hive/hive.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';
import '../utils/folder_hive_lightweight.dart';

class FolderRepository {
  static LazyBox<Folder> get _box =>
      Hive.lazyBox<Folder>(Constant.hiveFolderBox);

  /// 获取所有文件夹
  static Future<List<Folder>> getAllFolders() async {
    final list = <Folder>[];
    for (final key in _box.keys) {
      final f = await _box.get(key);
      if (f != null) list.add(f);
    }
    return list;
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
    await FolderHiveLightweight.saveFolder(folder);
  }
}
