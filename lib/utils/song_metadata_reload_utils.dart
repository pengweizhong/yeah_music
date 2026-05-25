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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 磁盘上的音频文件被改写后，刷新内存/Hive 中所有指向该路径的 [Song] 实例。
Future<void> reloadAllSongInstancesAfterFileMetadataChanged(
  BuildContext context,
  String path, {
  int maxEmbeddedArtBytes = SongLibraryMetadataHydrator.maxEmbeddedArtBytes,
  void Function()? afterProvidersNotify,
}) async {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return;

  final folder = Provider.of<FolderProvider>(context, listen: false);
  final play = Provider.of<PlayListProvider>(context, listen: false);

  SongLibraryMetadataHydrator.invalidatePath(trimmed);

  Future<void> loadInto(Song s) async {
    await FileUtils.loadSongMeta(
      s,
      loadEmbeddedAlbumArt: true,
      storeLyricsWithTrack: true,
      maxEmbeddedArtBytes: maxEmbeddedArtBytes,
    );
    final fp = ApplicationUtils.coverBytesFingerprint(s.imageBytes);
    ApplicationUtils.evictSongCoverProvidersForPath(
      s.path,
      keepFingerprint: fp > 0 ? fp : null,
    );
    ApplicationUtils.notifySongCoverChanged(s.path);
  }

  final pending = <Song>[];
  void collect(Song? s) {
    if (s == null) return;
    if (!songPathsEqual(s.path, trimmed)) return;
    if (pending.any((x) => identical(x, s))) return;
    pending.add(s);
  }

  for (final f in folder.folders) {
    final list = f.songList;
    if (list == null) continue;
    for (final s in list) {
      collect(s);
    }
  }
  for (final s in play.libraryMergedSongs) {
    collect(s);
  }
  for (final s in play.playList) {
    collect(s);
  }
  collect(play.currentSong);

  for (final s in pending) {
    await loadInto(s);
  }

  if (pending.isNotEmpty) {
    await persistEmbeddedSongPaths({for (final s in pending) s.path});
  }

  if (!context.mounted) return;
  folder.notifySongMetadataChangedRemote();
  play.notifySongMetadataChangedRemote();
  afterProvidersNotify?.call();

  final cur = play.currentSong;
  if (cur != null &&
      songPathsEqual(cur.path, trimmed) &&
      await SettingsService.loadAndroidCarLyricsEnabled()) {
    await MusicService.pushAndroidNotificationForSong(cur);
  }
}
