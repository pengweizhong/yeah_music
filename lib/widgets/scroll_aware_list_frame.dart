import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';

/// Material mdpi 参考下一英寸 160dp，故 1cm 约等于此值（固定滑块最短边长度）。
const double _kThumbMinLengthOneCmDp = 160.0 / 2.54;

/// 静止时的条宽。须足够大以避免误点到列表：[RawScrollbar] 命中区宽度即此值量级。
const double _kIdleThicknessDp = 7.0;

/// 用户滑动时加粗一档（离散切换，不使用逐帧数值动画）。
const double _kActiveThicknessDp = 13.0;

/// 静止 / 滑动时滑块白度（alpha），静止宜更暗以免抢眼。
const double _kIdleThumbAlpha = 0.05;
const double _kActiveThumbAlpha = 0.45;

/// 历史上曾用于在快速滚动时抑制列表封面解码；现已不再卸图，避免与 [ImageCache] 已缓存
/// 的封面在「灰色占位 ↔ 真图」之间反复切换造成闪动。
///
/// [scrollController] 非空时为歌曲列表挂载 [Scrollbar]：Material 在 Android 上默认
/// [`interactive:false`](https://api.flutter.dev/flutter/material/Scrollbar/interactive.html)，
/// 侧滑块无法拖动；显式设为可交互，并与下方 [Scrollable] 共用同一控制器。
/// 同时将 [ScrollBehavior.scrollbars] 置为 false，避免桌面端 ScrollBehavior 再包一层出现双滚动条。
///
/// 粗细为高亮时使用**离散**两档 [setState] 切换。**不要**在每帧插值 thickness 包住 [RawScrollbar]，
/// 否则 [RawScrollbar.didUpdateWidget] 会打断内部拖动，导致二次来回拖滑块选不中。
class ScrollAwareListFrame extends StatelessWidget {
  const ScrollAwareListFrame({
    super.key,
    required this.child,
    this.scrollController,
  });

  final Widget child;

  /// 与同树 [Scrollable]/[ScrollView]（如 [ListView]）传入的 [controller] 一致。
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (scrollController == null) {
      return child;
    }
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: _ProminentScrollbar(
        controller: scrollController!,
        child: child,
      ),
    );
  }
}

class _ProminentScrollbar extends StatefulWidget {
  const _ProminentScrollbar({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<_ProminentScrollbar> createState() => _ProminentScrollbarState();
}

class _ProminentScrollbarState extends State<_ProminentScrollbar> {
  Timer? _idleTimer;

  /// 用户在与滚动条相关的滑动中时为 true（仅在此处 setState 切换档位，不重绘每帧）。
  bool _activelyScrolling = false;

  void _kickEmphasis() {
    _idleTimer?.cancel();
    if (!_activelyScrolling && mounted) {
      setState(() => _activelyScrolling = true);
    }
    _idleTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _activelyScrolling = false);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  /// 不在 [ScrollController.listener] 里跟跳：会与滑块拖动时每帧冲突。
  bool _notificationIsUserScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (isListScrollFromProgrammaticJump(widget.controller)) return false;
    if (n is UserScrollNotification) return true;
    if (n is ScrollUpdateNotification && n.dragDetails != null) return true;
    if (n is ScrollStartNotification && n.dragDetails != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final thick = _activelyScrolling ? _kActiveThicknessDp : _kIdleThicknessDp;
    final alpha =
        _activelyScrolling ? _kActiveThumbAlpha : _kIdleThumbAlpha;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_notificationIsUserScroll(n)) _kickEmphasis();
        return false;
      },
      child: RawScrollbar(
        controller: widget.controller,
        interactive: true,
        /// 为 true 时 [RawScrollbarState._maybeStartFadeoutTimer] 不会启动淡出；
        /// 否则 [ScrollEnd] 后瞬时淡出，`fadeoutOpacityAnimation==0` 时源码中触摸命中直接失败（静止态永远点不中）。
        thumbVisibility: true,
        thickness: thick,
        minThumbLength: _kThumbMinLengthOneCmDp,
        thumbColor: Colors.white.withValues(alpha: alpha),
        fadeDuration: Duration.zero,
        timeToFade: Duration.zero,
        radius: Radius.circular(_activelyScrolling ? 6 : 5),
        crossAxisMargin: 0,
        child: SizedBox.expand(child: widget.child),
      ),
    );
  }
}
