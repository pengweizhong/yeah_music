// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

/// 与 [MiniPlayer] 条一致的毛玻璃：模糊、半透明、描边与阴影；抽屉 [FrostedGlassPanel.drawer]；
/// 底栏 [FrostedGlassBottomSheet]；居中 [FrostedGlassDialog] / [showFrostedDialog]。
class FrostedGlassPanel extends StatelessWidget {
  const FrostedGlassPanel._({
    super.key,
    required this.frostedKind,
    required this.shadowOffset,
    this.height,
    required this.child,
  });

  final Widget child;
  final Offset shadowOffset;
  final double? height;
  final FrostedSurfaceKind frostedKind;

  /// 底部迷你播放器条；固定高度以与 [MiniPlayer.barHeight] 一致。
  factory FrostedGlassPanel.bottomBar({
    Key? key,
    required Widget child,
    double height = 80,
  }) {
    return FrostedGlassPanel._(
      key: key,
      frostedKind: FrostedSurfaceKind.bottomBar,
      shadowOffset: const Offset(0, -2),
      height: height,
      child: child,
    );
  }

  /// 侧栏抽屉
  factory FrostedGlassPanel.drawer({Key? key, required Widget child}) {
    return FrostedGlassPanel._(
      key: key,
      frostedKind: FrostedSurfaceKind.drawerOrPinned,
      shadowOffset: const Offset(2, 0),
      height: null,
      child: child,
    );
  }

  /// 吸顶分节标题条（如首页「最近播放」）
  factory FrostedGlassPanel.pinnedSection({Key? key, required Widget child}) {
    return FrostedGlassPanel._(
      key: key,
      frostedKind: FrostedSurfaceKind.drawerOrPinned,
      shadowOffset: const Offset(0, 3),
      height: null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 抽屉：x 正；吸顶条：x=0, y=3；底栏：y 负
    final border = (frostedKind == FrostedSurfaceKind.drawerOrPinned)
        ? (shadowOffset.dx > 0
            ? Border(right: BorderSide(color: FrostedPalette.edgeLine(context)))
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? kGradLightInk.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ))
        : Border(top: BorderSide(color: FrostedPalette.edgeLine(context)));
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          height: height ?? double.infinity,
          decoration: BoxDecoration(
            color: FrostedPalette.fill(context, frostedKind),
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: shadowOffset,
              ),
            ],
          ),
          child: FrostedDeepTintChromeScope(
            child: child,
          ),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final r = BorderRadius.vertical(top: Radius.circular(topRadius));
    final e = FrostedPalette.edgeLine(context);
    final sigma = isLight ? 0.0 : 16.0;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FrostedPalette.fill(context, FrostedSurfaceKind.sheet),
            borderRadius: r,
            border: Border(
              top: BorderSide(color: e),
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
                      color: isLight
                          ? kGradLightInk.withValues(alpha: 0.26)
                          : Colors.white.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Theme(
                data: frostedBottomSheetContentTheme(context),
                child: FrostedSheetForegroundScope(
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部毛玻璃上使用的 [Theme]：夜间高对比白字；白天为白底黑字（与列表/表单可读性一致）。
ThemeData frostedBottomSheetContentTheme(BuildContext context) {
  final t = Theme.of(context);
  if (t.brightness == Brightness.light) {
    const ink = Color(0xFF000000);
    const inkMuted = Color(0xFF424242);
    return t.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: t.colorScheme.copyWith(
        surface: Colors.white,
        onSurface: ink,
        onSurfaceVariant: inkMuted,
      ),
      textTheme: t.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        decorationColor: ink,
      ),
      iconTheme: const IconThemeData(color: ink, opacity: 1),
      listTileTheme: t.listTileTheme.copyWith(
        textColor: ink,
        iconColor: ink,
      ),
      dividerTheme: const DividerThemeData(color: Color(0x1F000000)),
    );
  }
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sigma = isLight ? 0.0 : 16.0;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FrostedPalette.fill(
                context,
                FrostedSurfaceKind.dialog,
              ),
              borderRadius: r,
              border: Border.all(color: FrostedPalette.edgeLine(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Theme(
              data: frostedDialogContentTheme(context),
              child: FrostedSheetForegroundScope(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// 「关于」等与 [showFrostedDialog] 共用的浅色/深色正文色。
ThemeData frostedDialogContentTheme(BuildContext context) {
  final t = Theme.of(context);
  if (t.brightness == Brightness.light) {
    const ink = Color(0xFF000000);
    const inkMuted = Color(0xFF424242);
    return t.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: t.colorScheme.copyWith(
        surface: Colors.white,
        onSurface: ink,
        onSurfaceVariant: inkMuted,
      ),
      textTheme: t.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        decorationColor: ink,
      ),
      iconTheme: const IconThemeData(color: ink, opacity: 1),
    );
  }
  return t.copyWith(
    colorScheme: t.colorScheme.copyWith(
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xCCFFFFFF),
    ),
  );
}

/// 与 [Material Dialog] 默认水平 inset（约每侧 40）对齐，用于卡片可用宽度。
double _frostedDialogCardWidth(BuildContext context, double maxWidth) {
  final inset = DialogTheme.of(context).insetPadding ??
      const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  final screenW = MediaQuery.sizeOf(context).width;
  final avail = screenW - inset.horizontal;
  return avail.clamp(280.0, maxWidth);
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
    builder: (ctx) {
      // Dialog 内 Material 会按子组件固有宽度收缩；不设固定宽度时正文仅在窄列内居中，看起来像偏左。
      final cardW = _frostedDialogCardWidth(ctx, maxWidth);
      return Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: cardW,
          child: FrostedGlassDialog(
            maxWidth: cardW,
            child: child,
          ),
        ),
      );
    },
  );
}

/// 在 [showDialog] / [showFrostedDialog] 的 Future 完成后勿立刻调用 [TextEditingController.dispose]；
/// 对话框路由的子树可能仍在卸载，过早 dispose 可能触发 `_dependents.isEmpty` 断言。
/// 在 `await showFrostedDialog(...)` 之后改用本函数，延后到下一帧再 dispose。
void scheduleDisposeTextEditingController(TextEditingController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
