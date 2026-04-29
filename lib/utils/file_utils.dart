import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show AudioMetadata, Picture, PictureType, readMetadata;
import 'package:charset/charset.dart';
import 'package:yeah_music/logging/app_log.dart';

import '../models/song.dart';

/// 与详情页 [_pickCoverBytes] 一致：优先封面图类型块再退回首张。
Uint8List? pickEmbeddedCoverBytesFromPictures(
  List<Picture>? pictures, {
  required bool embedTooLargeOkToDiscard,
  int? maxEmbeddedArtBytes,
}) {
  if (pictures == null || pictures.isEmpty) return null;
  Picture? front;
  for (final pic in pictures) {
    if (pic.pictureType == PictureType.coverFront && pic.bytes.isNotEmpty) {
      front = pic;
      break;
    }
  }
  final raw = front?.bytes ?? pictures.first.bytes;
  if (raw.isEmpty) return null;
  final limit = maxEmbeddedArtBytes;
  final tooBig = limit != null && raw.length > limit;
  if (tooBig) return embedTooLargeOkToDiscard ? null : raw;
  return raw;
}

class FileUtils {
  /// 读取音频元数据。
  ///
  /// - [loadEmbeddedAlbumArt]：若为 false（适合「整文件夹批量入库」），不解析内嵌大图，内存与 Hive 体积极大下降；
  ///   列表等处可走 [SongLibraryMetadataHydrator] 后台补全封面与歌词等，或由 [ApplicationUtils.getImageCoverProvider] 占位。
  /// - [storeLyricsWithTrack]：若为 false，不写入歌词（长文本占内存且扫描阶段不需要）。
  /// - [maxEmbeddedArtBytes]：非 null 时，首帧内嵌图超过该字节则不写入封面（避免 FLAC 巨幅图撑爆内存/Hive）。
  ///   因此同一格式下也可能出现「有的 FLAC 有封面、有的没有」（图源过大或被标签工具写成非首块等）。
  ///   不传则不对大小做裁剪（单次全量入库等场景）。
  static Future<void> loadSongMeta(
    Song song, {
    bool loadEmbeddedAlbumArt = true,
    bool storeLyricsWithTrack = true,
    int? maxEmbeddedArtBytes,
  }) async {
    String filename = song.path.split('/').last;
    File file = File(song.path);
    late final AudioMetadata metadata;
    var resolvedEmbedImages = loadEmbeddedAlbumArt;
    try {
      metadata = readMetadata(file, getImage: resolvedEmbedImages);
    } catch (e, st) {
      if (loadEmbeddedAlbumArt) {
        appLog.w('readMetadata 失败，尝试跳过内嵌图: $filename', error: e);
        try {
          metadata = readMetadata(file, getImage: false);
          resolvedEmbedImages = false;
        } catch (e2, st2) {
          song.title = filename;
          appLog.e('读取歌曲元信息失败', error: e2, stackTrace: st2);
          return;
        }
      } else {
        song.title = filename;
        appLog.e('读取歌曲元信息失败', error: e, stackTrace: st);
        return;
      }
    }
    String title = decodeString(metadata.title ?? filename);
    song.album = decodeString(metadata.album);
    song.artist = decodeString(metadata.artist);
    song.title = title;
    song.duration = metadata.duration;
    song.year = metadata.year;
    song.trackNumber = metadata.trackNumber;
    song.discNumber = metadata.discNumber;
    song.sampleRate = metadata.sampleRate;
    song.bitrate = metadata.bitrate;
    song.lyrics = storeLyricsWithTrack ? metadata.lyrics : null;
    song.pictures = resolvedEmbedImages ? metadata.pictures : null;
    if (resolvedEmbedImages &&
        song.pictures != null &&
        song.pictures!.isNotEmpty) {
      final raw = pickEmbeddedCoverBytesFromPictures(
        song.pictures,
        embedTooLargeOkToDiscard: true,
        maxEmbeddedArtBytes: maxEmbeddedArtBytes,
      );
      song.imageBytes = raw;
      if (song.imageBytes == null && loadEmbeddedAlbumArt) {
        song.pictures = null;
      }
    } else {
      song.imageBytes = null;
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
