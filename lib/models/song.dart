import 'dart:typed_data';

class Song {
  final String path; // 文件路径
  final String title; // 歌曲名
  final String artist; // 歌手
  final String album; // 专辑
  final Uint8List? cover; // 封面图片
  final String? lyrics; // 歌词
  final int? year; // 发行年份
  final Uri uri;     // 文件 URI

  Song({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    this.cover,
    this.lyrics,
    this.year,
  });

}
