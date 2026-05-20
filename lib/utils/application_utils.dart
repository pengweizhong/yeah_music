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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

import '../models/song.dart';

class ApplicationUtils {
  /// 弹出软件的「关于」对话框（文案随界面语言）。
  static void showAboutDialog(BuildContext context) {
    showAppAboutDialog(context);
  }

  /// 自定义提示框（与全局 [showAppCustomDialog] 同一套磨砂 UI）。
  static Future<void> alertDialog(
    BuildContext context,
    String title,
    List<Widget> children,
    List<Widget> textButtons,
  ) {
    return showAppCustomDialog<void>(
      context: context,
      title: title,
      bodyChildren: children,
      actions: textButtons,
    );
  }

  /// 按路径与边长复用 [ImageProvider]，避免滑条反复 build 时创建新 [ResizeImage] 导致反复解码。
  static final Map<String, ImageProvider> _coverProviderCache = {};
  static const int _coverProviderMax = 500;

  /// 按需写入 [Song.imageBytes] 后调用，丢弃该曲路径下各尺寸缓存条目，避免继续用占位 [AssetImage]。
  static void evictSongCoverProvidersForPath(String songPath) {
    if (songPath.isEmpty) return;
    final prefix = '$songPath#';
    _coverProviderCache.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// [Uint8List.hashCode] 按对象身份变化，不能用于区分「内容相同的新缓冲区」。
  /// 与 [path]、边长一起组成 [getImageCoverProvider] 的缓存键，并在列表 [Image] 上作稳定 [ValueKey]。
  static int coverBytesFingerprint(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return 0;
    final len = bytes.length;
    var h = len;
    final n = len < 4096 ? len : 4096;
    for (var i = 0; i < n; i++) {
      h = (h * 31 + bytes[i]) & 0x3fffffff;
    }
    h ^= bytes[len - 1];
    return h;
  }

  /// 获取歌曲封面 [ImageProvider]。
  /// 内嵌封面使用 [ResizeImage] 按 [size]×[devicePixelRatio] 降采样解码，避免列表滚动时全尺寸解码进显存。
  static ImageProvider getImageCoverProvider(
    Song song, {
    double size = 32,
    double devicePixelRatio = 2.0,
  }) {
    if (song.imageBytes == null) {
      if (size < 20) {
        return AssetImage("assets/icons/icon_16x16@2x.png");
      }
      if (size < 40) {
        return AssetImage("assets/icons/icon_32x32@2x.png");
      }
      return AssetImage("assets/icons/icon_512x512@2x.png");
    }
    final dim = (size * devicePixelRatio).round().clamp(32, 2048);
    final fp = coverBytesFingerprint(song.imageBytes);
    final key = '${song.path}#$dim#$fp';
    final existing = _coverProviderCache[key];
    if (existing != null) {
      return existing;
    }
    if (_coverProviderCache.length >= _coverProviderMax) {
      _coverProviderCache.remove(_coverProviderCache.keys.first);
    }
    final base = MemoryImage(song.imageBytes!);
    final created = ResizeImage(
      base,
      width: dim,
      height: dim,
      allowUpscaling: false,
    );
    _coverProviderCache[key] = created;
    return created;
  }
}
