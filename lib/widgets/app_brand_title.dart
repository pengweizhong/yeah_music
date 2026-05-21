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
import 'package:yeah_music/themes/platform_typography.dart';
import 'package:yeah_music/widgets/app_themed_branding_logo.dart';

/// AppBar / 侧栏等处的 Logo + 产品名一行。
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({
    super.key,
    required this.title,
    this.logoSize = 28,
    this.titleStyle,
    /// 渐变 / 壁纸主页：透明底 logo，避免白底方块。
    this.onGradientBackground = false,
  });

  final String title;
  final double logoSize;
  final TextStyle? titleStyle;
  final bool onGradientBackground;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(logoSize * 0.28),
          child: AppThemedBrandingLogo(
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            useTransparentAsset: onGradientBackground,
          ),
        ),
        SizedBox(width: logoSize * 0.36),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.withPlatformFont,
          ),
        ),
      ],
    );
  }
}
