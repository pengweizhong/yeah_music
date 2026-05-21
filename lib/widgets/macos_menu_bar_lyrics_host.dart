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
import 'package:flutter/services.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:path/path.dart' as p;

/// 在非 Web 且 macOS 时生效：按设置将当前歌词同步到原生菜单栏。
class MacosMenuBarLyricsHost extends StatefulWidget {
  const MacosMenuBarLyricsHost({super.key, required this.child});

  final Widget child;

  @override
  State<MacosMenuBarLyricsHost> createState() => _MacosMenuBarLyricsHostState();
}

class _MacosMenuBarLyricsHostState extends State<MacosMenuBarLyricsHost> {
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<bool>? _playingSub;

  bool _registered = false;
  bool _enabled = false;
  Locale? _lastSyncedLocale;
  String? _lastSyncedMenuBarLine;
  bool? _lastSyncedMenuPlaying;
  String? _lastSyncedMenuTrackPath;
  String? _lastSyncedMenuPlayPauseTitle;

  final ExternalLyricLineFormatter _formatter =
      ExternalLyricLineFormatter(lyricStyle: LyricSettings());

  void _playlistChanged() {
    _formatter.invalidate();
    _resetMenuBarNativeDedupe();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    unawaited(_syncToNative(l10n));
  }

  void _resetMenuBarNativeDedupe() {
    _lastSyncedMenuBarLine = null;
    _lastSyncedMenuPlaying = null;
    _lastSyncedMenuTrackPath = null;
    _lastSyncedMenuPlayPauseTitle = null;
  }

  void _glueRefresh() {
    unawaited(_applyEnabledAndSync());
  }

  Future<void> _syncToNative(AppLocalizations? l10n) async {
    if (!MacosMenuBarLyrics.supported || !_enabled || !mounted) return;

    Song? song;
    try {
      song = Provider.of<PlayListProvider>(context, listen: false).currentSong;
    } catch (_) {
      song = null;
    }

    if (song != null) {
      final r = song.lyrics;
      if (r == null || r.trim().isEmpty) {
        await SongLibraryMetadataHydrator.hydrateIfNeeded(song);
      }
    }

    final pos = MusicService.lastPosition;

    final line = _formatter.formatLine(song: song, position: pos, l10n: l10n);
    if (line != _lastSyncedMenuBarLine) {
      _lastSyncedMenuBarLine = line;
      await MacosMenuBarLyrics.setText(line);
    }

    final playing = MusicService.isPlaying;
    final trackPath = song?.path ?? '';
    final playPauseTitle = playing
        ? (l10n?.menuBarContextPause ?? 'Pause')
        : (l10n?.menuBarContextPlay ?? 'Play');
    if (playing != _lastSyncedMenuPlaying ||
        trackPath != _lastSyncedMenuTrackPath ||
        playPauseTitle != _lastSyncedMenuPlayPauseTitle) {
      _lastSyncedMenuPlaying = playing;
      _lastSyncedMenuTrackPath = trackPath;
      _lastSyncedMenuPlayPauseTitle = playPauseTitle;
      await MacosMenuBarLyrics.setMenuBarState(
        isPlaying: playing,
        trackTitle: _trackTitleForMenu(song, l10n),
        trackArtist: _trackArtistForMenu(song, l10n),
        playPauseTitle: playPauseTitle,
        previousTitle: l10n?.menuBarContextPrevious ?? 'Previous Track',
        nextTitle: l10n?.menuBarContextNext ?? 'Next Track',
      );
    }
  }

  String _trackTitleForMenu(Song? song, AppLocalizations? l10n) {
    final idle = l10n?.menuBarLyricsIdle ?? 'Yeah Music';
    if (song == null) return idle;
    final t = song.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return p.basename(song.path);
  }

  String _trackArtistForMenu(Song? song, AppLocalizations? l10n) {
    if (song == null) return '';
    final a = song.artist?.trim();
    if (a != null && a.isNotEmpty) return a;
    return l10n?.homeUnknownTitle ?? '—';
  }

  Future<void> _applyEnabledAndSync() async {
    if (!MacosMenuBarLyrics.supported) return;
    _enabled = await SettingsService.loadMacosMenuBarLyricsEnabled();
    await MacosMenuBarLyrics.setVisible(_enabled);
    if (!_enabled) {
      _resetMenuBarNativeDedupe();
      return;
    }
    _resetMenuBarNativeDedupe();
    final s = await SettingsService.loadLyricSettings();
    if (mounted && s != null) {
      s.normalizeLayoutFields();
      _formatter.lyricStyle = s;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await _syncToNative(l10n);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb &&
        Platform.isMacOS &&
        MacosMenuBarLyrics.supported &&
        _registered &&
        _enabled) {
      final loc = Localizations.localeOf(context);
      if (_lastSyncedLocale != loc) {
        _lastSyncedLocale = loc;
        final l10n = AppLocalizations.of(context);
        unawaited(_syncToNative(l10n));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_attachAsync());
      });
    }
  }

  Future<void> _attachAsync() async {
    if (_registered || !MacosMenuBarLyrics.supported) return;

    MacosMenuBarLyricsGlue.register(_glueRefresh);

    await _applyEnabledAndSync();
    if (!mounted) {
      MacosMenuBarLyricsGlue.unregister();
      return;
    }

    _posSub = MusicService.positionStream.listen((_) {
      if (!_enabled) return;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      unawaited(_syncToNative(l10n));
    });

    _playingSub = MusicService.playingStream.listen((_) {
      if (!_enabled) return;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      unawaited(_syncToNative(l10n));
    });

    _lastSyncedLocale = Localizations.localeOf(context);

    MacosMenuBarLyrics.setNativeCommandHandler((call) async {
      final playList = Provider.of<PlayListProvider>(context, listen: false);
      switch (call.method) {
        case 'menuPlayPause':
          if (MusicService.isPlaying) {
            await MusicService().pause();
          } else {
            if (!MusicService.canUseResumeToPlay) {
              await playList.playAt(playList.currentIndex);
            } else {
              MusicService().resume();
            }
          }
          return null;
        case 'menuPrevious':
          await playList.playPrev();
          return null;
        case 'menuNext':
          await playList.playNext();
          return null;
        default:
          throw PlatformException(code: 'UNIMPLEMENTED', message: call.method);
      }
    });

    Provider.of<PlayListProvider>(context, listen: false)
        .addListener(_playlistChanged);
    _registered = true;
  }

  @override
  void dispose() {
    if (_registered && MacosMenuBarLyrics.supported) {
      MacosMenuBarLyricsGlue.unregister();
      try {
        Provider.of<PlayListProvider>(context, listen: false)
            .removeListener(_playlistChanged);
      } catch (_) {}
      _posSub?.cancel();
      _playingSub?.cancel();
      MacosMenuBarLyrics.setNativeCommandHandler(null);
      unawaited(MacosMenuBarLyrics.setVisible(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
