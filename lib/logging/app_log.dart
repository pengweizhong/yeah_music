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

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/logging/diagnostic_log_store.dart';

class _DiagnosticLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    unawaited(DiagnosticLogStore.appendLines(event.lines));
  }
}

/// 全应用统一 [Logger]。
///
/// 级别约定：
/// - `t`：极细，默认关闭（需将 [level] 调到 [Level.trace] 才全量，一般不用）
/// - `d`：开发排障（换源、排序、单目录等），**仅 [kDebugMode] 下**输出
/// - `i`：重要生命周期、用户可感知的成功操作
/// - `w`：可恢复问题、降级
/// - `e` / `f`：失败、致命；尽量带 [LogEvent.error] 与 [LogEvent.stackTrace]
///
/// [kDebugMode] 为 true 时用 [DevelopmentFilter]；否则用 [ProductionFilter]，
/// 只输出 [Level.info] 及以上，避免发版后刷屏与无意义 [d] 开销，同时仍保留启动、错误行。
final Logger appLog = Logger(
  filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  level: kDebugMode ? Level.debug : Level.info,
  printer: kDebugMode
      ? PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 6,
          lineLength: 100,
          printEmojis: false,
        )
      : SimplePrinter(printTime: true, colors: false),
  output: MultiOutput([ConsoleOutput(), _DiagnosticLogOutput()]),
);
