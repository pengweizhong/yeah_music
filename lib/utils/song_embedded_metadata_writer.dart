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

import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show MetadataParserException, Picture, PictureType;
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show
        CommonMetadataSetters,
        Mp3Metadata,
        Mp4Metadata,
        ParserTag,
        RiffMetadata,
        VorbisMetadata;
import 'package:path/path.dart' as p;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/third_party/audio_metadata_reader/riff_writer_fixed.dart';
import 'package:yeah_music/third_party/audio_metadata_reader/write_metadata_with_lyrics.dart';
import 'package:yeah_music/utils/wav_metadata_reader.dart' show pathLooksLikeWav;
import 'package:yeah_music/utils/wav_riff_metadata_bridge.dart'
    show readAllMetadataForWrite;

/// 内嵌封面在保存时的语义（其余图片帧在非 replace 时尽量保留）。
enum EmbeddedCoverEditKind {
  /// 保持 [readAllMetadata] 读到的图片列表不变。
  unchanged,

  /// 去掉「封面前置」类型（[PictureType.coverFront]）；其它插图保留。
  removed,

  /// 用 JPEG/PNG 字节替换前置封面（需提供 [replacementCoverBytes]）。
  replacedWithBytes,
}

/// 使用 [audio_metadata_reader] 将常见字段写回音频文件内嵌标签。
/// MP3 / FLAC 会通过补丁写入 USLT / Vorbis LYRICS，便于再次读取歌词。
///
/// - 先 [readAllMetadataForWrite] 完整读入再改字段（WAV 用项目内 RIFF 读取），尽量保留库能解析的内容。
/// - MP3 写入时会剔除文件原有 ID3v2 后再 prepend（见 [Id3v4WriterWithUslt]），避免叠标签损坏文件。
/// - MP4/M4A 使用修正后的写入器写回原路径（上游曾错误写入 `a_new.mp4`）。
Future<void> writeEmbeddedTagsForPath({
  required String path,
  required String title,
  required String? artist,
  required String? album,
  required DateTime? year,
  required int? trackNumber,
  required int? trackTotal,
  required int? discNumber,
  required int? totalDisc,
  required String? lyrics,
  EmbeddedCoverEditKind coverEdit = EmbeddedCoverEditKind.unchanged,
  Uint8List? replacementCoverBytes,
}) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw FileSystemException('file not found', path);
  }

  final ext = p.extension(file.path).toLowerCase();
  final isWav = pathLooksLikeWav(file.path);
  late final ParserTag meta;
  try {
    meta = readAllMetadataForWrite(file, getImage: true);
  } catch (e, st) {
    appLog.e(
      'writeEmbeddedTags read failed path=${file.path} ext=$ext',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
  final nt = title.trim();
  meta.setTitle(nt.isEmpty ? null : nt);
  _applyArtistForRoundTrip(meta, artist);
  meta.setAlbum(_trimOrNull(album));
  meta.setYear(year);
  meta.setTrackNumber(trackNumber);
  meta.setTrackTotal(trackTotal);
  meta.setCD(discNumber, totalDisc);
  meta.setLyrics(_trimOrNull(lyrics));
  _applyCoverEdit(meta, coverEdit, replacementCoverBytes);

  try {
    if (isWav && meta is RiffMetadata) {
      RiffWriterFixed().write(
        file,
        meta,
        trackTotal: trackTotal,
        lyrics: _trimOrNull(lyrics),
      );
      return;
    }
    writeMetadataWithLyricsFix(file, meta);
  } catch (e, st) {
    appLog.e(
      'writeEmbeddedTags write failed path=${file.path} ext=$ext meta=${meta.runtimeType}',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
}

String? _trimOrNull(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

/// [readMetadata] 对 MP3 的 artist 会优先读 TPE2 再 TPE1；内嵌编辑器只有一个「艺人」框，
/// 保存时同步写入 TPE1/TPE2，避免清空框后仍残留 TPE1。
void _applyArtistForRoundTrip(ParserTag meta, String? artist) {
  final v = _trimOrNull(artist);
  if (meta is Mp3Metadata) {
    meta.leadPerformer = v;
    meta.bandOrOrchestra = v;
    return;
  }
  meta.setArtist(v);
}

String _sniffImageMime(Uint8List b) {
  if (b.length >= 2 && b[0] == 0xff && b[1] == 0xd8) {
    return 'image/jpeg';
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4e &&
      b[3] == 0x47) {
    return 'image/png';
  }
  return '';
}

void _applyCoverEdit(
  ParserTag meta,
  EmbeddedCoverEditKind kind,
  Uint8List? replacementCoverBytes,
) {
  switch (kind) {
    case EmbeddedCoverEditKind.unchanged:
      return;
    case EmbeddedCoverEditKind.removed:
      _removeFrontCovers(meta);
      return;
    case EmbeddedCoverEditKind.replacedWithBytes:
      final bytes = replacementCoverBytes;
      if (bytes == null || bytes.isEmpty) return;
      final mime = _sniffImageMime(bytes);
      if (mime.isEmpty) {
        throw FormatException(
          'embedded cover must be JPEG or PNG',
        );
      }
      _replaceFrontCover(meta, Picture(bytes, mime, PictureType.coverFront));
  }
}

void _removeFrontCovers(ParserTag meta) {
  if (meta is Mp3Metadata) {
    meta.pictures = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
    return;
  }
  if (meta is Mp4Metadata) {
    meta.picture = null;
    return;
  }
  if (meta is VorbisMetadata) {
    meta.pictures = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
    return;
  }
  if (meta is RiffMetadata) {
    meta.pictures = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
  }
}

void _replaceFrontCover(ParserTag meta, Picture pic) {
  if (meta is Mp3Metadata) {
    final rest = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
    meta.pictures = [pic, ...rest];
    return;
  }
  if (meta is Mp4Metadata) {
    meta.picture = pic;
    return;
  }
  if (meta is VorbisMetadata) {
    final rest = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
    meta.pictures = [pic, ...rest];
    return;
  }
  if (meta is RiffMetadata) {
    final rest = meta.pictures
        .where((p) => p.pictureType != PictureType.coverFront)
        .toList();
    meta.pictures = [pic, ...rest];
  }
}

bool isEmbeddedMetadataWriteFailure(Object e) {
  return e is MetadataParserException || e is FileSystemException;
}
