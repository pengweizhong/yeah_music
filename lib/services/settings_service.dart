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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/playback_sound_preset.dart';
import 'package:yeah_music/models/playback_shortcut_config.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/models/song_recognition_entry.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';
import 'package:yeah_music/models/acr_cloud_recognition_config.dart';
import 'package:yeah_music/models/song_recognition_provider.dart';
import 'package:yeah_music/config/app_product_info.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/song_recognition_history_service.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/playback_speed.dart';

class SettingsService {
  /// 首页快捷入口 Hive 写入或云端恢复后自增；[HomePage] 监听以刷新顺序与显隐。
  static final ValueNotifier<int> quickEntryStorageRevision = ValueNotifier<int>(0);

  /// [hiveKeysCloudSliceLyricsUi] 中任一键写入 Hive 或云端恢复后自增；[SongPage] 等监听。
  static final ValueNotifier<int> lyricsUiStorageRevision = ValueNotifier<int>(0);

  /// [savePlaybackSoundPreset] 写入 Hive 后自增；播放页「更多」音效标题监听。
  static final ValueNotifier<int> playbackSoundPresetRevision =
      ValueNotifier<int>(0);

  /// [savePlaybackSpeed] 写入 Hive 后自增；播放页「更多」倍速标题监听。
  static final ValueNotifier<int> playbackSpeedRevision = ValueNotifier<int>(0);

  static const String _lyricSettingsKey = 'lyric_settings';
  static const String _playbackModeKey = 'playback_mode';
  static const String _playbackModeSchemaV2Key = 'playback_mode_schema_v2';
  static const String _timerDurationKey = 'timer_duration';
  static const String _quickEntryOrderKey = 'quick_entry_order';
  static const String _quickEntryHiddenKey = 'quick_entry_hidden';
  /// AudD 听歌识曲 API Token（https://dashboard.audd.io）；空则请求时使用 `test`（额度极低，仅供试用）。
  static const String _auddApiTokenKey = 'audd_api_token_v1';
  /// 识曲引擎：`audd` | `acrcloud`。
  static const String _songRecognitionProviderKey = 'song_recognition_provider_v1';
  /// ACRCloud 项目 JSON（host / accessKey / accessSecret）。
  static const String _acrCloudRecognitionConfigKey = 'acrcloud_recognition_config_v1';
  static const String _oneDriveClientIdKey = 'onedrive_client_id';
  static const String _oneDriveMusicRootIdKey = 'onedrive_music_root_id';
  static const String _oneDriveCloudAppFolderIdKey = 'onedrive_cloud_app_folder_id';
  static const String _oneDriveCloudAppFolderLabelKey = 'onedrive_cloud_app_folder_label';
  static const String _oneDriveMusicUploadFolderIdKey = 'onedrive_music_upload_folder_id';
  static const String _oneDriveMusicUploadFolderLabelKey = 'onedrive_music_upload_folder_label';
  static const String _oneDriveLocalDownloadDirKey = 'onedrive_local_download_dir';
  /// 曾用于点播落地的目录（用户清空「当前下载目录」后仍扫描这些路径，避免历史缓存「消失」）。
  static const String _oneDriveDownloadScanRootsKey =
      'onedrive_download_scan_roots_v1';
  static const String _oneDriveSyncSettingsKey = 'onedrive_sync_settings_v1';
  static const String _oneDriveLastConfigSyncAtKey = 'onedrive_last_config_sync_at_iso';
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

  /// 暂停 / 切歌前音量线性淡出时长（毫秒）；0 表示关闭。
  static const String _playbackFadeOutDurationMsKey =
      'playback_fade_out_duration_ms_v1';

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

  /// Android 播放音效预设 id（与 [PlaybackSoundPreset.storageId] 一致）。
  static const String _playbackSoundPresetKey = 'playback_sound_preset_v1';

  /// [PlaybackSoundPreset.custom] 时各频段增益（dB），与设备均衡器 band 顺序一致。
  static const String _playbackSoundCustomEqDbKey =
      'playback_sound_custom_eq_db_v1';

  /// 播放倍速（与 [kPlaybackSpeedOptions] 之一一致；默认 1.0）。
  static const String _playbackSpeedKey = 'playback_speed_v1';

  /// 首页问候卡片第二行：用户自定义条目（不含内置默认句）。
  static const String _homeGreetingCustomSubsKey =
      'home_greeting_custom_subtitles_v1';

  /// 与 [homeGreetingSub] 一同轮询时的游标（Hive）。
  static const String _homeGreetingSubCycleCursorKey =
      'home_greeting_sub_cycle_cursor_v1';

  /// `true`：随机展示；`false`：顺序轮播（仍写入游标）。
  static const String _homeGreetingRotationRandomKey =
      'home_greeting_rotation_random_v1';

  static const double desktopFloatingLyricsBgOpacityDefault = 0.42;
  static const int desktopFloatingLyricsLinesBeforeDefault = 2;
  static const int desktopFloatingLyricsLinesAfterDefault = 2;
  static const int playbackFadeOutDurationMsDefault = 500;
  static const int playbackFadeOutDurationMsMin = 0;
  static const int playbackFadeOutDurationMsMax = 1000;

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
      await box.put(_playbackModeSchemaV2Key, true);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackModeKey, mode.value);
        await box.put(_playbackModeSchemaV2Key, true);
      } catch (_) {}
    }
  }

  /// 加载播放模式
  static Future<PlaybackMode> loadPlaybackMode() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (box.get(_playbackModeSchemaV2Key) == true) {
        final value = box.get(_playbackModeKey, defaultValue: 0) as int?;
        return PlaybackModeExtension.fromValue(value ?? 0);
      }
      final legacy = box.get(_playbackModeKey, defaultValue: 0) as int? ?? 0;
      final mode = PlaybackModeExtension.fromLegacyStoredValue(legacy);
      await box.put(_playbackModeKey, mode.value);
      await box.put(_playbackModeSchemaV2Key, true);
      return mode;
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

  /// 移除已废弃的「音乐浏览根目录」Hive 项（设置入口已删除）。
  static Future<void> migrateRemoveOneDriveMusicRootSetting() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.delete(_oneDriveMusicRootIdKey);
    } catch (_) {}
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

  /// 合并用于「缓存歌单」扫描的目录（不清除当前下载目录时仍保留历史路径）。
  static Future<List<String>> loadOneDriveDownloadScanRoots() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      return await _readOneDriveDownloadScanRoots(box);
    } catch (_) {
      return [];
    }
  }

  /// 将当前「本地下载目录」并入扫描历史（应用启动时调用，保证曾选过目录即参与缓存歌单扫描）。
  static Future<void> ensureOneDriveDownloadScanRootsIncludesActiveDir() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final active = box.get(_oneDriveLocalDownloadDirKey) as String?;
      final t = active?.trim();
      if (t == null || t.isEmpty) return;
      await _mergeOneDriveDownloadScanRoot(box, p.normalize(t));
    } catch (_) {}
  }

  static Future<List<String>> _readOneDriveDownloadScanRoots(
    dynamic box,
  ) async {
    final raw = box.get(_oneDriveDownloadScanRootsKey) as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => p.normalize(e.toString().trim()))
            .where((s) => s.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    final active = box.get(_oneDriveLocalDownloadDirKey) as String?;
    final t = active?.trim();
    if (t != null && t.isNotEmpty) {
      final seeded = <String>[p.normalize(t)];
      await box.put(_oneDriveDownloadScanRootsKey, jsonEncode(seeded));
      return seeded;
    }
    return [];
  }

  static Future<void> _mergeOneDriveDownloadScanRoot(
    dynamic box,
    String normalizedPath,
  ) async {
    if (normalizedPath.isEmpty) return;
    List<String> list;
    final raw = box.get(_oneDriveDownloadScanRootsKey) as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded
            .map((e) => p.normalize(e.toString().trim()))
            .where((s) => s.isNotEmpty)
            .toList();
      } catch (_) {
        list = [];
      }
    } else {
      list = [];
    }
    list.remove(normalizedPath);
    list.insert(0, normalizedPath);
    const cap = 16;
    if (list.length > cap) {
      list = list.sublist(0, cap);
    }
    await box.put(_oneDriveDownloadScanRootsKey, jsonEncode(list));
  }

  /// 记录曾用于 OneDrive 点播落地的目录（与 [saveOneDriveLocalDownloadDir] 独立），供「缓存歌单」扫描。
  static Future<void> appendOneDriveDownloadScanRootIfNew(
    String directoryPath,
  ) async {
    final t = directoryPath.trim();
    if (t.isEmpty) return;
    final norm = p.normalize(t);
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await _mergeOneDriveDownloadScanRoot(box, norm);
    } catch (_) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await _mergeOneDriveDownloadScanRoot(box, norm);
      } catch (_) {}
    }
  }

  static Future<void> saveOneDriveLocalDownloadDir(String? path) async {
    Future<void> write(dynamic box) async {
      if (path == null || path.trim().isEmpty) {
        await box.delete(_oneDriveLocalDownloadDirKey);
      } else {
        final trimmed = path.trim();
        await box.put(_oneDriveLocalDownloadDirKey, trimmed);
        await _mergeOneDriveDownloadScanRoot(box, p.normalize(trimmed));
      }
    }

    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await write(box);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await write(box);
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

  static Future<DateTime?> loadOneDriveLastConfigSyncAt() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final s = box.get(_oneDriveLastConfigSyncAtKey) as String?;
      if (s == null || s.trim().isEmpty) return null;
      return DateTime.tryParse(s.trim());
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveOneDriveLastConfigSyncAt(DateTime? t) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      if (t == null) {
        await box.delete(_oneDriveLastConfigSyncAtKey);
      } else {
        await box.put(_oneDriveLastConfigSyncAtKey, t.toIso8601String());
      }
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        if (t == null) {
          await box.delete(_oneDriveLastConfigSyncAtKey);
        } else {
          await box.put(_oneDriveLastConfigSyncAtKey, t.toIso8601String());
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

  static Future<int> loadPlaybackFadeOutDurationMs() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_playbackFadeOutDurationMsKey);
      if (v is int) {
        return v.clamp(playbackFadeOutDurationMsMin, playbackFadeOutDurationMsMax);
      }
      if (v is num) {
        return v.round().clamp(playbackFadeOutDurationMsMin, playbackFadeOutDurationMsMax);
      }
      return playbackFadeOutDurationMsDefault;
    } catch (_) {
      return playbackFadeOutDurationMsDefault;
    }
  }

  static Future<void> savePlaybackFadeOutDurationMs(int milliseconds) async {
    final v = milliseconds.clamp(
      playbackFadeOutDurationMsMin,
      playbackFadeOutDurationMsMax,
    );
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackFadeOutDurationMsKey, v);
    } catch (_) {
      try {
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackFadeOutDurationMsKey, v);
      } catch (_) {}
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

  static Future<String> loadAuddApiToken() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_auddApiTokenKey);
      if (v is String) return v;
      return '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveAuddApiToken(String value) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_auddApiTokenKey, value.trim());
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_auddApiTokenKey, value.trim());
      } catch (_) {}
    }
  }

  static Future<SongRecognitionProvider> loadSongRecognitionProvider() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_songRecognitionProviderKey);
      if (v is String) return songRecognitionProviderFromStorage(v);
    } catch (_) {}
    return SongRecognitionProvider.audd;
  }

  static Future<void> saveSongRecognitionProvider(
    SongRecognitionProvider provider,
  ) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_songRecognitionProviderKey, provider.name);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_songRecognitionProviderKey, provider.name);
      } catch (_) {}
    }
  }

  static Future<AcrCloudRecognitionConfig> loadAcrCloudRecognitionConfig() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_acrCloudRecognitionConfigKey);
      if (v is String) return AcrCloudRecognitionConfig.decode(v);
    } catch (_) {}
    return const AcrCloudRecognitionConfig();
  }

  static Future<void> saveAcrCloudRecognitionConfig(
    AcrCloudRecognitionConfig config,
  ) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(
        _acrCloudRecognitionConfigKey,
        AcrCloudRecognitionConfig.encode(config),
      );
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(
          _acrCloudRecognitionConfigKey,
          AcrCloudRecognitionConfig.encode(config),
        );
      } catch (_) {}
    }
  }

  static Future<void> saveQuickEntryConfig(QuickEntryConfig c) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      c.normalizeInPlace();
      await box.put(_quickEntryOrderKey, c.order);
      await box.put(_quickEntryHiddenKey, c.hidden.toList());
      quickEntryStorageRevision.value++;
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        c.normalizeInPlace();
        await box.put(_quickEntryOrderKey, c.order);
        await box.put(_quickEntryHiddenKey, c.hidden.toList());
        quickEntryStorageRevision.value++;
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

  static Future<PlaybackSoundPreset> loadPlaybackSoundPreset() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_playbackSoundPresetKey);
      if (raw is String && raw.isNotEmpty) {
        return PlaybackSoundPreset.fromStorageId(raw);
      }
    } catch (_) {}
    return PlaybackSoundPreset.standard;
  }

  static Future<void> savePlaybackSoundPreset(PlaybackSoundPreset preset) async {
    var ok = false;
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackSoundPresetKey, preset.storageId);
      ok = true;
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackSoundPresetKey, preset.storageId);
        ok = true;
      } catch (_) {}
    }
    if (ok) playbackSoundPresetRevision.value++;
  }

  static Future<double> loadPlaybackSpeed() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_playbackSpeedKey);
      if (v is num) return normalizePlaybackSpeed(v.toDouble());
    } catch (_) {}
    return kDefaultPlaybackSpeed;
  }

  static Future<void> savePlaybackSpeed(double speed) async {
    final normalized = normalizePlaybackSpeed(speed);
    var ok = false;
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackSpeedKey, normalized);
      ok = true;
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackSpeedKey, normalized);
        ok = true;
      } catch (_) {}
    }
    if (ok) playbackSpeedRevision.value++;
  }

  static Future<List<double>> loadPlaybackSoundCustomBandGainsDb() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_playbackSoundCustomEqDbKey);
      if (raw is List) {
        return raw.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> savePlaybackSoundCustomBandGainsDb(
    List<double> gainsDb,
  ) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_playbackSoundCustomEqDbKey, gainsDb);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_playbackSoundCustomEqDbKey, gainsDb);
      } catch (_) {}
    }
  }

  /// 首页问候副文案：用户自定义（每则一行）；不含应用内置本地化默认句。
  static Future<List<String>> loadHomeGreetingCustomSubtitles() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final raw = box.get(_homeGreetingCustomSubsKey);
      if (raw is List) {
        return raw
            .map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHomeGreetingCustomSubtitles(
    List<String> lines,
  ) async {
    final cleaned =
        lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_homeGreetingCustomSubsKey, cleaned);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_homeGreetingCustomSubsKey, cleaned);
      } catch (_) {}
    }
  }

  static Future<int> loadHomeGreetingSubCycleCursor() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_homeGreetingSubCycleCursorKey, defaultValue: 0);
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveHomeGreetingSubCycleCursor(int value) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_homeGreetingSubCycleCursorKey, value);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_homeGreetingSubCycleCursorKey, value);
      } catch (_) {}
    }
  }

  static Future<bool> loadHomeGreetingRotationRandom() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final v = box.get(_homeGreetingRotationRandomKey, defaultValue: false);
      if (v is bool) return v;
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveHomeGreetingRotationRandom(bool value) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put(_homeGreetingRotationRandomKey, value);
    } catch (e) {
      try {
        await HiveUtils.closeBox(Constant.hiveRootPath);
        final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
        await box.put(_homeGreetingRotationRandomKey, value);
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
    _playbackFadeOutDurationMsKey,
    _androidCarLyricsEnabledKey,
    _androidCarLyricsShowCoverKey,
    _androidCarLyricsSyncLyricsKey,
    _playbackShortcutsKey,
    _wireRemoteControlKey,
    _songPageKeepScreenAwakeKey,
    _homeGreetingCustomSubsKey,
    _homeGreetingSubCycleCursorKey,
    _homeGreetingRotationRandomKey,
    _auddApiTokenKey,
    _songRecognitionProviderKey,
    _acrCloudRecognitionConfigKey,
    SongRecognitionHistoryService.hiveKeyHistory,
  ];

  static const String yeahMusicAppSettingsBackupFormatId = 'yeah_music_app_settings_v1';

  /// OneDrive 主题切片 JSON 顶层：与同目录背景图二进制文件名对应（不含设备本地路径）。
  static const String yeahMusicThemeExportBackgroundAssetNameKey =
      'themeBackgroundAssetName';

  static const Set<String> _themeBackgroundSidecarAllowedExt = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  };

  /// 读取主题备份文档中的云端背景图文件名（若有）。
  static String? themeBackgroundAssetNameFromDoc(Map<String, dynamic> doc) {
    final raw = doc[yeahMusicThemeExportBackgroundAssetNameKey];
    if (raw is! String) return null;
    final s = raw.trim();
    return s.isEmpty ? null : s;
  }

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
      if (prefs.containsKey('theme_gradient_direction'))
        'theme_gradient_direction': prefs.getInt('theme_gradient_direction'),
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
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
      'sharedPreferences': <String, dynamic>{'appearance': appearance},
    };
  }

  static Future<String> buildAppSettingsBackupJsonStringForCloud() async {
    final map = await buildAppSettingsBackupMapForCloud();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static List<String> hiveKeysCloudSliceHomeGreeting() => <String>[
        _homeGreetingCustomSubsKey,
        _homeGreetingSubCycleCursorKey,
        _homeGreetingRotationRandomKey,
      ];

  static List<String> hiveKeysCloudSliceQuickEntry() => <String>[
        _quickEntryOrderKey,
        _quickEntryHiddenKey,
      ];

  /// OneDrive 快捷入口切片：始终带上顺序与显隐，避免 Hive 里缺 [quick_entry_order] 键时上传不完整。
  static Future<Map<String, dynamic>> buildCloudBackupQuickEntrySliceMap() async {
    final cfg = await loadQuickEntryConfig() ?? QuickEntryConfig.defaultConfig();
    cfg.normalizeInPlace();
    final hiveFlat = <String, dynamic>{
      _quickEntryOrderKey: _hiveValueToJsonForCloudBackup(cfg.order),
      _quickEntryHiddenKey: _hiveValueToJsonForCloudBackup(cfg.hidden.toList()),
    };
    return <String, dynamic>{
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
    };
  }

  static List<String> hiveKeysCloudSliceLyricsUi() => <String>[
        _lyricSettingsKey,
        _songPageKeepScreenAwakeKey,
        _macosMenuBarLyricsKey,
        _desktopFloatingLyricsKey,
        _desktopFloatingLyricsBgOpacityKey,
        _desktopFloatingLyricsLinesBeforeKey,
        _desktopFloatingLyricsLinesAfterKey,
        _desktopFloatingLyricsLockedKey,
        _playbackFadeOutDurationMsKey,
        _androidCarLyricsEnabledKey,
        _androidCarLyricsShowCoverKey,
        _androidCarLyricsSyncLyricsKey,
      ];

  /// 歌词 UI 切片：各键始终写出，避免 Hive 缺键（如未改过「播放页常亮」）时无法上传。
  static Future<Map<String, dynamic>> buildCloudBackupLyricsUiSliceMap() async {
    final loaded = await loadLyricSettings();
    final lyric = loaded ?? LyricSettings();
    lyric.normalizeLayoutFields();
    final keepAwake = await loadSongPageKeepScreenAwake();
    final macMenu = await loadMacosMenuBarLyricsEnabled();
    final deskEn = await loadDesktopFloatingLyricsEnabled();
    final deskOp = await loadDesktopFloatingLyricsBgOpacity();
    final deskBefore = await loadDesktopFloatingLyricsLinesBefore();
    final deskAfter = await loadDesktopFloatingLyricsLinesAfter();
    final deskLock = await loadDesktopFloatingLyricsDragLocked();
    final fadeMs = await loadPlaybackFadeOutDurationMs();
    final carEn = await loadAndroidCarLyricsEnabled();
    final carCover = await loadAndroidCarLyricsShowCover();
    final carSync = await loadAndroidCarLyricsSyncLyrics();

    final hiveFlat = <String, dynamic>{
      _lyricSettingsKey: _hiveValueToJsonForCloudBackup(lyric),
      _songPageKeepScreenAwakeKey: _hiveValueToJsonForCloudBackup(keepAwake),
      _macosMenuBarLyricsKey: _hiveValueToJsonForCloudBackup(macMenu),
      _desktopFloatingLyricsKey: _hiveValueToJsonForCloudBackup(deskEn),
      _desktopFloatingLyricsBgOpacityKey: _hiveValueToJsonForCloudBackup(deskOp),
      _desktopFloatingLyricsLinesBeforeKey:
          _hiveValueToJsonForCloudBackup(deskBefore),
      _desktopFloatingLyricsLinesAfterKey:
          _hiveValueToJsonForCloudBackup(deskAfter),
      _desktopFloatingLyricsLockedKey: _hiveValueToJsonForCloudBackup(deskLock),
      _playbackFadeOutDurationMsKey: _hiveValueToJsonForCloudBackup(fadeMs),
      _androidCarLyricsEnabledKey: _hiveValueToJsonForCloudBackup(carEn),
      _androidCarLyricsShowCoverKey: _hiveValueToJsonForCloudBackup(carCover),
      _androidCarLyricsSyncLyricsKey: _hiveValueToJsonForCloudBackup(carSync),
    };

    return <String, dynamic>{
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
    };
  }

  /// 听歌识曲：各键始终写出，便于新设备与空历史时也能形成完整切片。
  static Future<Map<String, dynamic>> buildCloudBackupSongRecognitionSliceMap() async {
    final token = await loadAuddApiToken();
    final provider = await loadSongRecognitionProvider();
    final acr = await loadAcrCloudRecognitionConfig();
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final histRaw = box.get(SongRecognitionHistoryService.hiveKeyHistory);
    final histStr = histRaw is String
        ? histRaw
        : (histRaw == null ? '' : '$histRaw');

    final hiveFlat = <String, dynamic>{
      _auddApiTokenKey: _hiveValueToJsonForCloudBackup(token.trim()),
      _songRecognitionProviderKey:
          _hiveValueToJsonForCloudBackup(provider.name),
      _acrCloudRecognitionConfigKey:
          _hiveValueToJsonForCloudBackup(AcrCloudRecognitionConfig.encode(acr)),
      SongRecognitionHistoryService.hiveKeyHistory:
          _hiveValueToJsonForCloudBackup(histStr),
    };

    return <String, dynamic>{
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
    };
  }

  static List<String> hiveKeysCloudSlicePlaybackLists() => <String>[
        RecentPlayService.hiveKeyRecentSongPaths,
        RecentPlayService.hiveKeySongPlayCountMap,
        RecentPlayService.hiveKeyTotalListenedWallMs,
      ];

  /// OneDrive 切片上传：仅包含给定 Hive 键（不含 SharedPreferences）。
  static Future<Map<String, dynamic>> buildCloudBackupHiveSubsetMap(
    Iterable<String> keys,
  ) async {
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final hiveFlat = <String, dynamic>{};
    for (final key in keys) {
      if (!box.containsKey(key)) continue;
      hiveFlat[key] = _hiveValueToJsonForCloudBackup(box.get(key));
    }
    return <String, dynamic>{
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'hive': hiveFlat,
    };
  }

  /// 仅背景主题相关 SharedPreferences（appearance）。
  static Future<Map<String, dynamic>> buildCloudBackupThemeSliceMap() async {
    final prefs = await SharedPreferences.getInstance();
    final appearance = <String, dynamic>{
      if (prefs.containsKey('theme_type')) 'theme_type': prefs.getInt('theme_type'),
      if (prefs.containsKey('primary_color')) 'primary_color': prefs.getInt('primary_color'),
      if (prefs.containsKey('secondary_color')) 'secondary_color': prefs.getInt('secondary_color'),
      if (prefs.containsKey('theme_gradient_direction'))
        'theme_gradient_direction': prefs.getInt('theme_gradient_direction'),
      if (prefs.containsKey('background_image_path'))
        'background_image_path': prefs.getString('background_image_path'),
      if (prefs.containsKey('background_image_effect'))
        'background_image_effect': prefs.getDouble('background_image_effect'),
      if (prefs.containsKey('global_theme_mode')) 'global_theme_mode': prefs.getInt('global_theme_mode'),
    };

    return <String, dynamic>{
      'format': yeahMusicAppSettingsBackupFormatId,
      'version': 1,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'sharedPreferences': <String, dynamic>{'appearance': appearance},
    };
  }

  /// OneDrive：从切片 map 去掉设备本地的 [background_image_path]，写入 [yeahMusicThemeExportBackgroundAssetNameKey]，返回待上传文件。
  static Future<File?> prepareThemeBackgroundSidecarForOneDrive(
    Map<String, dynamic> map,
  ) async {
    map.remove(yeahMusicThemeExportBackgroundAssetNameKey);
    final spWrapperRaw = map['sharedPreferences'];
    if (spWrapperRaw is! Map) return null;
    final spWrapper = Map<String, dynamic>.from(
      spWrapperRaw.map((k, v) => MapEntry('$k', v)),
    );
    final appearanceRaw = spWrapper['appearance'];
    if (appearanceRaw is! Map) return null;
    final appearance = Map<String, dynamic>.from(
      appearanceRaw.map((k, v) => MapEntry('$k', v)),
    );

    final themeTypeRaw = appearance['theme_type'];
    final themeIndex = themeTypeRaw is int
        ? themeTypeRaw
        : (themeTypeRaw is num ? themeTypeRaw.round() : -1);

    final pathRaw = appearance['background_image_path'];
    appearance.remove('background_image_path');
    spWrapper['appearance'] = appearance;
    map['sharedPreferences'] = spWrapper;

    if (themeIndex != ThemeType.backgroundImage.index) return null;
    if (pathRaw is! String || pathRaw.trim().isEmpty) return null;

    try {
      final file = File(pathRaw.trim());
      if (!await file.exists()) return null;
      final len = await file.length();
      const maxBytes = 8 * 1024 * 1024;
      if (len <= 0 || len > maxBytes) return null;

      var ext = p.extension(file.path).toLowerCase();
      if (!_themeBackgroundSidecarAllowedExt.contains(ext)) {
        ext = '.jpg';
      }
      final remoteName =
          'yeah_music_theme_background${ext == '.jpeg' ? '.jpg' : ext}';
      map[yeahMusicThemeExportBackgroundAssetNameKey] = remoteName;
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _installThemeBackgroundFromRestoredSidecar(File src) async {
    if (!await src.exists()) return;
    final len = await src.length();
    const maxBytes = 8 * 1024 * 1024;
    if (len <= 0 || len > maxBytes) return;

    var ext = p.extension(src.path).toLowerCase();
    if (!_themeBackgroundSidecarAllowedExt.contains(ext)) {
      ext = '.jpg';
    }
    if (ext == '.jpeg') ext = '.jpg';

    final support = await getApplicationSupportDirectory();
    final base = ThemeConfigProvider.themeBackgroundSupportBaseName;
    for (final name in <String>[
      '$base.jpg',
      '$base.jpeg',
      '$base.png',
      '$base.webp',
      '$base.gif',
    ]) {
      final old = File(p.join(support.path, name));
      if (await old.exists()) {
        try {
          await old.delete();
        } catch (_) {}
      }
    }

    final destPath = p.join(support.path, '$base$ext');
    final bytes = await src.readAsBytes();
    if (bytes.isEmpty) return;
    await File(destPath).writeAsBytes(bytes, flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image_path', destPath);
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

  static bool _hiveCloudRestoreAllowedKey(String key) {
    if (_hiveKeysForCloudBackup.contains(key)) return true;
    return key == RecentPlayService.hiveKeyRecentSongPaths ||
        key == RecentPlayService.hiveKeySongPlayCountMap ||
        key == RecentPlayService.hiveKeyTotalListenedWallMs;
  }

  /// 将 [buildAppSettingsBackupMapForCloud] 产出的快照写回 Hive 与 SharedPreferences（appearance）。
  ///
  /// [themeBackgroundSidecarAbsolute]：与同目录主题切片配套的本地背景图文件（已由 Graph 下载）。
  static Future<void> applyCloudBackupMap(
    Map<String, dynamic> root, {
    String? themeBackgroundSidecarAbsolute,
  }) async {
    root.remove(yeahMusicThemeExportBackgroundAssetNameKey);
    final fmt = root['format'] as String?;
    if (fmt != yeahMusicAppSettingsBackupFormatId) {
      throw FormatException('unsupported settings backup format: $fmt');
    }
    final hiveRaw = root['hive'];
    if (hiveRaw is Map) {
      final hiveDecoded = Map<String, dynamic>.from(hiveRaw);
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      var touchedQuickEntry = false;
      var touchedLyricsUi = false;
      final lyricsUiKeys = hiveKeysCloudSliceLyricsUi();
      for (final entry in hiveDecoded.entries) {
        final key = entry.key;
        if (!_hiveCloudRestoreAllowedKey(key)) continue;
        if (key == _quickEntryOrderKey || key == _quickEntryHiddenKey) {
          touchedQuickEntry = true;
        }
        if (lyricsUiKeys.contains(key)) {
          touchedLyricsUi = true;
        }
        await box.put(
          key,
          _decodeHiveValueForCloudRestore(key, entry.value),
        );
      }
      if (touchedQuickEntry) {
        quickEntryStorageRevision.value++;
      }
      if (touchedLyricsUi) {
        lyricsUiStorageRevision.value++;
      }
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
    if (app.containsKey('theme_gradient_direction')) {
      await setIntPref('theme_gradient_direction', app['theme_gradient_direction']);
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

    final sidecar = themeBackgroundSidecarAbsolute?.trim();
    if (app.containsKey('theme_type')) {
      final ttRaw = app['theme_type'];
      final ti = ttRaw is int ? ttRaw : (ttRaw is num ? ttRaw.round() : null);
      if (ti == ThemeType.backgroundImage.index &&
          (sidecar == null || sidecar.isEmpty) &&
          !app.containsKey('background_image_path')) {
        await prefs.remove('background_image_path');
      }
    }

    if (sidecar != null && sidecar.isNotEmpty) {
      await _installThemeBackgroundFromRestoredSidecar(File(sidecar));
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
      case _playbackFadeOutDurationMsKey:
        return _asIntForCloudRestore(
          json,
          playbackFadeOutDurationMsDefault,
        ).clamp(playbackFadeOutDurationMsMin, playbackFadeOutDurationMsMax);
      case _playbackShortcutsKey:
      case _wireRemoteControlKey:
        if (json is String) return json;
        if (json is Map) {
          return jsonEncode(Map<String,dynamic>.from(json));
        }
        return '{}';
      case _homeGreetingCustomSubsKey:
        if (json is! List) return <dynamic>[];
        return json.map((e) => '$e').where((s) => s.isNotEmpty).toList();
      case _homeGreetingSubCycleCursorKey:
        return _asIntForCloudRestore(json, 0).clamp(0, 999999);
      case _homeGreetingRotationRandomKey:
        return _asBoolForCloudRestore(json, false);
      case _auddApiTokenKey:
        return '$json'.trim();
      case _songRecognitionProviderKey:
        return songRecognitionProviderFromStorage('$json').name;
      case _acrCloudRecognitionConfigKey:
        if (json is String) return json;
        if (json is Map) {
          return jsonEncode(Map<String,dynamic>.from(json));
        }
        return AcrCloudRecognitionConfig.encode(const AcrCloudRecognitionConfig());
      case SongRecognitionHistoryService.hiveKeyHistory:
        if (json is String) return json;
        if (json is List) {
          final jsonList = json;
          final rebuilt = <SongRecognitionEntry>[];
          for (final e in jsonList) {
            if (e is Map<String,dynamic>) {
              final x = SongRecognitionEntry.fromJsonMap(e);
              if (x != null) rebuilt.add(x);
            } else if (e is Map) {
              final x = SongRecognitionEntry.fromJsonMap(
                Map<String,dynamic>.from(e),
              );
              if (x != null) rebuilt.add(x);
            }
          }
          return SongRecognitionEntry.encodeList(rebuilt);
        }
        return SongRecognitionEntry.encodeList(const []);
      case RecentPlayService.hiveKeyRecentSongPaths:
        if (json is! List) return <dynamic>[];
        return json.map((e) => '$e').where((s) => s.trim().isNotEmpty).toList();
      case RecentPlayService.hiveKeySongPlayCountMap:
        if (json is! Map) return <dynamic, dynamic>{};
        final countMap = <dynamic, dynamic>{};
        for (final e in json.entries) {
          final k = '${e.key}'.trim();
          if (k.isEmpty) continue;
          countMap[k] = _asIntForCloudRestore(e.value, 0);
        }
        return countMap;
      case RecentPlayService.hiveKeyTotalListenedWallMs:
        return _asIntForCloudRestore(json, 0).clamp(0, 1 << 62);
      default:
        return json;
    }
  }
}
