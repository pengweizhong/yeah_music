import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/widgets/auto_marquee_single_line_text.dart';
import 'package:yeah_music/widgets/song_list_cover.dart';

/// 最近播放列表行（首页等）。顺序由调用方传入决定，不在此重排。
///
/// [trailingPlayCount] 非空时（如首页「最多播放」）：副标题为「艺人 · 专辑」补全后与播放次数合并，不会因 hydrate 丢掉次数。
class RecentPlayListRow extends StatefulWidget {
  const RecentPlayListRow({
    super.key,
    required this.song,
    required this.subtitle,
    required this.isCurrent,
    required this.onTap,
    this.trailingPlayCount,
  });

  final Song song;

  /// 轻量占位；后台补全后以 [songListSecondaryLine] 为准（除非 [trailingPlayCount] 已设置）。
  final String subtitle;
  final bool isCurrent;
  final VoidCallback onTap;

  /// 非空时在副标题末尾保留「已播放 N 次」（与 hydrate 后的元数据合并）。
  final int? trailingPlayCount;

  @override
  State<RecentPlayListRow> createState() => _RecentPlayListRowState();
}

class _RecentPlayListRowState extends State<RecentPlayListRow> {
  Future<bool>? _ongoingHydrate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateAfterLayout());
  }

  @override
  void didUpdateWidget(RecentPlayListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _hydrateAfterLayout(),
      );
    }
  }

  void _onRowVisibilityChanged(VisibilityInfo info) {
    if (!mounted || info.visibleFraction < 0.06) return;
    _hydrateAfterLayout();
  }

  void _hydrateAfterLayout() {
    if (!mounted) return;
    final song = widget.song;
    final fut = _ongoingHydrate ??=
        SongLibraryMetadataHydrator.hydrateIfNeeded(song).whenComplete(() {
          _ongoingHydrate = null;
        });
    fut.then((changed) {
      if (!mounted || !changed) return;
      setState(() {});
    });
  }

  String _displayTitle() {
    final t = widget.song.title;
    if (t != null && t.trim().isNotEmpty) return t;
    return '未知';
  }

  String _displaySubtitle(AppLocalizations l10n) {
    final pc = widget.trailingPlayCount;
    if (pc != null) {
      final line = songListSecondaryLine(widget.song).trim();
      if (line.isEmpty) {
        return l10n.homePlayCount(pc);
      }
      return l10n.homePlayCountWithBase(line, pc);
    }
    final line = songListSecondaryLine(widget.song);
    if (line.trim().isNotEmpty) return line;
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleStr = _displayTitle();
    final subtitleStr = _displaySubtitle(l10n);
    return VisibilityDetector(
      key: ValueKey<String>('recent_row_vis_${widget.song.path}'),
      onVisibilityChanged: _onRowVisibilityChanged,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isCurrent
                  ? Colors.white.withValues(alpha: 0.12)
                  : null,
              border: widget.isCurrent
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                SongListCover(
                  song: widget.song,
                  size: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.isCurrent
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          fontWeight: widget.isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      widget.trailingPlayCount != null
                          ? AutoMarqueeSingleLineText(
                              text: subtitleStr,
                              style: TextStyle(
                                color: widget.isCurrent
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                              gapBetweenLoops: 40,
                            )
                          : Text(
                              subtitleStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.isCurrent
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                    ],
                  ),
                ),
                _RecentPlayTrailingIcon(isCurrent: widget.isCurrent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentPlayTrailingIcon extends StatelessWidget {
  const _RecentPlayTrailingIcon({required this.isCurrent});
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (!isCurrent) {
      return Icon(
        Icons.play_arrow_rounded,
        color: Colors.white.withValues(alpha: 0.35),
        size: 26,
      );
    }
    return StreamBuilder<bool>(
      stream: MusicService.playingStream,
      initialData: MusicService.isPlaying,
      builder: (context, snap) {
        final playing = snap.data ?? false;
        if (playing) {
          return const _EqualizerPlayingBars(
            color: Color(0xFF7C4DFF),
            size: 26,
          );
        }
        return const Icon(
          Icons.pause_rounded,
          color: Color(0xFF7C4DFF),
          size: 26,
        );
      },
    );
  }
}

/// 正在播放时右侧动态均衡条（循环起伏）
class _EqualizerPlayingBars extends StatefulWidget {
  const _EqualizerPlayingBars({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_EqualizerPlayingBars> createState() => _EqualizerPlayingBarsState();
}

class _EqualizerPlayingBarsState extends State<_EqualizerPlayingBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// [t] 0~1 周期，[phase] 错开三根的相位
  double _h(double t, double phase) {
    final v = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2.0 + phase);
    return 0.32 + 0.68 * v;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final barW = s * 0.22;
    final gap = s * 0.08;
    final maxH = s * 0.72;
    return SizedBox(
      width: s,
      height: s,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = _ctrl.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(h: _h(t, 0) * maxH, w: barW, c: widget.color),
                SizedBox(width: gap),
                _bar(h: _h(t, 1.2) * maxH, w: barW, c: widget.color),
                SizedBox(width: gap),
                _bar(h: _h(t, 2.4) * maxH, w: barW, c: widget.color),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar({required double h, required double w, required Color c}) {
    return Container(
      width: w,
      height: h < 2 ? 2 : h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(w / 2),
      ),
    );
  }
}
