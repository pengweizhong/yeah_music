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

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide MenuItem;
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';

/// Linux/KDE 托盘入口：设置图标并提供播放控制右键菜单。
class LinuxTrayHost extends StatefulWidget {
  const LinuxTrayHost({super.key, required this.child});

  final Widget child;

  @override
  State<LinuxTrayHost> createState() => _LinuxTrayHostState();
}

class _LinuxTrayHostState extends State<LinuxTrayHost> with TrayListener {
  static const String _kIconPath = 'assets/icons/yeah_music1.png';
  static const String _kMenuShowHideWindow = 'show_hide_window';
  static const String _kMenuPlayPause = 'play_pause';
  static const String _kMenuPrevious = 'previous';
  static const String _kMenuNext = 'next';
  static const String _kMenuQuit = 'quit';

  StreamSubscription<bool>? _playingSub;
  bool _attached = false;
  bool _windowVisible = true;
  Locale? _lastLocale;
  WindowController? _windowController;

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
    trayManager.addListener(this);
    _attached = true;

    try {
      _windowController = await WindowController.fromCurrentEngine();
    } catch (_) {}

    await trayManager.setIcon(_kIconPath);
    // tray_manager 在 Linux 端未实现 setToolTip，调用会抛 MissingPluginException。
    if (!Platform.isLinux) {
      try {
        await trayManager.setToolTip('Yeah Music');
      } catch (_) {}
    }

    _playingSub = MusicService.playingStream.listen((_) {
      if (!mounted) return;
      unawaited(_refreshMenu());
    });

    final playList = context.read<PlayListProvider>();
    playList.addListener(_onPlaylistChanged);
    await _refreshMenu();
  }

  void _onPlaylistChanged() {
    if (!mounted) return;
    unawaited(_refreshMenu());
  }

  Future<void> _refreshMenu() async {
    if (!mounted || !_attached) return;
    final l10n = AppLocalizations.of(context);
    final playList = context.read<PlayListProvider>();
    final song = playList.currentSong;
    final isPlaying = MusicService.isPlaying;
    final menu = Menu(
      items: [
        MenuItem(label: _trackTitle(song, l10n), disabled: true),
        MenuItem(label: _trackArtist(song, l10n), disabled: true),
        MenuItem.separator(),
        MenuItem(
          key: _kMenuPlayPause,
          label: isPlaying
              ? (l10n.menuBarContextPause)
              : (l10n.menuBarContextPlay),
        ),
        MenuItem(key: _kMenuPrevious, label: l10n.menuBarContextPrevious),
        MenuItem(key: _kMenuNext, label: l10n.menuBarContextNext),
        MenuItem.separator(),
        MenuItem(
          key: _kMenuShowHideWindow,
          label: _windowVisible ? _hideLabel(l10n) : _showLabel(l10n),
        ),
        MenuItem.separator(),
        MenuItem(key: _kMenuQuit, label: _quitLabel(l10n)),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  String _showLabel(AppLocalizations l10n) =>
      _isChinese(context) ? '显示窗口' : 'Show Window';

  String _hideLabel(AppLocalizations l10n) =>
      _isChinese(context) ? '隐藏窗口' : 'Hide Window';

  String _quitLabel(AppLocalizations l10n) =>
      _isChinese(context) ? '退出应用' : 'Quit';

  bool _isChinese(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('zh');

  String _trackTitle(Song? song, AppLocalizations l10n) {
    if (song == null) return l10n.menuBarLyricsIdle;
    final t = song.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return l10n.menuBarLyricsIdle;
  }

  String _trackArtist(Song? song, AppLocalizations l10n) {
    if (song == null) return l10n.homeUnknownTitle;
    final a = song.artist?.trim();
    if (a != null && a.isNotEmpty) return a;
    return l10n.homeUnknownTitle;
  }

  Future<void> _toggleWindowVisible() async {
    final c = _windowController;
    if (c == null) return;
    try {
      if (_windowVisible) {
        await c.hide();
      } else {
        await c.show();
      }
      _windowVisible = !_windowVisible;
      await _refreshMenu();
    } catch (_) {}
  }

  Future<void> _quitApp() async {
    try {
      await trayManager.destroy();
    } catch (_) {}
    exit(0);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final playList = context.read<PlayListProvider>();
    switch (menuItem.key) {
      case _kMenuPlayPause:
        if (MusicService.isPlaying) {
          unawaited(MusicService().pause());
        } else if (!MusicService.canUseResumeToPlay) {
          unawaited(playList.playAt(playList.currentIndex));
        } else {
          MusicService().resume();
        }
        break;
      case _kMenuPrevious:
        unawaited(playList.playPrev());
        break;
      case _kMenuNext:
        unawaited(playList.playNext());
        break;
      case _kMenuShowHideWindow:
        unawaited(_toggleWindowVisible());
        break;
      case _kMenuQuit:
        unawaited(_quitApp());
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb && Platform.isLinux && _attached) {
      final locale = Localizations.localeOf(context);
      if (_lastLocale != locale) {
        _lastLocale = locale;
        unawaited(_refreshMenu());
      }
    }
  }

  @override
  void dispose() {
    if (_attached) {
      try {
        context.read<PlayListProvider>().removeListener(_onPlaylistChanged);
      } catch (_) {}
      trayManager.removeListener(this);
      unawaited(trayManager.destroy());
    }
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
