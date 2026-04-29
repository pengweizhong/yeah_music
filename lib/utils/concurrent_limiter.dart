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
