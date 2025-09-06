import 'dart:async';

import 'package:flutter/services.dart';

///为macos添加安全书签功能
class BookmarkService {
  static const _channel = MethodChannel('com.pengwz.yeah_music/bookmark');

  /// 打开文件夹选择器并返回路径
  static Future<String?> pickDirectory() async {
    return await _channel.invokeMethod<String>('pickDirectory');
  }

  /// 恢复所有
  static Future<List<String>> restoreAllBookmarks() async {
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>('restoreBookmark', null);
    return result?.cast<String>() ?? [];
  }

  /// 恢复指定路径
  static Future<String?> restoreBookmark(String targetPath) async {
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>('restoreBookmark', targetPath);
    if (result == null) {
      return null;
    }
    return result.isEmpty ? null : result.first;
  }
}
