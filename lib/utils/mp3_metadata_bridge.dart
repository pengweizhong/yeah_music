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

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show AudioMetadata, MetadataParserException;
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show Mp3Metadata, ParserTag;
import 'package:path/path.dart' as p;
import 'package:yeah_music/utils/mp3_id3_tolerant_reader.dart'
    show readMp3Id3v2Tolerant;

bool pathLooksLikeMp3(String path) => p.extension(path).toLowerCase() == '.mp3';

Mp3Metadata _readMp3Tolerant(File file, {required bool getImage}) =>
    readMp3Id3v2Tolerant(file, getImage: getImage);

AudioMetadata _mp3ToAudioMetadata(File file, Mp3Metadata mp3) {
  final meta = AudioMetadata(
    file: file,
    album: mp3.album,
    artist: mp3.bandOrOrchestra ?? mp3.leadPerformer ?? mp3.originalArtist,
    bitrate: mp3.bitrate,
    duration: mp3.duration,
    language: mp3.languages,
    lyrics: mp3.lyric,
    sampleRate: mp3.samplerate,
    title: mp3.songName,
    totalDisc: mp3.totalDics,
    trackNumber: mp3.trackNumber,
    trackTotal: mp3.trackTotal,
    year: DateTime(mp3.originalReleaseYear ?? mp3.year ?? 0),
    discNumber: mp3.discNumber,
  );
  meta.pictures = mp3.pictures;
  meta.genres = mp3.genres;
  return meta;
}

/// 写入前完整读入 MP3 标签（容错 ID3v2，避免库在 GBK/损坏 UTF-8 上抛错）。
ParserTag readMp3MetadataForWrite(File file, {bool getImage = true}) =>
    _readMp3Tolerant(file, getImage: getImage);

/// 列表/详情展示用内嵌元数据。
AudioMetadata readMp3EmbeddedMetadata(
  File file, {
  bool getImage = false,
}) =>
    _mp3ToAudioMetadata(file, _readMp3Tolerant(file, getImage: getImage));

/// 写入后校验：文件头仍为 ID3v2 且可再次读入。
void verifyMp3MetadataReadableAfterWrite(File file) {
  if (!pathLooksLikeMp3(file.path)) return;
  final bytes = file.readAsBytesSync();
  if (bytes.length < 10 ||
      bytes[0] != 0x49 ||
      bytes[1] != 0x44 ||
      bytes[2] != 0x33) {
    throw MetadataParserException(
      track: file,
      message: 'MP3 missing ID3v2 header after write',
    );
  }
  readMp3MetadataForWrite(file, getImage: false);
}
