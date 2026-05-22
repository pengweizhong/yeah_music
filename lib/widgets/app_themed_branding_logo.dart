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

import 'package:flutter/material.dart';

/// 应用内展示的 Yeah Music Logo：随主题切换资源。
///
/// - 浅色： [assetPathLight]（白底完整 logo）
/// - 深色： [assetPathDark]（透明底 logo）+ 黑底衬底
class AppThemedBrandingLogo extends StatelessWidget {
  const AppThemedBrandingLogo({
    super.key,
    required this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    /// 为 true 时始终使用透明底 [assetPathDark]（适合渐变 / 壁纸上的 AppBar）。
    this.useTransparentAsset = false,
  });

  final double height;
  final double? width;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final bool useTransparentAsset;

  /// 日间 / 浅色主题：自带白底。
  static const String assetPathLight = 'assets/icons/yeah_music.png';

  /// 夜间 / 深色主题：透明底，需配合黑底。
  static const String assetPathDark = 'assets/icons/yeah_music1.png';

  /// 兼容旧引用（默认浅色资源路径）。
  static const String assetPath = assetPathLight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkAsset = useTransparentAsset || isDark;
    final asset = useDarkAsset ? assetPathDark : assetPathLight;
    final image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
    if (!isDark || useTransparentAsset) return image;
    return ColoredBox(
      color: Colors.black,
      child: image,
    );
  }
}
