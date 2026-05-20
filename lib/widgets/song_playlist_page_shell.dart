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
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/widgets/scroll_aware_list_frame.dart';
import 'package:yeah_music/widgets/scroll_to_current_locate_layer.dart';

/// 本地曲库 / 用户歌单 / OneDrive 缓存等歌曲列表页共用：沉浸式 AppBar 时的顶部占位。
///
/// [extendBodyBehindAppBar] 下 Scaffold 会为 body 子树注入「padding.top == AppBar 高度」。
/// 必须在 Scaffold.body 的子结点 BuildContext（例如 [SongPlaylistBodyUnderlapColumn]
/// 或再包一层 [Builder]）上读取；若在 Consumer / Provider 的 builder 里直接用外层 context，
/// [MediaQuery.paddingOf] 往往只有系统安全区高度，列表会与标题栏重叠。
double songPlaylistUnderlapTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top;

/// 列表底部留白（MiniPlayer + 底部安全区）。
double songPlaylistListBottomPadding(BuildContext context) =>
    100 + MediaQuery.paddingOf(context).bottom;

/// 歌曲列表固定行高（与 [scheduleScrollListToCurrentSong]、[SongListScrollToCurrentLocate] 一致）。
const double kSongPlaylistRowExtent = 65;
const double kSongPlaylistRowExtentLinux = 70;

/// 默认歌曲行高在当前平台的有效值（Linux 适当放大以匹配字体度量）。
double effectiveSongPlaylistRowExtent([double itemExtent = kSongPlaylistRowExtent]) {
  if (defaultTargetPlatform == TargetPlatform.linux &&
      itemExtent == kSongPlaylistRowExtent) {
    return kSongPlaylistRowExtentLinux;
  }
  return itemExtent;
}

/// 主题背景 + Scaffold（extendBodyBehindAppBar）+ MiniPlayer；正文配合 [SongPlaylistBodyUnderlapColumn]。
class SongPlaylistThemedScaffold extends StatelessWidget {
  const SongPlaylistThemedScaffold({
    super.key,
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, theme, _) {
        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }
}

/// `Column([SizedBox(顶栏占位), Expanded(child)])`，避免列表第一行与 AppBar 重叠。
class SongPlaylistBodyUnderlapColumn extends StatelessWidget {
  const SongPlaylistBodyUnderlapColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: songPlaylistUnderlapTopInset(context)),
        Expanded(child: child),
      ],
    );
  }
}

typedef SongPlaylistIndexedRowBuilder =
    Widget Function(
      BuildContext context,
      Song song,
      int index,
      bool isCurrent,
    );

/// 固定行高歌曲列表：定位当前曲 + ScrollAwareListFrame + ListView。
///
/// [onRefresh] 非 null 时用 [RefreshIndicator] 包住 [ListView]（置于滚动条内侧），避免外层套刷新控件时出现顶部空白一行。
class SongPlaylistSongListView extends StatelessWidget {
  const SongPlaylistSongListView({
    super.key,
    required this.scrollController,
    required this.songs,
    required this.itemBuilder,
    this.itemExtent = kSongPlaylistRowExtent,
    this.cacheExtent = 280,
    this.physics,
    this.onRefresh,
    this.refreshIndicatorColor,
    this.refreshIndicatorBackgroundColor,
    this.listBottomInsetExtra = 0,
    /// [PlayListPage]：正在播来自其它列表（如歌单）时禁用「定位到当前」FAB，避免误滚乱序。
    this.locateFabOnlyWhenLibrarySession = false,
  });

  final ScrollController scrollController;
  final List<Song> songs;
  final SongPlaylistIndexedRowBuilder itemBuilder;
  final double itemExtent;
  final double cacheExtent;
  final ScrollPhysics? physics;

  /// 下拉刷新；与 [physics]（建议 [AlwaysScrollableScrollPhysics]）配合以便条目少时仍可下拉。
  final Future<void> Function()? onRefresh;

  final Color? refreshIndicatorColor;
  final Color? refreshIndicatorBackgroundColor;

  /// 附加列表底部留白（例如批量操作条盖住迷你播放器以上区域时上移列表）。
  final double listBottomInsetExtra;

  /// 为 true 时仅在全库会话下允许右下角定位到当前播（会话为歌单/最近等时按钮灰显）。
  final bool locateFabOnlyWhenLibrarySession;

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        songPlaylistListBottomPadding(context) + listBottomInsetExtra;
    final effectiveItemExtent = effectiveSongPlaylistRowExtent(itemExtent);
    final playList = context.read<PlayListProvider>();
    return Selector<PlayListProvider, String>(
      selector: (_, p) => normSongPath(p.currentSong?.path ?? ''),
      builder: (context, currentPathNorm, _) {
        Widget listCore = ListView.builder(
          controller: scrollController,
          physics: physics,
          itemExtent: effectiveItemExtent,
          cacheExtent: cacheExtent,
          padding: EdgeInsets.only(bottom: bottomPad),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isRowCurrent = currentPathNorm.isNotEmpty &&
                normSongPath(song.path) == currentPathNorm;
            return itemBuilder(context, song, index, isRowCurrent);
          },
        );

        if (onRefresh != null) {
          final light = Theme.of(context).brightness == Brightness.light;
          listCore = RefreshIndicator(
            onRefresh: onRefresh!,
            color: refreshIndicatorColor ??
                (light ? Theme.of(context).colorScheme.primary : Colors.white),
            backgroundColor: refreshIndicatorBackgroundColor ??
                (light
                    ? Colors.white
                    : Colors.black54),
            child: listCore,
          );
        }

        return SongListScrollToCurrentLocate(
          controller: scrollController,
          songs: songs,
          itemExtent: effectiveItemExtent,
          playList: playList,
          locateFabOnlyWhenLibrarySession: locateFabOnlyWhenLibrarySession,
          child: ScrollAwareListFrame(
            scrollController: scrollController,
            child: listCore,
          ),
        );
      },
    );
  }
}
