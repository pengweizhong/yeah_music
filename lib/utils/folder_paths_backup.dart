import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/logging/app_log.dart';

import '../models/folder.dart';

const String _kBackupFileName = 'yeah_music_folder_sources_backup.json';

/// Hive「音乐源」若因 OOM 被清空，仍可从此文件恢复路径（不含曲目/封面，体积极小）。
class FolderPathsBackup {
  FolderPathsBackup._();

  static Future<File> _file() async {
    if (kIsWeb) throw UnsupportedError('folder backup');
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _kBackupFileName));
  }

  /// 当前持久化的路径条目（路径非空）。
  static Future<List<({String path, String? name})>> load() async {
    if (kIsWeb) return [];
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <({String path, String? name})>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final pathStr = '${item['path'] ?? ''}'.trim();
        if (pathStr.isEmpty) continue;
        final nameStr = item['name'];
        final name = nameStr is String && nameStr.trim().isNotEmpty
            ? nameStr.trim()
            : null;
        out.add((path: pathStr, name: name));
      }
      return out;
    } catch (e, st) {
      appLog.w('读取音乐源路径备份失败', error: e, stackTrace: st);
      return [];
    }
  }

  static Future<void> save(List<Folder> folders) async {
    if (kIsWeb) return;
    try {
      final list = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final f in folders) {
        final path = f.path.trim();
        if (path.isEmpty) continue;
        final key = path.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        list.add({
          'path': path,
          if (f.name != null && f.name!.trim().isNotEmpty) 'name': f.name,
        });
      }
      final f = await _file();
      await f.writeAsString(
        const JsonEncoder.withIndent('  ').convert(list),
        flush: true,
      );
    } catch (e, st) {
      appLog.w('写入音乐源路径备份失败', error: e, stackTrace: st);
    }
  }
}
