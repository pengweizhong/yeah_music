import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/widgets/auto_marquee_single_line_text.dart';
import 'package:yeah_music/widgets/song_list_marquee_when_current_line.dart';

Color songAudioQualityAccent(SongAudioQualityTier tier, BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (tier) {
    SongAudioQualityTier.lq =>
      dark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A),
    SongAudioQualityTier.std =>
      dark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
    SongAudioQualityTier.hq =>
      dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
    SongAudioQualityTier.sq =>
      dark ? const Color(0xFF4DD0E1) : const Color(0xFF00838F),
    SongAudioQualityTier.hr =>
      dark ? const Color(0xFFE1BEE7) : const Color(0xFF4527A0),
    SongAudioQualityTier.dsd =>
      dark ? const Color(0xFFFFE082) : const Color(0xFFF57F17),
  };
}

String songAudioQualityLocalizedTitle(AppLocalizations l10n, SongAudioQualityTier t) {
  return switch (t) {
    SongAudioQualityTier.lq => l10n.audioQualityTierLq,
    SongAudioQualityTier.std => l10n.audioQualityTierStd,
    SongAudioQualityTier.hq => l10n.audioQualityTierHq,
    SongAudioQualityTier.sq => l10n.audioQualityTierSq,
    SongAudioQualityTier.hr => l10n.audioQualityTierHr,
    SongAudioQualityTier.dsd => l10n.audioQualityTierDsd,
  };
}

class _BadgeTierStyle {
  const _BadgeTierStyle({
    required this.padding,
    required this.decoration,
    required this.textStyle,
  });

  final EdgeInsets padding;
  final BoxDecoration decoration;
  final TextStyle textStyle;
}

_BadgeTierStyle _tierBadgeStyle(
  SongAudioQualityTier tier,
  Brightness brightness,
  bool compact,
) {
  final isDark = brightness == Brightness.dark;
  final fs = compact ? 9.5 : 10.5;
  /// 整体偏「细」：字重克制，高档略加重。
  final wRegular = FontWeight.w600;
  final wEmphasis = FontWeight.w700;

  final padH = compact ? 4.5 : 5.5;
  final padV = compact ? 1.5 : 2.0;

  switch (tier) {
    case SongAudioQualityTier.lq:
      // 低档：明显「淡出」——浅填色 + 细线框 + 弱对比字色。
      final fg = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF607D8B);
      final edge = isDark ? const Color(0xFF78909C) : const Color(0xFF90A4AE);
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: edge.withValues(alpha: isDark ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: 0.75,
            color: edge.withValues(alpha: isDark ? 0.22 : 0.28),
          ),
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w500,
          height: 1,
          letterSpacing: 0.35,
          color: fg.withValues(alpha: isDark ? 0.62 : 0.58),
        ),
      );

    case SongAudioQualityTier.std:
      // 中段偏克制：冷暖两端拉开，渐变肉眼可见但不厚重。
      final hi = isDark ? const Color(0xFF81D4FA) : const Color(0xFF42A5F5);
      final lo = isDark ? const Color(0xFF0D47A1) : const Color(0xFF0D47A1);
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hi.withValues(alpha: isDark ? 0.92 : 0.95),
              lo.withValues(alpha: isDark ? 0.88 : 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: 0.75,
            color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.45),
          ),
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: wRegular,
          height: 1,
          letterSpacing: 0.2,
          color: Colors.white.withValues(alpha: 0.94),
        ),
      );

    case SongAudioQualityTier.hq:
      final hi = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF81C784);
      final lo = isDark ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20);
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hi.withValues(alpha: isDark ? 0.88 : 0.94),
              lo.withValues(alpha: isDark ? 0.92 : 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: 0.75,
            color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.14 : 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: wRegular,
          height: 1,
          letterSpacing: 0.2,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      );

    case SongAudioQualityTier.sq:
      // 无损：深池绿 → 提亮晶边，斜向明暗差加大。
      final glow = const Color(0xFF26C6DA);
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH + 0.5, vertical: padV),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF002E26) : const Color(0xFF004D40),
              isDark ? const Color(0xFF004D40) : const Color(0xFF00796B),
              isDark ? const Color(0xFF26C6DA) : const Color(0xFF80CBC4),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            width: 0.75,
            color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: isDark ? 0.22 : 0.16),
              blurRadius: 6,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: wEmphasis,
          height: 1,
          letterSpacing: 0.22,
          color: Colors.white.withValues(alpha: 0.97),
        ),
      );

    case SongAudioQualityTier.hr:
      // 高解析：暗靛 → 亮丁香带，对比拉开。
      final accent = isDark ? const Color(0xFFF3E5F5) : Colors.white;
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH + 0.5, vertical: padV),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF311B92) : const Color(0xFF4527A0),
              isDark ? const Color(0xFF6A1B9A) : const Color(0xFF8E24AA),
              // 浅色末尾勿用过浅丁香带，否则白字可读性差；仍与中段拉开色相明暗。
              isDark ? const Color(0xFFE1BEE7) : const Color(0xFFAB47BC),
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            width: 0.75,
            color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.48),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withValues(alpha: isDark ? 0.28 : 0.22),
              blurRadius: 7,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: wEmphasis,
          height: 1,
          letterSpacing: 0.22,
          color: accent.withValues(alpha: isDark ? 0.96 : 0.98),
        ),
      );

    case SongAudioQualityTier.dsd:
      // 顶档：暗铜 → 高光金带 → 深琥珀收边，渐变层次拉开；描边与阴影略收。
      final text = isDark ? const Color(0xFF4E342E) : const Color(0xFF5D4037);
      return _BadgeTierStyle(
        padding: EdgeInsets.symmetric(horizontal: padH + 1.0, vertical: padV + 0.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF5D4037) : const Color(0xFF8D6E63),
              isDark ? const Color(0xFFC9A227) : const Color(0xFFE6C35C),
              isDark ? const Color(0xFFFFFDE7) : const Color(0xFFFFF9C4),
              isDark ? const Color(0xFFD4AC0D) : const Color(0xFFC9A227),
              isDark ? const Color(0xFF6D4C41) : const Color(0xFFB8860B),
            ],
            stops: const [0.0, 0.22, 0.48, 0.78, 1.0],
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            width: 1,
            color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.58),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withValues(alpha: isDark ? 0.28 : 0.22),
              blurRadius: 8,
              spreadRadius: -1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: fs,
          fontWeight: wEmphasis,
          height: 1,
          letterSpacing: 0.28,
          color: text,
        ),
      );
  }
}

class SongAudioQualityBadge extends StatelessWidget {
  const SongAudioQualityBadge({
    super.key,
    required this.tier,
    required this.compact,
  });

  final SongAudioQualityTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tip = songAudioQualityLocalizedTitle(l10n, tier);
    final code = tier.shortLabel;
    final style = _tierBadgeStyle(tier, Theme.of(context).brightness, compact);

    return Tooltip(
      message: tip,
      child: Container(
        padding: style.padding,
        decoration: style.decoration,
        child: Text(
          code,
          style: style.textStyle,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
      ),
    );
  }
}

/// 曲库列表副标题：音质标识在艺人/专辑文案之前。
class SongListSubtitleWithQualityRow extends StatelessWidget {
  const SongListSubtitleWithQualityRow({
    super.key,
    required this.song,
    required this.fallbackSubtitle,
    required this.textStyle,
    this.compactBadge = false,
    /// 为 true 且二级文案超出宽度时跑马灯（当前播放行）。
    this.isCurrentTrack = false,
  });

  final Song song;
  /// [songListSecondaryLine] 为空时的占位（与 [CompactSongListRow.subtitle] 一致）。
  final String fallbackSubtitle;
  final TextStyle textStyle;
  final bool compactBadge;
  final bool isCurrentTrack;

  @override
  Widget build(BuildContext context) {
    final tier = classifySongAudioQuality(song);
    final raw = songListSecondaryLine(song);
    final line = raw.trim().isNotEmpty ? raw : fallbackSubtitle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (tier != null) ...[
          SongAudioQualityBadge(tier: tier, compact: compactBadge),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: SongListMarqueeWhenCurrentLine(
            text: line,
            style: textStyle,
            isCurrentTrack: isCurrentTrack,
          ),
        ),
      ],
    );
  }
}

/// 最近播放：带播放次数跑马灯时同样前置音质标。
class SongListSubtitleWithQualityMarqueePlayCount extends StatelessWidget {
  const SongListSubtitleWithQualityMarqueePlayCount({
    super.key,
    required this.song,
    required this.textStyle,
    required this.playCount,
    required this.l10n,
    this.isCurrentTrack = false,
  });

  final Song song;
  final TextStyle textStyle;
  final int playCount;
  final AppLocalizations l10n;
  final bool isCurrentTrack;

  @override
  Widget build(BuildContext context) {
    final tier = classifySongAudioQuality(song);
    final line = songListSecondaryLine(song).trim();
    final text = line.isEmpty
        ? l10n.homePlayCount(playCount)
        : l10n.homePlayCountWithBase(line, playCount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (tier != null) ...[
          SongAudioQualityBadge(tier: tier, compact: true),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: AutoMarqueeSingleLineText(
            text: text,
            style: textStyle,
            enableMarquee: isCurrentTrack,
            gapBetweenLoops: 40,
          ),
        ),
      ],
    );
  }
}
