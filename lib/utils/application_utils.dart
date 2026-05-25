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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

import '../models/song.dart';

/// 同一路径封面 [imageBytes] 更新时通知各 [SongCoverImage]，避免多实例各自 evict + setState 闪烁。
final class _SongCoverPathListenable extends ChangeNotifier {}

/// 空路径占位，兼容无 [NeverListenable] 的 Flutter 版本。
final class _InertListenable implements Listenable {
  const _InertListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

const _inertListenable = _InertListenable();

final Map<String, _SongCoverPathListenable> _songCoverPathListenables = {};

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

  /// 同路径 [SongCoverImage] 共用；封面指纹变化时由 [notifySongCoverChanged] 广播。
  static Listenable songCoverListenable(String songPath) {
    if (songPath.isEmpty) {
      return _inertListenable;
    }
    return _songCoverPathListenables.putIfAbsent(
      songPath,
      () => _SongCoverPathListenable(),
    );
  }

  /// [Song.imageBytes] 指纹变化后调用，各封面 widget 同步 [_displayFp] 而无需重复 evict。
  static void notifySongCoverChanged(String songPath) {
    if (songPath.isEmpty) return;
    _songCoverPathListenables[songPath]?.notifyListeners();
  }

  /// 按需写入 [Song.imageBytes] 后调用。
  /// [keepFingerprint] 非空时仅丢弃其它指纹的缓存，保留已解码条目，减轻多尺寸同时重解码闪烁。
  static void evictSongCoverProvidersForPath(
    String songPath, {
    int? keepFingerprint,
  }) {
    if (songPath.isEmpty) return;
    final prefix = '$songPath#';
    if (keepFingerprint == null || keepFingerprint == 0) {
      _coverProviderCache.removeWhere((k, _) => k.startsWith(prefix));
      return;
    }
    final fpSuffix = '#$keepFingerprint';
    _coverProviderCache.removeWhere(
      (k, _) => k.startsWith(prefix) && !k.endsWith(fpSuffix),
    );
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
    final pathPrefix = '${song.path}#';
    final fpSuffix = '#$fp';
    ImageProvider? reuse;
    var reuseDim = dim + 1;
    for (final e in _coverProviderCache.entries) {
      final k = e.key;
      if (!k.startsWith(pathPrefix) || !k.endsWith(fpSuffix)) continue;
      final dimStr = k.substring(
        pathPrefix.length,
        k.length - fpSuffix.length,
      );
      final cachedDim = int.tryParse(dimStr);
      if (cachedDim == null || cachedDim < dim) continue;
      if (cachedDim < reuseDim) {
        reuseDim = cachedDim;
        reuse = e.value;
      }
    }
    if (reuse != null) {
      return reuse;
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
