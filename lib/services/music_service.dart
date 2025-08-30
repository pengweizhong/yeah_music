import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/models/song.dart';

import '../repositories/song_repository.dart';

var log = Logger(printer: SimplePrinter());

class MusicService {
  final _player = AudioPlayer();
  final SongRepository _repo = SongRepository();

  // 当前播放歌曲的 ValueNotifier
  final ValueNotifier<Song?> valueNotifierSong = ValueNotifier<Song?>(null);

  List<UriAudioSource> audioSources = [];
  int currentIndex = -1;

  Future<void> loadSongs(String folderPath) async {
    audioSources = await _repo.loadAudioSources(folderPath);
    // Load the playlist
    await _player.setAudioSources(
      audioSources,
      initialIndex: 0,
      initialPosition: Duration.zero,
      shuffleOrder: DefaultShuffleOrder(), // 可选：自定义洗牌
    );
    await setLoopMode(LoopMode.all);
    // 监听播放状态
    //顺序播放（LoopMode.off） → 监听 completed，手动调用 playNext()
    // 列表循环（LoopMode.all） → 播放器自己会循环，不需要手动调用 playNext()
    // 单曲循环（LoopMode.one） → 播放器会在同一首重复，也不触发 completed
    // _player.processingStateStream.listen((state) {
    //   log.d("当前歌曲播放状态: $state");
    //   if (state == ProcessingState.completed) {
    //     log.d("当前歌曲播放完成，自动播放下一曲");
    //     playNext(); // 播放完自动下一曲
    //   }
    // });
    //统一获取“每首歌播放完件”，无论循环模式：
    _player.sequenceStateStream.listen((sequenceState) {
      final current = sequenceState.currentSource;
      final index = sequenceState.currentIndex;
      if (index != null && current?.tag != valueNotifierSong.value) {
        log.d(
          "更新当前播放歌曲，${(current?.tag as Song).title}, 上一首：${valueNotifierSong.value?.title}",
        );
        valueNotifierSong.value = audioSources[index].tag;
      }
    });
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= audioSources.length) {
      log.e("无效的音乐下标: $index");
      return;
    }

    valueNotifierSong.value = audioSources[index].tag;
    currentIndex = index;
    log.d("播放歌曲: ${valueNotifierSong.value}，音乐下标： $currentIndex");
    try {
      await stop();
      await seek(Duration.zero, index: index);
      await play();
    } catch (e) {
      log.e("播放失败: $e");
    }
  }

  void playNext() {
    currentIndex = (currentIndex + 1) % audioSources.length;
    playSong(currentIndex);
  }

  void playPrev() {
    currentIndex = (currentIndex - 1) % audioSources.length;
    playSong(currentIndex);
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
}
