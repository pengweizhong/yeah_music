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
import 'package:flutter/foundation.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/widgets/song_audio_quality_badge.dart';
import 'package:yeah_music/widgets/playing_bars_indicator.dart';
import 'package:yeah_music/widgets/song_list_cover.dart';
import 'package:yeah_music/widgets/song_list_marquee_when_current_line.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';

/// 与 [ListTile] 同信息密度、更省布局/语义开销，并配合 [ListView] 的 [itemExtent] 固定行高，利于长列表跟滑。
class CompactSongListRow extends StatefulWidget {
  const CompactSongListRow({
    super.key,
    required this.song,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.isCurrent = false,
    this.showAddToPlaylist = true,
    this.onMoreMenuTap,
    /// 非空时副标题为「艺人·专辑」与累计播放次数（与首页「最多播放」一致）。
    this.trailingPlayCount,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionTap,
  });

  final Song song;
  /// 轻量扫描或缺省时用作主标题占位（与 [song.title] 二选一）。
  final String title;
  /// 副标题占位；补全后以 [songListSecondaryLine] 为准。
  final String subtitle;
  final VoidCallback onTap;
  /// 非选择模式下长按（如曲库多选）。
  final VoidCallback? onLongPress;
  /// 是否为当前正在播放（与 [PlayListProvider.currentSong] 对应行）
  final bool isCurrent;
  final bool showAddToPlaylist;
  /// 若提供则在尾部显示「更多」菜单，且**不再**显示加入歌单按钮（与 [showAddToPlaylist] 二选一优先）。
  final VoidCallback? onMoreMenuTap;
  final int? trailingPlayCount;
  /// 批量选曲：显示勾选并改 [onTap] 为勾选切换（通过 [onSelectionTap]）。
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionTap;

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
    if (!mounted || info.visibleFraction < 0.12) return;
    _hydrateAfterLayout();
  }

  Future<bool>? _ongoingHydrate;

  void _hydrateAfterLayout() {
    if (!mounted) return;
    final song = widget.song;
    if (song.playlistEntryMissingOnDevice) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final Color resolvedTitleColor;
    if (widget.song.playlistEntryMissingOnDevice) {
      resolvedTitleColor = scheme.error;
    } else if (widget.isCurrent) {
      resolvedTitleColor = primary;
    } else {
      resolvedTitleColor = context.gradFg();
    }
    final subtitleColor = widget.isCurrent
        ? primary.withValues(alpha: 0.82)
        : context.gradFgMuted();
    final trailingIconColor = context.gradFg(0.72);
    final isLinuxDesktop = defaultTargetPlatform == TargetPlatform.linux;
    final titleStr = _effectiveTitle();
    return VisibilityDetector(
      key: ValueKey<String>('list_row_vis_${widget.song.path}'),
      onVisibilityChanged: _onListRowVisibilityChanged,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.selectionMode
                ? (widget.onSelectionTap ?? widget.onTap)
                : widget.onTap,
            onLongPress:
                widget.selectionMode ? null : widget.onLongPress,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isCurrent
                    ? primary.withValues(alpha: isLinuxDesktop ? 0.11 : 0.14)
                    : widget.selectionMode && widget.isSelected
                        ? primary.withValues(alpha: 0.12)
                        : null,
                border: widget.isCurrent
                    ? (isLinuxDesktop
                        ? Border(
                            left: BorderSide(
                              color: primary.withValues(alpha: 0.60),
                              width: 2,
                            ),
                          )
                        : Border.all(
                            color: primary.withValues(alpha: 0.35),
                            width: 1,
                          ))
                    : widget.selectionMode && widget.isSelected
                        ? Border.all(
                            color: primary.withValues(alpha: 0.45),
                            width: 1,
                          )
                        : null,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.selectionMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        widget.isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: widget.isSelected ? primary : context.gradFg(0.38),
                        size: 26,
                      ),
                    ),
                  ],
                  SongListCover(
                    song: widget.song,
                    size: 48,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SongListMarqueeWhenCurrentLine(
                          text: titleStr,
                          style: TextStyle(
                            color: resolvedTitleColor,
                            fontSize: 16,
                            height: isLinuxDesktop ? 1.04 : null,
                            fontWeight: widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          isCurrentTrack: widget.isCurrent,
                        ),
                        SizedBox(height: isLinuxDesktop ? 1 : 2),
                        widget.trailingPlayCount != null
                            ? SongListSubtitleWithQualityMarqueePlayCount(
                                song: widget.song,
                                textStyle: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                  height: isLinuxDesktop ? 1.0 : null,
                                ),
                                playCount: widget.trailingPlayCount!,
                                l10n: l10n,
                                isCurrentTrack: widget.isCurrent,
                              )
                            : SongListSubtitleWithQualityRow(
                                song: widget.song,
                                fallbackSubtitle: widget.subtitle,
                                compactBadge: false,
                                textStyle: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                  height: isLinuxDesktop ? 1.0 : null,
                                ),
                                isCurrentTrack: widget.isCurrent,
                              ),
                      ],
                    ),
                  ),
                  if (widget.isCurrent) ListRowPlayingIndicator(color: primary),
                  if (!widget.selectionMode &&
                      widget.isCurrent &&
                      (widget.onMoreMenuTap != null || widget.showAddToPlaylist))
                    const SizedBox(width: 2),
                  if (!widget.selectionMode &&
                      widget.onMoreMenuTap != null)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: trailingIconColor),
                      tooltip: l10n.tooltipMoreActions,
                      onPressed: widget.onMoreMenuTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    )
                  else if (!widget.selectionMode && widget.showAddToPlaylist)
                    IconButton(
                      icon: Icon(Icons.playlist_add, color: trailingIconColor),
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
