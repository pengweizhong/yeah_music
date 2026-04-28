/// OneDrive 云端同步偏好（实际同步任务后续接入）。
enum OneDriveSyncFrequency {
  /// 不自动同步，仅保留配置供将来「立即同步」使用。
  manual,

  /// 每 1 小时。
  hourly1,

  /// 每 6 小时。
  hourly6,

  /// 每 12 小时。
  hourly12,

  /// 每 24 小时。
  hourly24,
}

OneDriveSyncFrequency oneDriveSyncFrequencyParse(
  String? raw, {
  required OneDriveSyncFrequency orElse,
}) {
  if (raw == null || raw.isEmpty) return orElse;
  for (final v in OneDriveSyncFrequency.values) {
    if (v.name == raw) return v;
  }
  return orElse;
}

class OneDriveSyncSettings {
  const OneDriveSyncSettings({
    required this.cloudSyncEnabled,
    required this.syncPlaylists,
    required this.syncAppSettings,
    required this.frequency,
  });

  final bool cloudSyncEnabled;
  final bool syncPlaylists;
  final bool syncAppSettings;
  final OneDriveSyncFrequency frequency;

  static const OneDriveSyncSettings defaults = OneDriveSyncSettings(
    cloudSyncEnabled: false,
    syncPlaylists: true,
    syncAppSettings: true,
    frequency: OneDriveSyncFrequency.hourly12,
  );

  OneDriveSyncSettings copyWith({
    bool? cloudSyncEnabled,
    bool? syncPlaylists,
    bool? syncAppSettings,
    OneDriveSyncFrequency? frequency,
  }) {
    return OneDriveSyncSettings(
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      syncPlaylists: syncPlaylists ?? this.syncPlaylists,
      syncAppSettings: syncAppSettings ?? this.syncAppSettings,
      frequency: frequency ?? this.frequency,
    );
  }

  Map<String, dynamic> toJson() => {
        'cloudSyncEnabled': cloudSyncEnabled,
        'syncPlaylists': syncPlaylists,
        'syncAppSettings': syncAppSettings,
        'frequency': frequency.name,
      };

  factory OneDriveSyncSettings.fromJson(Map<String, dynamic> m) {
    try {
      return OneDriveSyncSettings(
        cloudSyncEnabled: m['cloudSyncEnabled'] as bool? ?? false,
        syncPlaylists: m['syncPlaylists'] as bool? ?? true,
        syncAppSettings: m['syncAppSettings'] as bool? ?? true,
        frequency: oneDriveSyncFrequencyParse(
          m['frequency'] as String?,
          orElse: OneDriveSyncFrequency.hourly12,
        ),
      );
    } catch (_) {
      return OneDriveSyncSettings.defaults;
    }
  }
}
