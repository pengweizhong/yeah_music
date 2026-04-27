import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// 与 [MiniPlayer] 条一致的毛玻璃：模糊、半透明、描边与阴影；抽屉使用 [FrostedGlassPanel.drawer]。
class FrostedGlassPanel extends StatelessWidget {
  const FrostedGlassPanel._({
    super.key,
    required this.border,
    required this.shadowOffset,
    this.height,
    required this.child,
  });

  final Widget child;
  final BoxBorder border;
  final Offset shadowOffset;
  final double? height;

  /// 底部迷你播放器条；固定高度以与 [MiniPlayer.barHeight] 一致。
  factory FrostedGlassPanel.bottomBar({
    Key? key,
    required Widget child,
    double height = 80,
  }) {
    return FrostedGlassPanel._(
      key: key,
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      shadowOffset: const Offset(0, -2),
      height: height,
      child: child,
    );
  }

  /// 侧栏抽屉：铺满侧栏，右侧边线与轻微右侧阴影，与条同一套材质参数。
  factory FrostedGlassPanel.drawer({Key? key, required Widget child}) {
    return FrostedGlassPanel._(
      key: key,
      border: Border(
        right: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      shadowOffset: const Offset(2, 0),
      height: null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          height: height ?? double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: shadowOffset,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
