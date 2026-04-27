import 'dart:async';

import 'package:flutter/foundation.dart';

/// 启动/欢迎页中间轮播的「假加载」提示语（不反映真实 I/O 阶段，仅作观感）。
const List<String> kWelcomeFakeLoadHints = [
  '正在加载用户设置',
  '正在加载曲库',
  '正在加载歌单',
  '正在加载其他数据',
  '正在完成初始化',
];

const Duration kWelcomeFakeHintInterval = Duration(milliseconds: 1400);

/// 依序轮播 [kWelcomeFakeLoadHints]；[stop] 后不再更新 [hint].
class WelcomeFakeStatusRotator {
  WelcomeFakeStatusRotator() : hint = ValueNotifier<String>(kWelcomeFakeLoadHints.first);

  final ValueNotifier<String> hint;
  Timer? _t;

  void start() {
    _t?.cancel();
    _t = null;
    hint.value = kWelcomeFakeLoadHints.first;
    var i = 0;
    _t = Timer.periodic(kWelcomeFakeHintInterval, (_) {
      i = (i + 1) % kWelcomeFakeLoadHints.length;
      hint.value = kWelcomeFakeLoadHints[i];
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
