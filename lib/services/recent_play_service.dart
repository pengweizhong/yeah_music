import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 最近播放曲目（按文件路径去重，最新在前），以及各路径累计播放次数（与 [recordPath] 同步增加）。
class RecentPlayService {
  RecentPlayService._();

  static const String _hiveKey = 'recent_song_paths';
  static const String _playCountKey = 'song_play_count_map';
  static const int _maxItems = 40;

  static int _asIntCount(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return 0;
  }

  /// [updateRecentList] 为 false 时跳过「最近播放」列表；[bumpPlayCount] 为 false 时跳过播放次数累计。
  static Future<void> recordPath(
    String path, {
    bool updateRecentList = true,
    bool bumpPlayCount = true,
  }) async {
    final t = path.trim();
    if (t.isEmpty) return;
    if (!updateRecentList && !bumpPlayCount) return;
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (updateRecentList) {
        final rawRecent = box.get(_hiveKey);
        final list = <String>[
          if (rawRecent is List<dynamic>)
            ...rawRecent.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty),
        ];
        list.remove(t);
        list.insert(0, t);
        if (list.length > _maxItems) {
          list.removeRange(_maxItems, list.length);
        }
        await box.put(_hiveKey, list);
      }
      if (bumpPlayCount) {
        final rawCount = box.get(_playCountKey);
        final countMap = <String, int>{};
        if (rawCount is Map) {
          for (final e in rawCount.entries) {
            if (e.key is! String) continue;
            final k = (e.key as String).trim();
            if (k.isEmpty) continue;
            countMap[k] = _asIntCount(e.value);
          }
        }
        countMap[t] = (countMap[t] ?? 0) + 1;
        await box.put(_playCountKey, countMap);
      }
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

  /// 按累计播放次数降序返回（次数相同则按路径字符串排序，保证稳定）
  static Future<List<({String path, int count})>> getTopByPlayCount({
    int limit = 20,
  }) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_playCountKey);
      if (raw is! Map) return [];
      final pairs = <({String path, int count})>[];
      for (final e in raw.entries) {
        if (e.key is! String) continue;
        final p = (e.key as String).trim();
        if (p.isEmpty) continue;
        final c = _asIntCount(e.value);
        if (c <= 0) continue;
        pairs.add((path: p, count: c));
      }
      pairs.sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.path.compareTo(b.path);
      });
      if (limit <= 0) return pairs;
      if (pairs.length <= limit) return pairs;
      return pairs.sublist(0, limit);
    } catch (_) {
      return [];
    }
  }
}
