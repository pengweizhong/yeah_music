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
import 'package:yeah_music/widgets/song_list_cover.dart';

/// 艺术家 / 专辑浏览列表左侧：优先展示曲库内嵌封面字节，否则占位 + [fallbackIcon]。
class LibraryIndexCoverLeading extends StatelessWidget {
  const LibraryIndexCoverLeading({
    super.key,
    this.coverBytes,
    required this.fallbackIcon,
    this.size = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.iconColor,
  });

  final Uint8List? coverBytes;
  final IconData fallbackIcon;
  final double size;
  final BorderRadius borderRadius;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? Colors.white.withValues(alpha: 0.55);
    final b = coverBytes;
    if (b != null && b.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(
            b,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _fallbackShell(fallbackIcon, fg, size, borderRadius),
          ),
        ),
      );
    }
    return _fallbackShell(fallbackIcon, fg, size, borderRadius);
  }
}

Widget _fallbackShell(
  IconData icon,
  Color fg,
  double size,
  BorderRadius borderRadius,
) {
  return ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: songListCoverPlaceholderColor(),
        child: Icon(icon, color: fg, size: size * 0.5),
      ),
    ),
  );
}
