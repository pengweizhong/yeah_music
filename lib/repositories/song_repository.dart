import 'dart:io';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import '../models/song.dart';

class SongRepository {
  /// 从文件夹加载歌曲列表
  Future<List<Song>> loadSongs(String folderPath) async {
    final dir = Directory(folderPath);
    final files = dir.listSync().where(
      (f) =>
          f.path.endsWith(".mp3") ||
          f.path.endsWith(".flac") ||
          f.path.endsWith(".m4a") ||
          f.path.endsWith(".wav"),
    );

    List<Song> songs = [];
    for (var file in files) {
      try {
        final metadata = await MetadataRetriever.fromFile(File(file.path));
        songs.add(
          Song(
            path: file.path,
            title: metadata.trackName ?? file.uri.pathSegments.last,
            artist: metadata.trackArtistNames?.join(", ") ?? "未知歌手",
            album: metadata.albumName ?? "未知专辑",
            uri: file.uri,
            cover: metadata.albumArt,
            lyrics: null,
            // flutter_media_metadata 可能不支持歌词
            year: metadata.year,
          ),
        );
      } catch (e, st) {
        songs.add(
          Song(
            path: file.path,
            title: file.uri.pathSegments.last,
            artist: "未知歌手",
            album: "未知专辑",
            uri: file.uri,
          ),
        );
        print("解析歌曲失败: $e\n$st");
      }
    }
    return songs;
  }
}
