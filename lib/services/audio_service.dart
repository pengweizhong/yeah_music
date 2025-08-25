import 'dart:io';

import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  List<FileSystemEntity> songs = [];
  int currentIndex = -1;

  AudioPlayer get player => _player;

  Future<void> loadSongs(String path) async {
    final dir = Directory(path);
    final files = dir
        .listSync()
        .where(
          (f) =>
              f.path.endsWith(".mp3") ||
              f.path.endsWith(".flac") ||
              f.path.endsWith(".m4a") ||
              f.path.endsWith(".wav"),
        )
        .toList();

    songs = files;
    currentIndex = -1;
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.length) return;
    final song = songs[index];
    await _player.stop();
    await _player.setFilePath(song.path);
    await _player.play();
    currentIndex = index;
  }

  void playNext() {
    if (songs.isEmpty) return;
    final next = (currentIndex + 1) % songs.length;
    playSong(next);
  }

  void playPrev() {
    if (songs.isEmpty) return;
    final prev = (currentIndex - 1 + songs.length) % songs.length;
    playSong(prev);
  }

  void resume() => _player.play();

  void pause() => _player.pause();

  void dispose() {
    _player.dispose();
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void stop() {
    _player.stop();
  }
}
