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

import 'package:yeah_music/services/android_car_lyrics_sync.dart';
import 'package:yeah_music/services/settings_service.dart';

/// 系统通知 / 媒体会话上的「词」按钮等兜底入口。
class AndroidMediaSessionBridge {
  AndroidMediaSessionBridge._();

  /// 通知栏「词」按钮：切换「同步当前歌词行」。
  static Future<void> toggleLyricsSyncFromNotification() async {
    final cur = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    await SettingsService.saveAndroidCarLyricsSyncLyrics(!cur);
    await AndroidCarLyricsSync.applySettingsFromStorage();
    await AndroidCarLyricsSync.republishCurrentTrackMediaItem();
  }
}
