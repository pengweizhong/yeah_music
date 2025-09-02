import 'package:flutter_test/flutter_test.dart';
import 'package:yeah_music/models/lyric.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_uitls.dart';

void main() {
  String path = "/home/rocky/OneDrive/音乐/Music/Shakira,Freshlyground - Waka Waka (This Time for Africa).mp3";

  group('SongUtils', () {
    late Song song;

    setUp(() {
      song = Song(path);
    });

    tearDown(() {
      // 比如删除临时文件
    });

    // test('loadMeta sets album', () {
    //   SongUtils.loadMeta(song);
    //   expect(song.title, isNotNull);
    //   print(song.lyrics);
    //   //读取歌曲头像
    //   print(song.pictures?.length);
    // });

    test('parseLyrics', () async {
     await SongUtils.loadMeta(song);
      // List<LyricLine> lines = SongUtils.parseLyrics(song.lyrics);
      // for (var value in lines) {
      //   print(value);
      // }
      print(song);
    });
    // test('loadFileStat', () async {
    //   SongUtils.loadFileStat(song);
    // });
  });
}
