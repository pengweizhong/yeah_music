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
import 'dart:math' as math;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/utils/desktop_lyrics_payload_builder.dart';
import 'package:yeah_music/utils/desktop_lyrics_window_geometry_store.dart';
import 'package:yeah_music/welcome/app_startup_clock.dart';

/// 独立 Flutter 引擎入口：系统级歌词小窗（非主窗口内叠层）。
Future<void> runDesktopLyricsSubWindow() async {
  AppStartupClock.ensureStarted();
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const _DesktopLyricsSubApp());
}

class _DesktopLyricsSubApp extends StatelessWidget {
  const _DesktopLyricsSubApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      home: const DesktopLyricsSubWindowPage(),
    );
  }
}

class DesktopLyricsSubWindowPage extends StatefulWidget {
  const DesktopLyricsSubWindowPage({super.key});

  @override
  State<DesktopLyricsSubWindowPage> createState() =>
      _DesktopLyricsSubWindowPageState();
}

class _DesktopLyricsSubWindowPageState extends State<DesktopLyricsSubWindowPage>
    with WindowListener {
  Timer? _resizeDebounce;
  Timer? _geometryPersistDebounce;

  static const double _kMaxPanelW = 880.0;
  static const double _kMaxPanelH = 620.0;

  Map<String, dynamic> _payload = {
    'rows': [
      {
        'spans': [
          {'text': '…', 'fs': 20.0, 'c': 0xFFFFFFFF, 'wt': 400},
        ],
      },
    ],
    'align': 1,
    'rowPad': 6.0,
    'bgOpacity': 0.42,
    'dragLocked': false,
  };

  final GlobalKey _contentKey = GlobalKey();
  Size? _lastAppliedChromeSize;

  String? _lastResizeLayoutSignature;

  /// false：不根据歌词内容自动改窗口大小（已恢复磁盘记录，或用户已手动拖放过并落盘）。
  bool _autoResizeToContent = true;

  /// 程序性 [setBounds]/[setSize] 后短时间内不写回磁盘。
  DateTime? _ignorePersistUntil;

  static const WindowMethodChannel _channel = WindowMethodChannel(
    DesktopLyricsPayloadBuilder.channelName,
    mode: ChannelMode.unidirectional,
  );

  /// macOS：整窗 [NSWindow.ignoresMouseEvents]，锁定后点击穿透到下层应用。
  static const MethodChannel _mousePassthroughChannel =
      MethodChannel('yeah_music/desktop_lyrics_mouse');

  bool? _lastAppliedLockPassthrough;

  bool get _isMacOS => Platform.isMacOS;

  static String _layoutSignatureForResize(Map<String, dynamic> p) {
    final rows = p['rows'] as List? ?? [];
    final buf = StringBuffer()
      ..write(p['rowPad'])
      ..write('|')
      ..write(p['align'])
      ..write('|');
    for (final r in rows) {
      if (r is! Map) continue;
      final spans = r['spans'] as List? ?? [];
      for (final s in spans) {
        if (s is! Map) continue;
        buf.write(s['text']);
        buf.write('\u001f');
        buf.write(s['fs']);
        buf.write('\u001f');
        buf.write(s['wt']);
        buf.write('\u001e');
      }
      buf.write('\n');
    }
    return buf.toString();
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == DesktopLyricsPayloadBuilder.shutdownMethod) {
        await _teardownChannelAndCloseWindow();
        return null;
      }
      if (call.method == 'update' && call.arguments is Map) {
        final m = Map<String, dynamic>.from(call.arguments as Map);
        if (!mounted) return null;
        final sig = _layoutSignatureForResize(m);
        final layoutChanged = _lastResizeLayoutSignature != sig;
        _lastResizeLayoutSignature = sig;
        setState(() => _payload = m);
        _syncMousePassthroughFromPayload();
        if (layoutChanged && _autoResizeToContent) {
          _lastAppliedChromeSize = null;
          _debouncedResizeToContent();
        }
      }
      return null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initWindowChrome());
      _syncMousePassthroughFromPayload();
    });
  }

  void _syncMousePassthroughFromPayload() {
    final locked = _payload['dragLocked'] == true;
    if (_lastAppliedLockPassthrough == locked) return;
    _lastAppliedLockPassthrough = locked;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_applyNativeMousePassthrough(locked));
    });
  }

  Future<void> _applyNativeMousePassthrough(bool ignoreMouseEvents) async {
    if (!_isMacOS) return;
    Future<void> once() async {
      await _mousePassthroughChannel.invokeMethod<void>(
        'setIgnoresMouseEvents',
        <String, dynamic>{'ignore': ignoreMouseEvents},
      );
    }

    try {
      await once();
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      try {
        await once();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _geometryPersistDebounce?.cancel();
    _resizeDebounce?.cancel();
    unawaited(_channel.setMethodCallHandler(null));
    super.dispose();
  }

  @override
  void onWindowMoved() {
    _debouncedPersistGeometry();
  }

  @override
  void onWindowResized() {
    _debouncedPersistGeometry();
  }

  /// Linux 等可能只触发连续事件，用防抖统一落盘。
  @override
  void onWindowMove() {
    if (Platform.isLinux) _debouncedPersistGeometry();
  }

  @override
  void onWindowResize() {
    if (Platform.isLinux) _debouncedPersistGeometry();
  }

  void _debouncedPersistGeometry() {
    if (_ignorePersistUntil != null &&
        DateTime.now().isBefore(_ignorePersistUntil!)) {
      return;
    }
    _geometryPersistDebounce?.cancel();
    _geometryPersistDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistGeometryNow());
    });
  }

  Future<void> _persistGeometryNow() async {
    try {
      final r = await windowManager.getBounds();
      await DesktopLyricsWindowGeometryStore.save(r);
      if (mounted) _autoResizeToContent = false;
    } catch (_) {}
  }

  Future<void> _teardownChannelAndCloseWindow() async {
    _resizeDebounce?.cancel();
    _geometryPersistDebounce?.cancel();
    try {
      await _channel.setMethodCallHandler(null);
    } catch (_) {}
    if (!mounted) return;
    await _applyNativeMousePassthrough(false);
    try {
      await windowManager.close();
    } catch (_) {}
  }

  Future<void> _initWindowChrome() async {
    final saved = await DesktopLyricsWindowGeometryStore.load();
    _autoResizeToContent = saved == null;
    final initialSize = saved != null
        ? Size(saved.width, saved.height)
        : const Size(280, 72);

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: initialSize,
        minimumSize: const Size(
          DesktopLyricsWindowGeometryStore.minWidth,
          DesktopLyricsWindowGeometryStore.minHeight,
        ),
        center: false,
        backgroundColor: Colors.transparent,
        skipTaskbar: _isMacOS ? false : true,
        titleBarStyle: _isMacOS ? null : TitleBarStyle.hidden,
        title: '',
        alwaysOnTop: true,
      ),
      () async {
        if (!_isMacOS) {
          await windowManager.setAsFrameless();
        }
        await windowManager.setHasShadow(false);
        await windowManager.show();
        if (saved != null) {
          _ignorePersistUntil =
              DateTime.now().add(const Duration(milliseconds: 900));
          await windowManager.setBounds(saved);
        }
        if (_autoResizeToContent) {
          _debouncedResizeToContent();
        }
      },
    );
  }

  void _debouncedResizeToContent() {
    if (!_autoResizeToContent) return;
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 72), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_resizeToContentIfNeeded());
      });
    });
  }

  Future<void> _resizeToContentIfNeeded() async {
    if (!mounted || !_autoResizeToContent) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    const fudge = 8.0;
    final w = math
        .min(920.0, math.max(96.0, (box.size.width + fudge).ceilToDouble()));
    final h = math.min(
        1080.0, math.max(40.0, (box.size.height + fudge).ceilToDouble()));

    final last = _lastAppliedChromeSize;
    if (last != null &&
        (w - last.width).abs() < 2.0 &&
        (h - last.height).abs() < 2.0) {
      return;
    }
    _ignorePersistUntil =
        DateTime.now().add(const Duration(milliseconds: 600));
    _lastAppliedChromeSize = Size(w, h);
    await windowManager.setSize(Size(w, h));
  }

  @override
  Widget build(BuildContext context) {
    final alignIdx = (_payload['align'] as num?)?.toInt() ?? 1;
    final align = DesktopLyricsPayloadBuilder.alignFromIndex(alignIdx);
    final rowPad = (_payload['rowPad'] as num?)?.toDouble() ?? 6.0;
    final rows = (_payload['rows'] as List?) ?? const [];
    final bgOpacity =
        (_payload['bgOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.42;
    final dragLocked = _payload['dragLocked'] == true;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        widthFactor: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: dragLocked
              ? null
              : (_) {
                  unawaited(windowManager.startDragging());
                },
          child: LayoutBuilder(
            builder: (context, c) {
              final maxW = c.maxWidth.isFinite ? c.maxWidth : _kMaxPanelW;
              final maxH = c.maxHeight.isFinite && c.maxHeight > 0
                  ? c.maxHeight
                  : _kMaxPanelH;
              return Container(
                key: _contentKey,
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: bgOpacity),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxW,
                    maxHeight: math.min(maxH, 4000),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      for (final r in rows) _row(r, align, rowPad),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(dynamic raw, TextAlign align, double rowPad) {
    if (raw is! Map) return const SizedBox.shrink();
    final spansRaw = raw['spans'];
    if (spansRaw is! List || spansRaw.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <InlineSpan>[];
    for (var i = 0; i < spansRaw.length; i++) {
      if (i > 0) {
        children.add(const TextSpan(text: '\n'));
      }
      final s = spansRaw[i];
      if (s is! Map) continue;
      final useGrad = s['grad'] == true;
      final text = s['text'] as String? ?? '';
      final fs = (s['fs'] as num?)?.toDouble() ?? 18;
      final c = (s['c'] as num?)?.toInt() ?? 0xFFFFFFFF;
      final wt = (s['wt'] as num?)?.toInt() ?? 400;
      final tw = wt >= 600 ? FontWeight.w600 : FontWeight.w400;
      final baseStyle = TextStyle(
        fontSize: fs,
        height: 1.35,
        letterSpacing: 0.2,
        fontWeight: tw,
      );
      if (useGrad) {
        final g0 = (s['g0'] as num?)?.toInt() ?? 0xFFFFFFFF;
        final g1 = (s['g1'] as num?)?.toInt() ?? 0xFFFFB74D;
        final gd = (s['gd'] as num?)?.toInt();
        final lg = playlistCoverLinearGradient(
          [Color(g0), Color(g1)],
          direction: PlaylistCoverGradientDirection.fromStorage(gd),
        );
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => lg.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Text(
                text,
                style: baseStyle.merge(const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        );
      } else {
        children.add(
          TextSpan(
            text: text,
            style: baseStyle.merge(TextStyle(color: Color(c))),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPad),
      child: RichText(
        textAlign: align,
        text: TextSpan(
          style: const TextStyle(height: 1.35, letterSpacing: 0.2),
          children: children,
        ),
      ),
    );
  }
}
