import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../repositories/song_repository.dart';

class MusicService {
  final _player = AudioPlayer();
  final SongRepository _repo = SongRepository();

  List<Song> songs = [];
  int currentIndex = -1;

  Future<void> loadSongs(String folderPath) async {
    songs = await _repo.loadSongs(folderPath);
    currentIndex = -1;
  }

  Song? get currentSong => (currentIndex >= 0 && currentIndex < songs.length)
      ? songs[currentIndex]
      : null;

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.length) return;
    final song = songs[index];
    try {
      await _player.stop();
      await _player.setFilePath(song.path);
      await _player.play();
      currentIndex = index;
    } catch (e) {
      print("播放失败: $e");
    }
  }

  void playNext() => playSong((currentIndex + 1) % songs.length);

  void playPrev() => playSong((currentIndex - 1 + songs.length) % songs.length);

  void pause() => _player.pause();

  void resume() => _player.play();

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  void dispose() {
    _player.dispose();
  }

  void seek(Duration duration) {
    _player.seek(duration);
  }

  void stop() {
    _player.stop();
  }

}
