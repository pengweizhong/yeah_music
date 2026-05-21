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

import 'package:yeah_music/compments/bookmark_service.dart';

/// macOS 沙盒下读本地音频前恢复安全作用域书签。
abstract final class MacOsFileAccess {
  MacOsFileAccess._();

  /// 是否为沙盒/TCC 拒绝访问（errno 1 Operation not permitted 等）。
  static bool looksLikeAccessDenied(Object error) {
    if (!Platform.isMacOS) return false;
    if (error is FileSystemException) {
      final code = error.osError?.errorCode;
      if (code == 1 || code == 13) return true;
      final msg = '${error.message} ${error.path}'.toLowerCase();
      if (msg.contains('operation not permitted') ||
          msg.contains('permission denied')) {
        return true;
      }
    }
    final s = error.toString().toLowerCase();
    return s.contains('pathaccess') ||
        s.contains('operation not permitted') ||
        s.contains('errno = 1') ||
        s.contains('permission denied');
  }

  /// 读标签/播放前：恢复与 [filePath] 所属音乐目录匹配的书签。
  static Future<void> ensureForSongPath(String filePath) async {
    if (!Platform.isMacOS || filePath.isEmpty) return;

    final restored = await BookmarkService.restoreAllBookmarks();
    for (final root in restored) {
      if (_isUnderRoot(filePath, root)) return;
    }

    final parts = filePath.split('/');
    for (var i = parts.length - 1; i >= 2; i--) {
      final candidate = parts.sublist(0, i).join('/');
      if (candidate.isEmpty) continue;
      final one = await BookmarkService.restoreBookmark(candidate);
      if (one != null && _isUnderRoot(filePath, one)) return;
    }
  }

  static bool _isUnderRoot(String filePath, String root) {
    if (filePath == root) return true;
    final prefix = root.endsWith('/') ? root : '$root/';
    return filePath.startsWith(prefix);
  }
}
