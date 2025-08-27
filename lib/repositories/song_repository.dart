import 'dart:io';

import 'package:yeah_music/config/app_config.dart';

import '../models/song.dart';

class SongRepository {
  /// 从文件夹加载歌曲列表
  Future<List<Song>> loadSongs(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw Exception('文件夹不存在: $folderPath');
    }

    // 筛选支持的音频文件格式
    final files = dir.listSync().where(
      (f) =>
          AppConfig.supportedFormats.any((format) => f.path.endsWith(format)),
    );

    List<Song> songs = [];
    for (var file in files) {
      songs.add(Song(file.path, file.path.split("/").last));
    }
    return songs;
  }
}
