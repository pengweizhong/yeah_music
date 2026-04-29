import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/widgets/playing_bars_indicator.dart';
import 'package:yeah_music/widgets/song_list_cover.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';

/// 与 [ListTile] 同信息密度、更省布局/语义开销，并配合 [ListView] 的 [itemExtent] 固定行高，利于长列表跟滑。
class CompactSongListRow extends StatefulWidget {
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
  /// 轻量扫描或缺省时用作主标题占位（与 [song.title] 二选一）。
  final String title;
  /// 副标题占位；补全后以 [songListSecondaryLine] 为准。
  final String subtitle;
  final VoidCallback onTap;
  /// 是否为当前正在播放（与 [PlayListProvider.currentSong] 对应行）
  final bool isCurrent;
  final bool showAddToPlaylist;

  @override
  State<CompactSongListRow> createState() => _CompactSongListRowState();
}

class _CompactSongListRowState extends State<CompactSongListRow> {
  @override
  void initState() {
    super.initState();
    // 兜底：visibility 首帧偶有 0，仍尝试补全首屏条目
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateAfterLayout());
  }

  @override
  void didUpdateWidget(CompactSongListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _hydrateAfterLayout());
    }
  }

  /// 滑动进入可视区域时再拉元数据：避免离屏条目抢 IO，离开后再次划入可重试失败的解析。
  void _onListRowVisibilityChanged(VisibilityInfo info) {
    if (!mounted || info.visibleFraction < 0.06) return;
    _hydrateAfterLayout();
  }

  Future<bool>? _ongoingHydrate;

  void _hydrateAfterLayout() {
    if (!mounted) return;
    final song = widget.song;
    final fut = _ongoingHydrate ??=
        SongLibraryMetadataHydrator.hydrateIfNeeded(song).whenComplete(() {
      _ongoingHydrate = null;
    });
    fut.then((changed) {
      if (!mounted || !changed) return;
      setState(() {});
    });
  }

  String _effectiveTitle() {
    final t = widget.song.title;
    if (t != null && t.trim().isNotEmpty) return t;
    return widget.title;
  }

  String _effectiveSubtitle() {
    final line = songListSecondaryLine(widget.song);
    if (line.trim().isNotEmpty) return line;
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final titleStr = _effectiveTitle();
    final subtitleStr = _effectiveSubtitle();
    return VisibilityDetector(
      key: ValueKey<String>('list_row_vis_${widget.song.path}'),
      onVisibilityChanged: _onListRowVisibilityChanged,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isCurrent
                    ? primary.withValues(alpha: 0.14)
                    : null,
                border: widget.isCurrent
                    ? Border.all(
                        color: primary.withValues(alpha: 0.35),
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SongListCover(
                    song: widget.song,
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
                          titleStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.isCurrent ? primary : Colors.white,
                            fontSize: 16,
                            fontWeight: widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.isCurrent
                                ? primary.withValues(alpha: 0.82)
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isCurrent) ListRowPlayingIndicator(color: primary),
                  if (widget.isCurrent && widget.showAddToPlaylist)
                    const SizedBox(width: 2),
                  if (widget.showAddToPlaylist)
                    IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white70),
                      tooltip: l10n.tooltipAddToPlaylist,
                      onPressed: () =>
                          showAddToUserPlaylistsSheet(context, widget.song),
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
      ),
    );
  }
}
