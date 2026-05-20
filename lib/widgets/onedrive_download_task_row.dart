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
            LinearProgressIndicator(
              value: switch (task.status) {
                OneDriveDownloadStatus.completed => 1,
                _ => (total != null && total > 0)
                    ? prog.clamp(0.0, 1.0)
                    : null,
              },
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
