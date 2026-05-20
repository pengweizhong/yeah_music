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
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/folder.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 删除磁盘文件并刷新文件夹扫描、用户歌单与最近播放。
Future<void> deleteLibrarySongsAndRefresh({
  required FolderProvider folderProvider,
  required PlayListProvider playListProvider,
  required UserPlaylistProvider userPlaylistProvider,
  required List<Song> songs,
}) async {
  if (songs.isEmpty) return;
  if (Platform.isAndroid) {
    await ensureAndroidManageExternalStorageAccess();
  }
  final paths = songs.map((s) => s.path).toList();
  final normSet = {for (final s in songs) normSongPath(s.path)};

  for (final path in paths) {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    SongLibraryMetadataHydrator.invalidatePath(path);
  }

  await userPlaylistProvider.removePathsFromAllPlaylists(paths);
  await RecentPlayService.removePathsAndCounts(paths);

  final foldersToRefresh = <Folder>[];
  for (final folder in folderProvider.folders) {
    final list = folder.songList;
    if (list == null || list.isEmpty) continue;
    if (list.any((song) => normSet.contains(normSongPath(song.path)))) {
      foldersToRefresh.add(folder);
    }
  }
  for (var i = 0; i < foldersToRefresh.length; i++) {
    await folderProvider.flushSongToFolder(
      foldersToRefresh[i],
      i == foldersToRefresh.length - 1,
    );
  }
  for (final folder in foldersToRefresh) {
    playListProvider.flushPlaylist(folder);
  }
}

/// 单首重命名：仅改主文件名（保留扩展名），逻辑与批量重命名后的迁移一致。
Future<void> renameLibrarySongToStem({
  required FolderProvider folderProvider,
  required PlayListProvider playListProvider,
  required UserPlaylistProvider userPlaylistProvider,
  required Song song,
  required String newStem,
}) async {
  final oldPath = song.path.trim();
  if (oldPath.isEmpty) return;
  if (Platform.isAndroid) {
    await ensureAndroidManageExternalStorageAccess();
  }
  final f = File(oldPath);
  if (!await f.exists()) return;
  final ext = p.extension(oldPath);
  final dir = p.dirname(oldPath);
  var stem = newStem.trim();
  if (stem.isEmpty) stem = 'track';
  var dest = p.join(dir, '$stem$ext');
  if (await File(dest).exists()) {
    var k = 1;
    while (await File(dest).exists()) {
      dest = p.join(dir, '${stem}_$k$ext');
      k++;
      if (k > 9999) break;
    }
  }
  if (normSongPath(dest) == normSongPath(oldPath)) {
    return;
  }
  try {
    await f.rename(dest);
    SongLibraryMetadataHydrator.invalidatePath(oldPath);
  } catch (_) {
    return;
  }

  await userPlaylistProvider.replaceSongPathInAllPlaylists(oldPath, dest);
  await RecentPlayService.migratePaths({oldPath: dest});

  final normOld = normSongPath(oldPath);
  final foldersToRefresh = <Folder>[];
  for (final folder in folderProvider.folders) {
    final list = folder.songList;
    if (list == null || list.isEmpty) continue;
    if (list.any((s) => normSongPath(s.path) == normOld)) {
      foldersToRefresh.add(folder);
    }
  }
  for (var i = 0; i < foldersToRefresh.length; i++) {
    await folderProvider.flushSongToFolder(
      foldersToRefresh[i],
      i == foldersToRefresh.length - 1,
    );
  }
  for (final folder in foldersToRefresh) {
    playListProvider.flushPlaylist(folder);
  }
}

/// 在同一文件夹复制曲目为新主文件名（保留扩展名）；不改用户歌单与最近播放。
///
/// 成功返回目标路径；路径无效、源不存在或与原名冲突导致目标等于源路径时返回 `null`。
Future<String?> cloneLibrarySongToStem({
  required FolderProvider folderProvider,
  required PlayListProvider playListProvider,
  required Song song,
  required String newStem,
}) async {
  final oldPath = song.path.trim();
  if (oldPath.isEmpty) return null;
  if (Platform.isAndroid) {
    await ensureAndroidManageExternalStorageAccess();
  }
  final src = File(oldPath);
  if (!await src.exists()) return null;
  final ext = p.extension(oldPath);
  final dir = p.dirname(oldPath);
  var stem = newStem.trim();
  if (stem.isEmpty) stem = 'track';
  var dest = p.join(dir, '$stem$ext');
  if (await File(dest).exists()) {
    var k = 1;
    while (await File(dest).exists()) {
      dest = p.join(dir, '${stem}_$k$ext');
      k++;
      if (k > 9999) break;
    }
  }
  if (normSongPath(dest) == normSongPath(oldPath)) {
    return null;
  }
  try {
    await src.copy(dest);
  } catch (_) {
    return null;
  }
  SongLibraryMetadataHydrator.invalidatePath(dest);

  final normOld = normSongPath(oldPath);
  final foldersToRefresh = <Folder>[];
  for (final folder in folderProvider.folders) {
    final list = folder.songList;
    if (list == null || list.isEmpty) continue;
    if (list.any((s) => normSongPath(s.path) == normOld)) {
      foldersToRefresh.add(folder);
    }
  }
  for (var i = 0; i < foldersToRefresh.length; i++) {
    await folderProvider.flushSongToFolder(
      foldersToRefresh[i],
      i == foldersToRefresh.length - 1,
    );
  }
  for (final folder in foldersToRefresh) {
    playListProvider.flushPlaylist(folder);
  }
  return dest;
}

/// 按列表顺序重命名；[namePattern] 含 `%n` 时替换为递增序号，否则为 `pattern_序号`。
Future<void> renameLibrarySongsWithPattern({
  required FolderProvider folderProvider,
  required PlayListProvider playListProvider,
  required UserPlaylistProvider userPlaylistProvider,
  required List<Song> songsInOrder,
  required String namePattern,
  required int startNumber,
}) async {
  if (songsInOrder.isEmpty) return;
  final migrations = <String, String>{};
  var num = startNumber;
  for (final song in songsInOrder) {
    final oldPath = song.path.trim();
    if (oldPath.isEmpty) {
      num++;
      continue;
    }
    final f = File(oldPath);
    if (!await f.exists()) {
      num++;
      continue;
    }
    final ext = p.extension(oldPath);
    final dir = p.dirname(oldPath);
    final rawPattern = namePattern.trim();
    final baseName = rawPattern.contains('%n')
        ? rawPattern.replaceAll('%n', '$num').trim()
        : '${rawPattern}_$num'.trim();
    num++;
    var stem = baseName;
    if (stem.isEmpty) stem = 'track';
    var dest = p.join(dir, '$stem$ext');
    if (await File(dest).exists()) {
      var k = 1;
      while (await File(dest).exists()) {
        dest = p.join(dir, '${stem}_$k$ext');
        k++;
        if (k > 9999) break;
      }
    }
    if (normSongPath(dest) == normSongPath(oldPath)) {
      continue;
    }
    try {
      await f.rename(dest);
      migrations[oldPath] = dest;
      SongLibraryMetadataHydrator.invalidatePath(oldPath);
    } catch (_) {}
  }
  if (migrations.isEmpty) return;

  for (final e in migrations.entries) {
    await userPlaylistProvider.replaceSongPathInAllPlaylists(e.key, e.value);
  }
  await RecentPlayService.migratePaths(migrations);

  final normOld = migrations.keys.map(normSongPath).toSet();
  final foldersToRefresh = <Folder>[];
  for (final folder in folderProvider.folders) {
    final list = folder.songList;
    if (list == null || list.isEmpty) continue;
    if (list.any((song) => normOld.contains(normSongPath(song.path)))) {
      foldersToRefresh.add(folder);
    }
  }
  for (var i = 0; i < foldersToRefresh.length; i++) {
    await folderProvider.flushSongToFolder(
      foldersToRefresh[i],
      i == foldersToRefresh.length - 1,
    );
  }
  for (final folder in foldersToRefresh) {
    playListProvider.flushPlaylist(folder);
  }
}
