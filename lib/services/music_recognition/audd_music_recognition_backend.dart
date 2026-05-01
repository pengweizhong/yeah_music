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
