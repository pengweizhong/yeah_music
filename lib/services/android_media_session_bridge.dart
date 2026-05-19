import 'package:yeah_music/services/android_car_lyrics_sync.dart';
import 'package:yeah_music/services/settings_service.dart';

/// 系统通知 / 媒体会话上的「词」按钮等兜底入口。
class AndroidMediaSessionBridge {
  AndroidMediaSessionBridge._();

  static Future<void> toggleLyricsSyncFromNotification() async {
    final cur = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    await SettingsService.saveAndroidCarLyricsSyncLyrics(!cur);
    await AndroidCarLyricsSync.refreshSyncEnabled();
    await AndroidCarLyricsSync.republishCurrentTrackMediaItem();
  }
}
