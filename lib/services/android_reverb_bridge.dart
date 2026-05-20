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

import 'package:flutter/services.dart';

/// 曾尝试通过 [PresetReverb] 做系统混响；与 ExoPlayer 未做 aux 绑定时会破坏音量路由，故 Dart 侧不再下发混响。
///
/// 仍保留 [release] / [applyStored] 供 [MusicService] 在换源与销毁时调用，向原生发 **release**（无操作）以保持接口稳定。
class AndroidReverbBridge {
  AndroidReverbBridge._();

  static const MethodChannel _ch = MethodChannel('yeah_music/android_reverb');

  static Future<void> applyStored(int? _) async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod<void>('release');
    } catch (_) {}
  }

  static Future<void> release() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod<void>('release');
    } catch (_) {}
  }
}
