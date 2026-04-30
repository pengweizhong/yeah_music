import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android：系统「打开方式」将音频交给 Yeah Music 时，原生把 Uri 落地为可读路径；
/// Flutter 调用 [consumePendingPath] 取路径并播放（可多次调用直到返回 null）。
class OpenWithBridge {
  static const _ch = MethodChannel('com.pengwz.yeah_music/open_with');

  static Future<String?> consumePendingPath() async {
    if (kIsWeb) return null;
    if (!Platform.isAndroid) return null;
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
