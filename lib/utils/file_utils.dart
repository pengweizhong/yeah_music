import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show AudioMetadata, Picture, PictureType, readMetadata;
import 'package:charset/charset.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/utils/wav_metadata_reader.dart';

import '../models/song.dart';

/// 读取内嵌元数据；WAV 使用项目内修复实现（库内 RIFF 解析易错位导致标签全空）。
AudioMetadata readEmbeddedAudioMetadata(
  File file, {
  bool getImage = false,
}) {
  if (pathLooksLikeWav(file.path)) {
    try {
      return readWavMetadataYep(file, getImage: getImage);
    } catch (e, st) {
      appLog.w(
        'WAV 元数据解析失败，回退 audio_metadata_reader: ${file.path}',
        error: e,
        stackTrace: st,
      );
    }
  }
  return readMetadata(file, getImage: getImage);
}

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
    Future<AudioMetadata> readMeta(bool image) async {
      if (!kIsWeb && image) {
        final path = song.path;
        return Isolate.run(() {
          final f = File(path);
          return readEmbeddedAudioMetadata(f, getImage: true);
        });
      }
      return readEmbeddedAudioMetadata(file, getImage: image);
    }

    Future<AudioMetadata> readMetaNoImage() async {
      if (!kIsWeb) {
        final path = song.path;
        return Isolate.run(() {
          final f = File(path);
          return readEmbeddedAudioMetadata(f, getImage: false);
        });
      }
      return readEmbeddedAudioMetadata(file, getImage: false);
    }

    try {
      if (resolvedEmbedImages) {
        metadata = await readMeta(true);
      } else {
        metadata = await readMeta(false);
      }
    } catch (e, st) {
      if (loadEmbeddedAlbumArt) {
        appLog.w('readMetadata 失败，尝试跳过内嵌图: $filename', error: e);
        try {
          metadata = await readMetaNoImage();
          resolvedEmbedImages = false;
        } catch (e2) {
          song.title = filename;
          final msg = e2.toString();
          final short =
              msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
          appLog.w(
            '读取歌曲元信息失败（文件损坏或不完整）: $filename — $short',
          );
          return;
        }
      } else {
        song.title = filename;
        appLog.e('读取歌曲元信息失败', error: e, stackTrace: st);
        return;
      }
    }
    String decodedTitle = decodeString(metadata.title ?? filename);
    if (embeddedDisplayTextLooksCorrupt(decodedTitle)) {
      decodedTitle = p.basenameWithoutExtension(song.path);
    }
    song.title = decodedTitle;

    song.album = _metaFieldOrEmpty(metadata.album);
    song.artist = _metaFieldOrEmpty(metadata.artist);
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

  static String _metaFieldOrEmpty(String? raw) {
    final s = decodeString(raw ?? '');
    return embeddedDisplayTextLooksCorrupt(s) ? '' : s;
  }

  /// 规范化展示用字符串：
  /// - Unicode 字面量（含中文）若无法 `latin1.encode` 则直接返回；
  /// - Latin‑1 可逆时再试 UTF‑8 / GBK / 误解码拉回，多套结果按可读性打分择优。
  static String decodeString(String? raw) {
    if (raw == null) return '';
    final t = raw.trim();
    if (t.isEmpty) return '';

    List<int>? bytes;
    try {
      bytes = latin1.encode(t);
    } catch (_) {
      return t;
    }

    final candidates = <String>{t};
    try {
      candidates.add(utf8.decode(bytes, allowMalformed: false).trim());
    } catch (_) {}
    try {
      candidates.add(gbk.decode(bytes).trim());
    } catch (_) {}
    final recovered = recoverLabelFromLatin1Misread(bytes).trim();
    if (recovered.isNotEmpty) {
      candidates.add(recovered);
    }

    String best = '';
    var bestScore = -999999;
    if (!looksLikeGbkOfUtf8Garbage(t) && !containsUnicodeReplacementChar(t)) {
      best = t;
      bestScore = tagEmbeddingTextScoreForUi(t);
    }
    for (final s in candidates) {
      final x = s.trim();
      if (x.isEmpty) continue;
      if (looksLikeGbkOfUtf8Garbage(x)) continue;
      if (containsUnicodeReplacementChar(x)) continue;
      final sc = tagEmbeddingTextScoreForUi(x);
      if (sc > bestScore ||
          (sc == bestScore && x.length > best.length)) {
        bestScore = sc;
        best = x;
      }
    }
    if (best.isEmpty) best = t;
    return normalizeLatin1MisreadUtf8(best);
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
