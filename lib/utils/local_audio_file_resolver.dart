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

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 解析磁盘上真实存在的音频文件。
///
/// OneDrive 点播缓存常在应用私有目录（文件管理器里「隐藏」）；编辑标签后 [Song.path]
/// 若未更新或 Android 11+ 对外部路径 [File.exists] 受限，直接上传会误报「未找到音频文件」。
Future<File?> resolveExistingLocalAudioFile(
  String path, {
  List<Directory>? extraSearchRoots,
  bool requestAndroidBroadStorageIfNeeded = true,
}) async {
  final candidates = _pathCandidates(path);
  if (candidates.isEmpty) return null;

  Future<File?> probe(Iterable<String> paths) async {
    for (final c in paths) {
      try {
        final f = File(c);
        if (await f.exists()) return f;
      } catch (_) {}
    }
    if (requestAndroidBroadStorageIfNeeded && Platform.isAndroid) {
      final ok = await ensureAndroidManageExternalStorageAccess();
      if (ok) {
        for (final c in paths) {
          try {
            final f = File(c);
            if (await f.exists()) return f;
          } catch (_) {}
        }
      }
    }
    return null;
  }

  var hit = await probe(candidates);
  if (hit != null) return hit;

  final base = p.basename(candidates.first);
  if (base.isEmpty) return null;

  for (final c in candidates) {
    try {
      hit = await _matchBasenameInDirectory(Directory(p.dirname(c)), base);
      if (hit != null) return hit;
    } catch (_) {}
  }

  final roots = extraSearchRoots;
  if (roots != null) {
    for (final root in roots) {
      hit = await _searchUnderRoot(root, base);
      if (hit != null) {
        assert(() {
          if (!songPathsEqual(hit!.path, candidates.first)) {
            appLog.d(
              'resolveExistingLocalAudioFile: ${candidates.first} → ${hit.path}',
            );
          }
          return true;
        }());
        return hit;
      }
    }
  }

  return null;
}

List<String> _pathCandidates(String path) {
  final t = path.trim();
  if (t.isEmpty) return [];
  final out = <String>[];
  void add(String s) {
    final n = p.normalize(s);
    if (n.isEmpty) return;
    if (!out.contains(n)) out.add(n);
  }

  add(t);
  if (t.startsWith('file://')) {
    add(filePathFromMediaItemId(t));
  }
  try {
    add(File(t).absolute.path);
  } catch (_) {}
  return out;
}

Future<File?> _matchBasenameInDirectory(Directory dir, String base) async {
  if (!await dir.exists()) return null;
  final wantLower = base.toLowerCase();
  try {
    await for (final e in dir.list(followLinks: true)) {
      if (e is! File) continue;
      final bn = p.basename(e.path);
      if (bn == base || bn.toLowerCase() == wantLower) {
        try {
          if (await e.exists()) return e;
        } catch (_) {}
      }
    }
  } catch (_) {}
  return null;
}

Future<File?> _searchUnderRoot(Directory root, String base) async {
  if (!await root.exists()) return null;
  final wantLower = base.toLowerCase();
  try {
    await for (final e in root.list(recursive: true, followLinks: true)) {
      if (e is! File) continue;
      final bn = p.basename(e.path);
      if (!OneDriveConfig.isAudioOrOneDriveCachedFileName(bn) &&
          !OneDriveConfig.isAudioFileName(bn)) {
        continue;
      }
      if (bn == base || bn.toLowerCase() == wantLower) {
        try {
          if (await e.exists()) return e;
        } catch (_) {}
        continue;
      }
      final suffix =
          OneDriveConfig.cacheBasenameRemoteSuffixLower(bn.toLowerCase());
      if (suffix != null && suffix == wantLower) {
        try {
          if (await e.exists()) return e;
        } catch (_) {}
      }
    }
  } catch (_) {}
  return null;
}
