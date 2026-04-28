import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/desktop_lyrics_payload_builder.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

/// 桌面端独立系统小窗歌词（非主窗口叠层）。
bool get desktopFloatingLyricsSupported =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

final class DesktopFloatingLyricsGlue {
  DesktopFloatingLyricsGlue._();

  static DesktopFloatingLyricsGlue? _instance;
  VoidCallback? _refresh;

  static void register(VoidCallback onRefresh) {
    _instance ??= DesktopFloatingLyricsGlue._();
    _instance!._refresh = onRefresh;
  }

  static void unregister() {
    final i = _instance;
    if (i != null) i._refresh = null;
  }

  static Future<void> reloadFromHive() async {
    if (!desktopFloatingLyricsSupported) return;
    final i = _instance;
    if (i != null && i._refresh != null) i._refresh!();
  }
}

class DesktopFloatingLyricsHost extends StatefulWidget {
  const DesktopFloatingLyricsHost({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopFloatingLyricsHost> createState() =>
      _DesktopFloatingLyricsHostState();
}

class _DesktopFloatingLyricsHostState extends State<DesktopFloatingLyricsHost> {
  static const WindowMethodChannel _payloadChannel = WindowMethodChannel(
    DesktopLyricsPayloadBuilder.channelName,
    mode: ChannelMode.unidirectional,
  );

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<bool>? _playingSub;

  bool _registered = false;
  bool _enabled = false;
  WindowController? _lyricsWindow;

  LyricSettings _lyricStyle = LyricSettings();
  double _desktopBgOpacity =
      SettingsService.desktopFloatingLyricsBgOpacityDefault;
  int _desktopLinesBefore =
      SettingsService.desktopFloatingLyricsLinesBeforeDefault;
  int _desktopLinesAfter =
      SettingsService.desktopFloatingLyricsLinesAfterDefault;
  bool _desktopDragLocked = false;
  String? _parsedForPath;
  String? _parsedLyricsBlob;
  List<LyricEntry> _parsed = [];

  void _invalidateParse() {
    _parsedForPath = null;
    _parsedLyricsBlob = null;
    _parsed = [];
  }

  void _playlistChanged() {
    _invalidateParse();
    if (!mounted) return;
    unawaited(_syncPayload());
  }

  void _glueRefresh() {
    unawaited(_applyEnabledAndSync());
  }

  Future<void> _ensureLyricsWindow() async {
    if (!desktopFloatingLyricsSupported || _lyricsWindow != null) return;
    try {
      final w = await WindowController.create(
        WindowConfiguration(
          arguments: jsonEncode(<String, dynamic>{'role': 'desktop_lyrics'}),
          hiddenAtLaunch: false,
        ),
      );
      _lyricsWindow = w;
      await w.show();
    } catch (_) {
      _lyricsWindow = null;
    }
  }

  Future<void> _hideLyricsWindow() async {
    final w = _lyricsWindow;
    if (w == null) return;
    _lyricsWindow = null;
    try {
      await _payloadChannel.invokeMethod<void>(
        DesktopLyricsPayloadBuilder.shutdownMethod,
        null,
      );
    } catch (_) {}
    try {
      await w.hide();
    } catch (_) {}
  }

  Future<void> _syncPayload() async {
    if (!desktopFloatingLyricsSupported || !_enabled || !mounted) return;

    await _ensureLyricsWindow();

    if (!mounted) return;

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

    if (!mounted) return;
    final pos = MusicService.lastPosition;
    final l10n = AppLocalizations.of(context);

    if (song != null) {
      final raw = song.lyrics;
      final path = song.path;
      if (raw != null && raw.trim().isNotEmpty) {
        if (_parsedForPath != path || _parsedLyricsBlob != raw) {
          _parsedForPath = path;
          _parsedLyricsBlob = raw;
          _parsed = LyricsUtils.parseLyrics(raw);
        }
      } else {
        _invalidateParse();
      }
    } else {
      _invalidateParse();
    }

    final payload = DesktopLyricsPayloadBuilder.build(
      song: song,
      position: pos,
      settings: _lyricStyle,
      parsed: _parsed,
      idleText: l10n.menuBarLyricsIdle,
      noLyricsText: l10n.menuBarLyricsNoLyrics,
      linesBefore: _desktopLinesBefore,
      linesAfter: _desktopLinesAfter,
      bgOpacity: _desktopBgOpacity,
      dragLocked: _desktopDragLocked,
    );

    try {
      await _payloadChannel.invokeMethod<void>('update', payload);
    } catch (_) {}
  }

  Future<void> _applyEnabledAndSync() async {
    if (!desktopFloatingLyricsSupported) return;
    _enabled = await SettingsService.loadDesktopFloatingLyricsEnabled();
    if (!_enabled) {
      await _hideLyricsWindow();
      return;
    }
    final s = await SettingsService.loadLyricSettings();
    final bg = await SettingsService.loadDesktopFloatingLyricsBgOpacity();
    final lb = await SettingsService.loadDesktopFloatingLyricsLinesBefore();
    final la = await SettingsService.loadDesktopFloatingLyricsLinesAfter();
    final lk = await SettingsService.loadDesktopFloatingLyricsDragLocked();
    if (!mounted) return;
    setState(() {
      if (s != null) {
        s.normalizeLayoutFields();
        _lyricStyle = s;
      }
      _desktopBgOpacity = bg;
      _desktopLinesBefore = lb;
      _desktopLinesAfter = la;
      _desktopDragLocked = lk;
    });
    await _syncPayload();
  }

  @override
  void initState() {
    super.initState();
    if (desktopFloatingLyricsSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_attachAsync());
      });
    }
  }

  Future<void> _attachAsync() async {
    if (_registered || !desktopFloatingLyricsSupported) return;

    DesktopFloatingLyricsGlue.register(_glueRefresh);

    await _applyEnabledAndSync();
    if (!mounted) {
      DesktopFloatingLyricsGlue.unregister();
      return;
    }

    _posSub = MusicService.positionStream.listen((_) {
      if (!_enabled) return;
      if (!mounted) return;
      unawaited(_syncPayload());
    });

    _playingSub = MusicService.playingStream.listen((_) {
      if (!_enabled) return;
      if (!mounted) return;
      unawaited(_syncPayload());
    });

    Provider.of<PlayListProvider>(context, listen: false)
        .addListener(_playlistChanged);
    _registered = true;
  }

  @override
  void dispose() {
    if (_registered && desktopFloatingLyricsSupported) {
      DesktopFloatingLyricsGlue.unregister();
      try {
        Provider.of<PlayListProvider>(context, listen: false)
            .removeListener(_playlistChanged);
      } catch (_) {}
      _posSub?.cancel();
      _playingSub?.cancel();
      unawaited(_hideLyricsWindow());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
