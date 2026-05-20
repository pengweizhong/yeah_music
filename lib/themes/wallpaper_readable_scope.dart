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

/// 自定义壁纸模式下，由 [ThemeConfigProvider] 注入的「读得清」前景色（主字 / 次级字）。
///
/// 非壁纸页不挂此 [InheritedWidget]；[GradOnThemedBackground] 回退为按 [Theme] 亮暗取色。
class WallpaperReadableScope extends InheritedWidget {
  const WallpaperReadableScope({
    super.key,
    required this.foreground,
    required this.foregroundMuted,
    required super.child,
  });

  final Color foreground;
  final Color foregroundMuted;

  static WallpaperReadableScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WallpaperReadableScope>();
  }

  @override
  bool updateShouldNotify(WallpaperReadableScope oldWidget) {
    return foreground != oldWidget.foreground ||
        foregroundMuted != oldWidget.foregroundMuted;
  }
}
