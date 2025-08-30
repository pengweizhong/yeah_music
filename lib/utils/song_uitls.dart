import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:charset/charset.dart'; // 支持 gbk
import 'package:logger/logger.dart';
import 'package:yeah_music/models/song.dart' hide readMetadata;

import '../models/lyric.dart';

var log = Logger(printer: SimplePrinter());

class SongUtils {
  static void loadMeta(Song song) {
    final metadata = readMetadata(File(song.path), getImage: true);
    String filename = song.path.split("/").last;
    String title = decodeString(metadata.title ?? filename);
    log.d("加载歌曲元信息: $title，原始文件名称: $filename");
    song.album = decodeString(metadata.album);
    song.artist = decodeString(metadata.artist);
    song.title = title;
    song.duration = metadata.duration;
    song.year = metadata.year;
    song.trackNumber = metadata.trackNumber;
    song.discNumber = metadata.discNumber;
    song.lyrics = metadata.lyrics;
    song.sampleRate = metadata.sampleRate;
    song.bitrate = metadata.bitrate;
    song.pictures = metadata.pictures;
  }

  ///尝试解码字符串，优先使用 UTF-8，如果失败则使用 GBK
  static String decodeString(String? raw) {
    if (raw == null) {
      return "";
    }
    try {
      return utf8.decode(raw.codeUnits); // 尝试 UTF-8
    } catch (_) {
      try {
        return gbk.decode(raw.codeUnits); // 尝试 GBK
      } catch (_) {
        return raw; // 都失败就返回原始
      }
    }
  }

  ///解析歌词文本  可以切换语言模式
  static List<LyricLine> parseLyrics(
    String? rawLyrics, {
    int switchLanguageIndex = 0,
  }) {
    final lines = <LyricLine>[];
    if (rawLyrics == null) {
      return lines;
    }
    final regex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    // String preTimeStr = '';
    // int count = 0;
    for (final line in rawLyrics.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = double.parse(match.group(2)!);
        // String nowTimeStr = min.toString() + "-" + sec.toString();
        // if (preTimeStr.isEmpty) {
        //   preTimeStr = nowTimeStr;
        // } else if (preTimeStr == nowTimeStr) {
        //   count++;
        // } else {
        //   count = 0;
        // }
        final text = match.group(3)!;
        lines.add(
          LyricLine(
            Duration(minutes: min, milliseconds: (sec * 1000).toInt()),
            text,
          ),
        );
      }
    }
    return lines;
  }
}
