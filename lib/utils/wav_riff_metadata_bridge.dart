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
    show AudioMetadata, Picture, readAllMetadata;
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show ParserTag, RiffMetadata;
import 'package:yeah_music/utils/file_utils.dart' show readEmbeddedAudioMetadata;
import 'package:yeah_music/utils/wav_metadata_reader.dart' show pathLooksLikeWav;

/// 写入前完整读入标签。WAV 走 [readEmbeddedAudioMetadata]（`readAllMetadata` 不支持 RIFF）。
ParserTag readAllMetadataForWrite(File file, {bool getImage = true}) {
  if (pathLooksLikeWav(file.path)) {
    return riffMetadataFromEmbeddedRead(
      readEmbeddedAudioMetadata(
        file,
        getImage: getImage,
        repairLyrics: false,
      ),
    );
  }
  return readAllMetadata(file, getImage: getImage);
}

RiffMetadata riffMetadataFromEmbeddedRead(AudioMetadata meta) {
  final r = RiffMetadata(
    title: meta.title,
    artist: meta.artist,
    album: meta.album,
    year: meta.year,
    bitrate: meta.bitrate,
    samplerate: meta.sampleRate,
    duration: meta.duration,
    trackNumber: meta.trackNumber,
  );
  if (meta.genres.isNotEmpty) {
    r.genre = meta.genres.first;
  }
  r.pictures = List<Picture>.from(meta.pictures);
  return r;
}
