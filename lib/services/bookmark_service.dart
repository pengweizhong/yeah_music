import 'dart:async';

import 'package:flutter/services.dart';
///为macos添加安全书签功能
class BookmarkService {
  static const _channel = MethodChannel('com.pengwz.yeah_music/bookmark');

  /// 打开文件夹选择器并返回路径
  static Future<String?> pickDirectory() async {
    return await _channel.invokeMethod<String>('pickDirectory');
  }

  /// 恢复上次保存的书签并返回路径（如果可用）
  static Future<String?> restoreBookmark() async {
    return await _channel.invokeMethod<String>('restoreBookmark');
  }
}
