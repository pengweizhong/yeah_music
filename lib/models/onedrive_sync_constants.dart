/// OneDrive「配置同步」云端路径与文件名约定。
///
/// 在用户指定的同步根目录下：
/// `{同步根}/{设备型号文件夹}/{YYYYMMDDTHHmmss}/` 下放按切片拆分的 JSON。
abstract final class OneDriveSyncConstants {
  /// 旧版「跨设备歌单」目录名；已不再写入，列举备份时跳过以免误判为设备文件夹。
  static const String legacyCrossDeviceFolderName = 'YeahMusic_cross_device';

  /// 当前设备会话内的自建歌单导出（封面、配色、曲目顺序等）。
  static const String playlistsBlobFileName = 'yeah_music_playlists.json';

  /// 首页问候（与设置里的首页问候同源）。
  static const String sliceHomeGreetingFileName =
      'yeah_music_slice_home_greeting.json';

  /// 首页快捷入口排序与隐藏。
  static const String sliceQuickEntryFileName =
      'yeah_music_slice_quick_entry.json';

  /// 最近播放列表、播放次数与累计收听时长（驱动首页「最新 / 最多」与统计页相关 Hive）。
  static const String slicePlaybackListsFileName =
      'yeah_music_slice_playback_lists.json';

  /// 歌词样式、桌面 / 车载歌词与播放页屏幕常亮等。
  static const String sliceLyricsUiFileName =
      'yeah_music_slice_lyrics_ui.json';

  /// 背景主题（SharedPreferences appearance）。
  static const String sliceThemeFileName = 'yeah_music_slice_theme.json';

  /// 听歌识曲：AudD / ACRCloud 等与历史记录 Hive。
  static const String sliceSongRecognitionFileName =
      'yeah_music_slice_song_recognition.json';

  static final RegExp sessionFolderPattern =
      RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$');

  static bool isSessionFolderName(String name) =>
      sessionFolderPattern.hasMatch(name.trim());

  /// 已知会话切片文件名。
  static const List<String> sessionBlobFileNames = <String>[
    playlistsBlobFileName,
    sliceHomeGreetingFileName,
    sliceQuickEntryFileName,
    slicePlaybackListsFileName,
    sliceLyricsUiFileName,
    sliceThemeFileName,
    sliceSongRecognitionFileName,
  ];
}
