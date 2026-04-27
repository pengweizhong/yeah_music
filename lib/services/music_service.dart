import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/compments/bookmark_service.dart';
import 'package:yeah_music/logging/app_log.dart';

import '../models/song.dart';

class MusicService {
  //播放器成为全局单例
  static final _player = AudioPlayer();
  static bool isPlaying = false;

  /// 串行换源，避免自然播放结束瞬间立刻 setAudioSource 触发「Loading interrupted」
  static Future<void> _playChain = Future.value();

  Future<void> playSong(Song song) {
    final f = _playChain
        .catchError((Object? e) {
      appLog.d('playSong 前序(可忽略): $e');
    })
        .then((_) => _playSongBody(song));
    _playChain = f;
    return f;
  }

  Future<void> _playSongBody(Song song) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _player.stop();
        // 给平台层从 completed/idle 收尾再换源，降低并发中断
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 64));
        }
        await _player.setAudioSource(_buildAudioSource(song));
        await _player.seek(Duration.zero);
        play();
        return;
      } catch (e) {
        final msg = e.toString();
        if (attempt == 0 && msg.contains('interrupted')) {
          appLog.d('换源被中断，重试一次: $e');
          continue;
        }
        // macOS 安全作用域未恢复时常见 257 / permission
        if (attempt < 2 &&
            Platform.isMacOS &&
            (msg.contains('257') ||
                msg.contains('permission') ||
                msg.contains('Permission'))) {
          appLog.d('macOS: 尝试恢复安全作用域书签后重试播放');
          try {
            await BookmarkService.restoreAllBookmarks();
          } catch (_) {}
          continue;
        }
        appLog.e('设置音频并播放失败', error: e);
        return;
      }
    }
  }

  AudioSource _buildAudioSource(Song song) {
    final uri = Uri.file(song.path);
    final path = song.path.toLowerCase();
    if (path.endsWith('.mp3')) {
      return ProgressiveAudioSource(
        uri,
        tag: song,
        options: const ProgressiveAudioSourceOptions(
          androidExtractorOptions: AndroidExtractorOptions(
            constantBitrateSeekingEnabled: true,
            constantBitrateSeekingAlwaysEnabled: true,
            mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking,
          ),
          darwinAssetOptions: DarwinAssetOptions(
            preferPreciseDurationAndTiming: true,
          ),
        ),
      );
    }

    return ProgressiveAudioSource(
      uri,
      tag: song,
      options: const ProgressiveAudioSourceOptions(
        darwinAssetOptions: DarwinAssetOptions(
          preferPreciseDurationAndTiming: true,
        ),
      ),
    );
  }

  void playNext() {
    // playSong((currentIndex! + 1) % playlist.length);
  }

  void playPrev() {
    // playSong((currentIndex! - 1) % playlist.length);
  }

  ///开始播放
  void play() {
    _player.play();
    isPlaying = _player.playing;
  }

  ///暂停播放
  Future<void> pause() async {
    await _player.pause();
    isPlaying = false;
  }

  ///恢复播放（需已有音源；冷启动后从未 [setAudioSource] 时 [resume] 无效果，应改 [playSong]）
  void resume() {
    _player.play();
    isPlaying = _player.playing;
  }

  /// 当前是否适合直接 [resume]（已有音源且可继续）。为 idle/completed 时应走 [playSong]。
  static bool get canUseResumeToPlay {
    switch (_player.processingState) {
      case ProcessingState.ready:
      case ProcessingState.buffering:
      case ProcessingState.loading:
        return true;
      case ProcessingState.idle:
      case ProcessingState.completed:
        return false;
    }
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

  /// 最近一次 [positionStream] 的位置，供 UI 在尚未收到下一帧流事件时与歌词对齐
  static Duration _positionCache = Duration.zero;

  static Duration get lastPosition => _positionCache;

  static Stream<Duration> get positionStream {
    return _player.positionStream.map((d) {
      _positionCache = d;
      return d;
    });
  }

  static Stream<Duration?> get durationStream => _player.durationStream;

  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static Duration? get duration => _player.duration;

  static int? get currentIndex => _player.currentIndex;
}
