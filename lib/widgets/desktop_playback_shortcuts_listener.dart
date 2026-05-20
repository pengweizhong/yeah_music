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
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/playback_shortcut_controller.dart';
import 'package:yeah_music/services/music_service.dart';

/// 桌面端全局键盘：播放/暂停、上/下一曲（读 [PlaybackShortcutController.config]）。
class DesktopPlaybackShortcutsListener extends StatefulWidget {
  const DesktopPlaybackShortcutsListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final PlaybackShortcutController controller;
  final Widget child;

  @override
  State<DesktopPlaybackShortcutsListener> createState() =>
      _DesktopPlaybackShortcutsListenerState();
}

class _DesktopPlaybackShortcutsListenerState
    extends State<DesktopPlaybackShortcutsListener> {
  static bool get _desktop =>
      !kIsWeb &&
      (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    if (_desktop) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void dispose() {
    if (_desktop) {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_shouldDeferForTextField(event.logicalKey)) return false;

    final cfg = widget.controller.config;
    if (cfg.playPause.triggers(event)) {
      unawaited(_togglePlayPause());
      return true;
    }
    if (cfg.previous.triggers(event)) {
      unawaited(_playPrev());
      return true;
    }
    if (cfg.next.triggers(event)) {
      unawaited(_playNext());
      return true;
    }
    return false;
  }

  /// 媒体键不往输入框里打字；其它键在输入框聚焦时不抢事件。
  bool _shouldDeferForTextField(LogicalKeyboardKey key) {
    if (_isDedicatedMediaKey(key)) return false;
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || !primary.hasFocus) return false;
    final ctx = primary.context;
    if (ctx == null) return false;
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  bool _isDedicatedMediaKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious;
  }

  Future<void> _togglePlayPause() async {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final play = Provider.of<PlayListProvider>(ctx, listen: false);
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
  }

  Future<void> _playNext() async {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final play = Provider.of<PlayListProvider>(ctx, listen: false);
    if (!play.initialized || play.playList.isEmpty) return;
    await play.playNext();
  }

  Future<void> _playPrev() async {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final play = Provider.of<PlayListProvider>(ctx, listen: false);
    if (!play.initialized || play.playList.isEmpty) return;
    await play.playPrev();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
