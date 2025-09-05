import 'package:yeah_music/models/song.dart';

class Playlist {
  ///歌单名称
  String name;

  ///歌曲列表
  List<Song> songs;

  Playlist({required this.name, List<Song>? songs}) : songs = songs ?? [];
}
