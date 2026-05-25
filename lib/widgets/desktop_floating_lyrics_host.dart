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
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/desktop_lyrics_payload_builder.dart';
import 'package:yeah_music/utils/desktop_lyrics_window_geometry_store.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

/// 桌面端独立系统小窗歌词（非主窗口叠层）。
bool get desktopFloatingLyricsSupported =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// 设置页拖动滑条时即时预览（不必等 [onChangeEnd] 写 Hive）。
typedef DesktopLyricsChromePatch = void Function({
  double? bgOpacity,
  bool? dragLocked,
  int? linesBefore,
  int? linesAfter,
});

final class DesktopFloatingLyricsGlue {
  DesktopFloatingLyricsGlue._();

  static DesktopFloatingLyricsGlue? _instance;
  VoidCallback? _refresh;
  Future<void> Function()? _shutdown;

  static DesktopLyricsChromePatch? _chromePatch;
  static void Function(LyricSettings settings)? _lyricStyleSync;

  static void register(
    VoidCallback onRefresh, {
    Future<void> Function()? onShutdown,
    DesktopLyricsChromePatch? onChromePatch,
    void Function(LyricSettings settings)? onLyricStyleSync,
  }) {
    _instance ??= DesktopFloatingLyricsGlue._();
    _instance!._refresh = onRefresh;
    _instance!._shutdown = onShutdown;
    _chromePatch = onChromePatch;
    _lyricStyleSync = onLyricStyleSync;
  }

  static void applyChrome({
    double? bgOpacity,
    bool? dragLocked,
    int? linesBefore,
    int? linesAfter,
  }) {
    _chromePatch?.call(
      bgOpacity: bgOpacity,
      dragLocked: dragLocked,
      linesBefore: linesBefore,
      linesAfter: linesAfter,
    );
  }

  static void unregister() {
    final i = _instance;
    if (i != null) {
      i._refresh = null;
      i._shutdown = null;
    }
    _chromePatch = null;
    _lyricStyleSync = null;
  }

  /// 播放页歌词样式面板拖动时即时同步到桌面悬浮歌词（不必等 Hive 落盘）。
  static void syncLyricStyle(LyricSettings settings) {
    _lyricStyleSync?.call(settings);
  }

  static Future<void> shutdownBeforeQuit() async {
    if (!desktopFloatingLyricsSupported) return;
    final fn = _instance?._shutdown;
    if (fn != null) {
      try {
        await fn().timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    await forceCloseAllLyricsWindows();
  }

  /// 供 [requestLinuxDesktopQuit] 超时兜底。
  static Future<void> forceCloseAllLyricsWindows() =>
      _DesktopFloatingLyricsHostState.forceCloseAllLyricsWindows();

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
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<bool>? _playingSub;

  bool _registered = false;
  bool _enabled = false;
  bool _shuttingDown = false;
  WindowController? _lyricsWindow;
  Future<void>? _ensureWindowInFlight;

  static const Duration _kLyricsInvokeTimeout = Duration(seconds: 2);

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

  void _applyLyricStyleFromPanel(LyricSettings settings) {
    if (!mounted || !_enabled) return;
    final copy = LyricSettings.cloneOf(settings);
    setState(() => _lyricStyle = copy);
    unawaited(_syncPayload());
  }

  void _applyChromePatch({
    double? bgOpacity,
    bool? dragLocked,
    int? linesBefore,
    int? linesAfter,
  }) {
    if (!mounted) return;
    final onlyChrome =
        linesBefore == null && linesAfter == null;
    setState(() {
      if (bgOpacity != null) {
        _desktopBgOpacity = bgOpacity.clamp(0.0, 1.0);
      }
      if (dragLocked != null) _desktopDragLocked = dragLocked;
      if (linesBefore != null) {
        _desktopLinesBefore = linesBefore.clamp(0, 999);
      }
      if (linesAfter != null) {
        _desktopLinesAfter = linesAfter.clamp(0, 999);
      }
    });
    if (onlyChrome && _enabled) {
      unawaited(_syncChromeOnly(bgOpacity: bgOpacity, dragLocked: dragLocked));
      return;
    }
    unawaited(_syncPayload());
  }

  Future<void> _syncChromeOnly({
    double? bgOpacity,
    bool? dragLocked,
  }) async {
    if (!desktopFloatingLyricsSupported || !_enabled || !mounted) return;
    if (_lyricsWindow == null) {
      await _ensureLyricsWindow();
    }
    if (!mounted || _lyricsWindow == null) return;
    final patch = <String, dynamic>{};
    if (bgOpacity != null) patch['bgOpacity'] = bgOpacity.clamp(0.0, 1.0);
    if (dragLocked != null) patch['dragLocked'] = dragLocked;
    if (patch.isEmpty) return;
    await _invokeLyricsWindow('updateChrome', patch);
  }

  Future<dynamic> _invokeLyricsWindow(String method, [dynamic arguments]) async {
    var w = _lyricsWindow;
    if (w == null) {
      w = await _adoptExistingLyricsWindow();
      if (w != null && (_enabled || _shuttingDown) && mounted) {
        _lyricsWindow = w;
      }
    }
    if (w == null) return null;
    try {
      return await w
          .invokeMethod(method, arguments)
          .timeout(_kLyricsInvokeTimeout);
    } catch (e, st) {
      appLog.d('桌面歌词窗 $method 失败', error: e, stackTrace: st);
      return null;
    }
  }

  /// 退出时兜底：关闭所有歌词子引擎，避免 [invokeMethod] 挂起导致进程无法结束。
  static Future<void> forceCloseAllLyricsWindows() async {
    if (!desktopFloatingLyricsSupported) return;
    try {
      final all = await WindowController.getAll()
          .timeout(_DesktopFloatingLyricsHostState._kLyricsInvokeTimeout);
      for (final c in all) {
        if (!_isDesktopLyricsWindow(c)) continue;
        try {
          await c
              .invokeMethod(DesktopLyricsPayloadBuilder.shutdownMethod, null)
              .timeout(_DesktopFloatingLyricsHostState._kLyricsInvokeTimeout);
        } catch (_) {
          try {
            await c.hide();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<String> _lyricsWindowCreateArguments() async {
    final args = <String, dynamic>{'role': 'desktop_lyrics'};
    final saved = await DesktopLyricsWindowGeometryStore.load();
    if (saved != null) {
      args['geometry'] = <String, double>{
        'x': saved.left,
        'y': saved.top,
        'width': saved.width,
        'height': saved.height,
      };
    }
    return jsonEncode(args);
  }

  /// 由主进程写入 canonical 路径，避免子引擎 path_provider 与主进程不一致。
  Future<void> _persistLyricsGeometryFromSubWindow() async {
    final result = await _invokeLyricsWindow('getGeometry', null);
    if (result is! Map) return;
    final rect = DesktopLyricsWindowGeometryStore.rectFromJsonMap(result);
    if (rect != null) {
      await DesktopLyricsWindowGeometryStore.save(rect);
    }
  }

  static bool _isDesktopLyricsWindow(WindowController c) {
    if (c.arguments.isEmpty) return false;
    try {
      final j = jsonDecode(c.arguments);
      return j is Map && j['role'] == 'desktop_lyrics';
    } catch (_) {
      return false;
    }
  }

  /// 关闭多余的歌词子窗，只保留 [keep]（为 null 则全部隐藏）。
  Future<void> _hideExtraDesktopLyricsWindows({WindowController? keep}) async {
    try {
      final all = await WindowController.getAll();
      for (final c in all) {
        if (!_isDesktopLyricsWindow(c)) continue;
        if (keep != null && c.windowId == keep.windowId) continue;
        try {
          await c.hide();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 热重载或并发创建后，复用已有歌词窗，避免叠多个弹窗。
  Future<WindowController?> _adoptExistingLyricsWindow() async {
    try {
      final all = await WindowController.getAll();
      WindowController? keeper;
      for (final c in all) {
        if (!_isDesktopLyricsWindow(c)) continue;
        if (keeper == null) {
          keeper = c;
        } else {
          try {
            await c.hide();
          } catch (_) {}
        }
      }
      return keeper;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureLyricsWindow() async {
    if (!desktopFloatingLyricsSupported) return;
    if (_lyricsWindow != null) return;
    if (_ensureWindowInFlight != null) {
      await _ensureWindowInFlight;
      return;
    }
    _ensureWindowInFlight = _ensureLyricsWindowImpl();
    try {
      await _ensureWindowInFlight;
    } finally {
      _ensureWindowInFlight = null;
    }
  }

  Future<void> _ensureLyricsWindowImpl() async {
    if (_shuttingDown ||
        !desktopFloatingLyricsSupported ||
        _lyricsWindow != null ||
        !_enabled) {
      return;
    }

    final existing = await _adoptExistingLyricsWindow();
    if (existing != null) {
      _lyricsWindow = existing;
      if (_enabled) {
        try {
          await existing.show();
        } catch (_) {}
        // 复用隐藏窗：GTK 已保留位置，勿 restoreGeometry（会用过期 arguments 覆盖）。
        await _invokeLyricsWindow('ensureStacking', null);
      }
      await _hideExtraDesktopLyricsWindows(keep: existing);
      return;
    }

    await _hideExtraDesktopLyricsWindows();

    try {
      final w = await WindowController.create(
        WindowConfiguration(
          arguments: await _lyricsWindowCreateArguments(),
          // Linux：先隐藏，待子引擎注册插件并由 window_manager 配置后再 show
          hiddenAtLaunch: Platform.isLinux,
        ),
      );
      if (!_enabled || !mounted) {
        try {
          await w.hide();
        } catch (_) {}
        return;
      }
      _lyricsWindow = w;
      await _hideExtraDesktopLyricsWindows(keep: w);
      await w.show();
      await _invokeLyricsWindow('ensureStacking', null);
      if (Platform.isLinux) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await w.invokeMethod('restoreGeometry', null);
        await _invokeLyricsWindow('ensureStacking', null);
      }
    } catch (e, st) {
      appLog.w('创建桌面悬浮歌词窗口失败', error: e, stackTrace: st);
      _lyricsWindow = null;
    }
  }

  Future<void> _hideLyricsWindow({bool forQuit = false}) async {
    if (forQuit) {
      _shuttingDown = true;
      _enabled = false;
    }

    if (_ensureWindowInFlight != null) {
      try {
        await _ensureWindowInFlight!.timeout(_kLyricsInvokeTimeout);
      } catch (_) {}
    }

    final w = _lyricsWindow ?? await _adoptExistingLyricsWindow();

    if (!forQuit) {
      await _persistLyricsGeometryFromSubWindow();
      await _invokeLyricsWindow('persistGeometry', null);
    }

    if (w != null) {
      _lyricsWindow = w;
      await _invokeLyricsWindow(DesktopLyricsPayloadBuilder.shutdownMethod, null);
    }

    _lyricsWindow = null;
    await forceCloseAllLyricsWindows();
    await _hideExtraDesktopLyricsWindows();
  }

  Future<void> _syncPayload() async {
    if (_shuttingDown ||
        !desktopFloatingLyricsSupported ||
        !_enabled ||
        !mounted) {
      return;
    }

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
      globalDisplayMode: _lyricStyle.resolvedGlobalLyricDisplayMode,
    );

    await _invokeLyricsWindow('update', payload);
  }

  Future<void> _applyEnabledAndSync() async {
    if (!desktopFloatingLyricsSupported) return;
    final enabled = await SettingsService.loadDesktopFloatingLyricsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
    if (!_enabled) {
      await _hideLyricsWindow();
      return;
    }
    await _hideExtraDesktopLyricsWindows(keep: _lyricsWindow);
    final s = await SettingsService.loadLyricSettings();
    final bg = await SettingsService.loadDesktopFloatingLyricsBgOpacity();
    final lb = await SettingsService.loadDesktopFloatingLyricsLinesBefore();
    final la = await SettingsService.loadDesktopFloatingLyricsLinesAfter();
    final lk = await SettingsService.loadDesktopFloatingLyricsDragLocked();
    if (!mounted) return;
    setState(() {
      if (s != null) {
        _lyricStyle = LyricSettings.cloneOf(s);
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

  void _bindPlayerStreamSubscriptions() {
    if (!desktopFloatingLyricsSupported) return;
    _posSub?.cancel();
    _playingSub?.cancel();
    _posSub = MusicService.desktopLyricPositionStream.listen((_) {
      if (!_enabled || !mounted) return;
      unawaited(_syncPayload());
    });
    _playingSub = MusicService.playingStream.listen((_) {
      if (!_enabled || !mounted) return;
      unawaited(_syncPayload());
    });
  }

  void _reattachPlayerStreamSubscriptions() {
    _bindPlayerStreamSubscriptions();
    if (_enabled && mounted) {
      unawaited(_syncPayload());
    }
  }

  Future<void> _attachAsync() async {
    if (_registered || !desktopFloatingLyricsSupported) return;

    DesktopFloatingLyricsGlue.register(
      _glueRefresh,
      onShutdown: () => _hideLyricsWindow(forQuit: true),
      onChromePatch: _applyChromePatch,
      onLyricStyleSync: _applyLyricStyleFromPanel,
    );
    MusicService.addDesktopPlayerRecreatedListener(
      _reattachPlayerStreamSubscriptions,
    );
    _enabled = await SettingsService.loadDesktopFloatingLyricsEnabled();
    _bindPlayerStreamSubscriptions();

    await _applyEnabledAndSync();
    if (!mounted) {
      DesktopFloatingLyricsGlue.unregister();
      MusicService.removeDesktopPlayerRecreatedListener(
        _reattachPlayerStreamSubscriptions,
      );
      _posSub?.cancel();
      _playingSub?.cancel();
      return;
    }

    Provider.of<PlayListProvider>(context, listen: false)
        .addListener(_playlistChanged);
    _registered = true;
    if (_enabled && mounted) {
      unawaited(_syncPayload());
    }
  }

  @override
  void dispose() {
    if (_registered && desktopFloatingLyricsSupported) {
      MusicService.removeDesktopPlayerRecreatedListener(
        _reattachPlayerStreamSubscriptions,
      );
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
