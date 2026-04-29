import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_download_task.dart';

class OneDriveDownloadTaskRow extends StatelessWidget {
  const OneDriveDownloadTaskRow({
    super.key,
    required this.task,
    required this.formatBytes,
    required this.l10n,
  });

  final OneDriveDownloadTask task;
  final String Function(int) formatBytes;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (task.status) {
      OneDriveDownloadStatus.pending => l10n.oneDriveDownloadStatusPending,
      OneDriveDownloadStatus.downloading => task.isUpload
          ? l10n.oneDriveUploadStatusUploading
          : l10n.oneDriveDownloadStatusDownloading,
      OneDriveDownloadStatus.completed => l10n.oneDriveDownloadStatusDone,
      OneDriveDownloadStatus.failed => l10n.oneDriveDownloadStatusFailed,
      OneDriveDownloadStatus.cancelled => l10n.oneDriveDownloadStatusCancelled,
    };

    final prog = task.progress;
    final total = task.totalBytes;

    final progressBarColor = task.status == OneDriveDownloadStatus.completed
        ? const Color(0xFF66BB6A)
        : const Color(0xFF4FC3F7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            task.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
          ),
          if (task.status == OneDriveDownloadStatus.downloading ||
              task.status == OneDriveDownloadStatus.completed) ...[
            const SizedBox(height: 6),
            if (total != null && total > 0)
              LinearProgressIndicator(
                value: prog.clamp(0, 1),
                minHeight: 4,
                backgroundColor: const Color(0x22FFFFFF),
                color: progressBarColor,
              )
            else
              LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: const Color(0x22FFFFFF),
                color: progressBarColor,
              ),
            const SizedBox(height: 4),
            Text(
              total != null && total > 0
                  ? '${formatBytes(task.receivedBytes)} / ${formatBytes(total)}'
                  : formatBytes(task.receivedBytes),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
          if (task.status == OneDriveDownloadStatus.failed && task.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${task.error}',
                style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 11),
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }
}
