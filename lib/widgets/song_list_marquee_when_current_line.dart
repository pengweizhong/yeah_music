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
