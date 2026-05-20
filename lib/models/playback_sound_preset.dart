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

/// 播放音效预设（Android 硬件均衡器 + 响度；其它平台忽略）。
enum PlaybackSoundPreset {
  /// 关闭效果，原声。
  standard,

  /// 削弱低频、略抬中高频，突出人声。
  pureVocals,

  /// 两端略抬，中间略收，听感更开阔。
  spatialWide,

  rock,
  pop,
  electronic,
  classical,
  jazz,

  /// 现场感：略增强低频冲击与高频空气感。
  liveStage,

  /// 小空间混响色彩（浴室感）：略闷的中低频 + 湿滑高频。
  cozyRoom,

  /// 播客 / 口播：抬中高频清晰度，压低轰鸣与糊感。
  podcastVoice,

  /// 金属：更重的低频与中高频攻击性。
  metal,

  /// 嘻哈：Kick 下沉、节奏与齿音区略抬。
  hipHop,

  /// Lo-Fi：暗化高频、略抬盒子感中低频。
  loFi,

  /// 夜间聆听：整体收尖亮，减轻久听疲劳。
  nightComfort,

  /// 低频与响度增强。
  bassBoost,

  /// 用户在各频段上自定义 dB（见 Hive 自定义曲线）。
  custom;

  String get storageId {
    switch (this) {
      case PlaybackSoundPreset.standard:
        return 'standard';
      case PlaybackSoundPreset.pureVocals:
        return 'pure_vocals';
      case PlaybackSoundPreset.spatialWide:
        return 'spatial_wide';
      case PlaybackSoundPreset.rock:
        return 'rock';
      case PlaybackSoundPreset.pop:
        return 'pop';
      case PlaybackSoundPreset.electronic:
        return 'electronic';
      case PlaybackSoundPreset.classical:
        return 'classical';
      case PlaybackSoundPreset.jazz:
        return 'jazz';
      case PlaybackSoundPreset.liveStage:
        return 'live_stage';
      case PlaybackSoundPreset.cozyRoom:
        return 'cozy_room';
      case PlaybackSoundPreset.podcastVoice:
        return 'podcast_voice';
      case PlaybackSoundPreset.metal:
        return 'metal';
      case PlaybackSoundPreset.hipHop:
        return 'hip_hop';
      case PlaybackSoundPreset.loFi:
        return 'lo_fi';
      case PlaybackSoundPreset.nightComfort:
        return 'night';
      case PlaybackSoundPreset.bassBoost:
        return 'bass_boost';
      case PlaybackSoundPreset.custom:
        return 'custom';
    }
  }

  static PlaybackSoundPreset fromStorageId(String? raw) {
    switch (raw) {
      case 'pure_vocals':
        return PlaybackSoundPreset.pureVocals;
      case 'spatial_wide':
        return PlaybackSoundPreset.spatialWide;
      case 'rock':
        return PlaybackSoundPreset.rock;
      case 'pop':
        return PlaybackSoundPreset.pop;
      case 'electronic':
        return PlaybackSoundPreset.electronic;
      case 'classical':
        return PlaybackSoundPreset.classical;
      case 'jazz':
        return PlaybackSoundPreset.jazz;
      case 'live_stage':
        return PlaybackSoundPreset.liveStage;
      case 'cozy_room':
        return PlaybackSoundPreset.cozyRoom;
      case 'podcast_voice':
        return PlaybackSoundPreset.podcastVoice;
      case 'metal':
        return PlaybackSoundPreset.metal;
      case 'hip_hop':
        return PlaybackSoundPreset.hipHop;
      case 'lo_fi':
        return PlaybackSoundPreset.loFi;
      case 'night':
        return PlaybackSoundPreset.nightComfort;
      case 'bass_boost':
        return PlaybackSoundPreset.bassBoost;
      case 'custom':
        return PlaybackSoundPreset.custom;
      case 'standard':
      default:
        return PlaybackSoundPreset.standard;
    }
  }
}
