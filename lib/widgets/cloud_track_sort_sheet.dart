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
          child: Theme(
            data: frostedBottomSheetContentTheme(ctx),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      l10n.sortOptionsTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha, color: Colors.white),
                    title: Text(l10n.sortByName),
                    trailing: Icon(
                      sortType == CloudTrackSortType.fileName
                          ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.check_box_outline_blank,
                      color: Colors.white54,
                      size: 20,
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
                    leading: const Icon(Icons.folder_open_outlined, color: Colors.white),
                    title: Text(l10n.sortByPath),
                    trailing: Icon(
                      sortType == CloudTrackSortType.fullPath
                          ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.check_box_outline_blank,
                      color: Colors.white54,
                      size: 20,
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
        ),
      );
    },
  );
}
