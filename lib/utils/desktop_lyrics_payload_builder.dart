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

import 'package:flutter/painting.dart' show TextAlign;
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/lyric_highlight_gradient.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';

/// 供独立歌词窗口渲染：结构需可 JSON 序列化（仅 Map / List / num / String / bool）。
abstract final class DesktopLyricsPayloadBuilder {
  static const String channelName = 'yeah_music/desktop_lyrics_payload';

  /// 主进程调用后子窗口应注销 [WindowMethodChannel] 并 [windowManager.close]，释放单向 channel。
  static const String shutdownMethod = 'shutdown';

  /// [linesBefore] / [linesAfter]：以当前时间轴行为基准，向前/向后各允许显示多少条（含边界裁剪）。
  /// [bgOpacity]、[dragLocked]：悬浮窗背景与拖动锁定，由主进程写入 payload。
  static Map<String, dynamic> build({
    required Song? song,
    required Duration position,
    required LyricSettings settings,
    required List<LyricEntry> parsed,
    required String idleText,
    required String noLyricsText,
    required int linesBefore,
    required int linesAfter,
    required double bgOpacity,
    required bool dragLocked,
    int globalDisplayMode = -1,
  }) {
    settings.normalizeLayoutFields();
    final align = settings.lyricTextAlignIndex;
    final rowPad = settings.lyricLineSpacing / 2;

    if (song == null) {
      return _attachChrome(
        _idlePayload(
          text: idleText,
          settings: settings,
          align: align,
          rowPad: rowPad,
        ),
        bgOpacity: bgOpacity,
        dragLocked: dragLocked,
      );
    }
    if (parsed.isEmpty) {
      return _attachChrome(
        _idlePayload(
          text: noLyricsText,
          settings: settings,
          align: align,
          rowPad: rowPad,
        ),
        bgOpacity: bgOpacity,
        dragLocked: dragLocked,
      );
    }

    final idx = LyricsUtils.findCurrentLyricIndex(parsed, position);
    if (idx < 0) {
      return _attachChrome(
        _idlePayload(
          text: '…',
          settings: settings,
          align: align,
          rowPad: rowPad,
        ),
        bgOpacity: bgOpacity,
        dragLocked: dragLocked,
      );
    }

    for (var i = 0; i < parsed.length; i++) {
      parsed[i].isActive = i == idx;
    }

    final b = linesBefore.clamp(0, 999);
    final a = linesAfter.clamp(0, 999);
    final lo = (idx - b).clamp(0, parsed.length - 1);
    final hi = (idx + a).clamp(0, parsed.length - 1);

    final modeMap = settings.lyricDisplayMode;
    final rows = <Map<String, dynamic>>[];

    for (var i = lo; i <= hi; i++) {
      final row = _rowForIndex(
        parsed: parsed,
        index: i,
        effectivePos: position,
        settings: settings,
        lineSpecificMode: modeMap[i],
        globalDisplayMode: globalDisplayMode,
      );
      if (row != null) {
        rows.add(row);
      }
    }

    if (rows.isEmpty) {
      return _attachChrome(
        _idlePayload(
          text: noLyricsText,
          settings: settings,
          align: align,
          rowPad: rowPad,
        ),
        bgOpacity: bgOpacity,
        dragLocked: dragLocked,
      );
    }

    return _attachChrome(
      {
        'rows': rows,
        'align': align,
        'rowPad': rowPad,
      },
      bgOpacity: bgOpacity,
      dragLocked: dragLocked,
    );
  }

  static Map<String, dynamic> _attachChrome(
    Map<String, dynamic> payload, {
    required double bgOpacity,
    required bool dragLocked,
  }) {
    return {
      ...payload,
      'bgOpacity': bgOpacity.clamp(0.0, 1.0),
      'dragLocked': dragLocked,
    };
  }

  static Map<String, dynamic> _idlePayload({
    required String text,
    required LyricSettings settings,
    required int align,
    required double rowPad,
  }) {
    return {
      'rows': [
        {
          'spans': [
            {
              'text': text,
              'fs': settings.originalFontSize,
              'c': settings.upcomingOriginalColor,
              'wt': 400,
            },
          ],
        },
      ],
      'align': align,
      'rowPad': rowPad,
    };
  }

  /// 与播放页「多行歌词」模式一致：当前时间轴行应展示的文本（原文 / 单条翻译 / 全部）。
  static List<String> linesToShowForLyricLine({
    required LyricEntry line,
    required LyricSettings settings,
    required int? lineSpecificMode,
    required int globalDisplayMode,
  }) {
    final displayMode = lineSpecificMode ?? globalDisplayMode;
    final linesToShow = <String>[];

    if (displayMode == -1) {
      if (settings.showOriginal && line.lines.isNotEmpty) {
        linesToShow.add(line.lines[0]);
      }
      if (settings.showTranslations && line.lines.length > 1) {
        linesToShow.addAll(line.lines.sublist(1));
      }
    } else if (displayMode < line.lines.length) {
      linesToShow.add(line.lines[displayMode]);
    } else {
      if (settings.showOriginal && line.lines.isNotEmpty) {
        linesToShow.add(line.lines[0]);
      }
      if (settings.showTranslations && line.lines.length > 1) {
        linesToShow.addAll(line.lines.sublist(1));
      }
    }

    return linesToShow;
  }

  static Map<String, dynamic>? _rowForIndex({
    required List<LyricEntry> parsed,
    required int index,
    required Duration effectivePos,
    required LyricSettings settings,
    required int? lineSpecificMode,
    required int globalDisplayMode,
  }) {
    final line = parsed[index];
    final ts = line.timestamp;
    final played = ts != null && ts <= effectivePos;
    final active = line.isActive;
    final linesToShow = linesToShowForLyricLine(
      line: line,
      settings: settings,
      lineSpecificMode: lineSpecificMode,
      globalDisplayMode: globalDisplayMode,
    );

    if (linesToShow.isEmpty) {
      return null;
    }

    final displayMode = lineSpecificMode ?? globalDisplayMode;

    final isShowingAll = displayMode == -1;
    final isShowingSingleLine =
        displayMode >= 0 && displayMode < line.lines.length;

    final spans = <Map<String, dynamic>>[];

    for (var i = 0; i < linesToShow.length; i++) {
      final originalIndex = isShowingAll ? i : displayMode;
      final isOriginalLine = originalIndex == 0;
      final shouldHighlight = active &&
          ((isShowingAll) ||
              (isShowingSingleLine && originalIndex == displayMode));

      final activeColor = isOriginalLine
          ? settings.activeOriginalColor
          : settings.activeTranslationColor;
      final playedColor = isOriginalLine
          ? settings.playedOriginalColor
          : settings.playedTranslationColor;
      final upcomingColor = isOriginalLine
          ? settings.upcomingOriginalColor
          : settings.upcomingTranslationColor;

      final fs = shouldHighlight && isOriginalLine
          ? settings.originalFontSize + 2
          : (isOriginalLine
              ? settings.originalFontSize
              : settings.translationFontSize);

      final color = shouldHighlight
          ? activeColor
          : (played ? playedColor : upcomingColor);

      final rowKind = shouldHighlight
          ? LyricRowVisualKind.active
          : (played
              ? LyricRowVisualKind.played
              : LyricRowVisualKind.upcoming);
      final rowGradient = lyricRowGradientOrNull(settings, rowKind);

      final span = <String, dynamic>{
        'text': linesToShow[i],
        'fs': fs,
        'c': color,
        'wt': shouldHighlight ? 600 : 400,
      };
      if (rowGradient != null) {
        span['grad'] = true;
        switch (rowKind) {
          case LyricRowVisualKind.active:
            span['g0'] = settings.activeLyricGradientStart;
            span['g1'] = settings.activeLyricGradientEnd;
            span['gd'] = settings.activeLyricGradientDirectionIndex;
          case LyricRowVisualKind.played:
            span['g0'] = settings.playedLyricGradientStart;
            span['g1'] = settings.playedLyricGradientEnd;
            span['gd'] = settings.playedLyricGradientDirectionIndex;
          case LyricRowVisualKind.upcoming:
            span['g0'] = settings.upcomingLyricGradientStart;
            span['g1'] = settings.upcomingLyricGradientEnd;
            span['gd'] = settings.upcomingLyricGradientDirectionIndex;
        }
      }
      spans.add(span);
    }

    return {'spans': spans};
  }

  static TextAlign alignFromIndex(int index) {
    switch (index) {
      case 0:
        return TextAlign.left;
      case 2:
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }
}
