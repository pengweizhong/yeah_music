import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:charset/charset.dart'; // 支持 gbk
import 'package:logger/logger.dart';
import 'package:yeah_music/models/song.dart' hide readMetadata;

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
}
