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

import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/auto_marquee_single_line_text.dart';

/// 歌曲列表专用：仅当本行为当前播放（[isCurrentTrack]）且标题宽度不足时横向循环滚动；
/// 否则单行省略（与非当前行一致）。
///
/// 用于曲库 / 歌单 / 最近播放等共用列表行的一级标题或二级文案。
class SongListMarqueeWhenCurrentLine extends StatelessWidget {
  const SongListMarqueeWhenCurrentLine({
    super.key,
    required this.text,
    required this.style,
    required this.isCurrentTrack,
    this.gapBetweenLoops = 40,
    this.pixelsPerSecond = 36,
  });

  final String text;
  final TextStyle style;

  /// 与列表「当前正在播放」行对应时为 true。
  final bool isCurrentTrack;
  final double gapBetweenLoops;
  final double pixelsPerSecond;

  @override
  Widget build(BuildContext context) {
    return AutoMarqueeSingleLineText(
      text: text,
      style: style,
      enableMarquee: isCurrentTrack,
      gapBetweenLoops: gapBetweenLoops,
      pixelsPerSecond: pixelsPerSecond,
    );
  }
}
