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

/// 根 [ScaffoldMessenger]，用于无页面 [BuildContext] 时显示 SnackBar（如应用级定时关闭提示）
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 根 [Navigator]，用于 Snackbar action 等延迟回调中打开页面，避免原页面 context 已失效。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
