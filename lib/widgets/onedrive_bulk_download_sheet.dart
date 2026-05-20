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
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/widgets/onedrive_download_queue_panel.dart';

/// 底部弹层：发起批量下载并展示队列；关闭抽屉后下载在后台继续（由 [OneDriveDownloadQueueController] 持有）。
class OneDriveBulkDownloadSheet extends StatefulWidget {
  const OneDriveBulkDownloadSheet({
    super.key,
    required this.runBatch,
    this.autoPlayWhenDone = true,
  });

  final Future<List<Song>> Function(OneDriveDownloadQueueController controller) runBatch;

  final bool autoPlayWhenDone;

  @override
  State<OneDriveBulkDownloadSheet> createState() => _OneDriveBulkDownloadSheetState();
}

class _OneDriveBulkDownloadSheetState extends State<OneDriveBulkDownloadSheet> {
  bool _runEnded = false;
  late bool _autoPlayOnFinish;

  @override
  void initState() {
    super.initState();
    _autoPlayOnFinish = widget.autoPlayWhenDone;
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoff());
  }

  Future<void> _kickoff() async {
    final ctrl = context.read<OneDriveDownloadQueueController>();
    final play = context.read<PlayListProvider>();
    await widget.runBatch(ctrl);
    if (!mounted) return;
    setState(() {
      _runEnded = true;
    });
    if (_autoPlayOnFinish && ctrl.completedSongs.isNotEmpty && !ctrl.stopRequested && mounted) {
      await play.setPlaybackQueueAndPlay(
        ctrl.completedSongs,
        0,
        session: PlaybackSessionSurface.adHoc,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _playDownloaded(BuildContext context) async {
    final ctrl = context.read<OneDriveDownloadQueueController>();
    final play = context.read<PlayListProvider>();
    if (ctrl.completedSongs.isEmpty) return;
    await play.setPlaybackQueueAndPlay(
      ctrl.completedSongs,
      0,
      session: PlaybackSessionSurface.adHoc,
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Consumer<OneDriveDownloadQueueController>(
      builder: (context, ctrl, _) {
        final maxH = MediaQuery.sizeOf(context).height - bottomInset;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.oneDriveDownloadQueueTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.oneDriveDownloadCloseJustPanel,
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.close_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: OneDriveDownloadQueuePanel(
                      maxListHeight: null,
                      taskFilter: OneDriveQueuePanelTaskFilter.downloadsOnly,
                      showPlayDownloadedButton:
                          _runEnded && ctrl.hasCompletedSongs,
                      onPlayDownloaded: () => _playDownloaded(context),
                      autoPlaySwitch: SwitchListTile.adaptive(
                        value: _autoPlayOnFinish,
                        onChanged: _runEnded
                            ? null
                            : (v) {
                                setState(() => _autoPlayOnFinish = v);
                              },
                        title: Text(
                          l10n.oneDriveDownloadAutoPlayWhenDone,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        activeThumbColor: const Color(0xFF64B5F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
