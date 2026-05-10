import 'package:flutter/material.dart';

/// 根 [ScaffoldMessenger]，用于无页面 [BuildContext] 时显示 SnackBar（如应用级定时关闭提示）
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 根 [Navigator]，用于 Snackbar action 等延迟回调中打开页面，避免原页面 context 已失效。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
