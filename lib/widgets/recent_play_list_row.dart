import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/application_utils.dart';

/// 最近播放列表行（首页、最近播放页共用）。顺序由调用方传入的 [paths] 决定，不在此重排。
class RecentPlayListRow extends StatelessWidget {
  const RecentPlayListRow({
    super.key,
    required this.song,
    required this.subtitle,
    required this.isCurrent,
    required this.onTap,
  });

  final Song song;
  final String subtitle;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.12)
                : null,
            border: isCurrent
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.white24,
                  child: Image(
                    fit: BoxFit.cover,
                    image: ApplicationUtils.getImageCoverProvider(song, size: 96),
                    errorBuilder: (c, o, s) => Icon(
                      Icons.music_note_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title ?? '未知',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _RecentPlayTrailingIcon(isCurrent: isCurrent),
            ],
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
        return Icon(
          Icons.pause_rounded,
          color: Colors.white.withValues(alpha: 0.6),
          size: 26,
        );
      },
    );
  }
}

/// 正在播放时右侧动态均衡条（循环起伏）
class _EqualizerPlayingBars extends StatefulWidget {
  const _EqualizerPlayingBars({
    required this.color,
    required this.size,
  });

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
                _bar(
                  h: _h(t, 0) * maxH,
                  w: barW,
                  c: widget.color,
                ),
                SizedBox(width: gap),
                _bar(
                  h: _h(t, 1.2) * maxH,
                  w: barW,
                  c: widget.color,
                ),
                SizedBox(width: gap),
                _bar(
                  h: _h(t, 2.4) * maxH,
                  w: barW,
                  c: widget.color,
                ),
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
