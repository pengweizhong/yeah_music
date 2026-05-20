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
import 'package:yeah_music/models/song.dart';

/// 列表主标题：嵌入标题优先，否则用文件名（无扩展）。
String songListPrimaryTitle(Song song) {
  final t = song.title?.trim();
  if (t != null && t.isNotEmpty) return t;
  return p.basenameWithoutExtension(song.path);
}

/// 列表副标题：艺人 · 专辑（与曲库页、用户歌单、最近播放等处一致）。
String songListSecondaryLine(Song song) {
  if (song.artist == null || song.artist!.isEmpty) {
    return song.album ?? '';
  }
  if (song.album == null || song.album!.isEmpty) {
    return song.artist!;
  }
  return '${song.artist} · ${song.album}';
}
