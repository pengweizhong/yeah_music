import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/utils/song_list_sort.dart';

/// 排序选择底部表单。[includeAddedToPlaylistOption] 为 true 时多出「按加入歌单时间」（用户歌单页）
void showSongSortBottomSheet(
  BuildContext context, {
  required SongListSortType sortType,
  required bool isAscending,
  required void Function(SongListSortType type, bool ascending) onApply,
  bool includeAddedToPlaylistOption = false,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  showModalBottomSheet<void>(
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      l10n.sortOptionsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha, color: Colors.white),
                    title: Text(l10n.sortByName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sortType == SongListSortType.name)
                          Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 20,
                            color: primary,
                          ),
                        if (sortType == SongListSortType.name)
                          const SizedBox(width: 8),
                        if (sortType == SongListSortType.name)
                          Icon(Icons.check, color: primary),
                      ],
                    ),
                    onTap: () {
                      if (sortType == SongListSortType.name) {
                        onApply(SongListSortType.name, !isAscending);
                      } else {
                        onApply(SongListSortType.name, true);
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.white),
                    title: Text(l10n.sortByCreated),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sortType == SongListSortType.createTime)
                          Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 20,
                            color: primary,
                          ),
                        if (sortType == SongListSortType.createTime)
                          const SizedBox(width: 8),
                        if (sortType == SongListSortType.createTime)
                          Icon(Icons.check, color: primary),
                      ],
                    ),
                    onTap: () {
                      if (sortType == SongListSortType.createTime) {
                        onApply(SongListSortType.createTime, !isAscending);
                      } else {
                        onApply(SongListSortType.createTime, true);
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.update, color: Colors.white),
                    title: Text(l10n.sortByUpdated),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sortType == SongListSortType.modifyTime)
                          Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 20,
                            color: primary,
                          ),
                        if (sortType == SongListSortType.modifyTime)
                          const SizedBox(width: 8),
                        if (sortType == SongListSortType.modifyTime)
                          Icon(Icons.check, color: primary),
                      ],
                    ),
                    onTap: () {
                      if (sortType == SongListSortType.modifyTime) {
                        onApply(SongListSortType.modifyTime, !isAscending);
                      } else {
                        onApply(SongListSortType.modifyTime, true);
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                  if (includeAddedToPlaylistOption) ...[
                    ListTile(
                      leading: const Icon(
                        Icons.playlist_add_check,
                        color: Colors.white,
                      ),
                      title: Text(l10n.sortByAddedToPlaylist),
                      subtitle: Text(l10n.sortByAddedToPlaylistSub),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sortType == SongListSortType.addedToPlaylist)
                            Icon(
                              isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 20,
                              color: primary,
                            ),
                          if (sortType == SongListSortType.addedToPlaylist)
                            const SizedBox(width: 8),
                          if (sortType == SongListSortType.addedToPlaylist)
                            Icon(Icons.check, color: primary),
                        ],
                      ),
                      onTap: () {
                        if (sortType == SongListSortType.addedToPlaylist) {
                          onApply(
                            SongListSortType.addedToPlaylist,
                            !isAscending,
                          );
                        } else {
                          onApply(SongListSortType.addedToPlaylist, true);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
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
