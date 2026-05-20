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

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

///为macos添加安全书签功能
class BookmarkService {
  static const _channel = MethodChannel('com.pengwz.yeah_music/bookmark');

  /// 打开文件夹选择器并返回路径
  static Future<String?> pickDirectory() async {
    try {
      return await _channel.invokeMethod<String>('pickDirectory');
    } on MissingPluginException catch (_) {
      // 与原生 MethodChannel 绑定异常时，退回 file_picker（同一引擎下已注册）。
      if (Platform.isMacOS) {
        return FilePicker.platform.getDirectoryPath();
      }
      rethrow;
    }
  }

  /// 恢复所有
  static Future<List<String>> restoreAllBookmarks() async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod<List<dynamic>>('restoreBookmark', null);
      return result?.cast<String>() ?? [];
    } on MissingPluginException {
      return [];
    }
  }

  /// 恢复指定路径
  static Future<String?> restoreBookmark(String targetPath) async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod<List<dynamic>>('restoreBookmark', targetPath);
      if (result == null) {
        return null;
      }
      return result.isEmpty ? null : result.first;
    } on MissingPluginException {
      return null;
    }
  }
}
