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
