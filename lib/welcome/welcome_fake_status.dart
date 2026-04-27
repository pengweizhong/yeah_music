import 'dart:async';

import 'package:flutter/foundation.dart';

const Duration kWelcomeFakeHintInterval = Duration(milliseconds: 1400);

/// 依序轮播 [hints]；[stop] 后不再更新 [hint]。
class WelcomeFakeStatusRotator {
  WelcomeFakeStatusRotator(List<String> hints)
      : assert(hints.isNotEmpty),
        _hints = List<String>.from(hints),
        hint = ValueNotifier<String>(hints.first);

  List<String> _hints;
  final ValueNotifier<String> hint;
  Timer? _t;

  void setHintsIfChanged(List<String> next) {
    if (next.isEmpty) {
      return;
    }
    if (next.length == _hints.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if (next[i] != _hints[i]) {
          same = false;
          break;
        }
      }
      if (same) {
        return;
      }
    }
    _hints = List<String>.from(next);
    stop();
    hint.value = _hints.first;
    start();
  }

  void start() {
    if (_hints.isEmpty) {
      return;
    }
    _t?.cancel();
    _t = null;
    hint.value = _hints.first;
    var i = 0;
    _t = Timer.periodic(kWelcomeFakeHintInterval, (_) {
      i = (i + 1) % _hints.length;
      hint.value = _hints[i];
    });
  }

  /// 停止后从首条重新轮播（用于重试等场景）。
  void restart() {
    stop();
    start();
  }

  void stop() {
    _t?.cancel();
    _t = null;
  }

  void dispose() {
    stop();
    hint.dispose();
  }
}
