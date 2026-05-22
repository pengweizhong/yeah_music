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
import 'package:window_manager/window_manager.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/platform/desktop_tray_icon.dart';
import 'package:yeah_music/platform/linux_desktop_quit.dart';
import 'package:yeah_music/platform/tray_menu_material_icon.dart';
import 'package:yeah_music/services/music_service.dart';

/// Linux / Windows 系统托盘：图标、播放控制右键菜单、关闭主窗口时有序退出。
class LinuxTrayHost extends StatefulWidget {
  const LinuxTrayHost({super.key, required this.child});

  final Widget child;

  @override
  State<LinuxTrayHost> createState() => _LinuxTrayHostState();
}

class _LinuxTrayHostState extends State<LinuxTrayHost>
    with TrayListener, WindowListener {
  static const String _kLinuxIconPath = 'assets/icons/yeah_music1.png';
  static const String _kWindowsIconPath = 'assets/icons/yeah_music_tray.ico';

  static bool get _traySupported =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows);

  String get _iconPath =>
      Platform.isWindows ? _kWindowsIconPath : _kLinuxIconPath;

  final Map<int, String> _menuIconPathCache = {};
  static const String _kMenuShowHideWindow = 'show_hide_window';
  static const String _kMenuPlayPause = 'play_pause';
  static const String _kMenuPrevious = 'previous';
  static const String _kMenuNext = 'next';
  static const String _kMenuQuit = 'quit';

  /// Win32 托盘用 WM_COMMAND 整型 id；刷新菜单时 id 必须稳定，否则点击会错位。
  static const int _idTrackTitle = 10801;
  static const int _idTrackArtist = 10802;
  static const int _idSep1 = 10901;
  static const int _idSep2 = 10902;
  static const int _idSep3 = 10903;
  static const int _idPlayPause = 11001;
  static const int _idPrevious = 11002;
  static const int _idNext = 11003;
  static const int _idShowHide = 11004;
  static const int _idQuit = 11005;

  StreamSubscription<bool>? _playingSub;
  bool _attached = false;
  bool _windowManagerHooked = false;
  bool _windowVisible = true;
  Locale? _lastLocale;
  WindowController? _windowController;

  @override
  void initState() {
    super.initState();
    if (_traySupported) {
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

    try {
      await windowManager.ensureInitialized();
      if (!_windowManagerHooked) {
        windowManager.addListener(this);
        await windowManager.setPreventClose(true);
        _windowManagerHooked = true;
      }
      _windowVisible = await windowManager.isVisible();
    } catch (_) {}

    await _installTrayIcon();
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
    await _preloadTrayMenuIcons();
    await _refreshMenu();
  }

  void _onPlaylistChanged() {
    if (!mounted) return;
    unawaited(_refreshMenu());
  }

  /// 主窗口就绪后安装托盘图标（避免 HWND / 资源路径未就绪导致空白）。
  Future<void> _installTrayIcon() async {
    final iconFile = await resolveDesktopTrayIconPath(_iconPath);
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        await trayManager.setIcon(iconFile);
        return;
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: 120 * (attempt + 1)));
    }
  }

  @override
  void onWindowFocus() {
    if (_attached) {
      unawaited(_installTrayIcon());
    }
  }

  Future<void> _syncWindowVisibleFromNative() async {
    try {
      await windowManager.ensureInitialized();
      _windowVisible = await windowManager.isVisible();
    } catch (_) {}
  }

  Future<String?> _menuIconPath(IconData icon) async {
    final key = Object.hash(icon.codePoint, icon.fontFamily, icon.fontPackage);
    final cached = _menuIconPathCache[key];
    if (cached != null && await File(cached).exists()) return cached;
    try {
      final resolved = await trayMenuMaterialIconPath(icon);
      _menuIconPathCache[key] = resolved;
      return resolved;
    } catch (e, st) {
      appLog.w('托盘菜单图标生成失败: $icon', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> _preloadTrayMenuIcons() async {
    const icons = [
      Icons.play_arrow,
      Icons.pause,
      Icons.skip_previous,
      Icons.skip_next,
      Icons.visibility,
      Icons.visibility_off,
      Icons.logout,
    ];
    for (final icon in icons) {
      try {
        await _menuIconPath(icon);
      } catch (_) {}
    }
  }

  Future<void> _refreshMenu() async {
    if (!mounted || !_attached) return;
    await _syncWindowVisibleFromNative();
    final l10n = AppLocalizations.of(context);
    final playList = context.read<PlayListProvider>();
    final song = playList.currentSong;
    final isPlaying = MusicService.isPlaying;
    final menu = Menu(
      items: [
        _trayMenuItem(
          id: _idTrackTitle,
          label: _trackTitle(song, l10n),
          disabled: true,
        ),
        _trayMenuItem(
          id: _idTrackArtist,
          label: _trackArtist(song, l10n),
          disabled: true,
        ),
        _traySeparator(_idSep1),
        _trayMenuItem(
          id: _idPlayPause,
          key: _kMenuPlayPause,
          label: isPlaying
              ? (l10n.menuBarContextPause)
              : (l10n.menuBarContextPlay),
          icon: await _menuIconPath(
            isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
        _trayMenuItem(
          id: _idPrevious,
          key: _kMenuPrevious,
          label: l10n.menuBarContextPrevious,
          icon: await _menuIconPath(Icons.skip_previous),
        ),
        _trayMenuItem(
          id: _idNext,
          key: _kMenuNext,
          label: l10n.menuBarContextNext,
          icon: await _menuIconPath(Icons.skip_next),
        ),
        _traySeparator(_idSep2),
        _trayMenuItem(
          id: _idShowHide,
          key: _kMenuShowHideWindow,
          label: _windowVisible ? _hideLabel(l10n) : _showLabel(l10n),
          icon: await _menuIconPath(
            _windowVisible ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        _traySeparator(_idSep3),
        _trayMenuItem(
          id: _idQuit,
          key: _kMenuQuit,
          label: _quitLabel(l10n),
          icon: await _menuIconPath(Icons.logout),
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  MenuItem _trayMenuItem({
    required int id,
    String? key,
    required String label,
    String? icon,
    bool disabled = false,
  }) {
    final item = MenuItem(
      key: key,
      label: label,
      icon: icon,
      disabled: disabled,
    );
    item.id = id;
    return item;
  }

  MenuItem _traySeparator(int id) {
    final item = MenuItem.separator();
    item.id = id;
    return item;
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
    try {
      await windowManager.ensureInitialized();
      final visible = await windowManager.isVisible();
      if (visible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
      await _refreshMenu();
    } catch (_) {}
  }

  Future<void> _quitApp() async {
    await requestLinuxDesktopQuit();
  }

  @override
  void onWindowClose() {
    unawaited(_quitApp());
  }

  @override
  void onTrayIconRightMouseDown() {
    // Linux 由 AppIndicator 自带菜单；Windows 弹出前先同步可见性，避免文案与状态不一致。
    if (Platform.isWindows) {
      unawaited(_popupTrayMenuOnWindows());
    }
  }

  Future<void> _popupTrayMenuOnWindows() async {
    await _refreshMenu();
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final playList = context.read<PlayListProvider>();
    final actionKey = menuItem.key ?? _keyForTrayMenuId(menuItem.id);
    switch (actionKey) {
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

  String? _keyForTrayMenuId(int id) {
    switch (id) {
      case _idPlayPause:
        return _kMenuPlayPause;
      case _idPrevious:
        return _kMenuPrevious;
      case _idNext:
        return _kMenuNext;
      case _idShowHide:
        return _kMenuShowHideWindow;
      case _idQuit:
        return _kMenuQuit;
      default:
        return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_traySupported && _attached) {
      final locale = Localizations.localeOf(context);
      if (_lastLocale != locale) {
        _lastLocale = locale;
        unawaited(_refreshMenu());
      }
    }
  }

  @override
  void dispose() {
    if (_windowManagerHooked) {
      try {
        windowManager.removeListener(this);
      } catch (_) {}
    }
    if (_attached) {
      try {
        context.read<PlayListProvider>().removeListener(_onPlaylistChanged);
      } catch (_) {}
      trayManager.removeListener(this);
      // 勿在 dispose 中 destroy 托盘：与 libflutter_linux_gtk + epoxy 析构竞态会 SIGABRT。
      // 正常退出请走 [requestLinuxDesktopQuit]；进程退出后托盘由系统回收。
    }
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
