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

import 'package:path/path.dart' as p;
import 'package:yeah_music/models/song.dart';

/// 音质分级（展示短码：LQ / STD / HQ / SQ / HR / DSD）。
///
/// 从低到高的展示顺序见 [kSongAudioQualityTiersLowToHigh]。
enum SongAudioQualityTier {
  /// 流畅
  lq,

  /// 标准
  std,

  /// 高品质
  hq,

  /// 无损（CD 级）
  sq,

  /// 高解析
  hr,

  /// 顶级发烧（DSD）
  dsd,
}

/// 设置页音质说明、列表标识等：从低到高穷举。
const List<SongAudioQualityTier> kSongAudioQualityTiersLowToHigh = [
  SongAudioQualityTier.lq,
  SongAudioQualityTier.std,
  SongAudioQualityTier.hq,
  SongAudioQualityTier.sq,
  SongAudioQualityTier.hr,
  SongAudioQualityTier.dsd,
];

extension SongAudioQualityTierCode on SongAudioQualityTier {
  String get shortLabel => switch (this) {
        SongAudioQualityTier.lq => 'LQ',
        SongAudioQualityTier.std => 'STD',
        SongAudioQualityTier.hq => 'HQ',
        SongAudioQualityTier.sq => 'SQ',
        SongAudioQualityTier.hr => 'HR',
        SongAudioQualityTier.dsd => 'DSD',
      };
}

/// 路径级缓存失效（文件变更或元数据刷新前）。
final Map<String, SongAudioQualityTier?> _tierMemo = {};

/// [SongLibraryMetadataHydrator.invalidatePath] 等场景调用。
void invalidateSongAudioQualityCacheForPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return;
  _tierMemo.removeWhere((key, _) => key.startsWith('$trimmed|'));
}

SongAudioQualityTier? classifySongAudioQuality(Song song) {
  final path = song.path.trim();
  if (path.isEmpty) return null;

  final br = song.bitrate;
  final sr = song.sampleRate;
  final key = '$path|${br ?? '-'}|${sr ?? '-'}';
  if (_tierMemo.containsKey(key)) {
    return _tierMemo[key];
  }

  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  final kbps = _bitrateToKbps(br);

  SongAudioQualityTier? tier;

  if (ext == 'dff' || ext == 'dsf') {
    tier = SongAudioQualityTier.dsd;
  } else if (_isLosslessExtension(ext)) {
    tier = _tierLossless(sr);
  } else if (ext == 'm4a') {
    tier = _tierM4a(kbps, sr);
  } else if (_isLossyExtension(ext)) {
    tier = kbps != null ? _tierLossy(kbps) : null;
  } else {
    tier = _tierUnknownExtension(kbps, sr);
  }

  if (_tierMemo.length > 4000) {
    _tierMemo.clear();
  }
  _tierMemo[key] = tier;
  return tier;
}

bool _isLosslessExtension(String ext) {
  return ext == 'flac' ||
      ext == 'wav' ||
      ext == 'ape' ||
      ext == 'wv' ||
      ext == 'aiff' ||
      ext == 'aif';
}

bool _isLossyExtension(String ext) {
  return ext == 'mp3' ||
      ext == 'aac' ||
      ext == 'ogg' ||
      ext == 'opus' ||
      ext == 'wma' ||
      ext == 'mpc';
}

SongAudioQualityTier _tierLossless(int? sampleRateHz) {
  final sr = sampleRateHz ?? 44100;
  if (sr >= 88200) {
    return SongAudioQualityTier.hr;
  }
  return SongAudioQualityTier.sq;
}

SongAudioQualityTier? _tierM4a(int? kbps, int? sr) {
  if (kbps != null && kbps >= 400) {
    final rate = sr ?? 44100;
    return rate >= 88200 ? SongAudioQualityTier.hr : SongAudioQualityTier.sq;
  }
  if (kbps != null) {
    return _tierLossy(kbps);
  }
  return null;
}

SongAudioQualityTier? _tierUnknownExtension(int? kbps, int? sr) {
  if (sr != null && sr >= 88200 && kbps != null && kbps >= 350) {
    return SongAudioQualityTier.hr;
  }
  if (kbps == null) return null;
  if (kbps >= 450) {
    final rate = sr ?? 44100;
    return rate >= 88200 ? SongAudioQualityTier.hr : SongAudioQualityTier.sq;
  }
  return _tierLossy(kbps);
}

SongAudioQualityTier _tierLossy(int kbps) {
  if (kbps >= 256) return SongAudioQualityTier.hq;
  if (kbps >= 160) return SongAudioQualityTier.std;
  if (kbps >= 96) return SongAudioQualityTier.std;
  return SongAudioQualityTier.lq;
}

/// 常见库返回 bps（如 320000）；过小值按 kbps 字面处理。
int? _bitrateToKbps(int? raw) {
  if (raw == null || raw <= 0) return null;
  if (raw >= 32000) {
    return (raw + 500) ~/ 1000;
  }
  return raw;
}
