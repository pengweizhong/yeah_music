/// 全局提示组件：浮动 Snackbar、磨砂确认框、单行输入、自定义按钮与阻塞进度。
///
/// 新增界面反馈时请优先使用 [showAppSnackBar]、[showAppConfirmDialog]、
/// [showAppTextPromptDialog]、[showAppCustomDialog]、[showAppBlockingProgressDialog]、
/// [showAppScrollMessageDialog]、[showAppAboutDialog]，以保持视觉一致。
library;

import 'package:flutter/material.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/config/app_product_info.dart';
import 'package:yeah_music/l10n/app_localizations.dart';

/// 全局 Snackbar 气质：浮动、圆角、与磨砂弹层同系的深色壳层。
enum AppSnackKind {
  /// 一般说明
  neutral,

  /// 成功 / 完成
  success,

  /// 失败、异常文案
  error,
}

void _presentAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  AppSnackKind kind = AppSnackKind.neutral,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final scheme = Theme.of(messenger.context).colorScheme;
  late Color backgroundColor;
  late Color foregroundColor;

  switch (kind) {
    case AppSnackKind.success:
      backgroundColor = const Color(0xFF243532);
      foregroundColor = const Color(0xFFC8E6D5);
      break;
    case AppSnackKind.error:
      backgroundColor = Color.alphaBlend(
        scheme.error.withValues(alpha: 0.24),
        const Color(0xFF2A1C1E),
      );
      foregroundColor = scheme.error;
      break;
    case AppSnackKind.neutral:
      backgroundColor = const Color(0xFF323842);
      foregroundColor = const Color(0xFFF0F2F7);
      break;
  }

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      elevation: 10,
      content: Text(
        message,
        style: TextStyle(
          color: foregroundColor,
          height: 1.38,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      duration: duration,
      action: action == null
          ? null
          : SnackBarAction(
              label: action.label,
              textColor: foregroundColor,
              onPressed: action.onPressed,
            ),
    ),
  );
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.neutral,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = (context.mounted
          ? ScaffoldMessenger.maybeOf(context)
          : null) ??
      appScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  _presentAppSnackBar(messenger, message, kind: kind, duration: duration, action: action);
}

/// 无页面 [BuildContext] 时使用根 [ScaffoldMessenger]（与 [showAppSnackBar] 样式一致）。
void showAppSnackBarGlobal(
  String message, {
  AppSnackKind kind = AppSnackKind.neutral,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  _presentAppSnackBar(messenger, message, kind: kind, duration: duration, action: action);
}

String playbackFailedSnackMessageResolved(BuildContext? context) {
  if (context != null && context.mounted) {
    return AppLocalizations.of(context).playbackFailedSnackMessage;
  }
  final ctx = appScaffoldMessengerKey.currentContext;
  if (ctx != null) {
    return AppLocalizations.of(ctx).playbackFailedSnackMessage;
  }
  return "Couldn't play this track.";
}

/// 解码失败、文件缺失或格式不支持等导致未能开始播放时的全局提示。
void reportPlaybackFailureToUser([BuildContext? context]) {
  final msg = playbackFailedSnackMessageResolved(context);
  final messenger = (context != null && context.mounted
          ? ScaffoldMessenger.maybeOf(context)
          : null) ??
      appScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  _presentAppSnackBar(messenger, msg, kind: AppSnackKind.error);
}

/// 双按钮确认（磨砂圆角卡片，与 [showFrostedDialog] 一致）。
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  Widget? messageWidget,
  IconData? icon,
  bool confirmIsDestructive = false,
  String? cancelLabel,
  String? confirmLabel,
  double maxWidth = 400,
  bool barrierDismissible = true,
}) {
  final l10n = AppLocalizations.of(context);
  final cancel = cancelLabel ?? l10n.actionCancel;
  final confirm = confirmLabel ?? l10n.actionOK;

  return showFrostedDialog<bool>(
    context: context,
    maxWidth: maxWidth,
    barrierDismissible: barrierDismissible,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final onSurface = scheme.onSurface;
        final muted = scheme.onSurfaceVariant;

        final Widget body;
        final customMessage = messageWidget;
        if (customMessage != null) {
          body = DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.48, fontSize: 14.5),
            child: customMessage,
          );
        } else if (message != null) {
          body = Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.48, fontSize: 14.5),
          );
        } else {
          body = const SizedBox.shrink();
        }

        // Dialog 外层可能比 Column 固有宽度更宽；不设满宽时 Column 贴左，TextAlign.center 也会像没居中。
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            (confirmIsDestructive
                                    ? scheme.error
                                    : scheme.primary)
                                .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          icon,
                          size: 26,
                          color: confirmIsDestructive
                              ? scheme.error
                              : scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.42,
                  ),
                  child: SingleChildScrollView(
                    child: SizedBox(width: double.infinity, child: body),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(cancel),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: confirmIsDestructive
                          ? FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                            )
                          : null,
                      child: Text(confirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 单行 / 多行输入（磨砂材质与其它提示一致）。取消返回 `null`，确定返回.trim() 后的文本（可为空串）。
Future<String?> showAppTextPromptDialog({
  required BuildContext context,
  required String title,
  Widget? subtitle,
  String initialValue = '',
  String? fieldLabel,
  String? hintText,
  int maxLines = 1,
  String? cancelLabel,
  String? confirmLabel,
  double maxWidth = 400,
}) async {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: initialValue);
  final cancel = cancelLabel ?? l10n.actionCancel;
  final confirm = confirmLabel ?? l10n.actionOK;

  final result = await showFrostedDialog<String?>(
    context: context,
    maxWidth: maxWidth,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final sub = subtitle;

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 10),
                  DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                      fontSize: 14.5,
                    ),
                    child: sub,
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: maxLines,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    labelText: fieldLabel,
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop<String?>(ctx),
                      child: Text(cancel),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop<String?>(ctx, ctrl.text.trim()),
                      child: Text(confirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  scheduleDisposeTextEditingController(ctrl);
  return result;
}

/// 自定义正文（多条 [Widget]）与任意多个操作按钮；磨砂与其它提示一致。
///
/// 需在按钮里使用对话框内的 `context` 调用 `Navigator.pop`（可用外层包一层 [Builder]）。
Future<T?> showAppCustomDialog<T>({
  required BuildContext context,
  required String title,
  List<Widget> bodyChildren = const [],
  List<Widget> actions = const [],
  double maxWidth = 400,
  bool barrierDismissible = true,
}) {
  return showFrostedDialog<T>(
    context: context,
    maxWidth: maxWidth,
    barrierDismissible: barrierDismissible,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final onSurface = scheme.onSurface;
        final muted = scheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                    height: 1.25,
                  ),
                ),
                if (bodyChildren.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 14.5,
                      height: 1.48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bodyChildren,
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 不可手动关闭的阻塞进度；完成后由调用方 `Navigator.pop` 关闭。
///
/// [linearProgressBar] 为 true 时使用条形不确定进度，否则为环形。
void showAppBlockingProgressDialog({
  required BuildContext context,
  required String title,
  String? message,
  bool linearProgressBar = false,
}) {
  showFrostedDialog<void>(
    context: context,
    barrierDismissible: false,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final msg = message;
        return PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (linearProgressBar)
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          color: scheme.primary,
                        ),
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                  if (msg != null && msg.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// 仅滚动说明文案（无按钮，点遮罩关闭）。
Future<void> showAppScrollMessageDialog({
  required BuildContext context,
  required String title,
  required String body,
  double maxWidth = 400,
  double maxBodyHeightFraction = 0.55,
}) {
  return showFrostedDialog<void>(
    context: context,
    maxWidth: maxWidth,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final maxH = MediaQuery.sizeOf(ctx).height * maxBodyHeightFraction;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.48,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// 「关于」对话框（磨砂与其它提示一致）。
void showAppAboutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showFrostedDialog<void>(
    context: context,
    maxWidth: 400,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final onSurface = scheme.onSurface;
        final muted = scheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/yeah_music.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppProductInfo.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.settingsAboutDialogVersionLabel(
                        AppProductInfo.version,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.settingsAboutDialogBuildLabel(AppProductInfo.buildNumber),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 20),
                Divider(color: scheme.outline.withValues(alpha: 0.35)),
                const SizedBox(height: 12),
                _aboutDialogInfoRow(
                  scheme,
                  Icons.person_outline,
                  l10n.settingsAboutDialogAuthor,
                  'PengWeiZhong',
                ),
                const SizedBox(height: 12),
                _aboutDialogInfoRow(
                  scheme,
                  Icons.code,
                  l10n.settingsAboutDialogRepo,
                  'https://github.com/pengweizhong/yeah_music',
                ),
                const SizedBox(height: 12),
                _aboutDialogInfoRow(
                  scheme,
                  Icons.gavel,
                  l10n.settingsAboutDialogLicense,
                  'GPL-3.0',
                ),
                const SizedBox(height: 12),
                _aboutDialogInfoRow(
                  scheme,
                  Icons.copyright,
                  l10n.settingsAboutDialogCopyright,
                  '©2026 PengWeiZhong',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.settingsAboutDialogClose),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _aboutDialogInfoRow(
  ColorScheme scheme,
  IconData icon,
  String label,
  String value,
) {
  final onSurface = scheme.onSurface;
  final muted = scheme.onSurfaceVariant;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: muted),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 2),
            SelectableText(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
