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

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/playback_shortcut_controller.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

String _actionLabel(AppLocalizations l10n, WireRemoteControlAction a) {
  return switch (a) {
    WireRemoteControlAction.playPause => l10n.wireRemoteActionPlayPause,
    WireRemoteControlAction.next => l10n.wireRemoteActionNext,
    WireRemoteControlAction.previous => l10n.wireRemoteActionPrevious,
    WireRemoteControlAction.none => l10n.wireRemoteActionNone,
  };
}

Future<void> _pickAction(
  BuildContext context,
  AppLocalizations l10n,
  WireRemoteControlAction current,
  void Function(WireRemoteControlAction value) onChosen,
) async {
  final chosen = await showDialog<WireRemoteControlAction>(
    context: context,
    builder: (ctx) {
      return SimpleDialog(
        title: Text(l10n.wireRemotePickActionTitle),
        children: [
          for (final a in WireRemoteControlAction.values)
            ListTile(
              title: Text(_actionLabel(l10n, a)),
              trailing: a == current ? const Icon(Icons.check, size: 20) : null,
              onTap: () => Navigator.pop(ctx, a),
            ),
        ],
      );
    },
  );
  if (chosen != null && context.mounted) {
    onChosen(chosen);
  }
}

/// 有线耳机线控（单击 / 双击 / 三击）；**自定义映射仅在 Android 且应用前台时生效**。
class WireRemoteControlSection extends StatelessWidget {
  const WireRemoteControlSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = context.watch<PlaybackShortcutController>();
    final cfg = ctrl.wireRemote;
    final subStyle = TextStyle(color: context.gradFg(0.6), fontSize: 13);
    final supportedHere = !kIsWeb && Platform.isAndroid;

    return Opacity(
      opacity: supportedHere ? 1.0 : 0.48,
      child: ExpansionTile(
        leading: Icon(Icons.headset_outlined, color: context.gradFg()),
        title: Text(
          l10n.settingsWireRemoteTitle,
          style: TextStyle(color: context.gradFg()),
        ),
        subtitle: Text(
          supportedHere
              ? l10n.settingsWireRemoteSubtitle
              : l10n.settingsWireRemoteSubtitleOtherPlatforms,
          style: subStyle,
        ),
        iconColor: context.gradFg(),
        collapsedIconColor: context.gradFg(),
        children: [
          if (!supportedHere)
            ListTile(
              title: Text(
                l10n.settingsWireRemoteUnavailableTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                l10n.settingsWireRemoteUnavailableBody,
                style: subStyle,
              ),
            )
          else ...[
            SwitchListTile(
              secondary: Icon(Icons.tune, color: context.gradFg(0.75)),
              title: Text(
                l10n.settingsWireRemoteUseCustom,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                l10n.settingsWireRemoteUseCustomSubtitle,
                style: subStyle,
              ),
              value: cfg.enabled,
              onChanged: (v) => ctrl.setWireRemote(cfg.copyWith(enabled: v)),
            ),
            ListTile(
              title: Text(
                l10n.wireRemoteSingleTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                _actionLabel(l10n, cfg.singleClick),
                style: subStyle,
              ),
              enabled: cfg.enabled,
              onTap: cfg.enabled
                  ? () => _pickAction(context, l10n, cfg.singleClick, (a) {
                      ctrl.setWireRemote(cfg.copyWith(singleClick: a));
                    })
                  : null,
            ),
            ListTile(
              title: Text(
                l10n.wireRemoteDoubleTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                _actionLabel(l10n, cfg.doubleClick),
                style: subStyle,
              ),
              enabled: cfg.enabled,
              onTap: cfg.enabled
                  ? () => _pickAction(context, l10n, cfg.doubleClick, (a) {
                      ctrl.setWireRemote(cfg.copyWith(doubleClick: a));
                    })
                  : null,
            ),
            ListTile(
              title: Text(
                l10n.wireRemoteTripleTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                _actionLabel(l10n, cfg.tripleClick),
                style: subStyle,
              ),
              enabled: cfg.enabled,
              onTap: cfg.enabled
                  ? () => _pickAction(context, l10n, cfg.tripleClick, (a) {
                      ctrl.setWireRemote(cfg.copyWith(tripleClick: a));
                    })
                  : null,
            ),
            ListTile(
              title: Text(
                l10n.wireRemoteMediaNextTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                _actionLabel(l10n, cfg.mediaNextKeyAction),
                style: subStyle,
              ),
              enabled: cfg.enabled,
              onTap: cfg.enabled
                  ? () => _pickAction(context, l10n, cfg.mediaNextKeyAction, (
                      a,
                    ) {
                      ctrl.setWireRemote(cfg.copyWith(mediaNextKeyAction: a));
                    })
                  : null,
            ),
            ListTile(
              title: Text(
                l10n.wireRemoteMediaPreviousTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              subtitle: Text(
                _actionLabel(l10n, cfg.mediaPreviousKeyAction),
                style: subStyle,
              ),
              enabled: cfg.enabled,
              onTap: cfg.enabled
                  ? () => _pickAction(
                      context,
                      l10n,
                      cfg.mediaPreviousKeyAction,
                      (a) {
                        ctrl.setWireRemote(
                          cfg.copyWith(mediaPreviousKeyAction: a),
                        );
                      },
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
