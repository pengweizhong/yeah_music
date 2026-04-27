import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
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
    this.showAddToPlaylist = true,
  });

  final Song song;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showAddToPlaylist)
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white70),
                    tooltip: '加入歌单',
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
