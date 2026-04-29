import 'package:flutter/material.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

// region 列表「自动滚到当前」与定位按钮：忽略 jumpTo 后短时内的 offset 通知（含惯性）
final Map<ScrollController, DateTime> _listProgrammaticJumpAt = {};
const _kProgrammaticJumpIgnore = Duration(milliseconds: 220);

/// [scheduleScrollListToCurrentSong] 的 [ScrollController.jumpTo] 为程序触发；
/// 用时间窗忽略（避免与 ref-count+postFrame 解耦失败导致**永久锁死**、按钮永远不出现）
bool isListScrollFromProgrammaticJump(ScrollController c) {
  final t = _listProgrammaticJumpAt[c];
  if (t == null) return false;
  if (DateTime.now().difference(t) > _kProgrammaticJumpIgnore) {
    _listProgrammaticJumpAt.remove(c);
    return false;
  }
  return true;
}

void _markListProgrammaticJump(ScrollController c) {
  _listProgrammaticJumpAt[c] = DateTime.now();
}
// endregion

int _indexOfCurrentInSongs(List<Song> songs, String currentPath) {
  if (currentPath.isEmpty) return -1;
  final key = normSongPath(currentPath);
  for (var i = 0; i < songs.length; i++) {
    if (normSongPath(songs[i].path) == key) return i;
  }
  return -1;
}

/// 当前播放曲目是否出现在 [songs] 中（用于「定位到当前播放」是否可点）
bool isCurrentSongInDisplayList(PlayListProvider playList, List<Song> songs) {
  final c = playList.currentSong;
  if (c == null) return false;
  return _indexOfCurrentInSongs(songs, c.path) >= 0;
}

/// 在 [ListView]（固定 [itemExtent]）中滚到当前播放行；多帧重试直到 [ScrollController.hasClients]，
/// 避免首屏 [ListView] 尚未挂接时静默失败。
///
/// [onScrollApplied] 仅在「执行过对齐滚动」「当前行已在视窗内故跳过滚动」或（启用
/// [scrollToTopWhenCurrentMissingFromList] 且曲目不在列表时）滚至顶部后调用；若多帧后仍无
/// [ScrollController] 挂接或无当前歌，则改调 [onScrollFailed]（若提供）。
///
/// [forceAlign] 为 `true` 时（如用户点「定位到当前」）始终按 [alignBias] 对齐；为 `false` 时（切歌、
/// 进入页面等自动行为）若当前行已完整落在可见视窗内则**不** [jumpTo]，避免点击已可见行播放时的「瞬移」感。
///
/// [scrollToTopWhenCurrentMissingFromList] 为 `true` 时：当前播放曲目不在 [songs] 中时仍视为「已处理」，
/// 将列表 [jumpTo] 到顶部并调用 [onScrollApplied]（与成功对齐时相同），便于进入歌单页时从头展示。
void scheduleScrollListToCurrentSong({
  required BuildContext context,
  required ScrollController controller,
  required List<Song> songs,
  required double itemExtent,
  required PlayListProvider playList,
  double alignBias = 0.22,
  int maxFrames = 16,
  /// 为 `true` 时无视「已在屏幕内」判断，始终滚动到对齐位置（手动定位按钮）。
  bool forceAlign = false,
  bool scrollToTopWhenCurrentMissingFromList = false,
  void Function(String appliedPathNorm)? onScrollApplied,
  VoidCallback? onScrollFailed,
}) {
  var frames = 0;
  var didComplete = false;

  void tryScroll() {
    if (!context.mounted) {
      if (!didComplete) {
        didComplete = true;
        onScrollFailed?.call();
      }
      return;
    }
    if (didComplete) return;
    frames++;
    if (!controller.hasClients) {
      if (frames < maxFrames) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryScroll());
      } else {
        didComplete = true;
        onScrollFailed?.call();
      }
      return;
    }
    final current = playList.currentSong;
    if (current == null) {
      didComplete = true;
      onScrollFailed?.call();
      return;
    }
    final i = _indexOfCurrentInSongs(songs, current.path);
    if (i < 0) {
      if (scrollToTopWhenCurrentMissingFromList) {
        var topFrames = 0;
        void tryJumpTop() {
          if (!context.mounted) {
            didComplete = true;
            onScrollFailed?.call();
            return;
          }
          topFrames++;
          if (!controller.hasClients) {
            if (topFrames < maxFrames) {
              WidgetsBinding.instance.addPostFrameCallback((_) => tryJumpTop());
            } else {
              didComplete = true;
              onScrollFailed?.call();
            }
            return;
          }
          _markListProgrammaticJump(controller);
          controller.jumpTo(0);
          didComplete = true;
          onScrollApplied?.call(normSongPath(current.path));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => tryJumpTop());
      } else {
        didComplete = true;
        onScrollFailed?.call();
      }
      return;
    }
    final pos = controller.position;
    final rowTop = i * itemExtent;
    final viewH = pos.viewportDimension;
    final rowBottom = rowTop + itemExtent;
    final viewTop = pos.pixels;
    final viewBottom = pos.pixels + viewH;
    const tol = 1.0;

    if (!forceAlign &&
        rowTop >= viewTop - tol &&
        rowBottom <= viewBottom + tol) {
      didComplete = true;
      onScrollApplied?.call(normSongPath(current.path));
      return;
    }

    final target =
        (rowTop - viewH * alignBias).clamp(0.0, pos.maxScrollExtent);
    _markListProgrammaticJump(controller);
    controller.jumpTo(target);
    didComplete = true;
    onScrollApplied?.call(normSongPath(current.path));
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => tryScroll());
}
