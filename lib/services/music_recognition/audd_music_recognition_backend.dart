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

import 'package:yeah_music/services/audd_music_recognition_service.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_backend.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_outcome.dart';

/// AudD 实现。
final class AuddMusicRecognitionBackend implements MusicRecognitionBackend {
  AuddMusicRecognitionBackend({required this.apiToken});

  final String apiToken;

  @override
  Future<MusicRecognitionOutcome> recognizeFile(File file) async {
    final o = await AuddMusicRecognitionService.recognizeFile(
      file: file,
      apiToken: apiToken,
    );
    if (o.isSuccess) {
      return MusicRecognitionOutcome(
        rawStatus: 'success',
        title: o.title,
        artist: o.artist,
        album: o.album,
        releaseDate: o.releaseDate,
        appleMusicUrl: o.appleMusicUrl,
        spotifyUrl: o.spotifyUrl,
      );
    }
    if (o.isNoMatch) {
      return const MusicRecognitionOutcome(rawStatus: 'success');
    }
    return MusicRecognitionOutcome(
      rawStatus: 'error',
      errorMessage: o.errorMessage ?? o.rawStatus,
    );
  }
}
