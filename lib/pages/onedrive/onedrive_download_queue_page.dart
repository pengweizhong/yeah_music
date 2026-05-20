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

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_download_task.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/widgets/onedrive_download_queue_panel.dart';
import 'package:yeah_music/widgets/onedrive_download_task_row.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// 全屏传输队列页打开时默认选中的 Tab（与 [DefaultTabController.initialIndex] 一致）。
enum OneDriveTransferQueueTab {
  /// 下载队列（第一个 Tab）
  download(0),

  /// 上传队列（第二个 Tab）
  upload(1);

  const OneDriveTransferQueueTab(this.tabIndex);
  final int tabIndex;
}

/// 全屏传输队列 Tab：任务列表 + 底部留白一体滚动；短列表用 [SliverFillRemaining] 铺满视口剩余高度。
List<Widget> _transferQueueTaskSlivers({
  required List<OneDriveDownloadTask> tasks,
  required OneDriveDownloadQueueController ctrl,
  required AppLocalizations l10n,
  required double viewportBottomInset,
  required String emptyMessage,
}) {
  if (tasks.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewportBottomInset),
          child: Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white54, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const Divider(height: 1, color: Color(0x22FFFFFF));
          }
          final ti = index ~/ 2;
          return _dismissibleTransferTaskRow(
            task: tasks[ti],
            ctrl: ctrl,
            l10n: l10n,
          );
        }, childCount: tasks.length * 2 - 1),
      ),
    ),
    SliverToBoxAdapter(child: SizedBox(height: viewportBottomInset)),
    const SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: SizedBox.expand(),
    ),
  ];
}

Widget _dismissibleTransferTaskRow({
  required OneDriveDownloadTask task,
  required OneDriveDownloadQueueController ctrl,
  required AppLocalizations l10n,
}) {
  final key = ValueKey<String>(
    [
      task.isUpload ? 'upload' : 'download',
      task.graphItem.id,
      task.uploadLocalPath ?? '',
      task.uploadParentItemId ?? '',
      task.uploadRemoteFileName ?? '',
      task.enqueuedAt.microsecondsSinceEpoch,
    ].join('|'),
  );

  return Dismissible(
    key: key,
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFE53935),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            l10n.actionRemove,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    onDismissed: (_) => unawaited(ctrl.removeTask(task)),
    child: OneDriveDownloadTaskRow(
      task: task,
      formatBytes: formatOneDriveDownloadBytes,
      l10n: l10n,
    ),
  );
}

/// 全屏查看 / 控制 OneDrive 传输队列（关闭抽屉后任务仍在此继续）。
class OneDriveDownloadQueuePage extends StatelessWidget {
  const OneDriveDownloadQueuePage({
    super.key,
    this.initialTab = OneDriveTransferQueueTab.download,
  });

  /// 进入页面时默认展示的 Tab（下载 / 上传）。
  final OneDriveTransferQueueTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initialIndex = initialTab.tabIndex;
    return Consumer<ThemeConfigProvider>(
      builder: (context, theme, _) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialIndex,
          child: theme.buildThemedBackground(
            context: context,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              extendBody: true,
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  l10n.oneDriveTransferQueueTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                systemOverlayStyle: SystemUiOverlayStyle.light,
                bottom: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white70,
                  tabs: [
                    Tab(text: l10n.oneDriveTransferTabDownload),
                    Tab(text: l10n.oneDriveTransferTabUpload),
                  ],
                ),
              ),
              body: Builder(
                builder: (ctx) => Consumer<PlayListProvider>(
                  builder: (context, play, _) {
                    final showMini =
                        play.initialized &&
                        play.currentSong != null &&
                        play.playList.isNotEmpty;
                    final bottomPad =
                        MediaQuery.paddingOf(context).bottom +
                        8 +
                        (showMini ? MiniPlayer.barHeight : 0.0);
                    return Column(
                      children: [
                        SizedBox(height: songPlaylistUnderlapTopInset(ctx)),
                        Expanded(
                          child: TabBarView(
                            children: [
                              Consumer2<
                                OneDriveDownloadQueueController,
                                PlayListProvider
                              >(
                                builder: (context, ctrl, playList, _) {
                                  final tracks = filterOneDriveQueueTasks(
                                    ctrl,
                                    OneDriveQueuePanelTaskFilter.downloadsOnly,
                                  );
                                  final emptyDl = oneDriveQueueTabEmptyMessage(
                                    l10n,
                                    OneDriveQueuePanelTaskFilter.downloadsOnly,
                                  );
                                  return CustomScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            8,
                                          ),
                                          child: Text(
                                            l10n.oneDriveDownloadQueuePageHint,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: ctrl.hasCompletedSongs
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      0,
                                                      16,
                                                      8,
                                                    ),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: FilledButton.tonalIcon(
                                                    onPressed: () async {
                                                      await playList
                                                          .setPlaybackQueueAndPlay(
                                                            ctrl.completedSongs,
                                                            0,
                                                            session:
                                                                PlaybackSessionSurface
                                                                    .adHoc,
                                                          );
                                                    },
                                                    icon: const Icon(
                                                      Icons.play_arrow_rounded,
                                                    ),
                                                    label: Text(
                                                      l10n.oneDriveDownloadPlayDownloaded,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      SliverToBoxAdapter(
                                        child: OneDriveTransferQueueToolbar(
                                          ctrl: ctrl,
                                          l10n: l10n,
                                          taskFilter:
                                              OneDriveQueuePanelTaskFilter
                                                  .downloadsOnly,
                                        ),
                                      ),
                                      ..._transferQueueTaskSlivers(
                                        tasks: tracks,
                                        ctrl: ctrl,
                                        l10n: l10n,
                                        viewportBottomInset: bottomPad,
                                        emptyMessage: emptyDl,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Consumer<OneDriveDownloadQueueController>(
                                builder: (context, ctrl, _) {
                                  final tracks = filterOneDriveQueueTasks(
                                    ctrl,
                                    OneDriveQueuePanelTaskFilter.uploadsOnly,
                                  );
                                  final emptyUp = oneDriveQueueTabEmptyMessage(
                                    l10n,
                                    OneDriveQueuePanelTaskFilter.uploadsOnly,
                                  );
                                  return CustomScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            8,
                                          ),
                                          child: Text(
                                            l10n.oneDriveUploadQueuePageHint,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: OneDriveTransferQueueToolbar(
                                          ctrl: ctrl,
                                          l10n: l10n,
                                          taskFilter:
                                              OneDriveQueuePanelTaskFilter
                                                  .uploadsOnly,
                                        ),
                                      ),
                                      ..._transferQueueTaskSlivers(
                                        tasks: tracks,
                                        ctrl: ctrl,
                                        l10n: l10n,
                                        viewportBottomInset: bottomPad,
                                        emptyMessage: emptyUp,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              bottomNavigationBar: const MiniPlayer(),
            ),
          ),
        );
      },
    );
  }
}
