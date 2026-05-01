import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Linux 任务栏图标进度（KDE/Plasma 兼容 Unity LauncherEntry DBus 协议）。
abstract final class LinuxTaskbarProgress {
  static const MethodChannel _ch =
      MethodChannel('yeah_music/linux_taskbar_progress');

  static bool get supported => !kIsWeb && Platform.isLinux;

  static Future<void> setProgress({
    required double progress,
    bool visible = true,
  }) async {
    if (!supported) return;
    final clamped = progress.clamp(0.0, 1.0);
    try {
      await _ch.invokeMethod<void>('setProgress', <String, Object?>{
        'progress': clamped,
        'visible': visible,
      });
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<void>('clearProgress');
    } catch (_) {}
  }
}
