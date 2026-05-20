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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/services/linux_taskbar_progress.dart';
import 'package:yeah_music/services/music_service.dart';

/// Linux 桌面：把当前播放进度同步到任务栏图标覆盖层（KDE/Plasma）。
class LinuxTaskbarProgressHost extends StatefulWidget {
  const LinuxTaskbarProgressHost({super.key, required this.child});

  final Widget child;

  @override
  State<LinuxTaskbarProgressHost> createState() =>
      _LinuxTaskbarProgressHostState();
}

class _LinuxTaskbarProgressHostState extends State<LinuxTaskbarProgressHost> {
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<bool>? _playingSub;
  bool _attached = false;
  double _lastSent = -1;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_attachAsync());
      });
    }
  }

  Future<void> _attachAsync() async {
    if (!mounted || _attached) return;
    _attached = true;
    final playList = context.read<PlayListProvider>();
    playList.addListener(_onPlaylistChanged);
    _posSub = MusicService.positionStream.listen((_) => _pushProgressMaybe());
    _durSub = MusicService.durationStream.listen((_) => _pushProgressMaybe());
    _playingSub = MusicService.playingStream.listen((_) => _pushProgressMaybe());
    await _pushProgressMaybe(force: true);
  }

  void _onPlaylistChanged() {
    unawaited(_pushProgressMaybe(force: true));
  }

  Future<void> _pushProgressMaybe({bool force = false}) async {
    if (!mounted || !LinuxTaskbarProgress.supported) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastSentAt).inMilliseconds < 120) {
      return;
    }
    final playList = context.read<PlayListProvider>();
    final song = playList.currentSong;
    final dur = MusicService.duration;
    if (song == null || dur == null || dur <= Duration.zero) {
      _lastSent = -1;
      _lastSentAt = now;
      await LinuxTaskbarProgress.clear();
      return;
    }
    final pos = MusicService.lastPosition;
    final p = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    if (!force && _lastSent >= 0 && (p - _lastSent).abs() < 0.004) return;
    _lastSent = p;
    _lastSentAt = now;
    await LinuxTaskbarProgress.setProgress(progress: p, visible: true);
  }

  @override
  void dispose() {
    if (_attached) {
      try {
        context.read<PlayListProvider>().removeListener(_onPlaylistChanged);
      } catch (_) {}
      unawaited(LinuxTaskbarProgress.clear());
    }
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
