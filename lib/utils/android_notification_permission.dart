import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Android 13（API 33）起必须声明并运行时请求通知权限。
///
/// 未声明 [POST_NOTIFICATIONS] 或未授权时，部分机型「设置 → 应用 → 通知」入口会呈灰色、不可操作；
/// 播放器的媒体通知也无法正常展示。
Future<void> ensureAndroidPostNotificationsPermissionIfNeeded() async {
  if (!Platform.isAndroid) return;
  final s = await Permission.notification.status;
  if (s.isGranted || s.isLimited || s.isPermanentlyDenied) return;
  await Permission.notification.request();
}
