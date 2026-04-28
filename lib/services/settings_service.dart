import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
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
  static const String _oneDriveIndexFoldersKey = 'onedrive_index_folders';
  static const String _oneDriveIndexTracksKey = 'onedrive_index_tracks';
  static const String _oneDriveIndexAtKey = 'onedrive_index_at_iso';
  static const String _oneDriveCloudSortTypeKey = 'onedrive_cloud_sort_type';
  static const String _oneDriveCloudSortAscKey = 'onedrive_cloud_sort_asc';

  /// macOS 是否在菜单栏显示当前歌词。
  static const String _macosMenuBarLyricsKey = 'macos_menu_bar_lyrics';

  /// 桌面端是否在应用内显示悬浮单行歌词（macOS / Windows / Linux）。
  static const String _desktopFloatingLyricsKey = 'desktop_floating_lyrics';

  static const String _desktopFloatingLyricsBgOpacityKey =
      'desktop_floating_lyrics_bg_opacity';
  static const String _desktopFloatingLyricsLinesBeforeKey =
      'desktop_floating_lyrics_lines_before';
  static const String _desktopFloatingLyricsLinesAfterKey =
      'desktop_floating_lyrics_lines_after';
  static const String _desktopFloatingLyricsLockedKey =
      'desktop_floating_lyrics_locked';

  /// Android：车载 / 锁屏 / 蓝牙等媒体会话增强（封面、歌词行、队列切歌）。
  static const String _androidCarLyricsEnabledKey = 'android_car_lyrics_enabled';
  static const String _androidCarLyricsShowCoverKey =
      'android_car_lyrics_show_cover';
  static const String _androidCarLyricsSyncLyricsKey =
      'android_car_lyrics_sync_lyrics';

  static const double desktopFloatingLyricsBgOpacityDefault = 0.42;
  static const int desktopFloatingLyricsLinesBeforeDefault = 2;
  static const int desktopFloatingLyricsLinesAfterDefault = 2;

  static const double _desktopBgOpacityMin = 0.0;
  static const double _desktopBgOpacityMax = 0.92;
  static const int _desktopLinesRangeMax = 20;

  /// OneDrive 云端曲库列表的排序偏好。
  static Future<({CloudTrackSortType type, bool asc})> loadOneDriveCloudListSort() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_oneDriveCloudSortTypeKey) as String?;
      final ascRaw = box.get(_oneDriveCloudSortAscKey, defaultValue: true);
      var asc = true;
      if (ascRaw is bool) {
        asc = ascRaw;
      }
      var t = CloudTrackSortType.fileName;
      if (raw != null) {
        for (final v in CloudTrackSortType.values) {
          if (v.name == raw) {
            t = v;
            break;
          }
        }
      }
      return (type: t, asc: asc);
    } catch (_) {
      return (type: CloudTrackSortType.fileName, asc: true);
    }
  }

  static Future<void> saveOneDriveCloudListSort(CloudTrackSortType type, bool ascending) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_oneDriveCloudSortTypeKey, type.name);
      await box.put(_oneDriveCloudSortAscKey, ascending);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_oneDriveCloudSortTypeKey, type.name);
        await box.put(_oneDriveCloudSortAscKey, ascending);
      } catch (_) {}
    }
  }

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

  /// 参与云端曲库索引的根文件夹（Graph item id + 展示名）。
  static Future<List<Map<dynamic, dynamic>>> loadOneDriveIndexFolders() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_oneDriveIndexFoldersKey);
      if (raw is! List) return [];
      return raw.whereType<Map>().map((e) => Map<dynamic, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveOneDriveIndexFolders(List<Map<String, dynamic>> folders) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_oneDriveIndexFoldersKey, folders);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_oneDriveIndexFoldersKey, folders);
      } catch (_) {}
    }
  }

  static Future<List<Map<dynamic, dynamic>>> loadOneDriveIndexTracks() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_oneDriveIndexTracksKey);
      if (raw is! List) return [];
      return raw.whereType<Map>().map((e) => Map<dynamic, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveOneDriveIndexTracks(List<Map<String, dynamic>> tracks) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_oneDriveIndexTracksKey, tracks);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_oneDriveIndexTracksKey, tracks);
      } catch (_) {}
    }
  }

  static Future<DateTime?> loadOneDriveIndexCompletedAt() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final s = box.get(_oneDriveIndexAtKey) as String?;
      return s == null ? null : DateTime.tryParse(s.trim());
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveOneDriveIndexCompletedAt(DateTime? t) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (t == null) {
        await box.delete(_oneDriveIndexAtKey);
      } else {
        await box.put(_oneDriveIndexAtKey, t.toIso8601String());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (t == null) {
          await box.delete(_oneDriveIndexAtKey);
        } else {
          await box.put(_oneDriveIndexAtKey, t.toIso8601String());
        }
      } catch (_) {}
    }
  }

  static Future<bool> loadMacosMenuBarLyricsEnabled() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_macosMenuBarLyricsKey, defaultValue: false) as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveMacosMenuBarLyricsEnabled(bool enabled) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_macosMenuBarLyricsKey, enabled);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_macosMenuBarLyricsKey, enabled);
      } catch (_) {}
    }
  }

  static Future<bool> loadDesktopFloatingLyricsEnabled() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_desktopFloatingLyricsKey, defaultValue: false) as bool? ??
          false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveDesktopFloatingLyricsEnabled(bool enabled) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_desktopFloatingLyricsKey, enabled);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_desktopFloatingLyricsKey, enabled);
      } catch (_) {}
    }
  }

  static Future<double> loadDesktopFloatingLyricsBgOpacity() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_desktopFloatingLyricsBgOpacityKey);
      if (v is num) {
        return v
            .toDouble()
            .clamp(_desktopBgOpacityMin, _desktopBgOpacityMax);
      }
      return desktopFloatingLyricsBgOpacityDefault;
    } catch (_) {
      return desktopFloatingLyricsBgOpacityDefault;
    }
  }

  static Future<void> saveDesktopFloatingLyricsBgOpacity(double opacity) async {
    final o = opacity.clamp(_desktopBgOpacityMin, _desktopBgOpacityMax);
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_desktopFloatingLyricsBgOpacityKey, o);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_desktopFloatingLyricsBgOpacityKey, o);
      } catch (_) {}
    }
  }

  static Future<int> loadDesktopFloatingLyricsLinesBefore() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_desktopFloatingLyricsLinesBeforeKey);
      if (v is int) {
        return v.clamp(0, _desktopLinesRangeMax);
      }
      if (v is num) {
        return v.toInt().clamp(0, _desktopLinesRangeMax);
      }
      return desktopFloatingLyricsLinesBeforeDefault;
    } catch (_) {
      return desktopFloatingLyricsLinesBeforeDefault;
    }
  }

  static Future<void> saveDesktopFloatingLyricsLinesBefore(int n) async {
    final v = n.clamp(0, _desktopLinesRangeMax);
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_desktopFloatingLyricsLinesBeforeKey, v);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_desktopFloatingLyricsLinesBeforeKey, v);
      } catch (_) {}
    }
  }

  static Future<int> loadDesktopFloatingLyricsLinesAfter() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_desktopFloatingLyricsLinesAfterKey);
      if (v is int) {
        return v.clamp(0, _desktopLinesRangeMax);
      }
      if (v is num) {
        return v.toInt().clamp(0, _desktopLinesRangeMax);
      }
      return desktopFloatingLyricsLinesAfterDefault;
    } catch (_) {
      return desktopFloatingLyricsLinesAfterDefault;
    }
  }

  static Future<void> saveDesktopFloatingLyricsLinesAfter(int n) async {
    final v = n.clamp(0, _desktopLinesRangeMax);
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_desktopFloatingLyricsLinesAfterKey, v);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_desktopFloatingLyricsLinesAfterKey, v);
      } catch (_) {}
    }
  }

  static Future<bool> loadDesktopFloatingLyricsDragLocked() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_desktopFloatingLyricsLockedKey, defaultValue: false)
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveDesktopFloatingLyricsDragLocked(bool locked) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_desktopFloatingLyricsLockedKey, locked);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_desktopFloatingLyricsLockedKey, locked);
      } catch (_) {}
    }
  }

  static Future<bool> loadAndroidCarLyricsEnabled() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_androidCarLyricsEnabledKey, defaultValue: false) as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveAndroidCarLyricsEnabled(bool enabled) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_androidCarLyricsEnabledKey, enabled);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_androidCarLyricsEnabledKey, enabled);
      } catch (_) {}
    }
  }

  static Future<bool> loadAndroidCarLyricsShowCover() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_androidCarLyricsShowCoverKey, defaultValue: true) as bool? ??
          true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveAndroidCarLyricsShowCover(bool show) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_androidCarLyricsShowCoverKey, show);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_androidCarLyricsShowCoverKey, show);
      } catch (_) {}
    }
  }

  static Future<bool> loadAndroidCarLyricsSyncLyrics() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return box.get(_androidCarLyricsSyncLyricsKey, defaultValue: true) as bool? ??
          true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveAndroidCarLyricsSyncLyrics(bool sync) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_androidCarLyricsSyncLyricsKey, sync);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_androidCarLyricsSyncLyricsKey, sync);
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
