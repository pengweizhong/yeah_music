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

import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Android 13（API 33）起必须声明并运行时请求通知权限。
///
/// 未声明 [POST_NOTIFICATIONS] 或未授权时，部分机型「设置 → 应用 → 通知」入口会呈灰色、不可操作；
/// 播放器的媒体通知也无法正常展示。
/// 返回 `true` 表示已具备发通知权限（含 limited）；`false` 表示用户拒绝或未授权。
Future<bool> ensureAndroidPostNotificationsPermissionIfNeeded() async {
  if (!Platform.isAndroid) return true;
  var s = await Permission.notification.status;
  if (s.isGranted || s.isLimited) return true;
  if (s.isPermanentlyDenied) return false;
  s = await Permission.notification.request();
  return s.isGranted || s.isLimited;
}
