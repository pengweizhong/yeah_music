import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/widgets/playing_bars_indicator.dart';
import 'package:yeah_music/widgets/song_list_cover.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';

/// 与 [ListTile] 同信息密度、更省布局/语义开销，并配合 [ListView] 的 [itemExtent] 固定行高，利于长列表跟滑。
class CompactSongListRow extends StatelessWidget {
  const CompactSongListRow({
    super.key,
    required this.song,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isCurrent = false,
    this.showAddToPlaylist = true,
  });

  final Song song;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  /// 是否为当前正在播放（与 [PlayListProvider.currentSong] 对应行）
  final bool isCurrent;
  final bool showAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent ? primary.withValues(alpha: 0.14) : null,
              border: isCurrent
                  ? Border.all(color: primary.withValues(alpha: 0.35), width: 1)
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SongListCover(
                  song: song,
                  size: 48,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? primary : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent
                              ? primary.withValues(alpha: 0.82)
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ListRowPlayingIndicator(color: primary),
                if (isCurrent && showAddToPlaylist) const SizedBox(width: 2),
                if (showAddToPlaylist)
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white70),
                    tooltip: l10n.tooltipAddToPlaylist,
                    onPressed: () => showAddToUserPlaylistsSheet(context, song),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
