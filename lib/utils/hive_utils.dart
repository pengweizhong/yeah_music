import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/folder.dart';

/// [yeah_music_folders] LazyBox：禁用 Hive 自动压缩。
///
/// 压缩会把整个 `.hive` 载入内存重组；曲目多且含 [Song.imageBytes] 时极易 OOM（尤其 Android）。
/// 代价是删除/覆盖产生的空洞留在文件中，体积可能缓慢变大，通常优于崩溃。
bool hiveFolderLazyBoxCompactionStrategy(int entries, int deletedEntries) =>
    false;

class HiveUtils {
  HiveUtils._(); // 私有构造，防止实例化

  /// 初始化 Hive（Flutter 使用）
  static Future<void> init(String path) async {
    await Hive.initFlutter(path);
  }

  /// 打开一个 Box
  static Future<Box<T>> openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    } else {
      // 如果box已经打开，尝试获取
      try {
        final box = Hive.box(name);
        // 检查类型是否匹配
        if (box is Box<T>) {
          return box;
        } else {
          // 类型不匹配，关闭后重新打开
          await box.close();
          return await Hive.openBox<T>(name);
        }
      } catch (e) {
        // 类型不匹配，关闭后重新打开
        try {
          await Hive.box(name).close();
        } catch (_) {}
        return await Hive.openBox<T>(name);
      }
    }
  }

  /// 音乐源目录 box。[Hive.openBox] 会把整个 `.hive` 一次性读入内存（framesFromFile→readAsBytes），
  /// 大量曲目 + [Song.imageBytes] 时易 OOM；[LazyBox] 打开时仅流式扫描帧头（keysFromFile）。
  ///
  /// 对该 LazyBox **关闭 Hive 自动压缩**，避免 [StorageBackendVm.compact] 整文件读入导致低端机 OOM。
  static Future<LazyBox<Folder>> openFolderBox() async {
    final name = Constant.hiveFolderBox;
    if (!Hive.isBoxOpen(name)) {
      return Hive.openLazyBox<Folder>(
        name,
        compactionStrategy: hiveFolderLazyBoxCompactionStrategy,
      );
    }
    return Hive.lazyBox<Folder>(name);
  }

  /// [Hive.deleteBoxFromDisk] 失败时的兜底：按与 [Hive.initFlutter] 一致的目录删除 `.hive` / `.hivec` / `.lock`。
  static Future<void> deleteHiveBoxDiskFilesBestEffort(String boxName) async {
    if (kIsWeb) return;
    final lower = boxName.trim().toLowerCase();
    if (lower.isEmpty) return;
    try {
      await Hive.deleteBoxFromDisk(boxName);
      return;
    } catch (_) {}
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final root = appDir.path;
      for (final suffix in ['.hive', '.hivec', '.lock']) {
        try {
          final f = File(p.join(root, '$lower$suffix'));
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 获取 Box
  static Box<T> getBox<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw Exception("Box $name 未打开，请先调用 openBox");
    }
    return Hive.box<T>(name);
  }

  /// 保存单条数据（key-value）
  static Future<void> put<T>(String boxName, dynamic key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  /// 批量保存
  static Future<void> putAll<T>(String boxName, Map<dynamic, T> map) async {
    final box = await openBox<T>(boxName);
    await box.putAll(map);
  }

  /// 读取单条数据
  static T? get<T>(String boxName, dynamic key, {T? defaultValue}) {
    final box = getBox<T>(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  /// 删除单条数据
  static Future<void> delete<T>(String boxName, dynamic key) async {
    final box = getBox<T>(boxName);
    await box.delete(key);
  }

  /// 清空 Box
  static Future<void> clear<T>(String boxName) async {
    final box = getBox<T>(boxName);
    await box.clear();
  }

  /// 关闭 Box
  static Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  static Future<void> add<T>(BoxBase<T> box, T value) async {
    await box.add(value);
  }
}
