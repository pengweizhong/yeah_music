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
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_metadata_reader/src/utils/bit_manipulator.dart';
import 'package:audio_metadata_reader/src/writers/base_writer.dart';

/// 修正上游 [RiffWriter]：写回原文件、UTF‑8 INFO、可选曲目总数/歌词、封面 DISP。
///
/// 按 chunk 扫描界定 WAVE 体边界（不盲信 RIFF size 字段，避免截断 `data` 导致杂音）。
class RiffWriterFixed extends BaseMetadataWriter<RiffMetadata> {
  @override
  void write(
    File file,
    RiffMetadata metadata, {
    int? trackTotal,
    String? lyrics,
  }) {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 12) {
      throw const FormatException('wav too short');
    }
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
      throw const FormatException('not RIFF/WAVE');
    }

    final split = _splitRiffWaveAndTrailing(bytes);
    final rebuilt = _rebuildWaveBody(
      split.waveBody,
      metadata,
      trackTotal: trackTotal,
      lyrics: lyrics,
    );

    final out = BytesBuilder();
    out.add(ascii.encode('RIFF'));
    out.add(intToUint32LE(4 + rebuilt.length));
    out.add(ascii.encode('WAVE'));
    out.add(rebuilt);
    out.add(split.trailing);
    file.writeAsBytesSync(out.toBytes());
  }

  /// 从 offset 12 起扫描 chunk，得到 WAVE 体内字节与尾部附加数据（如 ID3）。
  static ({Uint8List waveBody, Uint8List trailing}) _splitRiffWaveAndTrailing(
    Uint8List bytes,
  ) {
    var off = 12;
    final fileLen = bytes.length;
    while (off + 8 <= fileLen) {
      if (_looksLikeEmbeddedId3TagAt(bytes, off)) break;

      final chunkId = ascii.decode(bytes.sublist(off, off + 4));
      if (!_isPlausibleChunkId(chunkId)) break;

      final chunkSize =
          ByteData.sublistView(bytes, off + 4).getUint32(0, Endian.little);
      final padded = chunkSize + (chunkSize.isOdd ? 1 : 0);
      final next = off + 8 + padded;
      if (next <= off || off + 8 + chunkSize > fileLen) break;
      off = next;
    }

    return (
      waveBody: bytes.sublist(12, off),
      trailing: off < fileLen ? bytes.sublist(off) : Uint8List(0),
    );
  }

  static bool _looksLikeEmbeddedId3TagAt(Uint8List bytes, int off) {
    if (off + 3 > bytes.length) return false;
    return bytes[off] == 0x49 && bytes[off + 1] == 0x44 && bytes[off + 2] == 0x33;
  }

  static bool _isPlausibleChunkId(String id) {
    if (id.length != 4) return false;
    for (final c in id.codeUnits) {
      final ok =
          (c >= 0x20 && c <= 0x7e) || c == 0x09; // printable ASCII / tab
      if (!ok) return false;
    }
    return true;
  }

  Uint8List _rebuildWaveBody(
    Uint8List waveBody,
    RiffMetadata metadata, {
    int? trackTotal,
    String? lyrics,
  }) {
    final out = BytesBuilder();
    var off = 0;
    var insertedInfo = false;

    while (off + 8 <= waveBody.length) {
      if (_looksLikeEmbeddedId3TagAt(waveBody, off)) break;

      final chunkId = ascii.decode(waveBody.sublist(off, off + 4));
      if (!_isPlausibleChunkId(chunkId)) break;

      final chunkSize =
          ByteData.sublistView(waveBody, off + 4).getUint32(0, Endian.little);
      final paddedSize = chunkSize + (chunkSize.isOdd ? 1 : 0);
      final nextOff = off + 8 + paddedSize;
      if (nextOff <= off || off + 8 + chunkSize > waveBody.length) break;

      final chunkBody = waveBody.sublist(off + 8, off + 8 + chunkSize);

      if (chunkId == 'LIST' &&
          chunkBody.length >= 4 &&
          ascii.decode(chunkBody.sublist(0, 4)) == 'INFO') {
        final encoded = _encodeListInfoChunk(
          metadata,
          trackTotal: trackTotal,
          lyrics: lyrics,
        );
        if (encoded.isNotEmpty) {
          insertedInfo = true;
          out.add(encoded);
        }
      } else {
        out.add(waveBody.sublist(off, nextOff));
        if (chunkId == 'fmt ' && !insertedInfo) {
          final encoded = _encodeListInfoChunk(
            metadata,
            trackTotal: trackTotal,
            lyrics: lyrics,
          );
          if (encoded.isNotEmpty) {
            out.add(encoded);
            insertedInfo = true;
          }
        }
      }

      off = nextOff;
    }

    if (!insertedInfo) {
      final encoded = _encodeListInfoChunk(
        metadata,
        trackTotal: trackTotal,
        lyrics: lyrics,
      );
      if (encoded.isNotEmpty) out.add(encoded);
    }

    return out.toBytes();
  }

  Uint8List _encodeListInfoChunk(
    RiffMetadata metadata, {
    int? trackTotal,
    String? lyrics,
  }) {
    final infoBuilder = BytesBuilder();

    void text(String id, String? value) {
      if (value == null || value.trim().isEmpty) return;
      infoBuilder.add(_writeTextChunk(id, value.trim()));
    }

    text('INAM', metadata.title);
    text('IART', metadata.artist);
    text('IPRD', metadata.album);
    if (metadata.year != null) {
      text('ICRD', '${metadata.year!.year}');
    }
    final lyricText = lyrics?.trim();
    if (lyricText != null && lyricText.isNotEmpty) {
      text('ICMT', lyricText);
    } else {
      text('ICMT', metadata.comment);
    }
    text('IGNR', metadata.genre);
    text('ISFT', metadata.encoder);
    text('ICOP', metadata.copyright);

    final tn = metadata.trackNumber;
    if (tn != null) {
      final itrk = trackTotal != null ? '$tn/$trackTotal' : '$tn';
      text('ITRK', itrk);
    }

    Picture? cover;
    for (final pic in metadata.pictures) {
      if (pic.pictureType == PictureType.coverFront && pic.bytes.isNotEmpty) {
        cover = pic;
        break;
      }
    }
    cover ??=
        metadata.pictures.isNotEmpty && metadata.pictures.first.bytes.isNotEmpty
            ? metadata.pictures.first
            : null;
    if (cover != null) {
      infoBuilder.add(_writeBinaryChunk('DISP', cover.bytes));
    }

    final infoData = infoBuilder.toBytes();
    if (infoData.isEmpty) return Uint8List(0);

    final listBuilder = BytesBuilder();
    listBuilder.add(ascii.encode('LIST'));
    listBuilder.add(intToUint32LE(4 + infoData.length));
    listBuilder.add(ascii.encode('INFO'));
    listBuilder.add(infoData);
    return listBuilder.toBytes();
  }

  Uint8List _writeTextChunk(String id, String value) {
    return _writeBinaryChunk(id, Uint8List.fromList(utf8.encode(value)));
  }

  Uint8List _writeBinaryChunk(String id, Uint8List valueBytes) {
    final builder = BytesBuilder();
    builder.add(ascii.encode(id));
    var size = valueBytes.length;
    final needsPadding = size.isOdd;
    if (needsPadding) size += 1;
    builder.add(intToUint32LE(size));
    builder.add(valueBytes);
    if (needsPadding) builder.addByte(0);
    return builder.toBytes();
  }
}
