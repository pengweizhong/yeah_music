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
