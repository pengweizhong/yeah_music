import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// 与 [MiniPlayer] 条一致的毛玻璃：模糊、半透明、描边与阴影；抽屉 [FrostedGlassPanel.drawer]；
/// 底栏 [FrostedGlassBottomSheet]；居中 [FrostedGlassDialog] / [showFrostedDialog]。
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

  /// 吸顶分节标题条（如首页「最近播放」）：底边 + 向下轻阴影，与 [FrostedGlassPanel.bottomBar] 同模糊与填充。
  factory FrostedGlassPanel.pinnedSection({Key? key, required Widget child}) {
    return FrostedGlassPanel._(
      key: key,
      border: Border(
        bottom: BorderSide(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      shadowOffset: const Offset(0, 3),
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

/// 与 [FrostedGlassPanel.drawer] 同一套模糊与半透明材质，用于 [showModalBottomSheet] 内容区（须将
/// [showModalBottomSheet] 的 [backgroundColor] 设为 [Colors.transparent]）。
class FrostedGlassBottomSheet extends StatelessWidget {
  const FrostedGlassBottomSheet({
    super.key,
    required this.child,
    this.topRadius = 20,
    this.showTopHandle = true,
  });

  final Widget child;
  final double topRadius;
  final bool showTopHandle;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.vertical(top: Radius.circular(topRadius));
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: r,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTopHandle) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部毛玻璃上使用的 [Theme]（高对比浅色字/图标，与 [FrostedGlassBottomSheet] 搭配）
ThemeData frostedBottomSheetContentTheme(BuildContext context) {
  final t = Theme.of(context);
  return t.copyWith(
    colorScheme: t.colorScheme.copyWith(
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xCCFFFFFF),
    ),
    listTileTheme: t.listTileTheme.copyWith(
      textColor: Colors.white,
      iconColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: Color(0x3FFFFFFF)),
  );
}

/// 居中 [Dialog] 内毛玻璃，与 [FrostedGlassBottomSheet] 同套模糊/半透明
class FrostedGlassDialog extends StatelessWidget {
  const FrostedGlassDialog({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.maxWidth = 400,
  });

  final Widget child;
  final double borderRadius;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: r,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// [FrostedGlassDialog] 内正文等浅色 [Theme]
ThemeData frostedDialogContentTheme(BuildContext context) {
  final t = Theme.of(context);
  return t.copyWith(
    colorScheme: t.colorScheme.copyWith(
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xCCFFFFFF),
    ),
  );
}

/// 与 [FrostedGlassDialog] 同材质的全局居中弹窗
Future<T?> showFrostedDialog<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 400,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Theme(
        data: frostedDialogContentTheme(ctx),
        child: FrostedGlassDialog(
          maxWidth: maxWidth,
          child: child,
        ),
      ),
    ),
  );
}
