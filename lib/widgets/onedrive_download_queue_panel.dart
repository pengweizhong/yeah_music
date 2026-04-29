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
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(color: Colors.white54, height: 1.45),
                  textAlign: TextAlign.center,
                ),
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

        final Widget listArea = maxListHeight != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight!),
                child: buildList(),
              )
            : Expanded(child: buildList());

        final resumeStale = ctrl.canResumeStaleTasks && !ctrl.canStopDownloads;
        final stopTooltip = resumeStale
            ? l10n.oneDriveDownloadContinueAll
            : l10n.oneDriveDownloadStopAll;
        final stopIcon = resumeStale ? Icons.play_arrow_rounded : Icons.stop_rounded;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: maxListHeight != null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.pause_rounded, size: 22),
                    tooltip: l10n.oneDriveDownloadPause,
                    onPressed: ctrl.canPauseDownloads ? ctrl.pause : null,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x66FFFFFF)),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    tooltip: l10n.oneDriveDownloadResume,
                    onPressed: ctrl.canResumeDownloads ? ctrl.resume : null,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x66FFFFFF)),
                    ),
                  ),
                  IconButton.filled(
                    icon: Icon(stopIcon, size: 22),
                    tooltip: stopTooltip,
                    onPressed: ctrl.canStopDownloads
                        ? ctrl.requestStop
                        : ctrl.canResumeStaleTasks
                            ? ctrl.resumeStaleTasks
                            : null,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  _clearListIconButton(ctrl, l10n, taskFilter),
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
          ],
        );
      },
    );
  }
}

Widget _clearListIconButton(
  OneDriveDownloadQueueController ctrl,
  AppLocalizations l10n,
  OneDriveQueuePanelTaskFilter filter,
) {
  late final bool enabled;
  late final String tooltip;
  late final Future<void> Function() onClear;

  switch (filter) {
    case OneDriveQueuePanelTaskFilter.downloadsOnly:
      enabled = ctrl.hasDownloadTasks;
      tooltip = l10n.oneDriveTransferClearDownloadsList;
      onClear = ctrl.clearDownloadTasksOnly;
      break;
    case OneDriveQueuePanelTaskFilter.uploadsOnly:
      enabled = ctrl.hasUploadTasks;
      tooltip = l10n.oneDriveTransferClearUploadsList;
      onClear = ctrl.clearUploadTasksOnly;
      break;
    case OneDriveQueuePanelTaskFilter.all:
      enabled = ctrl.hasRecordedTasks;
      tooltip = l10n.oneDriveDownloadClearHistory;
      onClear = ctrl.clearDownloadHistory;
      break;
  }

  final color =
      enabled ? Colors.white70 : Colors.white.withValues(alpha: 0.28);

  return IconButton(
    icon: Icon(Icons.delete_outline_rounded, size: 22, color: color),
    tooltip: tooltip,
    onPressed: enabled
        ? () async {
            await onClear();
          }
        : null,
  );
}
