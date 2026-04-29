import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/widgets/auto_marquee_single_line_text.dart';

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
      dark ? const Color(0xFFB39DDB) : const Color(0xFF4527A0),
    SongAudioQualityTier.dsd =>
      dark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17),
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
    final color = songAudioQualityAccent(tier, context);
    final code = tier.shortLabel;
    return Tooltip(
      message: tip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 5,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: compact ? 9.5 : 10,
            fontWeight: FontWeight.w700,
            height: 1,
            color: color.withValues(alpha: 0.98),
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
  });

  final Song song;
  /// [songListSecondaryLine] 为空时的占位（与 [CompactSongListRow.subtitle] 一致）。
  final String fallbackSubtitle;
  final TextStyle textStyle;
  final bool compactBadge;

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
          child: Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
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
  });

  final Song song;
  final TextStyle textStyle;
  final int playCount;
  final AppLocalizations l10n;

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
            gapBetweenLoops: 40,
          ),
        ),
      ],
    );
  }
}
