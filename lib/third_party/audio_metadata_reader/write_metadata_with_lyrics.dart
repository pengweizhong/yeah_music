import 'dart:io';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/flac.dart';
import 'package:audio_metadata_reader/src/parsers/id3v1.dart';
import 'package:audio_metadata_reader/src/parsers/id3v2.dart';
import 'package:audio_metadata_reader/src/parsers/mp4.dart';
import 'package:audio_metadata_reader/src/parsers/riff.dart';
import 'package:audio_metadata_reader/src/writers/id3v1_writer.dart';
import 'package:yeah_music/third_party/audio_metadata_reader/mp4_writer_fixed.dart';
import 'package:audio_metadata_reader/src/writers/riff_writer.dart';

import 'flac_writer_with_lyrics.dart';
import 'id3v4_writer_with_uslt.dart';

/// 与 `package:audio_metadata_reader/src/writer.dart` 的 [writeMetadata] 相同路由，
/// 但 MP3 / FLAC 使用带歌词持久化的写入实现。
void writeMetadataWithLyricsFix(File track, ParserTag metadata) {
  final reader = track.openSync();
  try {
    if (ID3v2Parser.canUserParser(reader)) {
      Id3v4WriterWithUslt().write(track, metadata as Mp3Metadata);
    } else if (MP4Parser.canUserParser(reader)) {
      Mp4WriterFixed().write(track, metadata as Mp4Metadata);
    } else if (FlacParser.canUserParser(reader)) {
      FlacWriterWithLyrics().write(track, metadata as VorbisMetadata);
    } else if (RiffParser.canUserParser(reader)) {
      RiffWriter().write(track, metadata as RiffMetadata);
    } else if (ID3v1Parser.canUserParser(reader)) {
      ID3v1Writer().write(track, metadata as Mp3Metadata);
    }
  } finally {
    reader.closeSync();
  }
}
