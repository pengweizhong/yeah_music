import 'dart:io';

import 'package:yeah_music/services/music_recognition/music_recognition_outcome.dart';

/// 识曲后端策略（类似 Java 的 `RecognitionStrategy`）。
abstract interface class MusicRecognitionBackend {
  Future<MusicRecognitionOutcome> recognizeFile(File file);
}
