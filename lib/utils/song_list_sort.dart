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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 排序维度。全库列表仅使用前三种（持久化键：`sort_type` / `sort_ascending`）；
/// [addedToPlaylist] 仅用于用户歌单（持久化键：`user_playlist_sort_type` 等）。
enum SongListSortType {
  name,
  createTime,
  modifyTime,

  /// 按加入当前歌单的先后顺序（需传入 [sortSongsCopy] 的 `pathAddIndex`）
  addedToPlaylist,
}

class SongSortPreferences {
  const SongSortPreferences({required this.type, required this.ascending});

  final SongListSortType type;
  final bool ascending;
}

/// 单次排序前从磁盘读取的时间（与 Finder / 资源管理器「修改日期」一致）
class _DiskTimes {
  const _DiskTimes({this.modified, this.changed});

  final DateTime? modified;
  final DateTime? changed;
}

/// 按路径读真实文件时间，避免 Hive / 后台 hydrate 与磁盘不一致导致排序乱跳。
Map<String, _DiskTimes> _prefetchDiskTimes(List<Song> songs) {
  if (kIsWeb) return {};
  final m = <String, _DiskTimes>{};
  for (final s in songs) {
    final p = s.path.trim();
    if (p.isEmpty) continue;
    try {
      final st = File(p).statSync();
      m[p] = _DiskTimes(modified: st.modified, changed: st.changed);
    } catch (_) {}
  }
  return m;
}

SongSortPreferences songSortPreferencesReadFromBox(Box<dynamic> box) {
  final raw = box.get('sort_type', defaultValue: 0) as int?;
  final asc = box.get('sort_ascending', defaultValue: true) as bool?;
  var idx = raw ?? 0;
  if (idx < 0) idx = 0;
  final max = SongListSortType.modifyTime.index;
  if (idx > max) idx = max;
  return SongSortPreferences(
    type: SongListSortType.values[idx],
    ascending: asc ?? true,
  );
}

List<Song> sortSongsCopy(
  List<Song> songs,
  SongListSortType type,
  bool ascending, {
  Map<String, int>? pathAddIndex,
}) {
  final out = List<Song>.from(songs);
  int rankAdded(String path) => pathAddIndex?[path] ?? 1 << 30;

  final disk =
      (type == SongListSortType.modifyTime || type == SongListSortType.createTime)
      ? _prefetchDiskTimes(out)
      : null;

  out.sort((a, b) {
    int result = 0;
    switch (type) {
      case SongListSortType.name:
        result = (a.title ?? '').compareTo(b.title ?? '');
        break;
      case SongListSortType.createTime:
        final da = disk?[a.path];
        final db = disk?[b.path];
        final aTime =
            da?.changed ??
            a.createDateTime ??
            da?.modified ??
            a.updateDateTime ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            db?.changed ??
            b.createDateTime ??
            db?.modified ??
            b.updateDateTime ??
            DateTime.fromMillisecondsSinceEpoch(0);
        result = aTime.compareTo(bTime);
        break;
      case SongListSortType.modifyTime:
        final da = disk?[a.path];
        final db = disk?[b.path];
        final aTime = da?.modified ?? a.updateDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = db?.modified ?? b.updateDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        result = aTime.compareTo(bTime);
        break;
      case SongListSortType.addedToPlaylist:
        if (pathAddIndex == null || pathAddIndex.isEmpty) {
          result = (a.title ?? '').compareTo(b.title ?? '');
        } else {
          result = rankAdded(a.path).compareTo(rankAdded(b.path));
        }
        break;
    }
    // 主键相同时用路径二次排序，次序稳定（不随升/降翻转路径比较）。
    if (result != 0) {
      return ascending ? result : -result;
    }
    return a.path.compareTo(b.path);
  });
  return out;
}

Future<SongSortPreferences> loadSongSortPreferences() async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  return songSortPreferencesReadFromBox(box);
}

/// 同步读取（Hive 已初始化后）；失败则默认按曲名升序。
SongSortPreferences loadSongSortPreferencesSync() {
  try {
    final box = HiveUtils.getBox<dynamic>(Constant.hiveRootPath);
    return songSortPreferencesReadFromBox(box);
  } catch (_) {
    return const SongSortPreferences(
      type: SongListSortType.name,
      ascending: true,
    );
  }
}

/// 用户歌单页排序偏好（含「加入歌单时间」）
Future<SongSortPreferences> loadUserPlaylistSortPreferences() async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  final rawUser = box.get('user_playlist_sort_type') as int?;
  if (rawUser == null) {
    return loadSongSortPreferences();
  }
  final asc = box.get('user_playlist_sort_ascending', defaultValue: true) as bool?;
  var idx = rawUser;
  if (idx < 0) idx = 0;
  final max = SongListSortType.values.length - 1;
  if (idx > max) idx = max;
  return SongSortPreferences(
    type: SongListSortType.values[idx],
    ascending: asc ?? true,
  );
}

Future<void> saveUserPlaylistSortPreferences(SongListSortType type, bool ascending) async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  await box.put('user_playlist_sort_type', type.index);
  await box.put('user_playlist_sort_ascending', ascending);
}

Future<void> saveSongSortPreferences(SongListSortType type, bool ascending) async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  await box.put('sort_type', type.index);
  await box.put('sort_ascending', ascending);
}
