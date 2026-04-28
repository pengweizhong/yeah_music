import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 悬浮歌词窗口的位置与尺寸（独立引擎无法与主进程共用 Hive，故用应用支持目录下的 JSON）。
abstract final class DesktopLyricsWindowGeometryStore {
  static const String _fileName = 'desktop_lyrics_window_geometry.json';

  static const double minWidth = 200;
  static const double minHeight = 80;
  static const double maxWidth = 8000;
  static const double maxHeight = 8000;

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final sub = Directory(p.join(dir.path, 'yeah_music'));
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return File(p.join(sub.path, _fileName));
  }

  /// 无效或文件不存在时返回 null。
  static Future<Rect?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final j = jsonDecode(await f.readAsString());
      if (j is! Map<String, dynamic>) return null;
      final x = (j['x'] as num?)?.toDouble();
      final y = (j['y'] as num?)?.toDouble();
      final w = (j['width'] as num?)?.toDouble();
      final h = (j['height'] as num?)?.toDouble();
      if (x == null || y == null || w == null || h == null) return null;
      if (w < minWidth || h < minHeight || w > maxWidth || h > maxHeight) {
        return null;
      }
      return Rect.fromLTWH(x, y, w, h);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Rect bounds) async {
    try {
      var w = bounds.width.clamp(minWidth, maxWidth);
      var h = bounds.height.clamp(minHeight, maxHeight);
      final f = await _file();
      await f.writeAsString(jsonEncode(<String, dynamic>{
        'x': bounds.left,
        'y': bounds.top,
        'width': w,
        'height': h,
      }));
    } catch (_) {}
  }
}
