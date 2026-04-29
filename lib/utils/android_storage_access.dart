import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android 11+（API 30）起对通用外部路径直接 [File] 读写往往需「所有文件访问」权限。
Future<bool> ensureAndroidManageExternalStorageAccess() async {
  if (!Platform.isAndroid) return true;
  final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  if (sdk < 30) return true;
  final status = await Permission.manageExternalStorage.status;
  if (status.isGranted) return true;
  final req = await Permission.manageExternalStorage.request();
  return req.isGranted;
}

/// 是否为典型「无权访问路径」错误（写入标签 / 删除文件失败时可据此提示用户开权限）。
bool looksLikeAndroidStorageAccessDenied(Object error) {
  if (!Platform.isAndroid) return false;
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    if (code == 13) return true;
    final msg = '${error.message} ${error.path}'.toLowerCase();
    if (msg.contains('permission') ||
        msg.contains('denied') ||
        msg.contains('eacces')) {
      return true;
    }
  }
  final str = error.toString().toLowerCase();
  return str.contains('permission denied') ||
      str.contains('pathaccess') ||
      str.contains('errno = 13');
}
