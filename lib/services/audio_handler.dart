// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/logging/app_log.dart';

/// 音频处理器 - 处理后台音频和通知栏
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayerHandler() {
    // 监听播放状态变化
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });
    
    // 监听播放完成
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }
  
  AudioPlayer get player => _player;
  
  /// 广播播放状态
  void _broadcastState() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }
  
  @override
  Future<void> play() => _player.play();
  
  @override
  Future<void> pause() => _player.pause();
  
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  
  @override
  Future<void> skipToNext() async {
    // 由外部控制
  }
  
  @override
  Future<void> skipToPrevious() async {
    // 由外部控制
  }
  
  /// 设置音频源并更新媒体项
  Future<void> setAudioSourceWithMediaItem(
    AudioSource source,
    MediaItem mediaItem,
  ) async {
    try {
      // 更新媒体项
      this.mediaItem.add(mediaItem);
      
      // 设置音频源
      await _player.setAudioSource(source);
      
    } catch (e) {
      appLog.e('audio_service: 设置音频源失败', error: e);
      rethrow;
    }
  }
  
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}



