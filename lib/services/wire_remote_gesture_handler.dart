import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/playback_shortcut_controller.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';
import 'package:yeah_music/platform/wire_remote_native.dart';
import 'package:yeah_music/services/music_service.dart';

/// 处理 Android 前台线控连击（由原生 [WireRemoteHolder] 经 MethodChannel 触发）。
class WireRemoteGestureHandler {
  WireRemoteGestureHandler._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    WireRemoteNative.attachHeadsetGestureHandler(_onHeadsetGesture);
  }

  static Future<void> syncNativeFromController(
    PlaybackShortcutController controller,
  ) {
    return WireRemoteNative.configure(controller.wireRemote);
  }

  static Future<void> _onHeadsetGesture(int clickCount) async {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final ctrl = Provider.of<PlaybackShortcutController>(ctx, listen: false);
    final cfg = ctrl.wireRemote;
    if (!cfg.enabled) return;
    final action = cfg.actionForClickCount(clickCount);
    await _dispatch(ctx, action);
  }

  static Future<void> _dispatch(
    BuildContext context,
    WireRemoteControlAction action,
  ) async {
    switch (action) {
      case WireRemoteControlAction.none:
        return;
      case WireRemoteControlAction.playPause:
        final play = Provider.of<PlayListProvider>(context, listen: false);
        if (!play.initialized ||
            play.playList.isEmpty ||
            play.currentSong == null) {
          return;
        }
        if (MusicService.isPlaying) {
          await MusicService().pause();
        } else {
          if (!MusicService.canUseResumeToPlay) {
            await play.playAt(play.currentIndex);
          } else {
            MusicService().resume();
          }
        }
      case WireRemoteControlAction.next:
        final play = Provider.of<PlayListProvider>(context, listen: false);
        if (!play.initialized || play.playList.isEmpty) return;
        await play.playNext();
      case WireRemoteControlAction.previous:
        final play = Provider.of<PlayListProvider>(context, listen: false);
        if (!play.initialized || play.playList.isEmpty) return;
        await play.playPrev();
    }
  }
}
