import 'package:flutter_test/flutter_test.dart';
import 'package:yeah_music/models/lyric.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_uitls.dart';

void main() {
  String path = "test/resources/花澤香菜 - 恋愛サーキュレーション.flac";

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

    test('parseLyrics', () {
      SongUtils.loadMeta(song);
      List<LyricLine> lines = SongUtils.parseLyrics(song.lyrics);
      for (var value in lines) {
        print(value);
      }
    });
  });
}
