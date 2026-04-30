import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 最近播放曲目（按文件路径去重，最新在前），以及各路径累计播放次数（与 [recordPath] 同步增加）。
class RecentPlayService {
  RecentPlayService._();

  /// Hive：最近播放路径列表（最新在前）。
  static const String hiveKeyRecentSongPaths = 'recent_song_paths';

  /// Hive：各路径累计播放次数。
  static const String hiveKeySongPlayCountMap = 'song_play_count_map';

  /// Hive：累计收听墙钟毫秒（与 [MusicService] 周期落盘一致）。
  static const String hiveKeyTotalListenedWallMs = 'total_listened_wall_clock_ms';

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
        final rawRecent = box.get(hiveKeyRecentSongPaths);
        final list = <String>[
          if (rawRecent is List<dynamic>)
            ...rawRecent.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty),
        ];
        list.remove(t);
        list.insert(0, t);
        if (list.length > maxStoredRecentPaths) {
          list.removeRange(maxStoredRecentPaths, list.length);
        }
        await box.put(hiveKeyRecentSongPaths, list);
      }
      if (bumpPlayCount) {
        final rawCount = box.get(hiveKeySongPlayCountMap);
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
        await box.put(hiveKeySongPlayCountMap, countMap);
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
      final rawRecent = box.get(hiveKeyRecentSongPaths);
      if (rawRecent is List<dynamic>) {
        final list = rawRecent
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .where((e) => !normSet.contains(normSongPath(e)))
            .toList();
        await box.put(hiveKeyRecentSongPaths, list);
      }
      final rawCount = box.get(hiveKeySongPlayCountMap);
      if (rawCount is Map) {
        final countMap = <String, int>{};
        for (final e in rawCount.entries) {
          if (e.key is! String) continue;
          final k = (e.key as String).trim();
          if (k.isEmpty) continue;
          if (normSet.contains(normSongPath(k))) continue;
          countMap[k] = _asIntCount(e.value);
        }
        await box.put(hiveKeySongPlayCountMap, countMap);
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
      final rawRecent = box.get(hiveKeyRecentSongPaths);
      if (rawRecent is List<dynamic>) {
        final list = <String>[];
        for (final e in rawRecent.whereType<String>()) {
          final t = e.trim();
          if (t.isEmpty) continue;
          final n = findNewFor(t);
          list.add(n ?? t);
        }
        await box.put(hiveKeyRecentSongPaths, list);
      }
      final rawCount = box.get(hiveKeySongPlayCountMap);
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
        await box.put(hiveKeySongPlayCountMap, countMap);
      }
    } catch (_) {}
  }

  /// 返回路径列表（最新在前）
  static Future<List<String>> getPaths({int limit = 20}) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(hiveKeyRecentSongPaths);
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
      final raw = box.get(hiveKeySongPlayCountMap);
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

  /// 累计「播放器处于播放状态」的墙上时钟毫秒（由播放层分段写入 Hive）。
  static Future<int> getTotalListenedMilliseconds() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(hiveKeyTotalListenedWallMs);
      return _asIntCount(v);
    } catch (_) {
      return 0;
    }
  }

  /// 累加收听毫秒（忽略非正增量）。
  static Future<void> addListenedMilliseconds(int deltaMs) async {
    if (deltaMs <= 0) return;
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final cur = _asIntCount(box.get(hiveKeyTotalListenedWallMs));
      await box.put(hiveKeyTotalListenedWallMs, cur + deltaMs);
    } catch (_) {}
  }

  /// 当前保存在 Hive 中的「最近播放」路径条数（最多 [maxStoredRecentPaths]）。
  static Future<int> getRecentListStoredCount() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(hiveKeyRecentSongPaths);
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
    final map = await getPlayCountMap();
    var tracks = 0;
    var total = 0;
    for (final c in map.values) {
      tracks++;
      total += c;
    }
    return (tracksWithCounts: tracks, totalPlayEvents: total);
  }

  /// 路径 → 累计播放次数（路径为 Hive 中存的原样 trimmed，与 [recordPath] 写入一致）。
  static Future<Map<String, int>> getPlayCountMap() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(hiveKeySongPlayCountMap);
      if (raw is! Map) return {};
      final out = <String, int>{};
      for (final e in raw.entries) {
        if (e.key is! String) continue;
        final k = (e.key as String).trim();
        if (k.isEmpty) continue;
        final c = _asIntCount(e.value);
        if (c <= 0) continue;
        out[k] = c;
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
