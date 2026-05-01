import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song_recognition_entry.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 本地听歌识曲历史（Hive）
class SongRecognitionHistoryService {
  static const String hiveKeyHistory = 'song_recognition_history_v1';
  static const int maxEntries = 300;

  static Future<List<SongRecognitionEntry>> loadAll() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(hiveKeyHistory);
      if (raw is! String || raw.isEmpty) return [];
      final list = SongRecognitionEntry.decodeList(raw);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeList(List<SongRecognitionEntry> list) async {
    final sorted = [...list]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    await box.put(hiveKeyHistory, SongRecognitionEntry.encodeList(sorted));
  }

  static Future<void> prepend(SongRecognitionEntry entry) async {
    try {
      final existing = await loadAll();
      final next = <SongRecognitionEntry>[entry, ...existing];
      if (next.length > maxEntries) {
        next.removeRange(maxEntries, next.length);
      }
      await _writeList(next);
    } catch (_) {}
  }

  static Future<void> updateEntry(SongRecognitionEntry entry) async {
    try {
      final existing = await loadAll();
      final i = existing.indexWhere((e) => e.id == entry.id);
      if (i < 0) return;
      existing[i] = entry;
      await _writeList(existing);
    } catch (_) {}
  }

  static Future<void> deleteById(String id) async {
    try {
      final existing = await loadAll();
      existing.removeWhere((e) => e.id == id);
      await _writeList(existing);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.delete(hiveKeyHistory);
    } catch (_) {}
  }
}
