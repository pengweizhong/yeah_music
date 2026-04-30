import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_metadata_reader/src/parsers/mp4.dart';
import 'package:audio_metadata_reader/src/utils/bit_manipulator.dart';
import 'package:audio_metadata_reader/src/writers/base_writer.dart';

class Mp4WriterFixed extends BaseMetadataWriter<Mp4Metadata> {
  late Mp4Metadata mp4metadata;

  @override
  void write(File file, Mp4Metadata metadata) {
    mp4metadata = metadata;
    final reader = file.openSync();

    final lengthFile = reader.lengthSync();
    final byteBuilder = BytesBuilder();

    while (reader.positionSync() < lengthFile) {
      final box = _readBox(reader.readSync(8));
      final topBoxData = reader.readSync(box.size - 8);

      if (box.type != "moov") {
        byteBuilder.add(intToUint32(topBoxData.length + 8));
        byteBuilder.add(box.type.codeUnits);
        byteBuilder.add(topBoxData);
      } else {
        final data = _processBox(topBoxData);

        byteBuilder.add(intToUint32(data.length + 8));
        byteBuilder.add(box.type.codeUnits);
        byteBuilder.add(data);
      }
    }

    reader.closeSync();

    file.writeAsBytesSync(byteBuilder.toBytes());
  }

  Uint8List _processBox(Uint8List data) {
    int offset = 0;
    const recursiveBoxes = {
      "moov",
      "udta",
      "meta",
      "ilst",
    };
    final byteBuilder = BytesBuilder();

    while (offset < data.length) {
      final headerBytes = data.sublist(offset, offset + 8);
      final box = _readBox(headerBytes);
      offset += 8;

      Uint8List boxData = data.sublist(offset, offset + box.size - 8);
      offset += box.size - 8;

      if (box.type == "ilst") {
        final newMetadataData = _replaceMetadata(boxData);

        byteBuilder.add(intToUint32(newMetadataData.length + 8));
        byteBuilder.add(box.type.codeUnits);
        byteBuilder.add(newMetadataData);
      } else if (recursiveBoxes.contains(box.type)) {
        if (box.type == "meta") {
          offset += 4;
          final subData = boxData.sublist(4);
          final recursiveBoxData = _processBox(subData);

          byteBuilder.add(intToUint32(recursiveBoxData.length + 12));
          byteBuilder.add(box.type.codeUnits);
          byteBuilder.add(boxData.sublist(0, 4));
          byteBuilder.add(recursiveBoxData);
        } else {
          final recursiveBoxData = _processBox(boxData);
          byteBuilder.add(intToUint32(recursiveBoxData.length + 8));
          byteBuilder.add(box.type.codeUnits);
          byteBuilder.add(recursiveBoxData);
        }
      } else {
        byteBuilder.add(intToUint32(boxData.length + 8));
        byteBuilder.add(box.type.codeUnits);
        byteBuilder.add(boxData);
      }
    }

    return byteBuilder.toBytes();
  }

  Uint8List _replaceMetadata(Uint8List data) {
    final ilstBuilder = BytesBuilder();

    if (mp4metadata.title != null) {
      ilstBuilder.add(_buildStringTag("©nam", mp4metadata.title!));
    }
    if (mp4metadata.artist != null) {
      ilstBuilder.add(_buildStringTag("©ART", mp4metadata.artist!));
    }
    if (mp4metadata.album != null) {
      ilstBuilder.add(_buildStringTag("©alb", mp4metadata.album!));
    }
    if (mp4metadata.genre != null) {
      ilstBuilder.add(_buildStringTag("©gen", mp4metadata.genre!));
    }
    if (mp4metadata.year != null) {
      ilstBuilder
          .add(_buildStringTag("©day", mp4metadata.year!.year.toString()));
    }
    if (mp4metadata.lyrics != null) {
      ilstBuilder.add(_buildStringTag("©lyr", mp4metadata.lyrics!));
    }

    if (mp4metadata.picture != null) {
      final covrTag = _buildCovrTag(mp4metadata.picture!);
      if (covrTag != null) {
        ilstBuilder.add(covrTag);
      }
    }

    if (mp4metadata.trackNumber != null) {
      ilstBuilder.add(_buildIntegerTag(
          "trkn", mp4metadata.trackNumber!, mp4metadata.totalTracks));
    }
    if (mp4metadata.discNumber != null) {
      ilstBuilder.add(_buildIntegerTag(
          "disk", mp4metadata.discNumber!, mp4metadata.totalDiscs));
    }

    return ilstBuilder.toBytes();
  }

  Uint8List _buildStringTag(String tagType, String value) {
    final valueBytes = utf8.encode(value);

    // --- Build the inner 'data' box ---
    // size (4 bytes) + 'data' (4 bytes) + version/flags (4 bytes) + locale (4 bytes) + value
    final dataBoxSize = 8 + 4 + 4 + valueBytes.length;
    final dataBuilder = BytesBuilder();
    dataBuilder.add(intToUint32(dataBoxSize)); // data box size
    dataBuilder.add("data".codeUnits); // data box type
    dataBuilder.add(intToUint32(1)); // version=0, flags=1 (UTF-8)
    dataBuilder.add(intToUint32(0)); // locale=0
    dataBuilder.add(valueBytes); // the actual string data

    // --- Build the outer tag box (e.g., ©nam) ---
    final dataBoxBytes = dataBuilder.toBytes();
    final tagBoxSize = 8 + dataBoxBytes.length;
    final tagBuilder = BytesBuilder();
    tagBuilder.add(intToUint32(tagBoxSize));
    tagBuilder.add(tagType.codeUnits);
    tagBuilder.add(dataBoxBytes);

    return tagBuilder.toBytes();
  }

  Uint8List? _buildCovrTag(Picture picture) {
    int dataTypeFlag;
    if (picture.mimetype.toLowerCase() == 'image/jpeg') {
      dataTypeFlag = 13; // JPEG data type
    } else if (picture.mimetype.toLowerCase() == 'image/png') {
      dataTypeFlag = 14; // PNG data type
    } else {
      print(
          "Warning: Unsupported picture mime type for 'covr' tag: ${picture.mimetype}. Skipping cover art.");
      return null; // Unsupported type
    }

    final valueBytes = picture.bytes;

    // --- Build the inner 'data' box ---
    // size (4) + 'data' (4) + version/flags (4, contains type) + locale (4) + value
    final dataBoxSize = 8 + 4 + 4 + valueBytes.length;
    final dataBuilder = BytesBuilder();
    dataBuilder.add(intToUint32(dataBoxSize)); // data box size
    dataBuilder.add("data".codeUnits);
    dataBuilder.add(intToUint32(dataTypeFlag)); // version=0, flags=dataTypeFlag
    dataBuilder.add(intToUint32(0)); // locale=0
    dataBuilder.add(valueBytes);

    // --- Build the outer 'covr' tag box ---
    final dataBoxBytes = dataBuilder.toBytes();
    final tagBoxSize = 8 + dataBoxBytes.length;
    final tagBuilder = BytesBuilder();
    tagBuilder.add(intToUint32(tagBoxSize));
    tagBuilder.add("covr".codeUnits);
    tagBuilder.add(dataBoxBytes);

    return tagBuilder.toBytes();
  }

  Uint8List _buildIntegerTag(String tagType, int current, [int? total]) {
    final dataBuilder = BytesBuilder();

    final valueBytes = BytesBuilder();
    valueBytes.add([0x00, 0x00]); // reserved
    valueBytes.add(intToUint16(current));
    valueBytes.add(intToUint16(total ?? 0));
    valueBytes.add([0x00, 0x00]); // reserved

    final fullData = valueBytes.toBytes();

    final dataBoxSize = 8 + 4 + 4 + fullData.length;
    dataBuilder.add(intToUint32(dataBoxSize));
    dataBuilder.add("data".codeUnits);
    dataBuilder.add(intToUint32(0)); // version=0, flags=0 (binary)
    dataBuilder.add(intToUint32(0)); // locale
    dataBuilder.add(fullData);

    final dataBox = dataBuilder.toBytes();
    final tagBoxSize = 8 + dataBox.length;

    final tagBuilder = BytesBuilder();
    tagBuilder.add(intToUint32(tagBoxSize));
    tagBuilder.add(tagType.codeUnits);
    tagBuilder.add(dataBox);

    return tagBuilder.toBytes();
  }

  /// A box (or atom) header uses 8 bytes
  ///
  /// [0...3] -> box size (header + body)
  /// [4...7] -> box name (ASCII)
  BoxHeader _readBox(Uint8List headerBytes) {
    final boxSize = getUint32(headerBytes.sublist(0, 4));
    final boxNameBytes = headerBytes.sublist(4);

    return BoxHeader(boxSize, String.fromCharCodes(boxNameBytes));
  }
}
