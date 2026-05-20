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

/// 从 [ensureStarted] 起单调计时，供启动页丝滑累加显示。
class AppStartupClock {
  AppStartupClock._();

  static Stopwatch? _sw;

  static void ensureStarted() {
    _sw ??= Stopwatch()..start();
  }

  /// 用户重试启动（如 Hive 失败）时从零重计。
  static void reset() {
    _sw = Stopwatch()..start();
  }

  static Duration get elapsed => _sw?.elapsed ?? Duration.zero;

  /// 浮点秒两位，便于与 Ticker 同帧平滑刷新。
  static String formatSeconds2() {
    final us = elapsed.inMicroseconds;
    final sec = us / 1e6;
    return sec.toStringAsFixed(2);
  }
}
