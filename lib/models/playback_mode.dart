enum PlaybackMode {
  sequential, // 顺序播放
  shuffle, // 随机播放
  singleLoop, // 单曲循环
  playOnce, // 仅播放一次
  timerShutdown, // 定时关闭
}

extension PlaybackModeExtension on PlaybackMode {
  String get displayName {
    switch (this) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.shuffle:
        return '随机播放';
      case PlaybackMode.singleLoop:
        return '单曲循环';
      case PlaybackMode.playOnce:
        return '仅播放一次';
      case PlaybackMode.timerShutdown:
        return '定时关闭';
    }
  }

  int get value {
    switch (this) {
      case PlaybackMode.sequential:
        return 0;
      case PlaybackMode.shuffle:
        return 1;
      case PlaybackMode.singleLoop:
        return 2;
      case PlaybackMode.playOnce:
        return 3;
      case PlaybackMode.timerShutdown:
        return 4;
    }
  }

  static PlaybackMode fromValue(int value) {
    switch (value) {
      case 0:
        return PlaybackMode.sequential;
      case 1:
        return PlaybackMode.shuffle;
      case 2:
        return PlaybackMode.singleLoop;
      case 3:
        return PlaybackMode.playOnce;
      case 4:
        return PlaybackMode.timerShutdown;
      default:
        return PlaybackMode.sequential;
    }
  }
}
