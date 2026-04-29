import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/widgets/onedrive_download_queue_panel.dart';
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
                    final showMini = play.initialized &&
                        play.currentSong != null &&
                        play.playList.isNotEmpty;
                    final bottomPad = MediaQuery.paddingOf(context).bottom +
                        8 +
                        (showMini ? MiniPlayer.barHeight : 0.0);
                    return Padding(
                      padding: EdgeInsets.only(bottom: bottomPad),
                      child: Column(
                        children: [
                          SizedBox(height: songPlaylistUnderlapTopInset(ctx)),
                          Expanded(
                            child: TabBarView(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                      child: Text(
                                        l10n.oneDriveDownloadQueuePageHint,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    Consumer2<OneDriveDownloadQueueController, PlayListProvider>(
                                      builder: (context, ctrl, playList, _) {
                                        if (!ctrl.hasCompletedSongs) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.tonalIcon(
                                              onPressed: () async {
                                                await playList.setPlaybackQueueAndPlay(
                                                  ctrl.completedSongs,
                                                  0,
                                                  session: PlaybackSessionSurface.adHoc,
                                                );
                                              },
                                              icon: const Icon(Icons.play_arrow_rounded),
                                              label: Text(l10n.oneDriveDownloadPlayDownloaded),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: OneDriveDownloadQueuePanel(
                                          maxListHeight: null,
                                          taskFilter: OneDriveQueuePanelTaskFilter.downloadsOnly,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                      child: Text(
                                        l10n.oneDriveUploadQueuePageHint,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: OneDriveDownloadQueuePanel(
                                          maxListHeight: null,
                                          taskFilter: OneDriveQueuePanelTaskFilter.uploadsOnly,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
