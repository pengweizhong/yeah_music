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
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show MetadataParserException, Picture;
import 'package:audio_metadata_reader/src/metadata/base.dart' show Mp3Metadata;
import 'package:yeah_music/utils/wav_metadata_reader.dart'
    show
        id3TextFromFramePayload,
        lyricFromUlstPayload,
        mergeId3v1TailAscii,
        pictureFromApicPayload,
        synchsafeFour;

final _trckRegex = RegExp(r'^(\d+)(?:/(\d+))?$');
final _discRegex = RegExp(r'^(\d+)(?:/(\d+))?$');

/// 不依赖 `ID3v2Parser` 的容错读入（单帧解码失败不拖垮整文件）。
Mp3Metadata readMp3Id3v2Tolerant(File file, {bool getImage = true}) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 10 ||
      bytes[0] != 0x49 ||
      bytes[1] != 0x44 ||
      bytes[2] != 0x33) {
    throw MetadataParserException(
      track: file,
      message: 'file does not start with ID3',
    );
  }

  final meta = Mp3Metadata();
  final lyricChunks = <String>[];
  final pictures = <Picture>[];

  final tagSpan = _leadingId3v2Span(bytes, 0);
  if (tagSpan < 10 || tagSpan > bytes.length) {
    throw MetadataParserException(
      track: file,
      message: 'invalid ID3v2 tag size',
    );
  }

  _consumeId3v2Frames(
    bytes,
    0,
    tagSpan,
    meta: meta,
    lyricChunks: lyricChunks,
    pictures: pictures,
    getImage: getImage,
  );

  if (bytes.length >= 128) {
    final tail = bytes.sublist(bytes.length - 128);
    mergeId3v1TailAscii(
      tail,
      considerTitle: (s) => meta.songName ??= _nonEmpty(s),
      considerArtist: (s) {
        meta.leadPerformer ??= _nonEmpty(s);
        meta.bandOrOrchestra ??= _nonEmpty(s);
      },
      considerAlbum: (s) => meta.album ??= _nonEmpty(s),
      considerGenre: (s) {
        final g = _nonEmpty(s);
        if (g != null && !meta.genres.contains(g)) meta.genres.add(g);
      },
      lyricChunks: lyricChunks,
      trackSetter: (n) => meta.trackNumber ??= n,
      yearSetter: (y) => meta.year ??= y?.year,
    );
  }

  if (meta.lyric == null && lyricChunks.isNotEmpty) {
    meta.lyric = lyricChunks.first;
  }
  if (getImage && pictures.isNotEmpty) {
    meta.pictures = pictures;
  }

  return meta;
}

int _leadingId3v2Span(Uint8List w, int offset) {
  final payloadSize = synchsafeFour(
    w[offset + 6],
    w[offset + 7],
    w[offset + 8],
    w[offset + 9],
  );
  var tagSpan = 10 + payloadSize;
  if ((w[offset + 5] & 0x10) != 0) {
    tagSpan += 10;
  }
  return tagSpan;
}

void _consumeId3v2Frames(
  Uint8List buf,
  int offset,
  int tagSpan, {
  required Mp3Metadata meta,
  required List<String> lyricChunks,
  required List<Picture> pictures,
  required bool getImage,
}) {
  final endExclusive = math.min(offset + tagSpan, buf.length);
  if (offset + 10 > endExclusive) return;

  final maj = buf[offset + 3];
  if (maj != 3 && maj != 4) return;

  var pos = offset + 10;
  final flagsByte = buf[offset + 5];
  if ((flagsByte & 0x40) != 0 && maj == 4 && pos + 4 <= endExclusive) {
    final extStart = pos;
    final extLen = synchsafeFour(
      buf[pos],
      buf[pos + 1],
      buf[pos + 2],
      buf[pos + 3],
    );
    if (extLen >= 6 && extStart + extLen <= endExclusive) {
      pos = extStart + extLen;
    }
  }

  while (pos + 10 <= endExclusive) {
    final fidBytes = Uint8List.sublistView(buf, pos, pos + 4);
    if (fidBytes.every((b) => b == 0)) break;

    final frameId = latin1.decode(fidBytes, allowInvalid: true);
    late int sz;
    if (maj == 4) {
      sz = synchsafeFour(
        buf[pos + 4],
        buf[pos + 5],
        buf[pos + 6],
        buf[pos + 7],
      );
    } else {
      sz = ByteData.sublistView(buf, pos + 4).getUint32(0, Endian.big);
    }
    pos += 10;

    if (sz <= 0 || pos + sz > endExclusive) break;

    final frameBody = Uint8List.sublistView(buf, pos, pos + sz);
    pos += sz;

    try {
      _applyId3Frame(
        frameId,
        frameBody,
        meta: meta,
        lyricChunks: lyricChunks,
        pictures: pictures,
        getImage: getImage,
      );
    } catch (_) {
      // 单帧损坏时跳过，继续读后续帧。
    }
  }
}

void _applyId3Frame(
  String frameId,
  Uint8List body, {
  required Mp3Metadata meta,
  required List<String> lyricChunks,
  required List<Picture> pictures,
  required bool getImage,
}) {
  switch (frameId) {
    case 'TIT2':
      meta.songName = _nonEmpty(id3TextFromFramePayload(body)) ?? meta.songName;
    case 'TPE1':
      meta.leadPerformer =
          _nonEmpty(id3TextFromFramePayload(body)) ?? meta.leadPerformer;
    case 'TPE2':
      meta.bandOrOrchestra =
          _nonEmpty(id3TextFromFramePayload(body)) ?? meta.bandOrOrchestra;
    case 'TALB':
      meta.album = _nonEmpty(id3TextFromFramePayload(body)) ?? meta.album;
    case 'TCON':
      _applyGenre(meta, id3TextFromFramePayload(body));
    case 'TRCK':
      _applyTrck(meta, id3TextFromFramePayload(body));
    case 'TPOS':
      _applyTpos(meta, id3TextFromFramePayload(body));
    case 'TYER':
    case 'TDRC':
      _applyYear(meta, id3TextFromFramePayload(body));
    case 'USLT':
      final txt = lyricFromUlstPayload(body);
      if (txt.isNotEmpty && !lyricChunks.contains(txt)) {
        lyricChunks.add(txt);
        meta.lyric ??= txt;
      }
    case 'APIC':
      if (!getImage) return;
      final pic = pictureFromApicPayload(body);
      if (pic != null) {
        final dup = pictures.any(
          (p) =>
              p.bytes.length == pic.bytes.length &&
              p.mimetype == pic.mimetype,
        );
        if (!dup) pictures.add(pic);
      }
    default:
      break;
  }
}

void _applyGenre(Mp3Metadata meta, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return;
  meta.contentType = t;
  final parts = t.split(RegExp(r'[;/|,/]')).map((e) => e.trim()).where(
        (e) => e.isNotEmpty,
      );
  for (final p in parts) {
    if (!meta.genres.contains(p)) meta.genres.add(p);
  }
}

void _applyTrck(Mp3Metadata meta, String raw) {
  final m = _trckRegex.firstMatch(raw.trim());
  if (m == null) return;
  meta.trackNumber ??= int.tryParse(m.group(1)!);
  meta.trackTotal ??= int.tryParse(m.group(2) ?? '');
}

void _applyTpos(Mp3Metadata meta, String raw) {
  final m = _discRegex.firstMatch(raw.trim());
  if (m == null) return;
  meta.discNumber ??= int.tryParse(m.group(1)!);
  meta.totalDics ??= int.tryParse(m.group(2) ?? '');
}

void _applyYear(Mp3Metadata meta, String raw) {
  final digits = RegExp(r'(\d{4})').firstMatch(raw.trim())?.group(1);
  if (digits == null) return;
  meta.year ??= int.tryParse(digits);
}

String? _nonEmpty(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}
