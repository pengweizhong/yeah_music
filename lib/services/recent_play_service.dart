import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 最近播放曲目（按文件路径去重，最新在前）
class RecentPlayService {
  RecentPlayService._();

  static const String _hiveKey = 'recent_song_paths';
  static const int _maxItems = 40;

  static Future<void> recordPath(String path) async {
    final t = path.trim();
    if (t.isEmpty) return;
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_hiveKey);
      final list = <String>[
        if (raw is List<dynamic>)
          ...raw.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty),
      ];
      list.remove(t);
      list.insert(0, t);
      if (list.length > _maxItems) {
        list.removeRange(_maxItems, list.length);
      }
      await box.put(_hiveKey, list);
    } catch (_) {}
  }

  /// 返回路径列表（最新在前）
  static Future<List<String>> getPaths({int limit = 20}) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_hiveKey);
      if (raw is! List<dynamic>) return [];
      final list = raw.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (limit <= 0) return list;
      if (list.length <= limit) return list;
      return list.sublist(0, limit);
    } catch (_) {
      return [];
    }
  }
}
