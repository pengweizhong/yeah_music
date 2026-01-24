import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/utils/hive_utils.dart';

class SettingsService {
  static const String _lyricSettingsKey = 'lyric_settings';
  static const String _playbackModeKey = 'playback_mode';
  static const String _timerDurationKey = 'timer_duration';

  /// 保存歌词设置
  static Future<void> saveLyricSettings(LyricSettings settings) async {
    try {
      // 使用dynamic类型避免类型冲突
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_lyricSettingsKey, settings);
    } catch (e) {
      // 如果失败，尝试重新打开box
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_lyricSettingsKey, settings);
      } catch (_) {
        // 忽略错误
      }
    }
  }

  /// 加载歌词设置
  static Future<LyricSettings?> loadLyricSettings() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_lyricSettingsKey) as LyricSettings?;
    } catch (e) {
      return null;
    }
  }

  /// 保存播放模式
  static Future<void> savePlaybackMode(PlaybackMode mode) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackModeKey, mode.value);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackModeKey, mode.value);
      } catch (_) {}
    }
  }

  /// 加载播放模式
  static Future<PlaybackMode> loadPlaybackMode() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final value = box.get(_playbackModeKey, defaultValue: 0) as int?;
      return PlaybackModeExtension.fromValue(value ?? 0);
    } catch (e) {
      return PlaybackMode.sequential;
    }
  }

  /// 保存定时关闭时长（分钟）
  static Future<void> saveTimerDuration(int minutes) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_timerDurationKey, minutes);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_timerDurationKey, minutes);
      } catch (_) {}
    }
  }

  /// 加载定时关闭时长（分钟）
  static Future<int> loadTimerDuration() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_timerDurationKey, defaultValue: 30) as int? ?? 30;
    } catch (e) {
      return 30;
    }
  }
}
