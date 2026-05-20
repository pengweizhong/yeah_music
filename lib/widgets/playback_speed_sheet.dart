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

import 'package:flutter/material.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/playback_speed.dart';

/// 播放页「更多」内打开的倍速底部面板。
Future<void> showPlaybackSpeedSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FrostedGlassBottomSheet(
          child: SafeArea(
            top: false,
            child: const _PlaybackSpeedSheetBody(),
          ),
        ),
      );
    },
  );
}

class _PlaybackSpeedSheetBody extends StatefulWidget {
  const _PlaybackSpeedSheetBody();

  @override
  State<_PlaybackSpeedSheetBody> createState() => _PlaybackSpeedSheetBodyState();
}

class _PlaybackSpeedSheetBodyState extends State<_PlaybackSpeedSheetBody> {
  late Future<double> _load;

  @override
  void initState() {
    super.initState();
    _load = SettingsService.loadPlaybackSpeed();
    SettingsService.playbackSpeedRevision.addListener(_onRevision);
  }

  @override
  void dispose() {
    SettingsService.playbackSpeedRevision.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    if (mounted) {
      setState(() {
        _load = SettingsService.loadPlaybackSpeed();
      });
    }
  }

  Future<void> _select(double speed) async {
    await MusicService.setPlaybackSpeed(speed);
    if (!mounted) return;
    setState(() {
      _load = Future.value(speed);
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<double>(
      future: _load,
      builder: (context, snap) {
        final current = normalizePlaybackSpeed(
          snap.data ?? MusicService.playbackSpeed,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.playbackSpeedSheetTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...kPlaybackSpeedOptions.map((speed) {
              final selected = speed == current;
              return ListTile(
                leading: Icon(
                  selected ? Icons.check_circle_rounded : Icons.speed_rounded,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(playbackSpeedLabel(speed)),
                trailing: selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => _select(speed),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
