// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/app_product_info.dart';

/// 悬浮歌词窗口的位置与尺寸（独立引擎无法与主进程共用 Hive，故用 JSON 落盘）。
///
/// Linux 子引擎的 [getApplicationSupportDirectory] 可能与主进程不一致（可执行名 vs
/// application-id），因此桌面端统一写入固定应用 ID 目录，并在 [load] 时迁移旧路径。
abstract final class DesktopLyricsWindowGeometryStore {
  static const String _fileName = 'desktop_lyrics_window_geometry.json';

  /// 与 [linux/CMakeLists.txt] 中 APPLICATION_ID 一致。
  static const String linuxApplicationId = 'com.pengwz.yeah_music';

  static const double minWidth = 200;
  static const double minHeight = 80;
  static const double maxWidth = 8000;
  static const double maxHeight = 8000;

  static String get _appId {
    final pkg = AppProductInfo.packageName.trim();
    return pkg.isNotEmpty ? pkg : linuxApplicationId;
  }

  static String _linuxDataHome() {
    final xdg = Platform.environment['XDG_DATA_HOME'];
    if (xdg != null && xdg.isNotEmpty) return xdg;
    final home = Platform.environment['HOME'] ?? '';
    return p.join(home, '.local', 'share');
  }

  static Future<Directory> _canonicalDir() async {
    if (Platform.isLinux) {
      final dir = Directory(
        p.join(_linuxDataHome(), _appId, 'yeah_music'),
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final support = await getApplicationSupportDirectory();
    final sub = Directory(p.join(support.path, 'yeah_music'));
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return sub;
  }

  static Future<File> _canonicalFile() async {
    final dir = await _canonicalDir();
    return File(p.join(dir.path, _fileName));
  }

  /// 旧版/子引擎可能写入的路径（用于迁移）。
  static Future<List<File>> _legacyFiles() async {
    final files = <File>[];
    if (Platform.isLinux) {
      final dataHome = _linuxDataHome();
      for (final id in <String>['yeah_music', _appId]) {
        files.add(
          File(p.join(dataHome, id, 'yeah_music', _fileName)),
        );
      }
    }
    try {
      final support = await getApplicationSupportDirectory();
      files.add(File(p.join(support.path, 'yeah_music', _fileName)));
    } catch (_) {}
    return files;
  }

  static Rect? _rectFromJsonMap(Map<String, dynamic> j) {
    final x = (j['x'] as num?)?.toDouble();
    final y = (j['y'] as num?)?.toDouble();
    final w = (j['width'] as num?)?.toDouble();
    final h = (j['height'] as num?)?.toDouble();
    if (x == null || y == null || w == null || h == null) return null;
    if (w < minWidth || h < minHeight || w > maxWidth || h > maxHeight) {
      return null;
    }
    return Rect.fromLTWH(x, y, w, h);
  }

  static Rect? rectFromJsonMap(Map<dynamic, dynamic> raw) {
    final j = <String, dynamic>{};
    raw.forEach((k, v) {
      if (k is String) j[k] = v;
    });
    return _rectFromJsonMap(j);
  }

  static Future<Rect?> _readFile(File f) async {
    if (!await f.exists()) return null;
    final decoded = jsonDecode(await f.readAsString());
    if (decoded is! Map<String, dynamic>) return null;
    return _rectFromJsonMap(decoded);
  }

  /// 无效或文件不存在时返回 null。
  static Future<Rect?> load() async {
    try {
      final primary = await _readFile(await _canonicalFile());
      if (primary != null) return primary;

      for (final legacy in await _legacyFiles()) {
        final r = await _readFile(legacy);
        if (r != null) {
          await save(r);
          return r;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Rect bounds) async {
    try {
      final w = bounds.width.clamp(minWidth, maxWidth);
      final h = bounds.height.clamp(minHeight, maxHeight);
      final f = await _canonicalFile();
      await f.writeAsString(
        jsonEncode(<String, dynamic>{
          'x': bounds.left,
          'y': bounds.top,
          'width': w,
          'height': h,
        }),
        flush: true,
      );
    } catch (_) {}
  }
}
