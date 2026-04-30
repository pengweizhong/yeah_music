import 'package:hive/hive.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';

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
    await folder.save();
  }
}
