// Copyright (c) 2025 Yeah Music
//
// ID3v1 仅 30 字节/字段；上游 [ID3v1Writer] 按字符截断且未限制 UTF-8 字节数，
// 中文标题会导致 `List.filled(negative)` 抛 RangeError。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/writers/base_writer.dart';

class Id3v1WriterSafe extends BaseMetadataWriter<Mp3Metadata> {
  @override
  void write(File file, Mp3Metadata metadata) {
    final tag = BytesBuilder();
    tag.add(ascii.encode('TAG'));
    tag.add(_fixedField(metadata.songName ?? '', 30));
    tag.add(_fixedField(metadata.bandOrOrchestra ?? metadata.leadPerformer ?? '', 30));
    tag.add(_fixedField(metadata.album ?? '', 30));
    tag.add(_yearField(metadata.year ?? metadata.originalReleaseYear));
    tag.add(_fixedField('', 30));
    tag.addByte(255);
    if (tag.length != 128) {
      throw StateError('ID3v1 tag must be 128 bytes, got ${tag.length}');
    }
    file.writeAsBytesSync(tag.toBytes(), mode: FileMode.append);
  }

  static Uint8List _fixedField(String text, int maxBytes) {
    final encoded = utf8.encode(text.trim());
    if (encoded.length <= maxBytes) {
      return Uint8List.fromList([
        ...encoded,
        ...List.filled(maxBytes - encoded.length, 0),
      ]);
    }
    var cut = maxBytes;
    while (cut > 0 && (encoded[cut] & 0xC0) == 0x80) {
      cut--;
    }
    return Uint8List.fromList([
      ...encoded.sublist(0, cut),
      ...List.filled(maxBytes - cut, 0),
    ]);
  }

  static Uint8List _yearField(int? year) {
    final y = year;
    final s = (y != null && y > 0 && y < 10000) ? y.toString().padLeft(4, '0').substring(0, 4) : '';
    return _fixedField(s, 4);
  }
}
