import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/widgets/onedrive_download_task_row.dart';

String formatOneDriveDownloadBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 队列列表过滤：[downloadsOnly] 用于批量下载抽屉与「下载」Tab；[uploadsOnly] 用于「上传」Tab。
enum OneDriveQueuePanelTaskFilter {
  all,
  downloadsOnly,
  uploadsOnly,
}

/// 下载控制区 + 任务列表（抽屉与全屏页共用）。
class OneDriveDownloadQueuePanel extends StatelessWidget {
  const OneDriveDownloadQueuePanel({
    super.key,
    this.maxListHeight,
    this.bottomPadding = 16,
    this.showPlayDownloadedButton = false,
    this.onPlayDownloaded,
    this.autoPlaySwitch,
    this.taskFilter = OneDriveQueuePanelTaskFilter.all,
  });

  /// 底部抽屉内为列表设上限；全屏页传 `null`，由外层 [Expanded] 包住本组件以占满剩余高度。
  final double? maxListHeight;

  final double bottomPadding;

  final bool showPlayDownloadedButton;

  final VoidCallback? onPlayDownloaded;

  /// 非 null 时插入「完成后自动播放」区域（仅首次批量抽屉使用）。
  final Widget? autoPlaySwitch;

  final OneDriveQueuePanelTaskFilter taskFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer<OneDriveDownloadQueueController>(
      builder: (context, ctrl, _) {
        final allSorted = ctrl.tasksSortedForDisplay;
        final tasks = switch (taskFilter) {
          OneDriveQueuePanelTaskFilter.all => allSorted,
          OneDriveQueuePanelTaskFilter.downloadsOnly =>
            allSorted.where((t) => !t.isUpload).toList(),
          OneDriveQueuePanelTaskFilter.uploadsOnly =>
            allSorted.where((t) => t.isUpload).toList(),
        };
        final emptyMessage = switch (taskFilter) {
          OneDriveQueuePanelTaskFilter.downloadsOnly =>
            l10n.oneDriveDownloadQueueEmpty,
          OneDriveQueuePanelTaskFilter.uploadsOnly => l10n.oneDriveUploadQueueEmpty,
          OneDriveQueuePanelTaskFilter.all => l10n.oneDriveTransferQueueEmpty,
        };

        Widget buildList() {
          if (tasks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                style: const TextStyle(color: Colors.white54, height: 1.45),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPadding),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0x22FFFFFF)),
            itemBuilder: (context, i) {
              return OneDriveDownloadTaskRow(
                task: tasks[i],
                formatBytes: formatOneDriveDownloadBytes,
                l10n: l10n,
              );
            },
          );
        }

        final listArea = maxListHeight != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight!),
                child: buildList(),
              )
            : Expanded(child: buildList());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: maxListHeight != null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.canPauseDownloads ? ctrl.pause : null,
                      icon: const Icon(Icons.pause_rounded, size: 20),
                      label: Text(l10n.oneDriveDownloadPause),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.canResumeDownloads ? ctrl.resume : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(l10n.oneDriveDownloadResume),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: ctrl.canStopDownloads
                          ? ctrl.requestStop
                          : ctrl.canResumeStaleTasks
                              ? ctrl.resumeStaleTasks
                              : null,
                      icon: Icon(
                        ctrl.canResumeStaleTasks && !ctrl.canStopDownloads
                            ? Icons.play_arrow_rounded
                            : Icons.stop_rounded,
                        size: 20,
                      ),
                      label: Text(
                        ctrl.canResumeStaleTasks && !ctrl.canStopDownloads
                            ? l10n.oneDriveDownloadContinueAll
                            : l10n.oneDriveDownloadStopAll,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?autoPlaySwitch,
            if (showPlayDownloadedButton && onPlayDownloaded != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onPlayDownloaded,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.oneDriveDownloadPlayDownloaded),
                  ),
                ),
              ),
            listArea,
            if (ctrl.hasRecordedTasks)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: TextButton.icon(
                  onPressed: () async {
                    await ctrl.clearDownloadHistory();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                  label: Text(
                    l10n.oneDriveDownloadClearHistory,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
