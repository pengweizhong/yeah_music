import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';

/// Android：与 MainActivity / [WireRemoteHolder] 的 MethodChannel。
class WireRemoteNative {
  static const _channel = MethodChannel('yeah_music/wire_remote');
  static bool _listenerAttached = false;

  static Future<void> configure(WireRemoteControlConfig c) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('configure', c.toNativeMap());
    } catch (_) {}
  }

  /// 注册来自原生线控连击的回调（仅一次）。
  static void attachHeadsetGestureHandler(
    Future<void> Function(int clickCount) onHeadsetGesture,
  ) {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_listenerAttached) return;
    _listenerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'headsetGesture') {
        final raw = call.arguments;
        final n = raw is int ? raw : int.tryParse('$raw') ?? 1;
        await onHeadsetGesture(n);
      }
    });
  }
}
