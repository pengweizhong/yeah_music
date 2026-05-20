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

import 'package:path/path.dart' as p;

/// 与全库/播放状态匹配路径时一致
String normSongPath(String path) {
  final t = path.trim();
  if (t.isEmpty) return '';
  return p.normalize(t).replaceAll(r'\', '/').toLowerCase();
}

/// [MediaItem.id] 可能为 `file:///...`
String filePathFromMediaItemId(String mediaId) {
  final t = mediaId.trim();
  if (t.startsWith('file://')) {
    try {
      return Uri.parse(t).toFilePath();
    } catch (_) {
      return t;
    }
  }
  return t;
}

bool mediaItemIdMatchesSongPath(String mediaId, String songPath) {
  return normSongPath(filePathFromMediaItemId(mediaId)) ==
      normSongPath(songPath);
}

bool songPathsEqual(String a, String b) => normSongPath(a) == normSongPath(b);
