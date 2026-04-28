import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// macOS 菜单栏歌词（原生 [NSStatusItem]），Flutter 侧通过 MethodChannel 更新文案。
abstract final class MacosMenuBarLyrics {
  static const MethodChannel _ch = MethodChannel('yeah_music/menu_bar_lyrics');

  static bool get supported => !kIsWeb && Platform.isMacOS;

  static Future<void> setVisible(bool visible) async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<void>('setVisible', visible);
    } catch (_) {}
  }

  static Future<void> setText(String text) async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<void>('setText', text);
    } catch (_) {}
  }
}

/// 注册 [reloadFromHive] / [notifySongOrLyricsMaybeChanged] 使用的刷新入口。
final class MacosMenuBarLyricsGlue {
  MacosMenuBarLyricsGlue._();

  static MacosMenuBarLyricsGlue? _instance;
  VoidCallback? _refresh;

  static void register(VoidCallback onRefresh) {
    _instance ??= MacosMenuBarLyricsGlue._();
    _instance!._refresh = onRefresh;
  }

  static void unregister() {
    final i = _instance;
    if (i != null) i._refresh = null;
  }

  /// 设置开关变更后：刷新可见性与子组件状态。
  static Future<void> reloadFromHive() async {
    if (!MacosMenuBarLyrics.supported) return;
    final i = _instance;
    if (i != null && i._refresh != null) i._refresh!();
  }
}
