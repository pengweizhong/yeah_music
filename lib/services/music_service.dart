import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../models/song.dart';
import '../repositories/song_repository.dart';

var log = Logger(printer: SimplePrinter());

class MusicService {
  final _player = AudioPlayer();
  final SongRepository _repo = SongRepository();

  // 当前播放歌曲的 ValueNotifier
  final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);

  List<Song> songs = [];
  int currentIndex = -1;

  Future<void> loadSongs(String folderPath) async {
    songs = await _repo.loadSongs(folderPath);
    currentIndex = -1;
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.length) {
      log.e("无效的音乐下标: $index");
      return;
    }
    final song = songs[index];
    currentSong.value = song;
    currentIndex = index;
    log.d("播放歌曲: ${song.title}，音乐下标： $currentIndex");
    try {
      await _player.stop();
      await _player.setFilePath(song.path);
      await _player.play();
    } catch (e) {
      log.e("播放失败: $e");
    }
  }

  void playNext() {
    currentIndex = (currentIndex + 1) % songs.length;
    playSong(currentIndex);
  }

  void playPrev() {
    currentIndex = (currentIndex - 1) % songs.length;
    playSong(currentIndex);
  }

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
