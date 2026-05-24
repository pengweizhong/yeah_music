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

/// 曲库/歌单等多选模式底部操作条；与 [FrostedGlassPanel.bottomBar] 一致，白天/夜间均可读。
class LibraryBatchActionBar extends StatelessWidget {
  const LibraryBatchActionBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    this.selectAllLabel,
    this.onUploadOneDrive,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onDelete,
    this.onDownload,
    this.downloadTooltip,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final String? selectAllLabel;
  final VoidCallback? onUploadOneDrive;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final String? downloadTooltip;

  static const double _contentHeight = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return FrostedGlassPanel.bottomBar(
      height: _contentHeight + bottomInset,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton(
                onPressed: onSelectAll,
                child: Text(selectAllLabel ?? l10n.libraryBatchSelectAll),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$selectedCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDownload != null)
                IconButton(
                  tooltip: downloadTooltip,
                  icon: const Icon(Icons.download_for_offline_outlined),
                  onPressed: onDownload,
                ),
              if (onUploadOneDrive != null)
                IconButton(
                  tooltip: l10n.libraryBatchUploadOneDrive,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  onPressed: onUploadOneDrive,
                ),
              if (onAddToPlaylist != null)
                IconButton(
                  tooltip: l10n.libraryBatchAddToPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  onPressed: onAddToPlaylist,
                ),
              if (onRemoveFromPlaylist != null)
                IconButton(
                  tooltip: l10n.userPlaylistBatchRemoveFromPlaylist,
                  icon: const Icon(Icons.playlist_remove_outlined),
                  onPressed: onRemoveFromPlaylist,
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: l10n.libraryBatchDelete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
