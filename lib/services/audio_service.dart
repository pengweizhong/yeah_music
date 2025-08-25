import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<bool> get playingStream => _player.playingStream;
  Duration? get duration => _player.duration;

  Future<void> playSong(Song song) async {
    try {
      await _player.stop();
      await _player.setFilePath(song.path);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  void dispose() => _player.dispose();
}
