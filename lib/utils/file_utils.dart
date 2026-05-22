// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/macos_file_access.dart';
import 'package:yeah_music/utils/wav_metadata_reader.dart';

import '../models/song.dart';

bool pathIsDsdAudio(String path) {
  final ext = p.extension(path).toLowerCase();
  return ext == '.dsf' || ext == '.dff';
}

/// 读取内嵌元数据；WAV 使用项目内修复实现（库内 RIFF 解析易错位导致标签全空）。
///
/// [repairLyrics] 为 false 时跳过对整文件的二次扫描（音乐源批量入库应关闭，否则极慢）。
AudioMetadata readEmbeddedAudioMetadata(
  File file, {
  bool getImage = false,
  bool repairLyrics = true,
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
  final metadata = readMetadata(file, getImage: getImage);
  if (repairLyrics) {
    final fixedLyrics = _repairPossiblyTruncatedEmbeddedLyrics(
      file: file,
      currentLyrics: metadata.lyrics,
    );
    if (fixedLyrics != null && fixedLyrics.trim().isNotEmpty) {
      metadata.lyrics = fixedLyrics;
    }
  }
  return metadata;
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
    /// Android 11+ 首次读盘遇 errno 13 时尝试请求「所有文件访问」后整体重试一次（避免通知/封面补载死循环）。
    bool storageUnlockRetryDone = false,
  }) async {
    final basename = p.basename(song.path);
    if (!kIsWeb && Platform.isMacOS) {
      await MacOsFileAccess.ensureForSongPath(song.path);
    }
    if (pathIsDsdAudio(song.path)) {
      song.title = p.basenameWithoutExtension(song.path);
      await loadFileStat(song);
      return;
    }
    File file = File(song.path);
    late final AudioMetadata metadata;
    var resolvedEmbedImages = loadEmbeddedAlbumArt;
    final repairLyrics = storeLyricsWithTrack;
    final filename = basename;

    Future<AudioMetadata> readMeta(bool image) async {
      if (!kIsWeb && image) {
        final path = song.path;
        return Isolate.run(() {
          final f = File(path);
          return readEmbeddedAudioMetadata(
            f,
            getImage: true,
            repairLyrics: repairLyrics,
          );
        });
      }
      return readEmbeddedAudioMetadata(
        file,
        getImage: image,
        repairLyrics: repairLyrics,
      );
    }

    Future<AudioMetadata> readMetaNoImage() async {
      // 批量入库（无内嵌图）：避免每首 Isolate.run 的开销。
      if (!kIsWeb && loadEmbeddedAlbumArt) {
        final path = song.path;
        return Isolate.run(() {
          final f = File(path);
          return readEmbeddedAudioMetadata(
            f,
            getImage: false,
            repairLyrics: repairLyrics,
          );
        });
      }
      return readEmbeddedAudioMetadata(
        file,
        getImage: false,
        repairLyrics: repairLyrics,
      );
    }

    try {
      if (resolvedEmbedImages) {
        metadata = await readMeta(true);
      } else {
        metadata = await readMetaNoImage();
      }
    } catch (e, st) {
      if (!storageUnlockRetryDone &&
          !kIsWeb &&
          Platform.isAndroid &&
          looksLikeAndroidStorageAccessDenied(e)) {
        await ensureAndroidManageExternalStorageAccess();
        await loadSongMeta(
          song,
          loadEmbeddedAlbumArt: loadEmbeddedAlbumArt,
          storeLyricsWithTrack: storeLyricsWithTrack,
          maxEmbeddedArtBytes: maxEmbeddedArtBytes,
          storageUnlockRetryDone: true,
        );
        return;
      }
      if (loadEmbeddedAlbumArt) {
        if (!kIsWeb &&
            Platform.isMacOS &&
            MacOsFileAccess.looksLikeAccessDenied(e)) {
          appLog.w(
            'macOS 无法读取该文件（请在 设置→音乐源 中重新选择对应文件夹）: $filename',
          );
          song.title = filename;
          return;
        }
        appLog.w('readMetadata 失败，尝试跳过内嵌图: $filename', error: e);
        try {
          metadata = await readMetaNoImage();
          resolvedEmbedImages = false;
        } catch (e2) {
          if (!storageUnlockRetryDone &&
              !kIsWeb &&
              Platform.isAndroid &&
              looksLikeAndroidStorageAccessDenied(e2)) {
            await ensureAndroidManageExternalStorageAccess();
            await loadSongMeta(
              song,
              loadEmbeddedAlbumArt: loadEmbeddedAlbumArt,
              storeLyricsWithTrack: storeLyricsWithTrack,
              maxEmbeddedArtBytes: maxEmbeddedArtBytes,
              storageUnlockRetryDone: true,
            );
            return;
          }
          song.title = filename;
          final msg = e2.toString();
          final short =
              msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
          if (!kIsWeb &&
              Platform.isMacOS &&
              MacOsFileAccess.looksLikeAccessDenied(e2)) {
            appLog.w(
              'macOS 无法读取该文件（请在 设置→音乐源 中重新选择对应文件夹）: $filename',
            );
          } else {
            appLog.w(
              '读取歌曲元信息失败（文件损坏或不完整）: $filename — $short',
            );
          }
          return;
        }
      } else {
        song.title = filename;
        if (!kIsWeb &&
            Platform.isMacOS &&
            MacOsFileAccess.looksLikeAccessDenied(e)) {
          appLog.w(
            'macOS 无法读取该文件（请在 设置→音乐源 中重新选择对应文件夹以授予访问权限）: $filename',
          );
        } else {
          appLog.e('读取歌曲元信息失败', error: e, stackTrace: st);
        }
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
    if (storeLyricsWithTrack) {
      song.lyrics = metadata.lyrics;
    }
    if (resolvedEmbedImages) {
      song.pictures = metadata.pictures;
    }
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
    } else if (loadEmbeddedAlbumArt) {
      song.imageBytes = null;
      song.pictures = null;
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

String? _repairPossiblyTruncatedEmbeddedLyrics({
  required File file,
  required String? currentLyrics,
}) {
  final ext = p.extension(file.path).toLowerCase();
  final now = currentLyrics?.trim() ?? '';

  try {
    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty) return currentLyrics;
    final chunks = <String>[];
    if (ext == '.mp3') {
      extractUsLtFromId3Haystack(bytes, chunks);
    } else if (ext == '.flac') {
      chunks.addAll(_extractLyricsFromFlacVorbisComment(bytes));
    }
    if (chunks.isEmpty) return currentLyrics;
    final best = _pickBestLyricsCandidate(chunks);
    if (best == null || best.trim().isEmpty) return currentLyrics;
    final fromReaderScore = _lyricsCandidateScore(now);
    final fromContainerScore = _lyricsCandidateScore(best.trim());
    if (fromContainerScore > fromReaderScore + 20) return best.trim();
  } catch (_) {}
  return currentLyrics;
}

List<String> _extractLyricsFromFlacVorbisComment(Uint8List bytes) {
  final out = <String>[];
  if (bytes.length < 8) return out;
  if (!(bytes[0] == 0x66 && bytes[1] == 0x4c && bytes[2] == 0x61 && bytes[3] == 0x43)) {
    return out;
  }
  var offset = 4;
  while (offset + 4 <= bytes.length) {
    final header = bytes[offset];
    final isLast = (header & 0x80) != 0;
    final blockType = header & 0x7f;
    final blockLen =
        (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += 4;
    if (offset + blockLen > bytes.length) break;
    if (blockType == 4) {
      final block = Uint8List.sublistView(bytes, offset, offset + blockLen);
      out.addAll(_parseVorbisLyricsComments(block));
    }
    offset += blockLen;
    if (isLast) break;
  }
  return out;
}

List<String> _parseVorbisLyricsComments(Uint8List block) {
  final out = <String>[];
  if (block.length < 8) return out;
  var off = 0;
  final vendorLen = _le32(block, off);
  off += 4;
  if (vendorLen < 0 || off + vendorLen > block.length) return out;
  off += vendorLen;
  if (off + 4 > block.length) return out;
  final commentCount = _le32(block, off);
  off += 4;
  for (var i = 0; i < commentCount; i++) {
    if (off + 4 > block.length) break;
    final len = _le32(block, off);
    off += 4;
    if (len < 0 || off + len > block.length) break;
    final raw = utf8.decode(Uint8List.sublistView(block, off, off + len), allowMalformed: true);
    off += len;
    final eq = raw.indexOf('=');
    if (eq <= 0) continue;
    final key = raw.substring(0, eq).trim().toUpperCase();
    final value = raw.substring(eq + 1).trim();
    if (value.isEmpty) continue;
    if (key == 'LYRICS' || key == 'UNSYNCEDLYRICS' || key == 'LYRIC' || key == 'LRC') {
      out.add(value);
    }
  }
  return out;
}

int _le32(Uint8List b, int o) {
  if (o + 4 > b.length) return -1;
  return b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);
}

bool _looksLikeTruncatedOrHeaderOnlyLyrics(String lyrics) {
  if (lyrics.isEmpty) return true;
  final lines = lyrics
      .split(RegExp(r'\r\n|\r|\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (lines.isEmpty) return true;

  final timedCount = RegExp(r'^\[\d{1,3}:[0-5]?\d(?:\.\d{1,3})?]').allMatches(lyrics).length;
  if (timedCount > 0) return false;

  final headerCount = lines
      .where((l) => RegExp(r'^\[[A-Za-z][A-Za-z0-9_-]{0,31}:[^\]]*]$').hasMatch(l))
      .length;
  // 只有少量头信息、没有时间轴，基本可判为“读到了开头但正文没拿到”。
  if (headerCount >= 2 && lines.length <= 8) return true;

  // 常见被截断特征：URL/标签行未闭合。
  if (lyrics.contains('[re:') && !lyrics.contains(']')) return true;
  if (lyrics.contains('https://') && !lyrics.contains('\n[')) return true;
  return false;
}

String? _pickBestLyricsCandidate(List<String> chunks) {
  String? best;
  var bestScore = -1 << 30;
  for (final c in chunks) {
    final t = c.trim();
    if (t.isEmpty) continue;
    final timed = RegExp(r'^\[\d{1,3}:[0-5]?\d(?:\.\d{1,3})?]', multiLine: true)
        .allMatches(t)
        .length;
    final headers =
        RegExp(r'^\[[A-Za-z][A-Za-z0-9_-]{0,31}:[^\]]*]$', multiLine: true)
            .allMatches(t)
            .length;
    var score = t.length + timed * 120 + headers * 8;
    if (timed == 0 && headers > 0) score -= 200;
    if (_looksLikeTruncatedOrHeaderOnlyLyrics(t)) score -= 300;
    if (score > bestScore) {
      bestScore = score;
      best = t;
    }
  }
  return best;
}

int _lyricsCandidateScore(String lyrics) {
  final t = lyrics.trim();
  if (t.isEmpty) return -100000;
  final timed = RegExp(r'^\[\d{1,3}:[0-5]?\d(?:\.\d{1,3})?]', multiLine: true)
      .allMatches(t)
      .length;
  final headers =
      RegExp(r'^\[[A-Za-z][A-Za-z0-9_-]{0,31}:[^\]]*]$', multiLine: true)
          .allMatches(t)
          .length;
  var score = t.length + timed * 120 + headers * 8;
  if (timed == 0 && headers > 0) score -= 200;
  if (_looksLikeTruncatedOrHeaderOnlyLyrics(t)) score -= 300;
  return score;
}
