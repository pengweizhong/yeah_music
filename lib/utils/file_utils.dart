import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:charset/charset.dart';
import 'package:yeah_music/logging/app_log.dart';

import '../models/song.dart';

class FileUtils {
  static Future<void> loadSongMeta(Song song) async {
    final metadata;
    String filename = song.path.split("/").last;
    File file = File(song.path);
    try {
      metadata = readMetadata(file, getImage: true);
    } catch (e) {
      song.title = filename;
      appLog.e('读取歌曲元信息失败', error: e);
      return;
    }
    String title = decodeString(metadata.title ?? filename);
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
    if (song.pictures != null && song.pictures!.isNotEmpty) {
      song.imageBytes = song.pictures![0].bytes;
    }
    await loadFileStat(song);
  }

  static Future<void> loadFileStat(Song song) async {
    File file = File(song.path);
    // 获取文件状态信息
    final stat = await file.stat();
    song.createDateTime = stat.changed;
    song.updateDateTime = stat.modified;
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

  // 歌词解析请使用 `lib/utils/lyrics_utils.dart`（支持同一时间戳多行/多语言）

  // /// 打开文件夹
  // static Future<void> openFolder(String folderPath) async {
  //   if (Platform.isWindows) {
  //     // Windows
  //     await Process.run('explorer', [folderPath]);
  //   } else if (Platform.isMacOS) {
  //     // macOS
  //     await Process.run('open', [folderPath]);
  //   } else if (Platform.isLinux) {
  //     // Linux
  //     await Process.run('xdg-open', [folderPath]);
  //   } else {
  //     throw UnsupportedError('This platform is not supported');
  //   }
  // }
}
