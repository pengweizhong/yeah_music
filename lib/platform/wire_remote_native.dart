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

  static Future<String> readDiagnosticsLog() async {
    if (kIsWeb || !Platform.isAndroid) return '';
    try {
      final raw = await _channel.invokeMethod<String>('readDiagnosticsLog');
      return raw ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> clearDiagnosticsLog() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('clearDiagnosticsLog');
    } catch (_) {}
  }

  static Future<void> appendDiagnosticsLog(String message) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('appendDiagnosticsLog', message);
    } catch (_) {}
  }

  static Future<void> setDiagnosticsEnabled(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setDiagnosticsEnabled', enabled);
    } catch (_) {}
  }

  /// 注册：线控连击 [onHeadsetGesture]、独立媒体键 [onMediaDiscrete]（`next` / `previous`）。
  static void attachRemoteHandlers({
    required Future<void> Function(int clickCount) onHeadsetGesture,
    required Future<void> Function(String kind) onMediaDiscrete,
  }) {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_listenerAttached) return;
    _listenerAttached = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'headsetGesture':
          final raw = call.arguments;
          final n = raw is int ? raw : int.tryParse('$raw') ?? 1;
          await onHeadsetGesture(n);
          break;
        case 'mediaDiscrete':
          final kind = call.arguments is String
              ? call.arguments as String
              : '${call.arguments}';
          await onMediaDiscrete(kind);
          break;
        default:
          break;
      }
    });
  }
}
