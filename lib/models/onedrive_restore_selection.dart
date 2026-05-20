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

import 'package:yeah_music/models/onedrive_cloud_backup_snapshot.dart';

/// 从云端恢复时勾选的粒度（与上传切片对应）。
class OneDriveRestoreSelection {
  const OneDriveRestoreSelection({
    required this.snapshot,
    required this.restorePlaylists,
    required this.restoreLegacyCombinedSettings,
    required this.restoreHomeGreeting,
    required this.restoreQuickEntry,
    required this.restorePlaybackLists,
    required this.restoreLyricsUi,
    required this.restoreSongRecognition,
    required this.restoreTheme,
    required this.replaceAllPlaylists,
  });

  final OneDriveCloudBackupSnapshot snapshot;

  final bool restorePlaylists;

  /// 旧版整块 `yeah_music_settings_*.json`。
  final bool restoreLegacyCombinedSettings;

  final bool restoreHomeGreeting;
  final bool restoreQuickEntry;
  final bool restorePlaybackLists;
  final bool restoreLyricsUi;
  final bool restoreSongRecognition;
  final bool restoreTheme;

  final bool replaceAllPlaylists;

  bool get wantsAnyPayload =>
      restorePlaylists ||
      restoreLegacyCombinedSettings ||
      restoreHomeGreeting ||
      restoreQuickEntry ||
      restorePlaybackLists ||
      restoreLyricsUi ||
      restoreSongRecognition ||
      restoreTheme;
}
