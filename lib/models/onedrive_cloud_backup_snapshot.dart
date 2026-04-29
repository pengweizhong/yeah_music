/// 云端应用文件夹内同一「时间戳」对应的歌单与/或设置备份文件。
class OneDriveCloudBackupSnapshot implements Comparable<OneDriveCloudBackupSnapshot> {
  const OneDriveCloudBackupSnapshot({
    required this.stamp,
    this.playlistsItemId,
    this.settingsItemId,
  });

  /// 与 [formatOneDriveBackupFileStamp] 一致的字符串，如 `2026-04-29_14-35-06`。
  final String stamp;

  /// `yeah_music_playlists_<stamp>.json` 的 Graph drive item id。
  final String? playlistsItemId;

  /// `yeah_music_settings_<stamp>.json` 的 Graph drive item id。
  final String? settingsItemId;

  bool get hasPlaylistsJson => playlistsItemId != null && playlistsItemId!.isNotEmpty;
  bool get hasSettingsJson => settingsItemId != null && settingsItemId!.isNotEmpty;

  @override
  int compareTo(OneDriveCloudBackupSnapshot other) =>
      other.stamp.compareTo(stamp);
}
