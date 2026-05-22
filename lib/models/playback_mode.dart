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

enum PlaybackMode {
  sequential, // 顺序播放（列表播完后停止）
  shuffle, // 随机播放（列表播完后重新洗牌循环）
  listLoop, // 列表循环
  singleLoop, // 单曲循环
  playOnce, // 仅播放一次
  timerShutdown, // 已废弃：定时关闭改由「更多」入口；仅兼容旧持久化值
}

/// 播放模式弹窗可选项（不含 [PlaybackMode.timerShutdown]）。
const List<PlaybackMode> kPlaybackModesForSheet = [
  PlaybackMode.sequential,
  PlaybackMode.shuffle,
  PlaybackMode.listLoop,
  PlaybackMode.singleLoop,
  PlaybackMode.playOnce,
];

extension PlaybackModeExtension on PlaybackMode {
  /// 列表播完后是否从头继续（顺序播放为 false）。
  bool get loopsList {
    switch (this) {
      case PlaybackMode.listLoop:
      case PlaybackMode.shuffle:
        return true;
      case PlaybackMode.sequential:
      case PlaybackMode.singleLoop:
      case PlaybackMode.playOnce:
      case PlaybackMode.timerShutdown:
        return false;
    }
  }

  /// 仅作调试或日志用；UI 请使用 [playbackModeLabel] 与 [AppLocalizations]。
  String get displayName {
    switch (this) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.shuffle:
        return '随机播放';
      case PlaybackMode.listLoop:
        return '列表循环';
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
      case PlaybackMode.listLoop:
        return 2;
      case PlaybackMode.singleLoop:
        return 3;
      case PlaybackMode.playOnce:
        return 4;
      case PlaybackMode.timerShutdown:
        return 5;
    }
  }

  static PlaybackMode fromValue(int value) {
    switch (value) {
      case 0:
        return PlaybackMode.sequential;
      case 1:
        return PlaybackMode.shuffle;
      case 2:
        return PlaybackMode.listLoop;
      case 3:
        return PlaybackMode.singleLoop;
      case 4:
        return PlaybackMode.playOnce;
      case 5:
        return PlaybackMode.timerShutdown;
      default:
        return PlaybackMode.sequential;
    }
  }

  /// 将旧版持久化整型（无 [listLoop]）映射为当前枚举。
  static PlaybackMode fromLegacyStoredValue(int value) {
    if (value <= 1) return fromValue(value);
    return fromValue(value + 1);
  }
}
