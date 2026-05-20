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
import 'package:yeah_music/models/onedrive_cloud_track.dart';

Future<void> showCloudTrackSortBottomSheet(
  BuildContext context, {
  required CloudTrackSortType sortType,
  required bool isAscending,
  required void Function(CloudTrackSortType type, bool ascending) onApply,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: FrostedGlassBottomSheet(
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    l10n.sortOptionsTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: Text(l10n.sortByName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sortType == CloudTrackSortType.fileName)
                        Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 20,
                          color: primary,
                        ),
                      if (sortType == CloudTrackSortType.fileName)
                        const SizedBox(width: 8),
                      if (sortType == CloudTrackSortType.fileName)
                        Icon(Icons.check, color: primary),
                    ],
                  ),
                  onTap: () {
                    if (sortType == CloudTrackSortType.fileName) {
                      onApply(CloudTrackSortType.fileName, !isAscending);
                    } else {
                      onApply(CloudTrackSortType.fileName, true);
                    }
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(l10n.sortByPath),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sortType == CloudTrackSortType.fullPath)
                        Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 20,
                          color: primary,
                        ),
                      if (sortType == CloudTrackSortType.fullPath)
                        const SizedBox(width: 8),
                      if (sortType == CloudTrackSortType.fullPath)
                        Icon(Icons.check, color: primary),
                    ],
                  ),
                  onTap: () {
                    if (sortType == CloudTrackSortType.fullPath) {
                      onApply(CloudTrackSortType.fullPath, !isAscending);
                    } else {
                      onApply(CloudTrackSortType.fullPath, true);
                    }
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}
