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

/// 全屏查看 / 控制 OneDrive 批量下载队列（关闭抽屉后任务仍在此继续）。
class OneDriveDownloadQueuePage extends StatelessWidget {
  const OneDriveDownloadQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, theme, _) {
        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.oneDriveDownloadQueueTitle,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
            body: Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.oneDriveDownloadQueuePageHint,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.4),
                  ),
                ),
                Consumer2<OneDriveDownloadQueueController, PlayListProvider>(
                  builder: (context, ctrl, play, _) {
                    if (!ctrl.hasCompletedSongs) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            await play.setPlaybackQueueAndPlay(
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OneDriveDownloadQueuePanel(maxListHeight: null),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }
}
