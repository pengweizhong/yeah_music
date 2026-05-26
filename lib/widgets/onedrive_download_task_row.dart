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
import 'package:flutter/services.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_download_task.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

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
          if (!task.isUpload && task.subtitle.trim().isNotEmpty)
            _CopyableTransferPathLine(
              label: l10n.oneDriveTransferPathCloudSource,
              path: task.subtitle.trim(),
              color: Colors.white.withValues(alpha: 0.35),
              copiedMessage: l10n.diagnosticLogCopied,
            ),
          if (task.isUpload) ...[
            if ((task.uploadCloudPath ?? '').trim().isNotEmpty)
              _CopyableTransferPathLine(
                label: l10n.oneDriveTransferPathUploadTo,
                path: task.uploadCloudPath!.trim(),
                color: Colors.white.withValues(alpha: 0.5),
                copiedMessage: l10n.diagnosticLogCopied,
              ),
            if ((task.uploadLocalPath ?? '').trim().isNotEmpty)
              _CopyableTransferPathLine(
                label: l10n.oneDriveTransferPathLocalSource,
                path: task.uploadLocalPath!.trim(),
                color: Colors.white.withValues(alpha: 0.35),
                copiedMessage: l10n.diagnosticLogCopied,
              ),
          ] else ...[
            if ((task.localDownloadRootPath ?? '').trim().isNotEmpty)
              _CopyableTransferPathLine(
                label: l10n.oneDriveTransferPathDownloadDir,
                path: task.localDownloadRootPath!.trim(),
                color: Colors.white.withValues(alpha: 0.5),
                copiedMessage: l10n.diagnosticLogCopied,
              ),
            if ((task.displayLocalDownloadPath ?? '').trim().isNotEmpty)
              _CopyableTransferPathLine(
                label: l10n.oneDriveTransferPathDownloadFile,
                path: task.displayLocalDownloadPath!.trim(),
                color: Colors.white.withValues(alpha: 0.45),
                copiedMessage: l10n.diagnosticLogCopied,
              ),
          ],
          if (task.isUpload && task.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              task.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ],
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

/// 传输队列路径行：点击整行或复制按钮将 [path] 写入剪贴板。
class _CopyableTransferPathLine extends StatelessWidget {
  const _CopyableTransferPathLine({
    required this.label,
    required this.path,
    required this.color,
    required this.copiedMessage,
  });

  final String label;
  final String path;
  final Color color;
  final String copiedMessage;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    showAppSnackBar(context, copiedMessage, kind: AppSnackKind.neutral);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _copy(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$label ',
                          style: TextStyle(color: color, fontSize: 11),
                        ),
                        TextSpan(
                          text: path,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.92),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: color.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
