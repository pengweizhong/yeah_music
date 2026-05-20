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

/// OneDrive 云端备份文件名用时间戳（年月日 + 时分秒，本地时区）。
///
/// 形如 `2026-04-29_14-35-06`（文件名安全，不含 `/` `:`）。
String formatOneDriveBackupFileStamp(DateTime local) {
  String z2(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${z2(local.month)}-${z2(local.day)}_${z2(local.hour)}-'
      '${z2(local.minute)}-${z2(local.second)}';
}

/// 同步会话文件夹名：`YYYYMMDDTHHmmss`（本地时区，不含分隔符）。
String formatOneDriveSyncSessionFolderStamp(DateTime local) {
  String z2(int n) => n.toString().padLeft(2, '0');
  return '${local.year}${z2(local.month)}${z2(local.day)}'
      'T${z2(local.hour)}${z2(local.minute)}${z2(local.second)}';
}

DateTime? parseLegacyOneDriveBackupFileStamp(String stamp) {
  final re = RegExp(r'^(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})$');
  final m = re.firstMatch(stamp.trim());
  if (m == null) return null;
  final y = int.tryParse(m.group(1)!);
  final mo = int.tryParse(m.group(2)!);
  final d = int.tryParse(m.group(3)!);
  final h = int.tryParse(m.group(4)!);
  final mi = int.tryParse(m.group(5)!);
  final s = int.tryParse(m.group(6)!);
  if (y == null || mo == null || d == null || h == null || mi == null || s == null) {
    return null;
  }
  try {
    return DateTime(y, mo, d, h, mi, s);
  } catch (_) {
    return null;
  }
}

DateTime? parseOneDriveSyncSessionFolderStamp(String stamp) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$')
      .firstMatch(stamp.trim());
  if (m == null) return null;
  final y = int.tryParse(m.group(1)!);
  final mo = int.tryParse(m.group(2)!);
  final d = int.tryParse(m.group(3)!);
  final h = int.tryParse(m.group(4)!);
  final mi = int.tryParse(m.group(5)!);
  final s = int.tryParse(m.group(6)!);
  if (y == null || mo == null || d == null || h == null || mi == null || s == null) {
    return null;
  }
  try {
    return DateTime(y, mo, d, h, mi, s);
  } catch (_) {
    return null;
  }
}
