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

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/flac.dart';
import 'package:audio_metadata_reader/src/parsers/id3v1.dart';
import 'package:audio_metadata_reader/src/parsers/id3v2.dart';
import 'package:audio_metadata_reader/src/parsers/mp4.dart';
import 'package:audio_metadata_reader/src/parsers/riff.dart';
import 'package:audio_metadata_reader/src/writers/id3v1_writer.dart';
import 'package:yeah_music/third_party/audio_metadata_reader/mp4_writer_fixed.dart';
import 'package:yeah_music/third_party/audio_metadata_reader/riff_writer_fixed.dart';

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
      RiffWriterFixed().write(track, metadata as RiffMetadata);
    } else if (ID3v1Parser.canUserParser(reader)) {
      ID3v1Writer().write(track, metadata as Mp3Metadata);
    }
  } finally {
    reader.closeSync();
  }
}
