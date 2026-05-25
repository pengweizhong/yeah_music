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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yeah_music/services/linux_taskbar_progress.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/widgets/desktop_floating_lyrics_host.dart';

/// 桌面退出是否已由 [requestLinuxDesktopQuit] 接管（避免 dispose 里重复销毁托盘）。
bool linuxDesktopQuitInProgress = false;

/// 有序退出：先停播/关子窗口/销毁托盘，再交给 Flutter 正常收尾。
///
/// Linux 上勿调用 [windowManager.destroy]：会触发
/// `FlutterEngineRemoveView`（implicit view 不可移除）并在 epoxy 中断言失败。
/// 主窗口关闭与托盘退出均使用 [SystemNavigator.pop]。
Future<void> requestLinuxDesktopQuit() async {
  if (kIsWeb) return;
  if (!Platform.isLinux && !Platform.isWindows) return;
  if (linuxDesktopQuitInProgress) return;
  linuxDesktopQuitInProgress = true;

  try {
    await EmbeddedSongMetadataPersistScheduler.flushPending();
  } catch (_) {}

  if (Platform.isLinux) {
    try {
      await LinuxTaskbarProgress.clear();
    } catch (_) {}
  }

  try {
    await MusicService().stop();
  } catch (_) {}

  try {
    await DesktopFloatingLyricsGlue.shutdownBeforeQuit()
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    try {
      await DesktopFloatingLyricsGlue.forceCloseAllLyricsWindows();
    } catch (_) {}
  }

  try {
    await trayManager.destroy();
  } catch (_) {}

  // 给原生插件释放 GL/DBus 的短暂窗口，避免与 GTK 析构叠在 libepoxy assert 上。
  await Future<void>.delayed(const Duration(milliseconds: 80));

  try {
    await windowManager.setPreventClose(false);
  } catch (_) {}

  if (Platform.isWindows) {
    try {
      await windowManager.destroy();
    } catch (_) {}
    exit(0);
  }

  SystemNavigator.pop();
}
