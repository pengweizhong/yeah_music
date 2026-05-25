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
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/platform_typography.dart';
import 'package:yeah_music/platform/desktop_lyrics_linux_shell.dart';
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
      theme: PlatformTypography.apply(
        ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
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
  Timer? _shrinkDebounce;
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

  /// 锁定后整窗鼠标穿透（macOS NSWindow / Linux GDK / Windows WS_EX_TRANSPARENT）。
  static const MethodChannel _mousePassthroughChannel =
      MethodChannel('yeah_music/desktop_lyrics_mouse');

  bool? _lastAppliedLockPassthrough;
  bool? _lastAppliedDragLocked;

  /// 使用 [Opacity] 做歌词条背景 alpha（Linux 依赖 realize 前 RGBA 补丁）。
  bool _linuxAlphaBackground = true;

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
    unawaited(_bindLyricsWindowMethodHandler());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initWindowChrome());
      _syncMousePassthroughFromPayload();
    });
  }

  Future<void> _bindLyricsWindowMethodHandler() async {
    try {
      final wc = await WindowController.fromCurrentEngine();
      await wc.setWindowMethodHandler(_onLyricsWindowMethod);
    } catch (_) {}
  }

  Future<void> _detachLyricsWindowMethodHandler() async {
    try {
      final wc = await WindowController.fromCurrentEngine();
      await wc.setWindowMethodHandler(null);
    } catch (_) {}
  }

  Future<dynamic> _onLyricsWindowMethod(MethodCall call) async {
    if (call.method == DesktopLyricsPayloadBuilder.shutdownMethod) {
      await _teardownChannelAndCloseWindow();
      return null;
    }
    if (call.method == 'update' && call.arguments is Map) {
      _applyPayloadUpdate(Map<String, dynamic>.from(call.arguments as Map));
      return null;
    }
    if (call.method == 'updateChrome' && call.arguments is Map) {
      _applyChromePatch(Map<String, dynamic>.from(call.arguments as Map));
      return null;
    }
    if (call.method == 'getGeometry') {
      return _geometryMapFromBounds(await windowManager.getBounds());
    }
    if (call.method == 'persistGeometry') {
      await _persistGeometryNow();
      return _geometryMapFromBounds(await windowManager.getBounds());
    }
    if (call.method == 'restoreGeometry') {
      await _restoreGeometryFromStore();
      return null;
    }
    if (call.method == 'ensureStacking') {
      await _ensureWindowStacking();
      return null;
    }
    return null;
  }

  void _applyPayloadUpdate(Map<String, dynamic> m) {
    if (!mounted) return;
    final sig = _layoutSignatureForResize(m);
    final layoutChanged = _lastResizeLayoutSignature != sig;
    _lastResizeLayoutSignature = sig;
    final dragLocked = m['dragLocked'] == true;
    final lockChanged = _lastAppliedDragLocked != dragLocked;
    _lastAppliedDragLocked = dragLocked;
    setState(() => _payload = m);
    _syncMousePassthroughFromPayload();
    if (lockChanged) {
      unawaited(_applyDragLockChromeChange(dragLocked));
    }
    if (layoutChanged && _autoResizeToContent) {
      _lastAppliedChromeSize = null;
      _debouncedResizeToContent();
    }
  }

  void _applyChromePatch(Map<String, dynamic> patch) {
    if (!mounted) return;
    setState(() {
      _payload = Map<String, dynamic>.from(_payload);
      if (patch.containsKey('bgOpacity')) {
        _payload['bgOpacity'] =
            (patch['bgOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ??
                _payload['bgOpacity'];
      }
      if (patch.containsKey('dragLocked')) {
        _payload['dragLocked'] = patch['dragLocked'] == true;
      }
    });
    final dragLocked = _payload['dragLocked'] == true;
    final lockChanged = _lastAppliedDragLocked != dragLocked;
    _lastAppliedDragLocked = dragLocked;
    _syncMousePassthroughFromPayload();
    if (lockChanged) {
      unawaited(_applyDragLockChromeChange(dragLocked));
    }
    if (patch.containsKey('bgOpacity')) {
      unawaited(_refreshLinuxTransparency());
    }
  }

  Future<void> _refreshLinuxTransparency() async {
    if (!Platform.isLinux) return;
    _linuxAlphaBackground =
        await DesktopLyricsLinuxShell.isCompositingAvailable();
    await DesktopLyricsLinuxShell.ensureTransparent();
    if (mounted) setState(() {});
  }

  /// 锁定/解锁时保持用户已拖好的窗口位置与尺寸（勿缩放到内容、勿在 Linux 上 setResizable）。
  Future<void> _applyDragLockChromeChange(bool dragLocked) async {
    Rect? bounds;
    try {
      bounds = await windowManager.getBounds();
    } catch (_) {}

    _ignorePersistUntil =
        DateTime.now().add(const Duration(milliseconds: 1200));

    // Linux：setResizable(false) 常导致窗口被 WM 撑大；锁定仅去掉边缘 DragToResizeArea。
    if (!Platform.isLinux) {
      try {
        await windowManager.setResizable(!dragLocked);
      } catch (_) {}
    }

    if (bounds != null) {
      try {
        await windowManager.setBounds(bounds);
      } catch (_) {}
    }
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
    Future<void> once() async {
      if (Platform.isMacOS) {
        await _mousePassthroughChannel.invokeMethod<void>(
          'setIgnoresMouseEvents',
          <String, dynamic>{'ignore': ignoreMouseEvents},
        );
      } else if (Platform.isLinux) {
        await DesktopLyricsLinuxShell.setPassThrough(ignoreMouseEvents);
      } else if (Platform.isWindows) {
        await windowManager.setIgnoreMouseEvents(ignoreMouseEvents);
      }
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
    _shrinkDebounce?.cancel();
    unawaited(_detachLyricsWindowMethodHandler());
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

  Map<String, double>? _geometryMapFromBounds(Rect r) {
    return <String, double>{
      'x': r.left,
      'y': r.top,
      'width': r.width,
      'height': r.height,
    };
  }

  Future<Rect?> _geometryFromWindowArguments() async {
    try {
      final wc = await WindowController.fromCurrentEngine();
      if (wc.arguments.isEmpty) return null;
      final dynamic j = jsonDecode(wc.arguments);
      if (j is! Map) return null;
      final g = j['geometry'];
      if (g is! Map) return null;
      final m = <String, dynamic>{};
      g.forEach((k, v) {
        if (k is String) m[k] = v;
      });
      return DesktopLyricsWindowGeometryStore.rectFromJsonMap(m);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistGeometryNow() async {
    try {
      final r = await windowManager.getBounds();
      await DesktopLyricsWindowGeometryStore.save(r);
      if (mounted) _autoResizeToContent = false;
    } catch (_) {}
  }

  /// 仅从磁盘恢复（勿读 [WindowController.arguments]：创建后用户拖动的位置不会写回 arguments）。
  Future<void> _restoreGeometryFromStore() async {
    final saved = await DesktopLyricsWindowGeometryStore.load();
    if (saved == null || !mounted) return;
    _autoResizeToContent = false;
    await _applySavedGeometry(saved);
  }

  Future<void> _ensureWindowStacking() async {
    try {
      await windowManager.setAlwaysOnTop(true);
    } catch (_) {}
  }

  /// show 后 WM/插件可能覆盖位置，GTK + window_manager 多次应用提高冷启动恢复率。
  Future<void> _applySavedGeometry(Rect saved) async {
    _ignorePersistUntil =
        DateTime.now().add(const Duration(milliseconds: 1500));
    for (var i = 0; i < 4; i++) {
      if (Platform.isLinux) {
        await DesktopLyricsLinuxShell.setWindowBounds(saved);
      }
      try {
        await windowManager.setBounds(saved);
      } catch (_) {}
      if (i < 3) {
        await Future<void>.delayed(Duration(milliseconds: 40 * (i + 1)));
      }
    }
  }

  Future<void> _teardownChannelAndCloseWindow() async {
    _resizeDebounce?.cancel();
    _shrinkDebounce?.cancel();
    _geometryPersistDebounce?.cancel();
    await _persistGeometryNow();
    if (!mounted) return;
    await _applyNativeMousePassthrough(false);
    // Linux：gtk_window_close 可能结束整应用；仅隐藏子窗，主进程复用。
    try {
      await windowManager.hide();
    } catch (_) {}
    if (Platform.isLinux) {
      return;
    }
    try {
      await windowManager.close();
    } catch (_) {}
  }

  Future<void> _initWindowChrome() async {
    final saved =
        await _geometryFromWindowArguments() ??
            await DesktopLyricsWindowGeometryStore.load();
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
        // Linux：勿让 waitUntilReadyToShow 写入 window_manager 的 window CSS 背景。
        backgroundColor: Platform.isLinux ? null : Colors.transparent,
        skipTaskbar: _isMacOS ? false : true,
        titleBarStyle: _isMacOS ? null : TitleBarStyle.hidden,
        title: '',
        alwaysOnTop: true,
      ),
      () async {
        if (!_isMacOS) {
          await windowManager.setAsFrameless();
        }
        // Linux：window_manager 的 CSS 背景会盖住 Flutter 半透明，改由原生 RGBA 合成。
        if (!Platform.isLinux) {
          await windowManager.setBackgroundColor(Colors.transparent);
        }
        await windowManager.setHasShadow(false);
        if (Platform.isLinux) {
          await DesktopLyricsLinuxShell.ensureTransparent();
          if (saved != null) {
            await DesktopLyricsLinuxShell.setWindowBounds(saved);
          }
        }
        await windowManager.show();
        await _ensureWindowStacking();
        if (Platform.isLinux) {
          await DesktopLyricsLinuxShell.ensureTransparent();
        }
        if (saved != null) {
          await _applySavedGeometry(saved);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_applySavedGeometry(saved));
          });
        }
        _lastAppliedDragLocked = _payload['dragLocked'] == true;
        if (_lastAppliedDragLocked == true) {
          unawaited(_applyDragLockChromeChange(true));
        } else if (!Platform.isLinux) {
          try {
            await windowManager.setResizable(true);
          } catch (_) {}
        }
        if (_autoResizeToContent) {
          _debouncedResizeToContent();
        } else if (saved == null) {
          _debouncedShrinkToContent();
        }
        // 窗口 realize/show 后再设一次穿透（首次 init 时窗可能尚未就绪）。
        _lastAppliedLockPassthrough = null;
        _syncMousePassthroughFromPayload();
      },
    );
  }

  void _debouncedShrinkToContent() {
    _shrinkDebounce?.cancel();
    _shrinkDebounce = Timer(const Duration(milliseconds: 96), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_shrinkWindowToContent());
      });
    });
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
    final size = await _measureContentChromeSize();
    if (size == null) return;

    final last = _lastAppliedChromeSize;
    if (last != null &&
        (size.width - last.width).abs() < 2.0 &&
        (size.height - last.height).abs() < 2.0) {
      return;
    }
    _ignorePersistUntil =
        DateTime.now().add(const Duration(milliseconds: 600));
    _lastAppliedChromeSize = size;
    await windowManager.setSize(size);
  }

  /// 纠正 desktop_multi_window 默认 1280×720 或历史误保存的过高窗口。
  Future<void> _shrinkWindowToContent() async {
    if (!mounted) return;
    final size = await _measureContentChromeSize();
    if (size == null) return;

    try {
      final bounds = await windowManager.getBounds();
      final tall = bounds.height > size.height + 20.0;
      final wide = bounds.width > size.width + 80.0;
      if (!tall && !wide) return;

      _ignorePersistUntil =
          DateTime.now().add(const Duration(milliseconds: 600));
      _lastAppliedChromeSize = size;
      await windowManager.setSize(size);
      if (mounted) _autoResizeToContent = false;
    } catch (_) {}
  }

  Future<Size?> _measureContentChromeSize() async {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    const fudge = 8.0;
    final w = math
        .min(920.0, math.max(96.0, (box.size.width + fudge).ceilToDouble()));
    final h = math.min(
        1080.0, math.max(40.0, (box.size.height + fudge).ceilToDouble()));
    return Size(w, h);
  }

  bool _showPanelBackground(double bgOpacity) => bgOpacity > 0.001;

  Color _panelFillColor(double bgOpacity) {
    if (_linuxAlphaBackground) {
      return Colors.black;
    }
    // 无 RGBA 合成：用不透明灰度模拟（100%→黑，0%→无底板）。
    final t = bgOpacity.clamp(0.0, 1.0);
    final v = ((1.0 - t) * 255).round();
    return Color.fromARGB(255, v, v, v);
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

    final panel = _buildLyricsPanel(
      align: align,
      rowPad: rowPad,
      rows: rows,
      bgOpacity: bgOpacity,
      dragLocked: dragLocked,
    );

    return IgnorePointer(
      ignoring: dragLocked,
      child: Material(
        type: MaterialType.transparency,
        child: dragLocked
            ? panel
            : DragToResizeArea(
                resizeEdgeSize: 10,
                child: panel,
              ),
      ),
    );
  }

  Widget _buildLyricsPanel({
    required TextAlign align,
    required double rowPad,
    required List<dynamic> rows,
    required double bgOpacity,
    required bool dragLocked,
  }) {
    return Align(
      alignment: Alignment.topCenter,
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
            final lyrics = Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

            final opacity = bgOpacity.clamp(0.0, 1.0);
            return Container(
              key: _contentKey,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (_showPanelBackground(opacity))
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _linuxAlphaBackground
                              ? RepaintBoundary(
                                  child: Opacity(
                                    opacity: opacity,
                                    child: ColoredBox(
                                      color: _panelFillColor(opacity),
                                    ),
                                  ),
                                )
                              : ColoredBox(
                                  color: _panelFillColor(opacity),
                                ),
                        ),
                      ),
                    lyrics,
                  ],
                ),
              ),
            );
          },
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
      final baseStyle = PlatformTypography.lyricLine(
        fontSize: fs,
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
          style: PlatformTypography.lyricLine(fontSize: 18),
          children: children,
        ),
      ),
    );
  }
}
