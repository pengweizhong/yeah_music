import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/playback_shortcut_controller.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_shortcut_config.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

bool _isModifierOnlyKey(LogicalKeyboardKey k) {
  return k == LogicalKeyboardKey.controlLeft ||
      k == LogicalKeyboardKey.controlRight ||
      k == LogicalKeyboardKey.shiftLeft ||
      k == LogicalKeyboardKey.shiftRight ||
      k == LogicalKeyboardKey.altLeft ||
      k == LogicalKeyboardKey.altRight ||
      k == LogicalKeyboardKey.metaLeft ||
      k == LogicalKeyboardKey.metaRight;
}

Future<SingleActivator?> _recordShortcut(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showFrostedDialog<SingleActivator>(
    context: context,
    child: Builder(
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsPlaybackShortcutsPressKey,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(ctx).pop();
                    return KeyEventResult.handled;
                  }
                  if (_isModifierOnlyKey(event.logicalKey)) {
                    return KeyEventResult.ignored;
                  }
                  final a = SingleActivator(
                    event.logicalKey,
                    control: HardwareKeyboard.instance.isControlPressed,
                    meta: HardwareKeyboard.instance.isMetaPressed,
                    alt: HardwareKeyboard.instance.isAltPressed,
                    shift: HardwareKeyboard.instance.isShiftPressed,
                  );
                  Navigator.of(ctx).pop(a);
                  return KeyEventResult.handled;
                },
                child: Text(
                  l10n.settingsPlaybackShortcutsPressKeyHint,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class PlaybackShortcutsSettingsSection extends StatelessWidget {
  const PlaybackShortcutsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = context.watch<PlaybackShortcutController>();
    final cfg = ctrl.config;
    final subStyle = TextStyle(color: context.gradFg(0.6), fontSize: 13);

    return ExpansionTile(
      leading: Icon(Icons.keyboard_outlined, color: context.gradFg()),
      title: Text(
        l10n.settingsPlaybackShortcutsTitle,
        style: TextStyle(color: context.gradFg()),
      ),
      subtitle: Text(l10n.settingsPlaybackShortcutsSubtitle, style: subStyle),
      iconColor: context.gradFg(),
      collapsedIconColor: context.gradFg(),
      children: [
        _ShortcutTile(
          label: l10n.settingsPlaybackShortcutsPlayPause,
          binding: cfg.playPause,
          onChange: () async {
            final a = await _recordShortcut(context);
            if (!context.mounted || a == null) return;
            await ctrl.setBinding(
              PlaybackShortcutKind.playPause,
              PlaybackShortcutBinding(enabled: true, activator: a),
            );
          },
          onDisable: () => ctrl.setBinding(
            PlaybackShortcutKind.playPause,
            const PlaybackShortcutBinding.disabled(),
          ),
          onEnableDefault: () => ctrl.setBinding(
            PlaybackShortcutKind.playPause,
            PlaybackShortcutBinding.defaultPlayPause(),
          ),
        ),
        _ShortcutTile(
          label: l10n.settingsPlaybackShortcutsPrevious,
          binding: cfg.previous,
          onChange: () async {
            final a = await _recordShortcut(context);
            if (!context.mounted || a == null) return;
            await ctrl.setBinding(
              PlaybackShortcutKind.previous,
              PlaybackShortcutBinding(enabled: true, activator: a),
            );
          },
          onDisable: () => ctrl.setBinding(
            PlaybackShortcutKind.previous,
            const PlaybackShortcutBinding.disabled(),
          ),
          onEnableDefault: () => ctrl.setBinding(
            PlaybackShortcutKind.previous,
            PlaybackShortcutBinding.defaultPrevious(),
          ),
        ),
        _ShortcutTile(
          label: l10n.settingsPlaybackShortcutsNext,
          binding: cfg.next,
          onChange: () async {
            final a = await _recordShortcut(context);
            if (!context.mounted || a == null) return;
            await ctrl.setBinding(
              PlaybackShortcutKind.next,
              PlaybackShortcutBinding(enabled: true, activator: a),
            );
          },
          onDisable: () => ctrl.setBinding(
            PlaybackShortcutKind.next,
            const PlaybackShortcutBinding.disabled(),
          ),
          onEnableDefault: () => ctrl.setBinding(
            PlaybackShortcutKind.next,
            PlaybackShortcutBinding.defaultNext(),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.binding,
    required this.onChange,
    required this.onDisable,
    required this.onEnableDefault,
  });

  final String label;
  final PlaybackShortcutBinding binding;
  final VoidCallback onChange;
  final VoidCallback onDisable;
  final VoidCallback onEnableDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = TextStyle(color: context.gradFg(0.6), fontSize: 13);
    final current = binding.enabled && binding.activator != null
        ? binding.describeKeys()
        : l10n.settingsPlaybackShortcutsDisabledLabel;
    final enabled = binding.enabled && binding.activator != null;

    return ListTile(
      title: Text(label, style: TextStyle(color: context.gradFg())),
      subtitle: Text(current, style: muted),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.gradFg(0.85),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: onChange,
            child: Text(l10n.settingsPlaybackShortcutsChange),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.gradFg(0.85),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: enabled ? onDisable : onEnableDefault,
            child: Text(
              enabled
                  ? l10n.settingsPlaybackShortcutsDisable
                  : l10n.settingsPlaybackShortcutsEnable,
            ),
          ),
        ],
      ),
    );
  }
}
