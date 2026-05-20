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

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';

/// 右下「定位到当前」按钮（与 [FrostedGlassPanel] 同系毛玻璃圆钮；歌词、列表共用）
class ScrollLocateToCurrentActionButton extends StatelessWidget {
  const ScrollLocateToCurrentActionButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  /// 为 null 时在 [onPressed] 非空时使用 [AppLocalizations.locateToCurrentPlaying]。
  final String? tooltip;

  static const double _diameter = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tip = onPressed == null
        ? l10n.locateNotInList
        : (tooltip ?? l10n.locateToCurrentPlaying);
    final iconColor = onPressed == null
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.white;

    Widget button = ClipRRect(
      borderRadius: BorderRadius.circular(_diameter / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x38FFFFFF),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(Icons.my_location, size: 22, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );

    button = Tooltip(message: tip, child: button);
    if (onPressed == null) {
      button = Opacity(opacity: 0.85, child: button);
    }
    return button;
  }
}

/// 列表/歌词在「用户手动滑走」后显示右下角定位按钮，2 秒无用户滚动后自动隐藏
/// 逻辑一致。歌词页使用 [onManualScroll] + [isManual] 与播放页 [SongPage] 的跟唱/暂停
/// 跟读共享状态；各歌曲列表使用内置定时器，仅需 [onLocate] 与 [canLocate]。
class ScrollToCurrentLocateLayer extends StatefulWidget {
  const ScrollToCurrentLocateLayer({
    super.key,
    required this.child,
    required this.canLocate,
    required this.onLocate,
    this.tooltip,
    this.onManualScroll,
    this.isManual,
    this.resetToken,
    /// 歌曲列表：监听器轴偏移，覆盖滚轮/触控板/拖拽（不依赖不稳定的 Notification）。
    /// 与 [onManualScroll] 互斥；歌词页不填，仍用 [ScrollNotification]。
    this.userActivityListScrollController,
    /// 为 true 时（与 [userActivityListScrollController] 同用）：
    /// 只要手滑就显示定位钮；[canLocate] 仅表示「可滚动到当前」用于按钮可点
    this.showOnManualListScrollAlone = false,
    /// 为 true 时歌曲列表也始终显示（调试）；一般保持 false 以手滑后显示、5s 无操作隐藏
    this.forceShowLocateFab = false,
  });

  final Widget child;

  /// 是否展示定位按钮的「可执行」条件（列表：当前歌在列表中；歌词：有当前行等）
  final bool canLocate;
  final VoidCallback onLocate;
  final String? tooltip;

  /// 非 null 时为**外接模式**（与歌词页 [SongPage] 一致）：
  /// [UserScrollNotification] 时调用；[isManual] 为父级维护的手动滚动状态
  final VoidCallback? onManualScroll;
  final bool? isManual;

  /// 仅**内置模式**下：变化时清除手动态与定时器（如当前曲目 path 变化）
  final Object? resetToken;
  final ScrollController? userActivityListScrollController;
  final bool showOnManualListScrollAlone;
  final bool forceShowLocateFab;

  @override
  State<ScrollToCurrentLocateLayer> createState() {
    return _ScrollToCurrentLocateLayerState();
  }
}

class _ScrollToCurrentLocateLayerState extends State<ScrollToCurrentLocateLayer> {
  bool _internalManual = false;
  Timer? _timer;
  ScrollController? _subscribedListScroll;

  bool get _external => widget.onManualScroll != null;

  bool get _showFab {
    if (widget.forceShowLocateFab &&
        widget.userActivityListScrollController != null) {
      return true;
    }
    if (_external) {
      return (widget.isManual ?? false) && widget.canLocate;
    }
    if (widget.showOnManualListScrollAlone) {
      return _internalManual;
    }
    return _internalManual && widget.canLocate;
  }

  void _onUserScrollNotification() {
    if (_external) {
      widget.onManualScroll!();
    } else {
      if (mounted) {
        setState(() => _internalManual = true);
      } else {
        _internalManual = true;
      }
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _internalManual = false);
        } else {
          _internalManual = false;
        }
      });
    }
  }

  void _resetInternal() {
    _timer?.cancel();
    if (mounted) {
      setState(() => _internalManual = false);
    } else {
      _internalManual = false;
    }
  }

  @override
  void didUpdateWidget(covariant ScrollToCurrentLocateLayer old) {
    super.didUpdateWidget(old);
    if (widget.userActivityListScrollController !=
        old.userActivityListScrollController) {
      _attachListScrollListener();
    }
    if (!_external && widget.resetToken != old.resetToken) {
      _resetInternal();
    }
  }

  @override
  void initState() {
    super.initState();
    _attachListScrollListener();
  }

  void _attachListScrollListener() {
    if (_subscribedListScroll == widget.userActivityListScrollController) {
      return;
    }
    if (_subscribedListScroll != null) {
      _subscribedListScroll!.removeListener(_onListControllerActivity);
    }
    _subscribedListScroll = widget.userActivityListScrollController;
    _subscribedListScroll?.addListener(_onListControllerActivity);
  }

  void _onListControllerActivity() {
    if (!mounted) return;
    if (_external) return;
    final c = widget.userActivityListScrollController;
    if (c == null) return;
    if (!c.hasClients) return;
    if (isListScrollFromProgrammaticJump(c)) {
      return;
    }
    _onUserScrollNotification();
  }

  @override
  void dispose() {
    if (_subscribedListScroll != null) {
      _subscribedListScroll!.removeListener(_onListControllerActivity);
    }
    _timer?.cancel();
    super.dispose();
  }

  /// [UserScrollNotification] 主要覆盖触屏/拖拽；鼠标滚轮、触控板用 [PointerScrollEvent]；滚动条拖动用 [ScrollStartNotification.dragDetails]
  bool _scrollNotificationSuggestsUserDrag(ScrollNotification n) {
    if (n is UserScrollNotification) return true;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasListScroll = widget.userActivityListScrollController != null;
    final scrollHost = hasListScroll
        ? widget.child
        : Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onUserScrollNotification();
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (_scrollNotificationSuggestsUserDrag(notification)) {
                  _onUserScrollNotification();
                }
                return false;
              },
              child: widget.child,
            ),
          );
    // [extendBody] 下列表 body 会延伸到迷你条下方；与行尾「加入歌单」错开；再下移约 0.8cm（~48dp）
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const locateFabDownApprox08cm = 70.0;
    //距屏幕右边
    final fabBottom = widget.userActivityListScrollController != null
        ? 4.0 + MiniPlayer.barHeight + safeBottom - locateFabDownApprox08cm
        : 16.0;
    //距底边；
    final fabRight = widget.userActivityListScrollController != null
        ? 48.0 // 列表场景：想往左移就改成 80、90…；想往右移就改成 60、50…
        : 10.0; // 歌词等非列表：同理加减
    // 非 Positioned 子项在 Stack 中不会自动展开到父约束；未铺满时 Scrollbar 轨道会缩成
    // 小块（看似「钉在右上」）且滑块无法拖动。必须填满再叠定位钮。
    return Stack(
      children: [
        Positioned.fill(child: scrollHost),
        if (_showFab)
          Positioned(
            right: fabRight,
            bottom: fabBottom,
            child: ScrollLocateToCurrentActionButton(
              onPressed: (widget.showOnManualListScrollAlone
                      ? widget.canLocate
                      : true)
                  ? () {
                      if (!_external) {
                        _resetInternal();
                      }
                      widget.onLocate();
                    }
                  : null,
              tooltip: widget.tooltip,
            ),
          ),
      ],
    );
  }
}

/// 与 [PlayListProvider]、[itemExtent] 与当前列表 [songs] 搭配使用的便捷封装
class SongListScrollToCurrentLocate extends StatelessWidget {
  const SongListScrollToCurrentLocate({
    super.key,
    required this.child,
    required this.controller,
    required this.songs,
    required this.itemExtent,
    required this.playList,
    this.tooltip,
    this.forceShowLocateFab = false,
    this.locateFabOnlyWhenLibrarySession = false,
  });

  final Widget child;
  final ScrollController controller;
  final List<Song> songs;
  final double itemExtent;
  final PlayListProvider playList;
  final String? tooltip;
  final bool forceShowLocateFab;

  /// 为 true（仅曲库列表）时：[canLocate] 还要求当前播放会话为全库。
  final bool locateFabOnlyWhenLibrarySession;

  @override
  Widget build(BuildContext context) {
    final inList = isCurrentSongInDisplayList(playList, songs);
    final canLocate = inList &&
        (!locateFabOnlyWhenLibrarySession ||
            playList.playbackSessionIsLibrary);
    return ScrollToCurrentLocateLayer(
      onManualScroll: null,
      isManual: null,
      userActivityListScrollController: controller,
      showOnManualListScrollAlone: true,
      forceShowLocateFab: forceShowLocateFab,
      canLocate: canLocate,
      resetToken: playList.currentSong?.path,
      tooltip: tooltip,
      onLocate: () {
        if (!inList) return;
        scheduleScrollListToCurrentSong(
          context: context,
          controller: controller,
          songs: songs,
          itemExtent: itemExtent,
          playList: playList,
          forceAlign: true,
        );
      },
      child: child,
    );
  }
}
