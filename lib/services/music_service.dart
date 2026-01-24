import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../models/song.dart';

var log = Logger(printer: SimplePrinter());

class MusicService {
  //播放器成为全局单例
  static final _player = AudioPlayer();
  static bool isPlaying = false;

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
    await _player.play();
    isPlaying = _player.playing;
  }

  ///暂停播放
  Future<void> pause() async {
    await _player.pause();
    isPlaying = false;
  }

  ///恢复播放
  Future<void> resume() async {
    await _player.play();
    isPlaying = _player.playing;
  }

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
    isPlaying = false;
    return _player.stop();
  }

  static Stream<bool> get playingStream {
    return _player.playingStream.map((playing) {
      isPlaying = playing;
      return playing;
    });
  }

  static Stream<Duration> get positionStream => _player.positionStream;

  static Stream<Duration?> get durationStream => _player.durationStream;

  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static Duration? get duration => _player.duration;

  static int? get currentIndex => _player.currentIndex;
}
