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

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Graph 文件夹名不允许的字符替换为 `_`，并限制长度。
String sanitizeOneDriveSyncFolderSegment(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    s = 'Device';
  }
  if (s.length > 96) {
    s = s.substring(0, 96);
  }
  return s;
}

/// 用于云端目录 `…/设备型号/时间戳/` 的设备展示名。
Future<String> resolveOneDriveSyncDeviceFolderLabel() async {
  if (kIsWeb) {
    return 'Web';
  }
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await plugin.androidInfo;
      final m =
          '${a.manufacturer} ${a.model}'.trim().replaceAll(RegExp(r'\s+'), ' ');
      return m.isEmpty ? 'Android' : m;
    }
    if (Platform.isIOS) {
      final i = await plugin.iosInfo;
      final name = i.utsname.machine.trim();
      return name.isEmpty ? 'iOS' : name;
    }
    if (Platform.isMacOS) {
      final m = await plugin.macOsInfo;
      final name = m.model.trim();
      return name.isEmpty ? 'macOS' : name;
    }
    if (Platform.isWindows) {
      final w = await plugin.windowsInfo;
      final name = w.computerName.trim();
      return name.isEmpty ? 'Windows' : name;
    }
    if (Platform.isLinux) {
      final l = await plugin.linuxInfo;
      final name = (l.prettyName.isNotEmpty ? l.prettyName : l.name).trim();
      return name.isEmpty ? 'Linux' : name;
    }
  } catch (_) {}
  return Platform.operatingSystem;
}
