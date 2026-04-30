import 'package:flutter/material.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';

/// 与播放页三种行状态对应的渐变来源。
enum LyricRowVisualKind {
  active,
  played,
  upcoming,
}

LinearGradient _pairGradient(int startArgb, int endArgb, int directionIndex) {
  return playlistCoverLinearGradient(
    [
      Color(startArgb),
      Color(endArgb),
    ],
    direction: PlaylistCoverGradientDirection.fromStorage(directionIndex),
  );
}

/// 该行状态下若开启渐变则返回渐变，否则 `null`（应用纯色）。
LinearGradient? lyricRowGradientOrNull(
  LyricSettings s,
  LyricRowVisualKind kind,
) {
  switch (kind) {
    case LyricRowVisualKind.active:
      if (!s.activeLyricUseGradient) return null;
      return _pairGradient(
        s.activeLyricGradientStart,
        s.activeLyricGradientEnd,
        s.activeLyricGradientDirectionIndex,
      );
    case LyricRowVisualKind.played:
      if (!s.playedLyricUseGradient) return null;
      return _pairGradient(
        s.playedLyricGradientStart,
        s.playedLyricGradientEnd,
        s.playedLyricGradientDirectionIndex,
      );
    case LyricRowVisualKind.upcoming:
      if (!s.upcomingLyricUseGradient) return null;
      return _pairGradient(
        s.upcomingLyricGradientStart,
        s.upcomingLyricGradientEnd,
        s.upcomingLyricGradientDirectionIndex,
      );
  }
}
