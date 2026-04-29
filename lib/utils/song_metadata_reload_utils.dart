import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// 磁盘上的音频文件被改写后，刷新内存/Hive 中所有指向该路径的 [Song] 实例。
Future<void> reloadAllSongInstancesAfterFileMetadataChanged(
  BuildContext context,
  String path, {
  int maxEmbeddedArtBytes = 512 * 1024,
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
    try {
      await s.save();
    } catch (_) {}
    ApplicationUtils.evictSongCoverProvidersForPath(s.path);
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

  if (!context.mounted) return;
  folder.notifySongMetadataChangedRemote();
  play.notifySongMetadataChangedRemote();
  afterProvidersNotify?.call();

  final cur = play.currentSong;
  if (cur != null && songPathsEqual(cur.path, trimmed)) {
    await MusicService.pushAndroidNotificationForSong(cur);
  }
}
