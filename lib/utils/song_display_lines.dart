import 'package:yeah_music/models/song.dart';

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
