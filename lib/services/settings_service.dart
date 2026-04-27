import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/utils/hive_utils.dart';

class SettingsService {
  static const String _lyricSettingsKey = 'lyric_settings';
  static const String _playbackModeKey = 'playback_mode';
  static const String _timerDurationKey = 'timer_duration';
  static const String _quickEntryOrderKey = 'quick_entry_order';
  static const String _quickEntryHiddenKey = 'quick_entry_hidden';
  static const String _oneDriveClientIdKey = 'onedrive_client_id';
  static const String _oneDriveMusicRootIdKey = 'onedrive_music_root_id';

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

  static Future<QuickEntryConfig?> loadQuickEntryConfig() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final orderRaw = box.get(_quickEntryOrderKey) as List<dynamic>?;
      final hiddenRaw = box.get(_quickEntryHiddenKey) as List<dynamic>?;
      return QuickEntryConfig.fromStorage(orderRaw, hiddenRaw);
    } catch (e) {
      return null;
    }
  }

  /// OneDrive Azure 应用 ID（与门户中「应用程序(客户端)ID」一致）。
  static Future<String?> loadOneDriveClientId() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_oneDriveClientIdKey) as String?;
      if (v != null && v.trim().isEmpty) return null;
      return v?.trim();
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveOneDriveClientId(String? value) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (value == null || value.trim().isEmpty) {
        await box.delete(_oneDriveClientIdKey);
      } else {
        await box.put(_oneDriveClientIdKey, value.trim());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (value == null || value.trim().isEmpty) {
          await box.delete(_oneDriveClientIdKey);
        } else {
          await box.put(_oneDriveClientIdKey, value.trim());
        }
      } catch (_) {}
    }
  }

  /// 进入 OneDrive 浏览页时的根文件夹 item id；`null` 表示个人网盘根「/」。
  static Future<String?> loadOneDriveMusicRootId() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_oneDriveMusicRootIdKey) as String?;
      if (v != null && v.trim().isEmpty) return null;
      return v?.trim();
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveOneDriveMusicRootId(String? itemId) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (itemId == null || itemId.trim().isEmpty) {
        await box.delete(_oneDriveMusicRootIdKey);
      } else {
        await box.put(_oneDriveMusicRootIdKey, itemId.trim());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (itemId == null || itemId.trim().isEmpty) {
          await box.delete(_oneDriveMusicRootIdKey);
        } else {
          await box.put(_oneDriveMusicRootIdKey, itemId.trim());
        }
      } catch (_) {}
    }
  }

  static Future<void> saveQuickEntryConfig(QuickEntryConfig c) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      c.normalizeInPlace();
      await box.put(_quickEntryOrderKey, c.order);
      await box.put(_quickEntryHiddenKey, c.hidden.toList());
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        c.normalizeInPlace();
        await box.put(_quickEntryOrderKey, c.order);
        await box.put(_quickEntryHiddenKey, c.hidden.toList());
      } catch (_) {}
    }
  }
}
