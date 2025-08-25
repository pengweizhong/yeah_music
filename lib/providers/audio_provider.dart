import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/audio_service.dart';

final audioServiceProvider = Provider((ref) => AudioService());

final songListProvider = StateProvider<List<Song>>((ref) => []);
final currentIndexProvider = StateProvider<int>((ref) => -1);

class AudioController {
  final AudioService _service;

  AudioController(this._service);

  Future<void> playSong(Song song) => _service.playSong(song as int);

  void pause() => _service.pause();

  void resume() => _service.resume();

  void seek(Duration position) => _service.seek(position);

  void playNext() => _service.playNext();

  void playPrev() => _service.playPrev();

  void stop() => _service.stop();

  void dispose() => _service.dispose();
}
