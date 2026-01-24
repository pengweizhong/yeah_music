import 'package:hive_flutter/hive_flutter.dart';

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
          return box as Box<T>;
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

  static Future<void> add<T>(Box<T> box, T value) async {
    await box.add(value);
  }
}
