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
      Widget sortTile({
        required IconData icon,
        required String title,
        required CloudTrackSortType type,
      }) {
        final selected = sortType == type;
        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                  color: primary,
                ),
              if (selected) const SizedBox(width: 8),
              if (selected) Icon(Icons.check, color: primary),
            ],
          ),
          onTap: () {
            if (selected) {
              onApply(type, !isAscending);
            } else {
              onApply(type, true);
            }
            Navigator.pop(ctx);
          },
        );
      }

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
                sortTile(
                  icon: Icons.sort_by_alpha,
                  title: l10n.sortByName,
                  type: CloudTrackSortType.fileName,
                ),
                sortTile(
                  icon: Icons.folder_open_outlined,
                  title: l10n.sortByPath,
                  type: CloudTrackSortType.fullPath,
                ),
                sortTile(
                  icon: Icons.schedule_outlined,
                  title: l10n.sortByCreated,
                  type: CloudTrackSortType.createdDate,
                ),
                sortTile(
                  icon: Icons.update_outlined,
                  title: l10n.sortByUpdated,
                  type: CloudTrackSortType.modifiedDate,
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
