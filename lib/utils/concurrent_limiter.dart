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
import 'dart:collection';

/// 计数信号量：限制同时执行的异步任务数量（用于磁盘 readMetadata 等）。
class ConcurrentLimiter {
  ConcurrentLimiter(this.maxConcurrent) : _available = maxConcurrent;

  final int maxConcurrent;
  int _available;
  final Queue<Completer<void>> _waiting = Queue();

  Future<void> acquire() async {
    while (_available == 0) {
      final c = Completer<void>();
      _waiting.addLast(c);
      await c.future;
    }
    _available--;
  }

  void release() {
    _available++;
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    }
  }
}
