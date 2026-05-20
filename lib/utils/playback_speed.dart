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

/// 播放倍速选项（与播放页「更多 → 倍速」一致）。
const List<double> kPlaybackSpeedOptions = [
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
];

const double kDefaultPlaybackSpeed = 1.0;

double normalizePlaybackSpeed(double? raw) {
  if (raw == null || !raw.isFinite || raw <= 0) {
    return kDefaultPlaybackSpeed;
  }
  for (final o in kPlaybackSpeedOptions) {
    if ((raw - o).abs() < 0.001) return o;
  }
  return kDefaultPlaybackSpeed;
}

/// 通知栏 / 列表展示用，如 `1x`、`1.25x`。
String playbackSpeedLabel(double speed) {
  final s = normalizePlaybackSpeed(speed);
  if (s == s.roundToDouble()) return '${s.toInt()}x';
  final t = s.toStringAsFixed(2);
  return '${t.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
}
