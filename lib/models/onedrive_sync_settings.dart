/// OneDrive 云端同步偏好。
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
    required this.syncUserPlaylists,
    required this.syncHomeGreeting,
    required this.syncQuickEntry,
    required this.syncPlaybackListsAndStats,
    required this.syncLyricsUi,
    required this.syncThemeAppearance,
    required this.frequency,
  });

  final bool cloudSyncEnabled;

  /// 自建歌单（封面、配色、列表与曲目顺序）；默认写入「本设备型号 / 时间戳」目录。
  final bool syncUserPlaylists;

  /// 首页首张卡片问候语（与设置 → 首页问候同源）。
  final bool syncHomeGreeting;

  /// 首页快捷入口：排序与显示开关。
  final bool syncQuickEntry;

  /// 最近播放列表、播放次数累计与收听时长（首页最新 / 最多播放与统计页播放相关 Hive）。
  final bool syncPlaybackListsAndStats;

  /// 歌词样式、桌面 / 车载歌词与播放页屏幕常亮等。
  final bool syncLyricsUi;

  /// 背景主题（含背景图路径与渐变等 SharedPreferences）。
  final bool syncThemeAppearance;

  final OneDriveSyncFrequency frequency;

  /// 是否存在任一会上传到本会话目录的配置切片。
  bool get hasConfigurableSlices =>
      syncHomeGreeting ||
      syncQuickEntry ||
      syncPlaybackListsAndStats ||
      syncLyricsUi ||
      syncThemeAppearance ||
      syncUserPlaylists;

  static const OneDriveSyncSettings defaults = OneDriveSyncSettings(
    cloudSyncEnabled: false,
    syncUserPlaylists: true,
    syncHomeGreeting: true,
    syncQuickEntry: true,
    syncPlaybackListsAndStats: true,
    syncLyricsUi: true,
    syncThemeAppearance: true,
    frequency: OneDriveSyncFrequency.hourly12,
  );

  OneDriveSyncSettings copyWith({
    bool? cloudSyncEnabled,
    bool? syncUserPlaylists,
    bool? syncHomeGreeting,
    bool? syncQuickEntry,
    bool? syncPlaybackListsAndStats,
    bool? syncLyricsUi,
    bool? syncThemeAppearance,
    OneDriveSyncFrequency? frequency,
  }) {
    return OneDriveSyncSettings(
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      syncUserPlaylists: syncUserPlaylists ?? this.syncUserPlaylists,
      syncHomeGreeting: syncHomeGreeting ?? this.syncHomeGreeting,
      syncQuickEntry: syncQuickEntry ?? this.syncQuickEntry,
      syncPlaybackListsAndStats:
          syncPlaybackListsAndStats ?? this.syncPlaybackListsAndStats,
      syncLyricsUi: syncLyricsUi ?? this.syncLyricsUi,
      syncThemeAppearance: syncThemeAppearance ?? this.syncThemeAppearance,
      frequency: frequency ?? this.frequency,
    );
  }

  Map<String, dynamic> toJson() => {
        'cloudSyncEnabled': cloudSyncEnabled,
        'syncUserPlaylists': syncUserPlaylists,
        'syncHomeGreeting': syncHomeGreeting,
        'syncQuickEntry': syncQuickEntry,
        'syncPlaybackListsAndStats': syncPlaybackListsAndStats,
        'syncLyricsUi': syncLyricsUi,
        'syncThemeAppearance': syncThemeAppearance,
        'frequency': frequency.name,
      };

  factory OneDriveSyncSettings.fromJson(Map<String, dynamic> m) {
    try {
      final legacyPlaylists = m['syncPlaylists'] as bool?;
      final legacySettings = m['syncAppSettings'] as bool?;

      bool slice(bool? explicit, {required bool legacyGate}) =>
          explicit ?? legacyGate;

      final playlistsDefault = legacyPlaylists ?? true;
      final settingsDefault = legacySettings ?? true;

      return OneDriveSyncSettings(
        cloudSyncEnabled: m['cloudSyncEnabled'] as bool? ?? false,
        syncUserPlaylists:
            m['syncUserPlaylists'] as bool? ?? playlistsDefault,
        syncHomeGreeting: slice(
          m['syncHomeGreeting'] as bool?,
          legacyGate: settingsDefault,
        ),
        syncQuickEntry: slice(
          m['syncQuickEntry'] as bool?,
          legacyGate: settingsDefault,
        ),
        syncPlaybackListsAndStats: slice(
          m['syncPlaybackListsAndStats'] as bool?,
          legacyGate: settingsDefault,
        ),
        syncLyricsUi: slice(
          m['syncLyricsUi'] as bool?,
          legacyGate: settingsDefault,
        ),
        syncThemeAppearance: slice(
          m['syncThemeAppearance'] as bool?,
          legacyGate: settingsDefault,
        ),
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
