import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/playback_shortcut_config.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';
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
  static const String _oneDriveCloudAppFolderIdKey = 'onedrive_cloud_app_folder_id';
  static const String _oneDriveCloudAppFolderLabelKey = 'onedrive_cloud_app_folder_label';
  static const String _oneDriveMusicUploadFolderIdKey = 'onedrive_music_upload_folder_id';
  static const String _oneDriveMusicUploadFolderLabelKey = 'onedrive_music_upload_folder_label';
  static const String _oneDriveLocalDownloadDirKey = 'onedrive_local_download_dir';
  static const String _oneDriveSyncSettingsKey = 'onedrive_sync_settings_v1';
  static const String _oneDriveIndexFoldersKey = 'onedrive_index_folders';
  static const String _oneDriveIndexTracksKey = 'onedrive_index_tracks';
  static const String _oneDriveIndexAtKey = 'onedrive_index_at_iso';
  static const String _oneDriveCloudSortTypeKey = 'onedrive_cloud_sort_type';
  static const String _oneDriveCloudSortAscKey = 'onedrive_cloud_sort_asc';
  static const String _oneDriveDownloadQueueHistoryKey = 'onedrive_download_queue_history_v2';

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

  /// 桌面端播放控制快捷键（JSON）。
  static const String _playbackShortcutsKey = 'playback_shortcuts_v1';

  /// Android 有线耳机线控连击映射（JSON）。
  static const String _wireRemoteControlKey = 'wire_remote_control_v1';

  /// 播放页是否保持屏幕常亮。
  static const String _songPageKeepScreenAwakeKey = 'song_page_keep_screen_awake';

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

  /// 云端应用数据目录（设置/歌单备份等预留）：Graph driveItem id 与展示名。
  static Future<(String?, String)> loadOneDriveCloudAppFolder() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final idRaw = box.get(_oneDriveCloudAppFolderIdKey) as String?;
      final labelRaw = box.get(_oneDriveCloudAppFolderLabelKey) as String?;
      final id = idRaw?.trim();
      final label = labelRaw?.trim() ?? '';
      if (id == null || id.isEmpty) {
        return (null, '');
      }
      return (id, label);
    } catch (_) {
      return (null, '');
    }
  }

  static Future<void> saveOneDriveCloudAppFolder(String? itemId, String label) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (itemId == null || itemId.trim().isEmpty) {
        await box.delete(_oneDriveCloudAppFolderIdKey);
        await box.delete(_oneDriveCloudAppFolderLabelKey);
      } else {
        await box.put(_oneDriveCloudAppFolderIdKey, itemId.trim());
        await box.put(_oneDriveCloudAppFolderLabelKey, label.trim());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (itemId == null || itemId.trim().isEmpty) {
          await box.delete(_oneDriveCloudAppFolderIdKey);
          await box.delete(_oneDriveCloudAppFolderLabelKey);
        } else {
          await box.put(_oneDriveCloudAppFolderIdKey, itemId.trim());
          await box.put(_oneDriveCloudAppFolderLabelKey, label.trim());
        }
      } catch (_) {}
    }
  }

  /// 本地上传至 OneDrive 的默认目标文件夹（Graph driveItem id）；与应用数据目录可分开配置。
  static Future<(String?, String)> loadOneDriveMusicUploadFolder() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final idRaw = box.get(_oneDriveMusicUploadFolderIdKey) as String?;
      final labelRaw = box.get(_oneDriveMusicUploadFolderLabelKey) as String?;
      final id = idRaw?.trim();
      final label = labelRaw?.trim() ?? '';
      if (id == null || id.isEmpty) {
        return (null, '');
      }
      return (id, label);
    } catch (_) {
      return (null, '');
    }
  }

  static Future<void> saveOneDriveMusicUploadFolder(String? itemId, String label) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (itemId == null || itemId.trim().isEmpty) {
        await box.delete(_oneDriveMusicUploadFolderIdKey);
        await box.delete(_oneDriveMusicUploadFolderLabelKey);
      } else {
        await box.put(_oneDriveMusicUploadFolderIdKey, itemId.trim());
        await box.put(_oneDriveMusicUploadFolderLabelKey, label.trim());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (itemId == null || itemId.trim().isEmpty) {
          await box.delete(_oneDriveMusicUploadFolderIdKey);
          await box.delete(_oneDriveMusicUploadFolderLabelKey);
        } else {
          await box.put(_oneDriveMusicUploadFolderIdKey, itemId.trim());
          await box.put(_oneDriveMusicUploadFolderLabelKey, label.trim());
        }
      } catch (_) {}
    }
  }

  /// 本地下载目录（预留：从 OneDrive 整曲下载到设备）。
  static Future<String?> loadOneDriveLocalDownloadDir() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_oneDriveLocalDownloadDirKey) as String?;
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveOneDriveLocalDownloadDir(String? path) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (path == null || path.trim().isEmpty) {
        await box.delete(_oneDriveLocalDownloadDirKey);
      } else {
        await box.put(_oneDriveLocalDownloadDirKey, path.trim());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (path == null || path.trim().isEmpty) {
          await box.delete(_oneDriveLocalDownloadDirKey);
        } else {
          await box.put(_oneDriveLocalDownloadDirKey, path.trim());
        }
      } catch (_) {}
    }
  }

  static Future<OneDriveSyncSettings> loadOneDriveSyncSettings() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_oneDriveSyncSettingsKey) as String?;
      if (raw == null || raw.trim().isEmpty) {
        return OneDriveSyncSettings.defaults;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>?;
      if (decoded == null) return OneDriveSyncSettings.defaults;
      return OneDriveSyncSettings.fromJson(decoded);
    } catch (_) {
      return OneDriveSyncSettings.defaults;
    }
  }

  static Future<void> saveOneDriveSyncSettings(OneDriveSyncSettings s) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_oneDriveSyncSettingsKey, jsonEncode(s.toJson()));
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_oneDriveSyncSettingsKey, jsonEncode(s.toJson()));
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

  /// OneDrive 下载队列记录（JSON 数组）。
  static Future<List<Map<String, dynamic>>> loadOneDriveDownloadQueueHistory() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_oneDriveDownloadQueueHistoryKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        return decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> saveOneDriveDownloadQueueHistory(List<Map<String, dynamic>> rows) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_oneDriveDownloadQueueHistoryKey, json.encode(rows));
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_oneDriveDownloadQueueHistoryKey, json.encode(rows));
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

  static Future<PlaybackShortcutConfig> loadPlaybackShortcutConfig() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_playbackShortcutsKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return PlaybackShortcutConfig.fromJson(decoded);
        }
      }
    } catch (_) {}
    return PlaybackShortcutConfig.defaults;
  }

  static Future<void> savePlaybackShortcutConfig(
    PlaybackShortcutConfig config,
  ) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackShortcutsKey, jsonEncode(config.toJson()));
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackShortcutsKey, jsonEncode(config.toJson()));
      } catch (_) {}
    }
  }

  static Future<WireRemoteControlConfig> loadWireRemoteControlConfig() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_wireRemoteControlKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return WireRemoteControlConfig.fromJson(decoded);
        }
      }
    } catch (_) {}
    return WireRemoteControlConfig.defaults;
  }

  static Future<void> saveWireRemoteControlConfig(
    WireRemoteControlConfig config,
  ) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_wireRemoteControlKey, jsonEncode(config.toJson()));
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_wireRemoteControlKey, jsonEncode(config.toJson()));
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

  static Future<bool> loadSongPageKeepScreenAwake() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_songPageKeepScreenAwakeKey, defaultValue: false);
      if (v is bool) return v;
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveSongPageKeepScreenAwake(bool value) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_songPageKeepScreenAwakeKey, value);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_songPageKeepScreenAwakeKey, value);
      } catch (_) {}
    }
  }

  /// 参与云端「应用设置」备份的 Hive 键（排除体积巨大的索引曲目与普通下载队列历史）。
  static const List<String> _hiveKeysForCloudBackup = <String>[
    _lyricSettingsKey,
    _playbackModeKey,
    _timerDurationKey,
    _quickEntryOrderKey,
    _quickEntryHiddenKey,
    _oneDriveClientIdKey,
    _oneDriveMusicRootIdKey,
    _oneDriveCloudAppFolderIdKey,
    _oneDriveCloudAppFolderLabelKey,
    _oneDriveMusicUploadFolderIdKey,
    _oneDriveMusicUploadFolderLabelKey,
    _oneDriveLocalDownloadDirKey,
    _oneDriveSyncSettingsKey,
    _oneDriveIndexFoldersKey,
    _oneDriveIndexAtKey,
    _oneDriveCloudSortTypeKey,
    _oneDriveCloudSortAscKey,
    _macosMenuBarLyricsKey,
    _desktopFloatingLyricsKey,
    _desktopFloatingLyricsBgOpacityKey,
    _desktopFloatingLyricsLinesBeforeKey,
    _desktopFloatingLyricsLinesAfterKey,
    _desktopFloatingLyricsLockedKey,
    _androidCarLyricsEnabledKey,
    _androidCarLyricsShowCoverKey,
    _androidCarLyricsSyncLyricsKey,
    _playbackShortcutsKey,
    _wireRemoteControlKey,
    _songPageKeepScreenAwakeKey,
  ];

  static const String yeahMusicAppSettingsBackupFormatId = 'yeah_music_app_settings_v1';

  static dynamic _hiveValueToJsonForCloudBackup(dynamic value) {
    if (value == null || value is num || value is String || value is bool) {
      return value;
    }
    if (value is LyricSettings) {
      return value.toBackupMap();
    }
    if (value is List) {
      return value.map<dynamic>(_hiveValueToJsonForCloudBackup).toList();
    }
    if (value is Map) {
      final out = <String, dynamic>{};
      for (final e in value.entries) {
        out['${e.key}'] = _hiveValueToJsonForCloudBackup(e.value);
      }
      return out;
    }
    return value.toString();
  }

  /// 供 OneDrive 上传：应用偏好（Hive 白名单项与 SharedPreferences：主题、明暗、界面语言）。
  static Future<Map<String, dynamic>> buildAppSettingsBackupMapForCloud() async {
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final hiveFlat = <String, dynamic>{};
    for (final key in _hiveKeysForCloudBackup) {
      if (!box.containsKey(key)) continue;
      hiveFlat[key] = _hiveValueToJsonForCloudBackup(box.get(key));
    }
    final prefs = await SharedPreferences.getInstance();
    final appearance = <String, dynamic>{
      if (prefs.containsKey('theme_type')) 'theme_type': prefs.getInt('theme_type'),
      if (prefs.containsKey('primary_color')) 'primary_color': prefs.getInt('primary_color'),
      if (prefs.containsKey('secondary_color')) 'secondary_color': prefs.getInt('secondary_color'),
      if (prefs.containsKey('background_image_path'))
        'background_image_path': prefs.getString('background_image_path'),
      if (prefs.containsKey('background_image_effect'))
        'background_image_effect': prefs.getDouble('background_image_effect'),
      if (prefs.containsKey('global_theme_mode')) 'global_theme_mode': prefs.getInt('global_theme_mode'),
      if (prefs.containsKey('app_language_option')) 'app_language_option': prefs.getString('app_language_option'),
    };

    return {
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
      'sharedPreferences': <String, dynamic>{'appearance': appearance},
    };
  }

  static Future<String> buildAppSettingsBackupJsonStringForCloud() async {
    final map = await buildAppSettingsBackupMapForCloud();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static int _asIntForCloudRestore(dynamic json, [int fallback = 0]) {
    if (json is int) return json;
    if (json is num) return json.round();
    return fallback;
  }

  static double _asDoubleForCloudRestore(dynamic json, double fallback) {
    if (json is double) return json;
    if (json is num) return json.toDouble();
    return fallback;
  }

  static bool _asBoolForCloudRestore(dynamic json, bool fallback) {
    if (json is bool) return json;
    return fallback;
  }

  /// 将 [buildAppSettingsBackupMapForCloud] 产出的快照写回 Hive 与 SharedPreferences（appearance）。
  static Future<void> applyCloudBackupMap(Map<String, dynamic> root) async {
    final fmt = root['format'] as String?;
    if (fmt != yeahMusicAppSettingsBackupFormatId) {
      throw FormatException('unsupported settings backup format: $fmt');
    }
    final hiveRaw = root['hive'];
    if (hiveRaw is! Map) {
      throw const FormatException('settings backup missing hive');
    }
    final hiveDecoded = Map<String, dynamic>.from(hiveRaw);
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    for (final key in _hiveKeysForCloudBackup) {
      if (!hiveDecoded.containsKey(key)) continue;
      await box.put(
        key,
        _decodeHiveValueForCloudRestore(key, hiveDecoded[key]),
      );
    }

    final spWrapper = root['sharedPreferences'];
    if (spWrapper is! Map) return;
    final appearance = spWrapper['appearance'];
    if (appearance is! Map) return;
    final app = Map<String, dynamic>.from(appearance);
    final prefs = await SharedPreferences.getInstance();
    Future<void> setIntPref(String prefsKey, Object? v) async {
      if (v is int) {
        await prefs.setInt(prefsKey, v);
      } else if (v is num) {
        await prefs.setInt(prefsKey, v.round());
      }
    }

    if (app.containsKey('theme_type')) {
      await setIntPref('theme_type', app['theme_type']);
    }
    if (app.containsKey('primary_color')) {
      await setIntPref('primary_color', app['primary_color']);
    }
    if (app.containsKey('secondary_color')) {
      await setIntPref('secondary_color', app['secondary_color']);
    }
    if (app.containsKey('background_image_path')) {
      final v = app['background_image_path'];
      if (v == null) {
        await prefs.remove('background_image_path');
      } else if (v is String) {
        await prefs.setString('background_image_path', v);
      }
    }
    if (app.containsKey('background_image_effect')) {
      final v = app['background_image_effect'];
      if (v is num) {
        await prefs.setDouble('background_image_effect', v.toDouble());
      }
    }
    if (app.containsKey('global_theme_mode')) {
      await setIntPref('global_theme_mode', app['global_theme_mode']);
    }
    if (app.containsKey('app_language_option')) {
      final v = app['app_language_option'];
      if (v is String) {
        await prefs.setString('app_language_option', v);
      }
    }
  }

  static dynamic _decodeHiveValueForCloudRestore(String key, dynamic json) {
    switch (key) {
      case _lyricSettingsKey:
        if (json is! Map) {
          throw const FormatException('backup hive lyric_settings invalid');
        }
        final ls = LyricSettings.fromBackupMap(Map<String,dynamic>.from(json));
        return ls;
      case _playbackModeKey:
        return _asIntForCloudRestore(json, 0).clamp(0, 999);
      case _timerDurationKey:
        return _asIntForCloudRestore(json, 30);
      case _quickEntryOrderKey:
        if (json is! List) return <dynamic>[];
        return json.map((e) => '$e').where((s) => s.isNotEmpty).toList();
      case _quickEntryHiddenKey:
        if (json is! List) return <dynamic>[];
        return json.map((e) => '$e').where((s) => s.isNotEmpty).toList();
      case _oneDriveClientIdKey:
      case _oneDriveMusicRootIdKey:
      case _oneDriveCloudAppFolderIdKey:
      case _oneDriveCloudAppFolderLabelKey:
      case _oneDriveMusicUploadFolderIdKey:
      case _oneDriveMusicUploadFolderLabelKey:
      case _oneDriveLocalDownloadDirKey:
        return '$json';
      case _oneDriveSyncSettingsKey:
        if (json is String && json.trim().isNotEmpty) {
          return json.trim();
        }
        if (json is Map) {
          return jsonEncode(Map<String,dynamic>.from(json));
        }
        return jsonEncode(OneDriveSyncSettings.defaults.toJson());
      case _oneDriveIndexFoldersKey:
        if (json is! List) {
          return <Map<dynamic,dynamic>>[];
        }
        return json
            .whereType<Map>()
            .map((e) => Map<dynamic,dynamic>.from(e))
            .toList();
      case _oneDriveIndexAtKey:
        final s = json is String ? json : '$json';
        return DateTime.tryParse(s)?.toIso8601String() ??
            DateTime.now().toIso8601String();
      case _oneDriveCloudSortTypeKey:
        return '$json';
      case _oneDriveCloudSortAscKey:
        return _asBoolForCloudRestore(json, true);
      case _macosMenuBarLyricsKey:
      case _desktopFloatingLyricsKey:
      case _desktopFloatingLyricsLockedKey:
      case _androidCarLyricsEnabledKey:
      case _androidCarLyricsShowCoverKey:
      case _androidCarLyricsSyncLyricsKey:
      case _songPageKeepScreenAwakeKey:
        return _asBoolForCloudRestore(json, false);
      case _desktopFloatingLyricsBgOpacityKey:
        return _asDoubleForCloudRestore(
          json,
          desktopFloatingLyricsBgOpacityDefault,
        ).clamp(_desktopBgOpacityMin, _desktopBgOpacityMax);
      case _desktopFloatingLyricsLinesBeforeKey:
        return _asIntForCloudRestore(
          json,
          desktopFloatingLyricsLinesBeforeDefault,
        ).clamp(0, _desktopLinesRangeMax);
      case _desktopFloatingLyricsLinesAfterKey:
        return _asIntForCloudRestore(
          json,
          desktopFloatingLyricsLinesAfterDefault,
        ).clamp(0, _desktopLinesRangeMax);
      case _playbackShortcutsKey:
      case _wireRemoteControlKey:
        if (json is String) return json;
        if (json is Map) {
          return jsonEncode(Map<String,dynamic>.from(json));
        }
        return '{}';
      default:
        return json;
    }
  }
}
