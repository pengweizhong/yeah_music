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
