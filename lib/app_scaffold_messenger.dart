import 'package:flutter/material.dart';

/// 根 [ScaffoldMessenger]，用于无页面 [BuildContext] 时显示 SnackBar（如应用级定时关闭提示）
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
