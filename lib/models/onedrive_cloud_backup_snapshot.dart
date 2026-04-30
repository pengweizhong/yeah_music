import 'package:yeah_music/models/onedrive_sync_constants.dart';
import 'package:yeah_music/utils/onedrive_backup_stamp.dart';

/// 云端备份条目在列表中的形态：旧版平铺文件、按设备会话目录。
enum OneDriveCloudBackupSnapshotKind {
  legacyFlat,
  deviceSession,
}

/// 云端同步根目录下的某次备份（或旧版单次平铺快照）。
class OneDriveCloudBackupSnapshot
    implements Comparable<OneDriveCloudBackupSnapshot> {
  const OneDriveCloudBackupSnapshot({
    required this.kind,
    required this.sortStamp,
    this.deviceFolderLabel,
    this.leafFolderItemId,
    this.playlistsItemId,
    this.settingsItemId,
    this.blobItemIds = const {},
  });

  final OneDriveCloudBackupSnapshotKind kind;

  /// 排序用：旧版为 `yyyy-MM-dd_HH-mm-ss`；会话目录为 `yyyyMMddTHHmmss`。
  final String sortStamp;

  /// `deviceSession` 时为云端设备文件夹名（型号段）。
  final String? deviceFolderLabel;

  /// [deviceSession] 时指向 `…/设备/时间戳/` 文件夹 id。
  final String? leafFolderItemId;

  /// 旧版：`yeah_music_playlists_<stamp>.json`。
  final String? playlistsItemId;

  /// 旧版：`yeah_music_settings_<stamp>.json`。
  final String? settingsItemId;

  /// 新版：会话目录内各切片 `文件名 → driveItemId`。
  final Map<String, String> blobItemIds;

  DateTime get comparableInstant {
    switch (kind) {
      case OneDriveCloudBackupSnapshotKind.legacyFlat:
        return parseLegacyOneDriveBackupFileStamp(sortStamp) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      case OneDriveCloudBackupSnapshotKind.deviceSession:
        return parseOneDriveSyncSessionFolderStamp(sortStamp) ??
            DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String? _blob(String name) {
    final id = blobItemIds[name]?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool get hasPlaylistsJson =>
      (playlistsItemId != null && playlistsItemId!.trim().isNotEmpty) ||
      _blob(OneDriveSyncConstants.playlistsBlobFileName) != null;

  bool get hasLegacyCombinedSettingsJson =>
      settingsItemId != null && settingsItemId!.trim().isNotEmpty;

  bool get hasHomeGreetingJson =>
      _blob(OneDriveSyncConstants.sliceHomeGreetingFileName) != null;

  bool get hasQuickEntryJson =>
      _blob(OneDriveSyncConstants.sliceQuickEntryFileName) != null;

  bool get hasPlaybackListsJson =>
      _blob(OneDriveSyncConstants.slicePlaybackListsFileName) != null;

  bool get hasLyricsUiJson =>
      _blob(OneDriveSyncConstants.sliceLyricsUiFileName) != null;

  bool get hasThemeJson =>
      _blob(OneDriveSyncConstants.sliceThemeFileName) != null;

  bool get hasAnySliceSettingsJson =>
      hasHomeGreetingJson ||
      hasQuickEntryJson ||
      hasPlaybackListsJson ||
      hasLyricsUiJson ||
      hasThemeJson;

  @override
  int compareTo(OneDriveCloudBackupSnapshot other) =>
      other.comparableInstant.compareTo(comparableInstant);
}
