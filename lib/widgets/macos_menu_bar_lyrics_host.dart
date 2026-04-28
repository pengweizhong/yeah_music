import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:path/path.dart' as p;

/// 发往原生的安全防护；视觉固定宽度与「…」由 macOS [NSStatusItem] 侧完成。
const int _kMenuBarLyricsSafetyMaxGraphemes = 512;

String _sanitizeMenuBarPayload(String text) {
  final t = text.trim();
  if (t.isEmpty) return t;
  final ch = t.characters;
  if (ch.length <= _kMenuBarLyricsSafetyMaxGraphemes) return t;
  return '${ch.take(_kMenuBarLyricsSafetyMaxGraphemes)}…';
}

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

  LyricSettings _lyricStyle = LyricSettings();
  /// 与 [_parsedLyricsBlob]、[_parsed] 对齐；需在路径或歌词原文变化时重解析。
  String? _parsedForPath;
  String? _parsedLyricsBlob;
  List<LyricEntry> _parsed = [];

  void _playlistChanged() {
    _invalidateLyricsCache();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    unawaited(_syncToNative(l10n));
  }

  void _glueRefresh() {
    unawaited(_applyEnabledAndSync());
  }

  void _invalidateLyricsCache() {
    _parsedForPath = null;
    _parsedLyricsBlob = null;
    _parsed = [];
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

    final line = _formatLineForMenuBar(song: song, position: pos, l10n: l10n);
    await MacosMenuBarLyrics.setText(line);

    final playing = MusicService.isPlaying;
    await MacosMenuBarLyrics.setMenuBarState(
      isPlaying: playing,
      trackTitle: _trackTitleForMenu(song, l10n),
      trackArtist: _trackArtistForMenu(song, l10n),
      playPauseTitle: playing
          ? (l10n?.menuBarContextPause ?? 'Pause')
          : (l10n?.menuBarContextPlay ?? 'Play'),
      previousTitle: l10n?.menuBarContextPrevious ?? 'Previous Track',
      nextTitle: l10n?.menuBarContextNext ?? 'Next Track',
    );
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

  String _formatLineForMenuBar({
    required Song? song,
    required Duration position,
    required AppLocalizations? l10n,
  }) {
    final idle = l10n?.menuBarLyricsIdle ?? 'Yeah Music';
    final noLyrics = l10n?.menuBarLyricsNoLyrics ?? 'No lyrics';

    if (song == null) {
      return _sanitizeMenuBarPayload(idle);
    }

    final raw = song.lyrics;
    if (raw == null || raw.trim().isEmpty) {
      return _sanitizeMenuBarPayload(noLyrics);
    }

    final path = song.path;
    if (_parsedForPath != path || _parsedLyricsBlob != raw) {
      _parsedForPath = path;
      _parsedLyricsBlob = raw;
      _parsed = LyricsUtils.parseLyrics(raw);
    }

    if (_parsed.isEmpty) {
      return _sanitizeMenuBarPayload(noLyrics);
    }

    final idx = LyricsUtils.findCurrentLyricIndex(_parsed, position);
    if (idx < 0 || idx >= _parsed.length) {
      return _sanitizeMenuBarPayload('…');
    }

    final lines = _parsed[idx].lines;
    final parts = <String>[];
    if (_lyricStyle.showOriginal && lines.isNotEmpty) {
      parts.add(lines[0]);
    }
    if (_lyricStyle.showTranslations && lines.length > 1) {
      parts.addAll(lines.sublist(1));
    }
    if (parts.isEmpty && lines.isNotEmpty) {
      parts.add(lines[0]);
    }

    final lyricLine = parts.join(' · ');
    if (lyricLine.isEmpty) {
      return _sanitizeMenuBarPayload(noLyrics);
    }
    return _sanitizeMenuBarPayload(lyricLine);
  }

  Future<void> _applyEnabledAndSync() async {
    if (!MacosMenuBarLyrics.supported) return;
    _enabled = await SettingsService.loadMacosMenuBarLyricsEnabled();
    await MacosMenuBarLyrics.setVisible(_enabled);
    if (!_enabled) {
      return;
    }
    final s = await SettingsService.loadLyricSettings();
    if (mounted && s != null) {
      s.normalizeLayoutFields();
      setState(() => _lyricStyle = s);
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await _syncToNative(l10n);
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
