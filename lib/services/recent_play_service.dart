import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 最近播放曲目（按文件路径去重，最新在前），以及各路径累计播放次数（与 [recordPath] 同步增加）。
class RecentPlayService {
  RecentPlayService._();

  static const String _hiveKey = 'recent_song_paths';
  static const String _playCountKey = 'song_play_count_map';

  /// Hive 中保留的最近播放路径上限（最新在前，超出则从末尾丢弃）。
  static const int maxStoredRecentPaths = 100;

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
        if (list.length > maxStoredRecentPaths) {
          list.removeRange(maxStoredRecentPaths, list.length);
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

  /// 从最近播放与播放次数中移除路径（曲目已从磁盘删除等）。
  static Future<void> removePathsAndCounts(Iterable<String> paths) async {
    final normSet = <String>{
      for (final t in paths)
        if (t.trim().isNotEmpty) normSongPath(t),
    };
    if (normSet.isEmpty) return;

    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final rawRecent = box.get(_hiveKey);
      if (rawRecent is List<dynamic>) {
        final list = rawRecent
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .where((e) => !normSet.contains(normSongPath(e)))
            .toList();
        await box.put(_hiveKey, list);
      }
      final rawCount = box.get(_playCountKey);
      if (rawCount is Map) {
        final countMap = <String, int>{};
        for (final e in rawCount.entries) {
          if (e.key is! String) continue;
          final k = (e.key as String).trim();
          if (k.isEmpty) continue;
          if (normSet.contains(normSongPath(k))) continue;
          countMap[k] = _asIntCount(e.value);
        }
        await box.put(_playCountKey, countMap);
      }
    } catch (_) {}
  }

  /// 最近列表与播放次数：将旧路径置换为新路径（文件重命名后）。
  static Future<void> migratePaths(Map<String, String> oldToNew) async {
    if (oldToNew.isEmpty) return;
    bool normEq(String a, String b) {
      final x = a.replaceAll(r'\', '/').toLowerCase();
      final y = b.replaceAll(r'\', '/').toLowerCase();
      return x == y;
    }

    String? findNewFor(String path) {
      for (final e in oldToNew.entries) {
        if (normEq(path, e.key)) return e.value;
      }
      return null;
    }

    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final rawRecent = box.get(_hiveKey);
      if (rawRecent is List<dynamic>) {
        final list = <String>[];
        for (final e in rawRecent.whereType<String>()) {
          final t = e.trim();
          if (t.isEmpty) continue;
          final n = findNewFor(t);
          list.add(n ?? t);
        }
        await box.put(_hiveKey, list);
      }
      final rawCount = box.get(_playCountKey);
      if (rawCount is Map) {
        final countMap = <String, int>{};
        for (final e in rawCount.entries) {
          if (e.key is! String) continue;
          final k = (e.key as String).trim();
          if (k.isEmpty) continue;
          countMap[k] = _asIntCount(e.value);
        }
        for (final e in oldToNew.entries) {
          final oldRaw = e.key.trim();
          final newRaw = e.value.trim();
          if (oldRaw.isEmpty || newRaw.isEmpty) continue;
          String? oldKey;
          for (final k in countMap.keys) {
            if (normEq(k, oldRaw)) {
              oldKey = k;
              break;
            }
          }
          if (oldKey == null) continue;
          final carry = countMap.remove(oldKey) ?? 0;
          if (carry <= 0) continue;
          String? mergeKey;
          for (final k in countMap.keys) {
            if (normEq(k, newRaw)) {
              mergeKey = k;
              break;
            }
          }
          if (mergeKey != null) {
            countMap[mergeKey] = (countMap[mergeKey] ?? 0) + carry;
          } else {
            countMap[newRaw] = (countMap[newRaw] ?? 0) + carry;
          }
        }
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

  /// 当前保存在 Hive 中的「最近播放」路径条数（最多 [maxStoredRecentPaths]）。
  static Future<int> getRecentListStoredCount() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_hiveKey);
      if (raw is! List<dynamic>) return 0;
      return raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// 播放次数映射：有记录的曲目数（次数 > 0）、累计播放事件总和。
  static Future<({int tracksWithCounts, int totalPlayEvents})>
      getPlayCountTotals() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_playCountKey);
      if (raw is! Map) {
        return (tracksWithCounts: 0, totalPlayEvents: 0);
      }
      var tracks = 0;
      var total = 0;
      for (final e in raw.entries) {
        if (e.key is! String) continue;
        final k = (e.key as String).trim();
        if (k.isEmpty) continue;
        final c = _asIntCount(e.value);
        if (c <= 0) continue;
        tracks++;
        total += c;
      }
      return (tracksWithCounts: tracks, totalPlayEvents: total);
    } catch (_) {
      return (tracksWithCounts: 0, totalPlayEvents: 0);
    }
  }
}
