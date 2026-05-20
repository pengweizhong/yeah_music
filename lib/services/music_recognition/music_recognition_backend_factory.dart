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

import 'package:yeah_music/models/acr_cloud_recognition_config.dart';
import 'package:yeah_music/models/song_recognition_provider.dart';
import 'package:yeah_music/services/music_recognition/acrcloud_music_recognition_backend.dart';
import 'package:yeah_music/services/music_recognition/audd_music_recognition_backend.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_backend.dart';

/// 根据用户选择的引擎创建后端（工厂方法，类似 Java `XXXFactory.getInstance()`）。
final class MusicRecognitionBackendFactory {
  MusicRecognitionBackendFactory._();

  static MusicRecognitionBackend create({
    required SongRecognitionProvider provider,
    required String auddApiToken,
    required AcrCloudRecognitionConfig acrCloudConfig,
  }) {
    switch (provider) {
      case SongRecognitionProvider.audd:
        return AuddMusicRecognitionBackend(apiToken: auddApiToken);
      case SongRecognitionProvider.acrcloud:
        return AcrCloudMusicRecognitionBackend(config: acrCloudConfig);
    }
  }
}
