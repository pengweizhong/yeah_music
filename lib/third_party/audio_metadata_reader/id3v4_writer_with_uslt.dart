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

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/tag_parser.dart';
import 'package:audio_metadata_reader/src/writers/base_writer.dart';

import 'mp3_strip_id3v2_prefix.dart';

class TagHeader {
  final int majorVersion;
  final int minorVersion;
  final int size;
  final bool hasFooter;
  final bool hasExtendedHeader;

  TagHeader(this.majorVersion, this.minorVersion, this.size, this.hasFooter,
      this.hasExtendedHeader);

  int get version => majorVersion * 100 + minorVersion;
}

/// 在官方 [Id3v4Writer] 基础上补充 USLT 帧写入（上游未写 lyrics，导致读回为空）。
class Id3v4WriterWithUslt extends BaseMetadataWriter<Mp3Metadata> {
  @override
  void write(File file, Mp3Metadata metadata) {
    // check if the file has an ID3 metadata
    final size = file.lengthSync();

    final builder = BytesBuilder();

    _writeFrames(builder, metadata);

    final finalBuilder = BytesBuilder();

    _writeHeader(finalBuilder, builder.length);
    finalBuilder.add(builder.toBytes());

    if (size == 0) {
      file.writeAsBytesSync(finalBuilder.toBytes());
    } else {
      final oldData = file.readAsBytesSync();
      final audioPayload = stripLeadingId3v2Blocks(oldData);
      file.writeAsBytesSync([
        ...finalBuilder.toBytes(),
        ...audioPayload,
      ]);
    }
  }

  void _writeFrames(BytesBuilder builder, Mp3Metadata metadata) {
    if (metadata.pictures.isNotEmpty) {
      _writePictures(builder, metadata.pictures);
    }

    if (metadata.album != null) {
      _writeFrame(builder, "TALB", metadata.album!);
    }
    if (metadata.bpm != null) {
      _writeFrame(builder, "TBPM", metadata.bpm!);
    }
    if (metadata.composer != null) {
      _writeFrame(builder, "TCOM", metadata.composer!);
    }
    if (metadata.contentType != null) {
      _writeFrame(builder, "TCON", metadata.contentType!);
    }
    if (metadata.copyrightMessage != null) {
      _writeFrame(builder, "TCOP", metadata.copyrightMessage!);
    }
    if (metadata.date != null) {
      _writeFrame(builder, "TDAT", metadata.date!);
    }

    if (metadata.playlistDelay != null) {
      _writeFrame(builder, "TDLY", metadata.playlistDelay!);
    }
    if (metadata.encodedBy != null) {
      _writeFrame(builder, "TENC", metadata.encodedBy!);
    }
    if (metadata.textWriter != null) {
      _writeFrame(builder, "TEXT", metadata.textWriter!);
    }
    if (metadata.fileType != null) {
      _writeFrame(builder, "TFLT", metadata.fileType!);
    }
    if (metadata.time != null) {
      _writeFrame(builder, "TIME", metadata.time!);
    }
    if (metadata.contentGroupDescription != null) {
      _writeFrame(builder, "TIT1", metadata.contentGroupDescription!);
    }
    if (metadata.songName != null) {
      _writeFrame(builder, "TIT2", metadata.songName!);
    }

    if (metadata.subtitle != null) {
      _writeFrame(builder, "TIT3", metadata.subtitle!);
    }
    if (metadata.initialKey != null) {
      _writeFrame(builder, "TKEY", metadata.initialKey!);
    }
    if (metadata.languages != null) {
      _writeFrame(builder, "TLAN", metadata.languages!);
    }
    if (metadata.duration != null) {
      final duration = metadata.duration!;
      _writeFrame(builder, "TLEN", "${duration.inMilliseconds}");
    }
    if (metadata.mediatype != null) {
      _writeFrame(builder, "TMED", metadata.mediatype!);
    }
    if (metadata.originalAlbum != null) {
      _writeFrame(builder, "TOAL", metadata.originalAlbum!);
    }

    if (metadata.originalFilename != null) {
      _writeFrame(builder, "TOFN", metadata.originalFilename!);
    }
    if (metadata.originalTextWriter != null) {
      _writeFrame(builder, "TOLY", metadata.originalTextWriter!);
    }
    if (metadata.originalArtist != null) {
      _writeFrame(builder, "TOPE", metadata.originalArtist!);
    }
    if (metadata.originalReleaseYear != null) {
      _writeFrame(builder, "TORY", metadata.originalReleaseYear!.toString());
    }
    if (metadata.fileOwner != null) {
      _writeFrame(builder, "TOWN", metadata.fileOwner!);
    }
    if (metadata.leadPerformer != null) {
      _writeFrame(builder, "TPE1", metadata.leadPerformer!);
    }
    if (metadata.bandOrOrchestra != null) {
      _writeFrame(builder, "TPE2", metadata.bandOrOrchestra!);
    }
    if (metadata.conductor != null) {
      _writeFrame(builder, "TPE3", metadata.conductor!);
    }
    if (metadata.interpreted != null) {
      _writeFrame(builder, "TPE4", metadata.interpreted!);
    }
    if (metadata.partOfSet != null) {
      _writeFrame(builder, "TPOS", metadata.partOfSet!);
    }
    if (metadata.publisher != null) {
      _writeFrame(builder, "TPUB", metadata.publisher!);
    }
    if (metadata.trackNumber != null) {
      if (metadata.trackTotal != null) {
        _writeFrame(
            builder, "TRCK", "${metadata.trackNumber}/${metadata.trackTotal}");
      } else {
        _writeFrame(builder, "TRCK", "${metadata.trackNumber}");
      }
    }
    if (metadata.recordingDates != null) {
      _writeFrame(builder, "TRDA", metadata.recordingDates!);
    }
    if (metadata.internetRadioStationName != null) {
      _writeFrame(builder, "TRSN", metadata.internetRadioStationName!);
    }
    if (metadata.internetRadioStationOwner != null) {
      _writeFrame(builder, "TRSO", metadata.internetRadioStationOwner!);
    }
    if (metadata.size != null) {
      _writeFrame(builder, "TSIZ", metadata.size!);
    }
    if (metadata.isrc != null) {
      _writeFrame(builder, "TSRC", metadata.isrc!);
    }
    if (metadata.encoderSoftware != null) {
      _writeFrame(builder, "TSSE", metadata.encoderSoftware!);
    }
    if (metadata.year != null) {
      _writeFrame(builder, "TYER", metadata.year!.toString());
    }
    if (metadata.genres.isNotEmpty) {
      final genresString = metadata.genres.join('/');
      _writeFrame(builder, "TCON", genresString);
    } else if (metadata.contentType != null) {
      _writeFrame(builder, "TCON", metadata.contentType!);
    }

    if (metadata.lyric != null && metadata.lyric!.trim().isNotEmpty) {
      _writeFrameWithBytes(
        builder,
        'USLT',
        _buildUsltPayloadUtf8(metadata.lyric!.trim()),
      );
    }
  }

  Uint8List _buildUsltPayloadUtf8(String lyric) {
    final bb = BytesBuilder();
    bb.addByte(3);
    bb.add(ascii.encode('eng'));
    bb.addByte(0);
    bb.add(utf8.encode(lyric));
    return bb.toBytes();
  }

  void _writeFrame(BytesBuilder builder, String frameId, String data) {
    builder.add(frameId.codeUnits);

    builder.add(_encodeSynchsafeInteger(data.length + 1));
    // flags
    builder.add([0, 0]);

    builder.addByte(0x03);
    builder.add(utf8.encode(data));
  }

  void _writeFrameWithBytes(
      BytesBuilder builder, String frameId, Uint8List data) {
    builder.add(frameId.codeUnits);

    builder.add(_encodeSynchsafeInteger(data.length + 1));
    // flags
    builder.add([0, 0]);

    builder.addByte(0x03);
    builder.add(data);
  }

  void _writePictures(BytesBuilder builder, List<Picture> pictures) {
    for (final picture in pictures) {
      final pictureBuilder = BytesBuilder();

      // encoding
      // pictureBuilder.addByte(4);
      // mimetype
      pictureBuilder.add([...utf8.encode(picture.mimetype), 0x00]);

      // picture type
      pictureBuilder.addByte(switch (picture.pictureType) {
        PictureType.other => 0x0,
        PictureType.fileIcon32x32 => 0x1,
        PictureType.otherFileIcon => 0x2,
        PictureType.coverFront => 0x3,
        PictureType.coverBack => 0x4,
        PictureType.leafletPage => 0x5,
        PictureType.mediaLabelCD => 0x6,
        PictureType.leadArtist => 0x7,
        PictureType.artistPerformer => 0x8,
        PictureType.conductor => 0x9,
        PictureType.bandOrchestra => 0x0A,
        PictureType.composer => 0x0B,
        PictureType.lyricistTextWriter => 0x0C,
        PictureType.recordingLocation => 0x0D,
        PictureType.duringRecording => 0x0E,
        PictureType.duringPerformance => 0x0F,
        PictureType.movieVideoScreenCapture => 0x10,
        PictureType.brightColouredFish => 0x11,
        PictureType.illustration => 0x12,
        PictureType.bandArtistLogotype => 0x13,
        PictureType.publisherStudioLogotype => 0x14,
      });

      // description
      pictureBuilder.addByte(0);

      pictureBuilder.add(picture.bytes);

      _writeFrameWithBytes(builder, "APIC", pictureBuilder.toBytes());
    }
  }

  Uint8List _encodeSynchsafeInteger(int value) {
    return Uint8List.fromList([
      (value >> 21) & 0x7F,
      (value >> 14) & 0x7F,
      (value >> 7) & 0x7F,
      value & 0x7F,
    ]);
  }

  void _writeHeader(BytesBuilder builder, int dataSize) {
    // ID3
    builder.addByte(0x49);
    builder.addByte(0x44);
    builder.addByte(0x33);

    // the ID3 version For us, only 4
    builder.addByte(4);
    // the version is always followed by a 0x00 byte
    builder.addByte(0);

    // write flags
    builder.addByte(0);

    // write ID3 metadata size
    builder.add(_encodeSynchsafeInteger(dataSize));
  }
}
