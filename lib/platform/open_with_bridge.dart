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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 系统「打开方式」将音频交给 Yeah Music 时，原生入队路径；
/// Flutter 调用 [consumePendingPath] 取路径并播放（可多次调用直到返回 null）。
class OpenWithBridge {
  static const _ch = MethodChannel('com.pengwz.yeah_music/open_with');

  static Future<String?> consumePendingPath() async {
    if (kIsWeb) return null;
    if (!Platform.isAndroid && !Platform.isMacOS) return null;
    try {
      final path = await _ch.invokeMethod<String>('consumePending');
      final t = path?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
