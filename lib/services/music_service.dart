import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../models/song.dart';

var log = Logger(printer: SimplePrinter());

class MusicService {
  final _player = AudioPlayer();

  Future<void> playSong(Song song) async {
    log.d("播放歌曲: ${song.title}");
    try {
      await stop();
      await seek(Duration.zero);
      _player.setAudioSource(AudioSource.uri(Uri.file(song.path), tag: song));
      await play();
    } catch (e) {
      log.e("播放失败: $e");
    }
  }

  void playNext() {
    // playSong((currentIndex! + 1) % playlist.length);
  }

  void playPrev() {
    // playSong((currentIndex! - 1) % playlist.length);
  }

  ///开始播放
  Future<void> play() async {
    return _player.play();
  }

  ///暂停播放
  Future<void> pause() async => _player.pause();

  ///恢复播放
  Future<void> resume() async => play();

  ///设置音乐列表播放模式
  Future<void> setLoopMode(LoopMode mode) async => _player.setLoopMode(mode);

  Future<void> dispose() async {
    return _player.dispose();
  }

  ///定位播放进度
  Future<void> seek(Duration duration, {int? index}) async {
    return _player.seek(duration, index: index);
  }

  ///暂停播放
  Future<void> stop() async {
    return _player.stop();
  }

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  int? get currentIndex => _player.currentIndex;
}
