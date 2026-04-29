/// OneDrive 云端备份文件名用时间戳（年月日 + 时分秒，本地时区）。
///
/// 形如 `2026-04-29_14-35-06`（文件名安全，不含 `/` `:`）。
String formatOneDriveBackupFileStamp(DateTime local) {
  String z2(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${z2(local.month)}-${z2(local.day)}_${z2(local.hour)}-'
      '${z2(local.minute)}-${z2(local.second)}';
}
