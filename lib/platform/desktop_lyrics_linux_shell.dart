// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Linux 歌词子窗：GTK RGBA 合成与透明背景。
abstract final class DesktopLyricsLinuxShell {
  static const MethodChannel _channel =
      MethodChannel('yeah_music/desktop_lyrics_shell');

  static Future<void> ensureTransparent() async {
    if (!Platform.isLinux) return;
    try {
      await _channel.invokeMethod<void>('ensureTransparent');
    } catch (_) {}
  }

  /// 当前屏幕是否支持 RGBA 透明合成（Wayland 部分环境可能为 false）。
  static Future<bool> isCompositingAvailable() async {
    if (!Platform.isLinux) return true;
    try {
      final v = await _channel.invokeMethod<bool>('isCompositingAvailable');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 锁定歌词后鼠标穿透到下层窗口（需 KDE/X11 等合成器）。
  static Future<void> setPassThrough(bool passThrough) async {
    if (!Platform.isLinux) return;
    try {
      await _channel.invokeMethod<void>('setPassThrough', <String, dynamic>{
        'passThrough': passThrough,
      });
    } catch (_) {}
  }

  /// 在 show 前/后通过 GTK 直接移动子窗（冷启动恢复位置比纯 Dart 更可靠）。
  static Future<void> setWindowBounds(Rect bounds) async {
    if (!Platform.isLinux) return;
    try {
      await _channel.invokeMethod<void>('setWindowBounds', <String, dynamic>{
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      });
    } catch (_) {}
  }
}
