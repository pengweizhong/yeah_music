import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 横向波浪进度：波形相位由「播放时间 × 推导 BPM」驱动（随播放线性前进，暂停自然静止），
/// 不再使用与时间轴无关的循环动画，避免 GIF 感；拖拽时用预览进度驱动相位。
class WaveProgressBar extends StatefulWidget {
  const WaveProgressBar({
    super.key,
    required this.value,
    required this.playbackMs,
    required this.trackDurationMs,
    required this.rhythmSeed,
    required this.activeColor,
    required this.inactiveBaseColor,
    this.enabled = true,
    this.height = 28,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  /// 0～1，用于裁剪已播区域。
  final double value;

  /// 当前用于绘制波形相位的播放位置（毫秒），拖拽预览时应传入预览时刻。
  final int playbackMs;

  /// 曲目时长（毫秒），用于推断较慢/较快曲目下的波浪密度。
  final int trackDurationMs;

  /// 每首歌稳定种子（如 path.hashCode），决定推导 BPM，同一首歌波形节奏一致。
  final int rhythmSeed;

  final Color activeColor;
  final Color inactiveBaseColor;
  final bool enabled;

  /// 触控高度（波形绘制居中）。
  final double height;

  final ValueChanged<double>? onChanged;
  final VoidCallback? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar> {
  double _lastEmitted = 0;

  void _emitFraction(double dx, double width) {
    if (!widget.enabled || width <= 0) return;
    final f = (dx / width).clamp(0.0, 1.0);
    _lastEmitted = f;
    widget.onChanged?.call(f);
  }

  @override
  Widget build(BuildContext context) {
    final inactive = widget.enabled
        ? widget.inactiveBaseColor
        : widget.inactiveBaseColor.withValues(alpha: 0.45);

    final pbpm = _inferBpm(widget.rhythmSeed, widget.trackDurationMs);

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (!w.isFinite || w <= 0) {
            return SizedBox(height: widget.height);
          }
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.enabled
                ? (e) {
                    widget.onChangeStart?.call();
                    _emitFraction(e.localPosition.dx, w);
                  }
                : null,
            onPointerMove: widget.enabled
                ? (e) => _emitFraction(e.localPosition.dx, w)
                : null,
            onPointerUp: widget.enabled
                ? (_) => widget.onChangeEnd?.call(_lastEmitted)
                : null,
            onPointerCancel: widget.enabled
                ? (_) => widget.onChangeEnd?.call(_lastEmitted)
                : null,
            child: CustomPaint(
              size: Size(w, widget.height),
              painter: _WaveProgressPainter(
                progress: widget.value.clamp(0.0, 1.0),
                playbackMs: widget.playbackMs.clamp(0, 1 << 30),
                inferredBpm: pbpm,
                activeColor: widget.enabled
                    ? widget.activeColor
                    : widget.activeColor.withValues(alpha: 0.45),
                inactiveColor: inactive,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 无真实节拍检测时的稳定启发：种子决定 BPM，时长微调快慢体感。
double _inferBpm(int seed, int durationMs) {
  final spread = seed.abs() % 52;
  var bpm = 88.0 + spread;
  if (durationMs > 8 * 60 * 1000) {
    bpm *= 0.93;
  } else if (durationMs > 0 && durationMs < 95 * 1000) {
    bpm = (bpm + 10).clamp(72.0, 148.0);
  }
  return bpm.clamp(72.0, 148.0);
}

class _WaveProgressPainter extends CustomPainter {
  _WaveProgressPainter({
    required this.progress,
    required this.playbackMs,
    required this.inferredBpm,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final int playbackMs;
  final double inferredBpm;
  final Color activeColor;
  final Color inactiveColor;

  /// rad/ms，与 BPM 对齐的主节拍角频率。
  double get _omegaBeat =>
      (2 * math.pi * inferredBpm) / (60.0 * 1000.0);

  double _surfaceY(double x, double width, double height) {
    if (width <= 0) return height * 0.5;

    final omega = _omegaBeat;
    final ms = playbackMs.toDouble();
    // 相对推导 BPM 放慢相位推进，形状变化更舒缓（否则容易显得急促）。
    const temporalEase = 0.34;
    final phaseDrive = ms * omega * temporalEase;

    // 横向波纹略疏一些，视觉上不那么挤。
    final spatial = (x / width) * math.pi * 2 * 2.35;
    final mid = height * 0.48;
    final amp = height * 0.152;

    // 很慢的明暗起伏，压低振幅以免抢眼。
    final swell = 1.0 + 0.038 * math.sin(phaseDrive * 0.14);

    final y = mid +
        amp *
            swell *
            (math.sin(spatial + phaseDrive * 0.58) +
                0.22 *
                    math.sin(
                      spatial * 1.618033988749895 + phaseDrive * 0.56 + 1.07,
                    ));

    return y;
  }

  Path _waveFillPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, h);

    const step = 1.25;
    var y = _surfaceY(0, w, h);
    path.lineTo(0, y);
    for (double x = step; x <= w; x += step) {
      y = _surfaceY(x, w, h);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    if (w <= 0 || size.height <= 0) return;

    final full = _waveFillPath(size);

    canvas.drawPath(full, Paint()..color = inactiveColor);

    final px = (w * progress).clamp(0.0, w);
    if (px > 0.5) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, px, size.height));
      canvas.drawPath(full, Paint()..color = activeColor);
      canvas.restore();

      final edgeX = px.clamp(0.0, w);
      final surfY = _surfaceY(edgeX, w, size.height);
      final knobPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(edgeX, surfY),
        5,
        knobPaint,
      );
      canvas.drawCircle(
        Offset(edgeX, surfY),
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playbackMs != playbackMs ||
        oldDelegate.inferredBpm != inferredBpm ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
