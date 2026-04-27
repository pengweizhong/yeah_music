import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/list_cover_image_policy.dart';

/// 包住使用 [SongListCover] 的 [ScrollView] / [ListView]：竖向有滚动位移时
/// 不加载封面，停止后约 [idle] 再解码，把 CPU/GPU 留给跟手滑动。
class ScrollAwareListFrame extends StatefulWidget {
  const ScrollAwareListFrame({
    super.key,
    this.idle = const Duration(milliseconds: 160),
    required this.child,
  });

  /// 最后一次 [ScrollUpdateNotification] 之后多久视为「已停滑」并恢复封面
  final Duration idle;
  final Widget child;

  @override
  State<ScrollAwareListFrame> createState() => _ScrollAwareListFrameState();
}

class _ScrollAwareListFrameState extends State<ScrollAwareListFrame> {
  var _inVerticalScroll = false;
  Timer? _doneScrolling;

  @override
  void dispose() {
    _doneScrolling?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification n) {
        if (n.metrics.axis != Axis.vertical) {
          return false;
        }
        if (n is! ScrollUpdateNotification) {
          return false;
        }
        _doneScrolling?.cancel();
        if (!_inVerticalScroll) {
          setState(() {
            _inVerticalScroll = true;
          });
        }
        _doneScrolling = Timer(widget.idle, () {
          if (!mounted) {
            return;
          }
          setState(() {
            _inVerticalScroll = false;
          });
        });
        return false;
      },
      child: ListCoverImagePolicy(
        suppressDecode: _inVerticalScroll,
        child: widget.child,
      ),
    );
  }
}
