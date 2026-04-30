import 'package:flutter/material.dart';

/// 单行文本在可用宽度不足时向左循环滚动（无缝拼接两段相同文案）。
///
/// 使用 [ScrollController] + 横向 [SingleChildScrollView] 承载宽内容，避免
/// [UnconstrainedBox]/[OverflowBox] 在 debug 下对「内容超出父级」的断言。
///
/// [enableMarquee] 为 false 时不滚动（单行省略），用于「仅当前播放行跑马灯」等场景。
///
/// 动画状态混用 [TickerProviderStateMixin]：[LayoutBuilder] 在同一布局阶段可能对子树多次
/// 回调 build；若在此期间销毁并重建 [AnimationController]，[SingleTickerProviderStateMixin]
/// 会在尚未释放前一 ticker 槽位时误判「多 ticker」断言。
class AutoMarqueeSingleLineText extends StatefulWidget {
  const AutoMarqueeSingleLineText({
    super.key,
    required this.text,
    required this.style,
    this.enableMarquee = true,
    this.gapBetweenLoops = 40,
    this.pixelsPerSecond = 36,
  });

  final String text;
  final TextStyle style;

  /// 为 false 时始终使用省略号，不启动滚动动画。
  final bool enableMarquee;
  final double gapBetweenLoops;

  /// 滚动速率（像素/秒），越小越慢。
  final double pixelsPerSecond;

  @override
  State<AutoMarqueeSingleLineText> createState() =>
      _AutoMarqueeSingleLineTextState();
}

class _AutoMarqueeSingleLineTextState extends State<AutoMarqueeSingleLineText>
    with TickerProviderStateMixin {
  AnimationController? _ctrl;
  final ScrollController _scrollCtrl = ScrollController();
  String? _trackedText;
  double? _trackedLoop;

  void _syncMarqueeScroll() {
    final c = _ctrl;
    final loop = _trackedLoop;
    if (!mounted || c == null || loop == null) return;
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.jumpTo(c.value * loop);
  }

  void _disposeAnim() {
    _ctrl?.removeListener(_syncMarqueeScroll);
    _ctrl?.dispose();
    _ctrl = null;
  }

  bool _needsNewAnim(double loop) {
    return _ctrl == null ||
        _trackedText != widget.text ||
        (_trackedLoop != null && (loop - _trackedLoop!).abs() > 0.5);
  }

  @override
  void didUpdateWidget(AutoMarqueeSingleLineText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableMarquee && !widget.enableMarquee) {
      _disposeAnim();
      _trackedText = null;
      _trackedLoop = null;
    }
  }

  void _ensureAnim(double loopDistance) {
    if (!_needsNewAnim(loopDistance)) return;
    _disposeAnim();
    final durationMs =
        (loopDistance / widget.pixelsPerSecond * 1000).round().clamp(
              4500,
              120000,
            );
    _trackedText = widget.text;
    _trackedLoop = loopDistance;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )
      ..addListener(_syncMarqueeScroll)
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncMarqueeScroll();
    });
  }

  @override
  void dispose() {
    _disposeAnim();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 1) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }
        if (!widget.enableMarquee) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }
        final span = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);
        final tw = tp.width;

        if (tw <= maxW + 0.5) {
          _disposeAnim();
          _trackedText = null;
          _trackedLoop = null;
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final loop = tw + widget.gapBetweenLoops;
        _ensureAnim(loop);

        if (_ctrl == null) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final lineHeight = tp.height.clamp(1.0, 512.0);
        return SizedBox(
          width: maxW,
          height: lineHeight,
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.text, maxLines: 1, style: widget.style),
                  SizedBox(width: widget.gapBetweenLoops),
                  Text(widget.text, maxLines: 1, style: widget.style),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
