// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Yeah Music';

  @override
  String get menuHome => '主页';

  @override
  String get menuSongList => '歌曲列表';

  @override
  String get menuPlaylists => '歌单';

  @override
  String get menuMusicSource => '音乐源';

  @override
  String get menuStatistics => '统计';

  @override
  String get menuSettings => '设置';

  @override
  String get statisticsTitle => '统计';

  @override
  String get statisticsSubtitle => '曲库、收听习惯与歌单概览';

  @override
  String get statisticsReloadTooltip => '刷新';

  @override
  String get statisticsReloadStarted => '正在刷新播放统计…';

  @override
  String get statisticsReloadDone => '播放统计已更新';

  @override
  String get statisticsReloadFailed => '无法刷新播放统计';

  @override
  String get statisticsSectionLibrary => '曲库';

  @override
  String get statisticsSectionPlayback => '播放';

  @override
  String get statisticsSectionPlaylists => '歌单';

  @override
  String get statisticsSectionOneDrive => 'OneDrive';

  @override
  String get statisticsTracksLabel => '曲目总数';

  @override
  String get statisticsFoldersLabel => '音乐文件夹';

  @override
  String get statisticsDurationLabel => '估算总时长';

  @override
  String get statisticsDurationHint => '仅统计元数据中带有有效时长的曲目';

  @override
  String get statisticsFormatsLabel => '格式分布';

  @override
  String get statisticsFormatsOther => '其他';

  @override
  String statisticsFormatsMore(int count) {
    return '另有 $count 种扩展名';
  }

  @override
  String get statisticsQualityLabel => '音质分布';

  @override
  String get statisticsQualityHint => '与曲库音质标识相同规则：在元数据可读时根据格式、码率与采样率推断分级';

  @override
  String get statisticsQualityUnknown => '未知';

  @override
  String get statisticsHistoricalListeningLabel => '历史听歌时长';

  @override
  String get statisticsHistoricalListeningHint =>
      '仅在播放器处于播放状态时累计墙上时钟（暂停、停止不计）；倍速不改变累计规则。自本版本起写入本地；强制退出可能丢失尚未落盘的数秒（按批写入）。';

  @override
  String get statisticsPlaybackTotalLabel => '听的总歌数';

  @override
  String get statisticsPlaybackTotalSubtitle => '本地累计播放次数（每次开始播放计一次）';

  @override
  String get statisticsPlaybackDistinctLabel => '有播放记录的曲目数';

  @override
  String get statisticsRecentEntriesLabel => '最近播放列表条数';

  @override
  String statisticsRecentEntriesSubtitle(int max) {
    return '本地最多保留 $max 条路径';
  }

  @override
  String get statisticsPlaylistsCountLabel => '自建歌单数量';

  @override
  String get statisticsPlaylistRefsLabel => '歌单内曲目条目';

  @override
  String get statisticsPlaylistRefsSubtitle => '各歌单路径数相加；同一首歌在多歌单中会重复计数';

  @override
  String get statisticsOneDriveIndexedLabel => '云端索引曲目';

  @override
  String get statisticsOneDriveCachedLabel => '已缓存 / 下载到本地';

  @override
  String get statisticsOneDriveUnavailable => '登录 OneDrive 后查看云端统计';

  @override
  String get statisticsNotInitialized => '正在初始化曲库…';

  @override
  String statisticsDurationHM(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String statisticsDurationMOnly(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get statisticsDurationUnknown => '无法估算';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsBackgroundTheme => '背景主题';

  @override
  String get settingsBackgroundThemeSubtitle => '纯色、自定义颜色或背景图';

  @override
  String get settingsBackgroundThemeDesc => '可选择纯色、自定义强调色或全屏背景图，具体项在下一页调整。';

  @override
  String get settingsSystemInfo => '系统信息';

  @override
  String get settingsSystemInfoSubtitle => '本机与存储空间';

  @override
  String get settingsSystemInfoDesc => '查看设备相关信息与磁盘剩余空间；展开后可查看各目录占用。';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutSubtitle => '版本与开源许可';

  @override
  String get settingsAboutDesc => '应用名称与版本、致谢与开源协议全文。';

  @override
  String get settingsHomeGreetingTitle => '首页问候';

  @override
  String get settingsHomeGreetingListSubtitle => '自定义句子与内置默认轮换展示';

  @override
  String get settingsHomeGreetingHelp =>
      '首页问候卡片第二行会先有一条内置、随界面语言变化的默认文案。下列每一条为你的自定义句子（不限条数）；保存后与默认文案一起轮播，轮播方式可在下方选择顺序或随机。';

  @override
  String get settingsHomeGreetingLineHint => '输入问候文案';

  @override
  String get settingsHomeGreetingRotationTitle => '轮播方式';

  @override
  String get settingsHomeGreetingRotationSequential => '顺序';

  @override
  String get settingsHomeGreetingRotationRandom => '随机';

  @override
  String get settingsHomeGreetingEmptyHint => '暂无自定义句子，点击下方添加一行';

  @override
  String get settingsHomeGreetingAddLine => '添加一行';

  @override
  String get settingsHomeGreetingSave => '保存';

  @override
  String get settingsHomeGreetingSaved => '已保存';

  @override
  String get settingsAboutDialogAuthor => '作者';

  @override
  String get settingsAboutDialogRepo => '仓库';

  @override
  String get settingsAboutDialogLicense => '许可证';

  @override
  String get settingsAboutDialogCopyright => '版权';

  @override
  String get settingsAboutDialogClose => '关闭';

  @override
  String settingsAboutDialogVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutDialogBuildLabel(String buildNumber) {
    return '构建号 $buildNumber';
  }

  @override
  String get settingsAboutDialogVersionTapHint => '点击检查更新';

  @override
  String get settingsAboutUpdateChecking => '正在检查更新…';

  @override
  String get settingsAboutUpdateAlreadyLatest => '已是最新版本';

  @override
  String get settingsAboutUpdateAvailableTitle => '发现新版本';

  @override
  String settingsAboutUpdateAvailableBody(String latest, String current) {
    return '远程版本为 v$latest，当前为 v$current。';
  }

  @override
  String get settingsAboutUpdateOpenReleases => '打开发行页面';

  @override
  String get settingsAboutUpdateCheckFailed => '检查更新失败';

  @override
  String get settingsAboutUpdateNoRelease => '仓库尚无 GitHub Release';

  @override
  String get settingsSponsorTitle => '赞助与支持';

  @override
  String get settingsSponsorSubtitle => '应用免费 · Star 或自愿打赏';

  @override
  String get settingsSponsorSectionFreeTitle => 'Yeah Music 完全免费';

  @override
  String get settingsSponsorSectionFreeBody =>
      'Yeah Music 免费提供完整功能，不设「付费解锁」或「必须订阅」。请勿向声称「售卖本软件」的第三方付费；商店中出现的收费上架如遇非官方账号请谨慎甄别。维护占用业余时间；下列支持均为自愿，不影响任何功能。';

  @override
  String get settingsSponsorSectionStarTitle => '在 GitHub 点 Star';

  @override
  String get settingsSponsorSectionStarHint =>
      'Star 不花钱，能帮助仓库被更多人看到，也方便你接收动态与发行说明。';

  @override
  String get settingsSponsorRepoYeahMusicTitle => 'Yeah Music';

  @override
  String get settingsSponsorRepoYeahMusicSubtitle => '本播放器源码仓库';

  @override
  String get settingsSponsorRepoDynamicSql2Title => 'Dynamic-SQL2';

  @override
  String get settingsSponsorRepoDynamicSql2Subtitle =>
      '动态 SQL2 / Java DSL 开源仓库';

  @override
  String get settingsSponsorEasterEggTriggerLine => '查看付费打赏方法';

  @override
  String get settingsSponsorEasterEggDialogTitle => '想得美';

  @override
  String get settingsSponsorEasterEggDialogBody => '想付钱？门都没有！此项目用爱发电。';

  @override
  String get settingsSponsorExternalHint =>
      '打开链接后将离开本应用，请在可信页面完成操作；打赏不会解锁任何功能。';

  @override
  String get settingsSponsorCopyLink => '复制链接';

  @override
  String get settingsSponsorLinkCopied => '已复制链接';

  @override
  String get settingsSponsorLaunchFailed => '无法打开链接';

  @override
  String get settingsSysinfoSectionDevice => '设备信息';

  @override
  String get settingsSysinfoSectionStorage => '存储空间';

  @override
  String get settingsSysinfoPlatformLabel => '运行平台';

  @override
  String get settingsSysinfoTotalSpace => '总空间';

  @override
  String get settingsSysinfoUsedSpace => '已使用';

  @override
  String get settingsSysinfoFreeSpace => '剩余空间';

  @override
  String get settingsSysinfoStorageUnavailable => '存储信息暂时无法获取';

  @override
  String get settingsSysinfoDeviceModel => '设备型号';

  @override
  String get settingsSysinfoManufacturer => '制造商';

  @override
  String get settingsSysinfoOsVersion => '系统版本';

  @override
  String get settingsSysinfoSdkVersion => 'SDK 版本';

  @override
  String get settingsSysinfoDeviceName => '设备名称';

  @override
  String get settingsSysinfoHostName => '主机名';

  @override
  String get settingsSysinfoKernelVersion => '内核版本';

  @override
  String get settingsSysinfoDistroLabel => '版本';

  @override
  String get settingsSysinfoBuildNumber => '构建号';

  @override
  String get settingsSysinfoError => '错误';

  @override
  String get settingsSysinfoFetchFailed => '无法获取设备信息';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '界面显示语言';

  @override
  String get settingsLanguageDesc => '设置菜单与界面文案语言；曲目信息仍以文件内嵌元数据为准。';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle => '微软账号同步、目录与下载位置';

  @override
  String get settingsOneDriveDesc =>
      '使用 Microsoft 登录（正式版无需填写客户端 ID）。可选音乐浏览根目录、云端应用数据文件夹与本地下载目录；点播时若自定义目录存在则写入该处，否则使用应用数据下的默认存储。';

  @override
  String get settingsPlaybackShortcutsTitle => '快捷键';

  @override
  String get settingsPlaybackShortcutsSubtitle => '播放、暂停、上一曲、下一曲';

  @override
  String get settingsPlaybackShortcutsPlayPause => '播放 / 暂停';

  @override
  String get settingsPlaybackShortcutsPrevious => '上一曲';

  @override
  String get settingsPlaybackShortcutsNext => '下一曲';

  @override
  String get settingsPlaybackShortcutsChange => '更改…';

  @override
  String get settingsPlaybackShortcutsDisable => '关闭';

  @override
  String get settingsPlaybackShortcutsEnable => '开启';

  @override
  String get settingsPlaybackShortcutsDisabledLabel => '已关闭';

  @override
  String get settingsPlaybackShortcutsPressKey => '录制快捷键';

  @override
  String get settingsPlaybackShortcutsPressKeyHint => '请按下新的组合键。Esc 取消。';

  @override
  String get settingsPlaybackShortcutsUnavailableBody =>
      '快捷键仅在 Windows / macOS / Linux 桌面版可自定义。';

  @override
  String get settingsWireRemoteTitle => '耳机线控';

  @override
  String get settingsWireRemoteSubtitle => '有线连击与蓝牙独立下一曲/上一曲键';

  @override
  String get settingsWireRemoteSubtitleOtherPlatforms =>
      '自定义线控仅在 Android 版、应用位于前台时生效。';

  @override
  String get settingsWireRemoteUnavailableTitle => '此处不可编辑';

  @override
  String get settingsWireRemoteUnavailableBody =>
      '耳机按键自定义仅在 Android、应用位于前台时生效（含蓝牙独立键）。桌面端请使用「快捷键」；iOS 由系统处理。';

  @override
  String get settingsWireRemoteUseCustom => '使用自定义线控';

  @override
  String get settingsWireRemoteUseCustomSubtitle => '关闭后由系统按默认方式处理耳机按键。';

  @override
  String get wireRemoteSingleTitle => '单击';

  @override
  String get wireRemoteDoubleTitle => '双击';

  @override
  String get wireRemoteTripleTitle => '三击';

  @override
  String get wireRemoteMediaNextTitle => '「下一曲」媒体键（蓝牙等）';

  @override
  String get wireRemoteMediaPreviousTitle => '「上一曲」媒体键（蓝牙等）';

  @override
  String get wireRemoteActionPlayPause => '播放 / 暂停';

  @override
  String get wireRemoteActionNext => '下一曲';

  @override
  String get wireRemoteActionPrevious => '上一曲';

  @override
  String get wireRemoteActionNone => '无';

  @override
  String get wireRemotePickActionTitle => '选择动作';

  @override
  String get settingsMacosMenuBarLyrics => '菜单栏歌词';

  @override
  String get settingsMacosMenuBarLyricsSubtitle => '菜单栏单行紧凑歌词';

  @override
  String get settingsMacosMenuBarLyricsDesc => '在系统菜单栏显示单行歌词（macOS）';

  @override
  String get settingsDesktopLyricsGroupTitle => '桌面歌词';

  @override
  String get settingsDesktopLyricsGroupSubtitle => '悬浮窗与 macOS 菜单栏歌词';

  @override
  String get settingsDesktopLyricsGroupDetail =>
      '桌面歌词包含可拖动的悬浮歌词窗，以及 macOS 上可选的菜单栏单行歌词。\n\n悬浮窗与播放页使用同一套歌词样式（颜色、多行模式、翻译等）。可锁定位置、调节背景透明度，并设置当前时间轴行上下各显示多少行。\n\n菜单栏歌词（仅 macOS）为紧凑单行，不需要悬浮窗时可在菜单栏常驻查看。';

  @override
  String get settingsDesktopFloatingLyrics => '悬浮歌词';

  @override
  String get settingsDesktopFloatingLyricsSubtitle => '可拖动的当前歌词浮窗';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      '在应用窗口上方显示可拖动的当前歌词，与播放页歌词样式设置一致。';

  @override
  String get settingsDesktopFloatingBgOpacity => '背景透明度';

  @override
  String get settingsDesktopFloatingBgOpacitySubtitle => '歌词板背景的透明程度';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      '歌词面板背景的明暗程度；0 为完全无背景，仅显示文字。';

  @override
  String get settingsDesktopFloatingLinesBefore => '当前行之前';

  @override
  String get settingsDesktopFloatingLinesBeforeSubtitle => '当前行上方时间轴行数';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      '以当前时间轴行为基准，向上允许显示多少行（不含当前行）。';

  @override
  String get settingsDesktopFloatingLinesAfter => '当前行之后';

  @override
  String get settingsDesktopFloatingLinesAfterSubtitle => '当前行下方时间轴行数';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      '以当前时间轴行为基准，向下允许显示多少行（不含当前行）。';

  @override
  String get settingsDesktopFloatingDragLock => '锁定位置';

  @override
  String get settingsDesktopFloatingDragLockSubtitle => '禁止拖动悬浮窗';

  @override
  String get settingsDesktopFloatingDragLockDesc => '开启后悬浮歌词窗口不可拖动。';

  @override
  String get settingsCarLyricsGroupTitle => '车载歌词';

  @override
  String get settingsCarLyricsGroupSubtitle => '媒体通知、蓝牙与 Android Auto';

  @override
  String get settingsCarLyricsGroupDetail =>
      '使用 Android 媒体会话，让锁屏、蓝牙耳机与 Android Auto 等显示正在播放内容并提供控制。\n\n开启：在播放器中构建完整队列，通知与车机上的上一首/下一首对应真实切歌；播放/暂停与单曲循环在支持范围内与 App 一致。\n\n封面：将内嵌封面送到通知与支持显示封面车机。\n\n歌词：在支持的系统上把媒体副标题更新为当前歌词行，规则与 App 内其它歌词展示一致。\n\n随机、仅播一次等模式仍以 App 内「播放模式」为准；车机上的列表循环/随机可能与部分模式不完全一致。';

  @override
  String get settingsCarLyricsEnabled => '启用车载歌词';

  @override
  String get settingsCarLyricsEnabledSubtitle => '通知栏队列与切歌';

  @override
  String get settingsCarLyricsEnabledDesc =>
      '显示媒体通知与队列，支持车机/耳机切歌；单曲循环与系统重复模式同步。';

  @override
  String get settingsCarLyricsShowCover => '显示封面';

  @override
  String get settingsCarLyricsShowCoverSubtitle => '通知与车机展示封面';

  @override
  String get settingsCarLyricsShowCoverDesc => '在通知与支持的车机上展示内嵌封面图。';

  @override
  String get settingsCarLyricsSyncLyrics => '同步当前歌词行';

  @override
  String get settingsCarLyricsSyncLyricsSubtitle => '副标题显示当前歌词';

  @override
  String get settingsCarLyricsSyncLyricsDesc => '在支持的系统上将副标题更新为当前歌词。';

  @override
  String get settingsCarLyricsOnlyAndroidHint =>
      '仅 Android 可生效与修改；当前设备上开关为只读，仅展示已保存的选项。';

  @override
  String get menuBarLyricsIdle => 'Yeah Music · 未在播放';

  @override
  String get menuBarLyricsNoLyrics => '暂无歌词';

  @override
  String get menuBarContextPlay => '播放';

  @override
  String get menuBarContextPause => '暂停';

  @override
  String get menuBarContextPrevious => '上一曲';

  @override
  String get menuBarContextNext => '下一曲';

  @override
  String get oneDriveSettingsTitle => 'OneDrive';

  @override
  String get oneDriveSectionAccount => '账户';

  @override
  String get oneDriveSectionPaths => '目录与存储';

  @override
  String get oneDriveSectionSync => '云端同步';

  @override
  String get oneDriveSyncMasterTitle => '同步到 OneDrive';

  @override
  String get oneDriveSyncMasterSubtitle =>
      '按需勾选同步类别。每次上传会在云端应用文件夹下创建「设备型号 / yyyyMMddTHHmmss」目录。';

  @override
  String get oneDriveSyncItemUserPlaylists => '我的歌单';

  @override
  String get oneDriveSyncItemUserPlaylistsSubtitle =>
      '封面、配色、歌单列表与曲目顺序（按设备目录保存）。';

  @override
  String get oneDriveSyncItemHomeGreeting => '首页问候（首张卡片）';

  @override
  String get oneDriveSyncItemHomeGreetingSubtitle => '与设置 → 首页问候为同一数据源。';

  @override
  String get oneDriveSyncItemQuickEntry => '首页快捷入口';

  @override
  String get oneDriveSyncItemQuickEntrySubtitle => '排序与各入口显示开关。';

  @override
  String get oneDriveSyncItemPlaybackListsStats => '最新 / 最多播放与播放统计';

  @override
  String get oneDriveSyncItemPlaybackListsStatsSubtitle =>
      '最近播放列表、播放次数与累计收听时长。';

  @override
  String get oneDriveSyncItemLyricsUi => '歌词与播放页';

  @override
  String get oneDriveSyncItemLyricsUiSubtitle => '歌词样式、桌面 / 车载歌词与播放页屏幕常亮等。';

  @override
  String get oneDriveSyncItemSongRecognition => '听歌识曲与记录';

  @override
  String get oneDriveSyncItemSongRecognitionSubtitle =>
      '所用引擎及 AudD / ACRCloud 密钥、本地识别历史。';

  @override
  String get oneDriveSyncItemTheme => '背景主题';

  @override
  String get oneDriveSyncItemThemeSubtitle => '渐变、预设 / 自定义颜色与背景图片等（不含界面语言）。';

  @override
  String get oneDriveSyncFrequencyLabel => '同步频率';

  @override
  String get oneDriveSyncFreqManual => '仅手动';

  @override
  String get oneDriveSyncFreq1h => '每 1 小时';

  @override
  String get oneDriveSyncFreq6h => '每 6 小时';

  @override
  String get oneDriveSyncFreq12h => '每 12 小时';

  @override
  String get oneDriveSyncFreq24h => '每 24 小时';

  @override
  String get oneDriveSyncNow => '立即同步';

  @override
  String get oneDriveSyncNowDescription =>
      '立即上传已勾选类别：写入云端应用文件夹下的「设备型号 / yyyyMMddTHHmmss」。';

  @override
  String get oneDriveSyncNowNeedLogin => '请先登录微软账号。';

  @override
  String get oneDriveSyncNowNeedCloudFolder => '请先在上方选好「云端应用数据文件夹」，才知道备份往哪儿放。';

  @override
  String get oneDriveSyncNowFinished => '已上传到云端应用文件夹下的同步目录。';

  @override
  String oneDriveSyncNowFailed(String message) {
    return '备份失败：$message';
  }

  @override
  String get oneDriveRestoreFromCloud => '从云端恢复';

  @override
  String get oneDriveRestoreSubtitle => '选择备份条目（旧版平铺文件或按设备会话目录），再勾选要恢复的内容。';

  @override
  String get oneDriveRestoreSheetTitle => '选择备份时间点';

  @override
  String get oneDriveRestoreGroupThisDevice => '本设备';

  @override
  String get oneDriveRestoreGroupOtherDevices => '其他设备';

  @override
  String get oneDriveRestoreGroupLegacyFlat => '旧版平铺';

  @override
  String get oneDriveRestoreContentSectionTitle => '要恢复的内容';

  @override
  String get oneDriveRestoreLoadMore => '加载更多';

  @override
  String oneDriveRestoreListShowing(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get oneDriveRestoreTabUnknownDevice => '未知设备';

  @override
  String get oneDriveRestoreEmpty => '尚未发现备份文件。请先使用下方「立即同步」上传歌单或设置。';

  @override
  String get oneDriveRestorePlaylistCheckbox => '歌单';

  @override
  String get oneDriveRestoreLegacySettingsCheckbox => '旧版整块设置 JSON';

  @override
  String get oneDriveRestoreSliceHomeGreeting => '首页问候';

  @override
  String get oneDriveRestoreSliceQuickEntry => '首页快捷入口';

  @override
  String get oneDriveRestoreSlicePlaybackLists => '最近播放与统计 Hive';

  @override
  String get oneDriveRestoreSliceLyricsUi => '歌词与屏幕常亮';

  @override
  String get oneDriveRestoreSliceSongRecognition => '听歌识曲与记录';

  @override
  String get oneDriveRestoreSliceTheme => '背景主题';

  @override
  String get oneDriveRestorePlaylistModeMerge => '合并到本地（同 id 歌单合并曲目）';

  @override
  String get oneDriveRestorePlaylistModeReplace => '覆盖本地歌单（先清空再导入）';

  @override
  String get oneDriveRestoreAction => '恢复';

  @override
  String get oneDriveRestoreNeedPickContent => '请至少勾选一项要恢复的内容。';

  @override
  String get oneDriveRestoreMissingPlaylistsFile => '该备份中没有歌单文件。';

  @override
  String get oneDriveRestoreMissingSettingsFile => '该备份中没有旧版整块设置文件。';

  @override
  String oneDriveBackupSnapshotDeviceSession(
    String deviceName,
    String sessionStamp,
  ) {
    return '$deviceName · $sessionStamp';
  }

  @override
  String get oneDriveSyncNowNeedMasterOn => '请先开启上方的「同步到 OneDrive」。';

  @override
  String get oneDriveSyncNowNothingSelected => '请先在上方勾选至少一项同步类别。';

  @override
  String get oneDriveRestoreFinished => '恢复完成。';

  @override
  String oneDriveRestoreFailed(String message) {
    return '恢复失败：$message';
  }

  @override
  String get oneDriveRestoreLoadingList => '正在读取备份列表…';

  @override
  String get oneDriveSyncNowInProgress => '同步中…';

  @override
  String get oneDriveRestoreInProgress => '恢复中…';

  @override
  String get oneDriveCloudAppDataTitle => '云端应用数据文件夹';

  @override
  String get oneDriveCloudAppDataSubtitle => '预留：设置备份、歌单与同步等。';

  @override
  String get oneDriveCloudAppFolderUnset => '未设置';

  @override
  String get oneDriveLocalDownloadTitle => '本地下载目录';

  @override
  String get oneDriveLocalDownloadSubtitle =>
      '从云端点播时：若此处路径存在则保存到该文件夹；未指定或路径不存在时使用下方默认存储空间。';

  @override
  String get oneDriveLocalDownloadUnset => '未设置（后续将使用默认路径）';

  @override
  String get oneDriveChooseCloudFolder => '在 OneDrive 中选择';

  @override
  String get oneDriveChooseLocalFolder => '选择本地文件夹…';

  @override
  String get oneDrivePickFolderForAppData => '选择用于应用数据与未来备份的文件夹。';

  @override
  String get oneDrivePickFolderForMusicUpload => '选择本设备上传音乐时使用的目标文件夹。';

  @override
  String get oneDriveMusicUploadFolderTitle => '上传音乐目标文件夹';

  @override
  String get oneDriveMusicUploadFolderSubtitle =>
      '从本机曲库上传到 OneDrive 时的默认父文件夹。未单独设置时，将使用上方的云端应用文件夹。';

  @override
  String get oneDriveMusicUploadFolderFallback => '与云端应用文件夹相同';

  @override
  String get oneDriveAppMissingClientConfig => '这一版暂时还不能用微软账号登录，下一版本也许会加入该功能';

  @override
  String get oneDriveNeedSignInForPicker => '请先登录后再选择 OneDrive 文件夹。';

  @override
  String get oneDriveClear => '清除';

  @override
  String get oneDriveSignIn => '使用 Microsoft 登录';

  @override
  String get oneDriveSignOut => '退出登录';

  @override
  String get oneDriveSignOutDone => '已退出 OneDrive 账号';

  @override
  String get oneDriveSignedIn => '已登录';

  @override
  String get oneDriveNotSignedIn => '未登录';

  @override
  String get oneDriveLinuxUnsupported => '当前平台暂不支持 OneDrive 登录。';

  @override
  String get oneDriveSignInFailed => '未能登录，请检查网络后重试。';

  @override
  String get oneDriveCacheNote =>
      '默认存储为应用数据下的 onedrive_cache；仅当上方自定义文件夹存在且为目录时才写入该处。';

  @override
  String get oneDriveOpenBrowser => '打开 OneDrive';

  @override
  String get homeEntryOneDrive => 'OneDrive';

  @override
  String get oneDriveBrowserTitle => 'OneDrive';

  @override
  String get oneDriveEmptyFolder => '此文件夹为空';

  @override
  String get oneDrivePlayAll => '播放本文件夹全部';

  @override
  String get oneDrivePreparing => '正在准备…';

  @override
  String get oneDriveDownloadQueueTitle => 'OneDrive 下载队列';

  @override
  String get oneDriveTransferQueueTitle => 'OneDrive 传输队列';

  @override
  String get oneDriveTransferTabDownload => '下载';

  @override
  String get oneDriveTransferTabUpload => '上传';

  @override
  String get oneDriveDownloadPause => '暂停';

  @override
  String get oneDriveDownloadResume => '继续';

  @override
  String get oneDriveDownloadStopAll => '全部停止';

  @override
  String get oneDriveDownloadContinueAll => '全部继续';

  @override
  String get oneDriveDownloadAutoPlayWhenDone => '队列全部完成后自动播放';

  @override
  String get oneDriveDownloadPlayDownloaded => '播放已下载的歌曲';

  @override
  String get oneDriveDownloadStatusPending => '等待中';

  @override
  String get oneDriveDownloadStatusDownloading => '下载中';

  @override
  String get oneDriveDownloadStatusDone => '已完成';

  @override
  String get oneDriveDownloadStatusFailed => '失败';

  @override
  String get oneDriveDownloadStatusCancelled => '已取消';

  @override
  String get oneDriveDownloadCloseJustPanel => '关闭面板（下载继续在后台）';

  @override
  String get oneDriveDownloadQueueEmpty =>
      '暂无批量下载任务。\n在云端曲库或 OneDrive 浏览器中使用「播放全部」即可在此查看；关闭抽屉不会中断下载。';

  @override
  String get oneDriveUploadQueueEmpty =>
      '暂无上传任务。\n在本地曲库中通过多选栏的「上传到 OneDrive」添加；关闭界面不会中断后台传输。';

  @override
  String get oneDriveTransferQueueEmpty => '当前队列中还没有任务。';

  @override
  String get oneDriveDownloadQueuePageHint => '在此暂停、继续或停止批量下载。关闭抽屉不会取消后台任务。';

  @override
  String get oneDriveUploadQueuePageHint =>
      '本机发起的上传会显示在此，可用上方按钮暂停、继续或停止；清空记录会同时影响下载与上传历史。';

  @override
  String get oneDriveDownloadQueueSubtitle => '查看与控制上传、下载与播放';

  @override
  String get oneDriveDownloadQueueTooltip => '下载队列';

  @override
  String get oneDriveBrowserRefreshTooltip => '刷新本页（清除列表缓存并从云端重新加载）';

  @override
  String oneDriveEnqueueAddedSingle(String name) {
    return '已将「$name」添加到下载队列';
  }

  @override
  String oneDriveEnqueueAddedMany(int count) {
    return '已将 $count 首添加到下载队列';
  }

  @override
  String get oneDriveDownloadViewQueue => '查看队列';

  @override
  String get oneDriveDownloadClearHistory => '清空记录';

  @override
  String get oneDriveTransferClearDownloadsList => '清空下载列表';

  @override
  String get oneDriveTransferClearUploadsList => '清空上传列表';

  @override
  String oneDriveError(String message) {
    return 'OneDrive 错误：$message';
  }

  @override
  String get oneDriveUp => '上级';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · 云端曲库';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      '添加的文件夹会递归扫描出音频列表；点曲目按需下载（自定义目录存在则用该目录，否则用默认缓存），已下载的可离线播放。';

  @override
  String get oneDriveCloudLibraryEmpty =>
      '还没有索引。\n请先点「在网盘中选择文件夹」，选好一个或多个音乐目录后，再点「重新扫描」。';

  @override
  String get oneDriveCachedPlaylistTitle => 'OneDrive · 缓存下载';

  @override
  String get oneDriveCachedPlaylistEmpty =>
      '暂无从 OneDrive 下载到本机的曲目。请在云端曲库点播歌曲；文件会保存到应用缓存或你设置的本地下载目录。';

  @override
  String get oneDriveIndexRootsLabel => '已索引目录';

  @override
  String get oneDriveRescanIndex => '重新扫描';

  @override
  String get oneDriveBrowseFolders => '在网盘中选择文件夹';

  @override
  String get oneDrivePickFolderForIndex => '点文件夹右侧的 +，或进入文件夹后点「使用此文件夹」。';

  @override
  String get oneDriveUseCurrentFolder => '使用此文件夹';

  @override
  String get oneDrivePickMultipleFoldersHint => '勾选文件夹进行选择；点右侧箭头进入子文件夹继续选择。';

  @override
  String get oneDriveIncludeOpenFolderInSelection => '包含当前文件夹';

  @override
  String oneDriveAddSelectedFoldersAction(int count) {
    return '添加（$count）';
  }

  @override
  String get oneDriveAddFolderTooltip => '加入云端曲库';

  @override
  String get oneDriveIndexingEllipsis => '正在扫描目录…';

  @override
  String oneDriveLastIndexed(String time) {
    return '上次扫描：$time';
  }

  @override
  String get oneDrivePlayAllTracks => '播放全部';

  @override
  String oneDriveTracksCount(int count) {
    return '$count 首';
  }

  @override
  String get oneDriveCloudSearchHint => '搜索文件名或路径…';

  @override
  String get oneDriveNoIndexRoots => '尚未配置目录，请先「在网盘中选择文件夹」。';

  @override
  String get oneDriveLastIndexedNever => '上次扫描：—';

  @override
  String get oneDriveIndexFoldersRecursiveHint => '扫描会递归包含各文件夹及其子目录下的所有音频文件。';

  @override
  String get oneDriveRemoveIndexFolderTitle => '移除索引文件夹？';

  @override
  String oneDriveRemoveIndexFolderMessage(String name) {
    return '要从索引中移除「$name」吗？该文件夹及其子文件夹中的曲目将不再出现在列表中，需要时可重新添加。';
  }

  @override
  String get oneDriveRemoveIndexFolderAction => '移除';

  @override
  String get languageSettingsTitle => '语言';

  @override
  String get languageSettingsDescription =>
      '选择应用界面显示语言。选择「跟随系统」时，在已提供翻译的情况下将跟随设备语言。';

  @override
  String get langFollowSystem => '跟随系统';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langSimplifiedChinese => '简体中文';

  @override
  String get langTraditionalChinese => '繁體中文';

  @override
  String get themeSettingsTitle => '主题设置';

  @override
  String get globalTheme => '全局主题';

  @override
  String get globalThemeDesc => '控制应用界面整体为浅色、深色或跟随系统；将保存到本机。';

  @override
  String get themeLight => '白天模式';

  @override
  String get themeDark => '夜晚模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get sectionThemeType => '主题类型';

  @override
  String get themeTypeSolid => '预设颜色';

  @override
  String get themeTypeCustom => '自定义颜色';

  @override
  String get themeTypeImage => '背景图片';

  @override
  String get sectionPresetColors => '预设颜色';

  @override
  String get sectionCustomColor => '自定义颜色';

  @override
  String get sectionBackgroundImage => '背景图片';

  @override
  String get primaryColor => '主色调';

  @override
  String get secondaryColor => '次色调';

  @override
  String get themeGradientRgbSectionTitle => '渐变背景';

  @override
  String get themeGradientRgbSectionSubtitle => '渐变 RGB 滑块，可同时微调两端颜色和渐变方向。';

  @override
  String get themeGradientRgbFineTune => '编辑双色与方向…';

  @override
  String get themeGradientRgbDialogTitle => '背景渐变';

  @override
  String get actionSelect => '选择';

  @override
  String get fogBackground => '背景雾化';

  @override
  String get fogBackgroundDesc =>
      '虚化并压暗壁纸，减少对文字图标的干扰。即使调低也会保留轻度整幅压暗与上下边缘渐晕；花纹多或反差大的图建议再调高。默认 45%。';

  @override
  String get fogWeak => '弱';

  @override
  String get fogStrong => '强';

  @override
  String get actionPickImage => '选择图片';

  @override
  String get actionRemove => '移除';

  @override
  String cannotSaveBackground(String error) {
    return '无法保存背景图（请重试或换一张）：$error';
  }

  @override
  String get themeWallpaperSavedRestartHint => '壁纸已保存。若界面仍未更新，请完全退出应用后重新打开。';

  @override
  String get colorDialogTitlePrimary => '选择主色调';

  @override
  String get colorDialogTitleSecondary => '选择次色调';

  @override
  String get actionCancel => '取消';

  @override
  String get actionRetry => '重试';

  @override
  String startupFailed(String error) {
    return '启动失败：$error';
  }

  @override
  String get welcomeTagline => '每一次聆听，都从这里开始';

  @override
  String get welcomeEnter => '进入应用';

  @override
  String get welcomeEnterWait => '进入应用（需等待加载完成）';

  @override
  String get welcomeHintWhenReady => '加载已完成，可随时进入主页。';

  @override
  String get welcomeHintWhenNotReady => '启动完成后将自动进入主页。';

  @override
  String get welcomePreparing => '正在完成启动准备…';

  @override
  String get welcomeCountdownLabel => '启动时间';

  @override
  String get welcomeCountdownSubDoneReady => '首页资源已就绪，可立即进入';

  @override
  String get welcomeStartupSubLoading => '正在加载首页所需数据…完成后自动进入';

  @override
  String get secondsUnit => '秒';

  @override
  String get welcomeNotReadyMessage => '请稍等，资源尚未加载完成。';

  @override
  String welcomeLoadError(String error) {
    return '加载出错了。请检查存储权限或稍后重试。\n\n$error';
  }

  @override
  String get welcomeFakeUserSettings => '正在加载用户设置';

  @override
  String get welcomeFakeLibrary => '正在加载曲库';

  @override
  String get welcomeFakePlaylists => '正在加载歌单';

  @override
  String get welcomeFakeOther => '正在加载其他数据';

  @override
  String get welcomeFakeFinishing => '正在完成初始化';

  @override
  String get homeGreetingLateNight => '夜深了';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homePullLoftTitle => '从本机重新载入';

  @override
  String get homePullReleaseHint => '松手即可载入已保存的配置';

  @override
  String get homePullEmptyTease => '这里什么也没有，再拉也没有用呀';

  @override
  String get homePullStepThemeWallpaper => '主题：配色、渐变与壁纸';

  @override
  String get homePullStepBrightnessMode => '外观：浅色 / 深色模式';

  @override
  String get homePullStepLanguage => '界面语言';

  @override
  String get homePullStepPlaylistsCarousel => '歌单与首页横滑顺序';

  @override
  String get homePullStepShortcuts => '首页快捷入口';

  @override
  String get homePullStepRecentTopPlayed => '最近播放与播放次数';

  @override
  String get homePullStepLyricsDisplay => '歌词显示（从存储重新读取）';

  @override
  String get homePullStepPlaybackPrefs => '播放模式（随机 / 循环等）';

  @override
  String get homePullRefreshDone => '已从本机存储重新载入配置。';

  @override
  String homePullRefreshFailed(String error) {
    return '本机载入失败：$error';
  }

  @override
  String get homeMenuTooltip => '菜单';

  @override
  String get homeSearchTooltip => '搜索';

  @override
  String get homeQuickEntryEmpty => '暂无快捷入口，点击「管理」可显示本地曲库、我的歌单、OneDrive 缓存歌单等';

  @override
  String get homeEntryLibrary => '本地曲库';

  @override
  String get homeEntryMyPlaylists => '我的歌单';

  @override
  String get homeEntryRecent => '最近播放';

  @override
  String get homeEntryMostPlayed => '最多播放';

  @override
  String get homeEntryDiscover => '发现';

  @override
  String get homeEntryCloudLibrary => '云端曲库';

  @override
  String get homeEntryOneDriveCachePlaylist => '缓存歌单';

  @override
  String get homeSectionQuickEntry => '快捷入口';

  @override
  String get homeActionManage => '管理';

  @override
  String get homeSectionMyPlaylists => '我的歌单';

  @override
  String get homeActionMore => '更多';

  @override
  String get homeLoadingLibrary => '正在加载曲库…';

  @override
  String get homeRecentEmpty => '暂无最近播放，在曲库或歌单中播放歌曲后会显示';

  @override
  String get homeSectionMostPlayed => '最多播放';

  @override
  String get homeSectionRecentPlays => '最近播放';

  @override
  String get homeActionAll => '全部';

  @override
  String get homeMostPlayedPathMismatch =>
      '已有播放次数记录，但路径与当前曲库不一致（重命名/移动后请重扫音乐目录，再播几次会恢复）';

  @override
  String get homeMostPlayedEmpty => '暂无播放次数统计，在曲库或歌单中多播几次歌后会按次数排行';

  @override
  String get mostPlayedSwitchSortAscending => '切换为按播放次数正序（少→多）';

  @override
  String get mostPlayedSwitchSortDescending => '切换为按播放次数倒序（多→少）';

  @override
  String homePlayCount(int c) {
    return '已播放 $c 次';
  }

  @override
  String homePlayCountWithBase(String base, int c) {
    return '$base · 已播放 $c 次';
  }

  @override
  String homeGreetingLine(String greeting) {
    return '$greeting，今天想听点什么？';
  }

  @override
  String get homeGreetingSub => '从下面继续上次的歌，或选一张歌单开始';

  @override
  String get homeSearchHint => '搜索歌曲、歌手、歌单';

  @override
  String get homeContinuePlaying => '继续播放';

  @override
  String get homeUnknownTitle => '未知';

  @override
  String get homeNowPlayingAlbum => '正在播放';

  @override
  String get homeNothingPlaying => '还没有在播放';

  @override
  String get homeOpenLibraryToPlay => '去本地曲库选一首歌开始';

  @override
  String get homeAllSongsLoading => '加载中…';

  @override
  String get homeScanMusicFolder => '去扫描音乐目录';

  @override
  String homeTrackCount(int n) {
    return '$n 首';
  }

  @override
  String get homeAllSongs => '全部歌曲';

  @override
  String get homeCreatePlaylist => '创建歌单';

  @override
  String get homeCreatePlaylistSub => '集中收藏你喜欢的歌';

  @override
  String get homeEmptyPlaylist => '空歌单';

  @override
  String get songsListEmpty => '暂无歌曲';

  @override
  String get tooltipSort => '排序';

  @override
  String get playbackFailedSnackMessage => '无法播放该曲目，文件可能缺失、无法读取或格式不支持。';

  @override
  String get languageRestartNotice => '部分界面需重启应用后才会完全应用所选语言。';

  @override
  String get locateNotInList => '当前播放不在本列表';

  @override
  String get locateToCurrent => '定位到当前';

  @override
  String get locateToCurrentPlaying => '定位到当前播放';

  @override
  String get locateToLyricLine => '定位到当前歌词';

  @override
  String get tooltipBack => '返回';

  @override
  String get tooltipAddToPlaylist => '加入歌单';

  @override
  String get menuPlayNextAfterCurrent => '下一曲播放';

  @override
  String get libraryPlayNextAfterCurrentQueued => '当前曲目结束后将播放所选歌曲';

  @override
  String get libraryPlayNextAfterCurrentNotInQueue => '所选歌曲不在当前播放队列中';

  @override
  String get tooltipDone => '完成';

  @override
  String get tooltipMoreActions => '操作';

  @override
  String get tooltipMore => '更多';

  @override
  String get tooltipLyricStyle => '歌词样式';

  @override
  String get songPageMoreSheetTitle => '更多操作';

  @override
  String get songPageMoreQueryMetadata => '查询歌曲元信息';

  @override
  String get songPageMoreUploadOneDrive => '上传至 OneDrive';

  @override
  String get songPageMoreShare => '分享';

  @override
  String get songPageMoreEditMusicTagsExternal => '使用音乐标签编辑…';

  @override
  String get songPageMoreEditMusicTagsInline => '编辑内嵌标签…';

  @override
  String get songPageInlineTagsUnstableTitle => '提示';

  @override
  String get songPageInlineTagsUnstableBody =>
      '此功能尚未完全稳定，写入时可能损坏音频文件内的元数据。建议先克隆或复制该歌曲作为备份后再继续。';

  @override
  String get songPageInlineTagsUnstableContinue => '仍要继续';

  @override
  String get songPageInlineTagsUnstableCancel => '取消';

  @override
  String get songPageInlineTagsEditorTitle => '编辑内嵌标签';

  @override
  String get songPageInlineTagsFieldTitle => '标题';

  @override
  String get songPageInlineTagsFieldArtist => '艺术家';

  @override
  String get songPageInlineTagsFieldAlbum => '专辑';

  @override
  String get songPageInlineTagsCoverSection => '内嵌封面';

  @override
  String get songPageInlineTagsCoverReplace => '选择图片并裁剪…';

  @override
  String get songPageInlineTagsCoverRemove => '移除封面';

  @override
  String get songPageInlineTagsCoverInvalid => '请选择 JPEG 或 PNG 图片。';

  @override
  String get songPageInlineTagsFieldYear => '年份';

  @override
  String get songPageInlineTagsFieldTrackNumber => '曲目编号';

  @override
  String get songPageInlineTagsFieldTrackTotal => '曲目总数';

  @override
  String get songPageInlineTagsFieldDiscNumber => '碟片编号';

  @override
  String get songPageInlineTagsFieldDiscTotal => '碟片总数';

  @override
  String get songPageInlineTagsFieldLyrics => '歌词';

  @override
  String get songPageInlineTagsSave => '保存';

  @override
  String get songPageInlineTagsSaved => '已写入文件';

  @override
  String songPageInlineTagsSaveFailed(Object error) {
    return '无法保存标签：$error';
  }

  @override
  String get songPageStorageManageAllFilesHint =>
      '修改或删除外部存储中的音频需要「所有文件访问」权限，请在系统设置中为本应用开启后重试。';

  @override
  String get audioQualityTierLq => '流畅';

  @override
  String get audioQualityTierStd => '标准';

  @override
  String get audioQualityTierHq => '高品质';

  @override
  String get audioQualityTierSq => '无损（CD 级）';

  @override
  String get audioQualityTierHr => '高解析';

  @override
  String get audioQualityTierDsd => '顶级发烧';

  @override
  String get songPageMoreEditLyricsExternal => '使用 SyncedLyricEditor 编辑…';

  @override
  String get songPageSyncedLyricEditorNotInstalled =>
      '未安装 SyncedLyric Editor，无法跳转编辑。';

  @override
  String get songPageSyncedLyricEditorLaunchFailed =>
      '无法打开 SyncedLyric Editor。';

  @override
  String get songPageMusicTagEditorUnsupportedPlatform =>
      '外部标签编辑仅在 Android 上可用。';

  @override
  String get songPageMusicTagEditorFileNotFound => '未找到音频文件。';

  @override
  String get songPageMusicTagEditorNotInstalled =>
      '未安装 Music Tag Editor，无法跳转编辑。';

  @override
  String get songPageMusicTagEditorCannotSharePath => '无法从当前路径向其它应用打开该文件。';

  @override
  String get songPageMusicTagEditorLaunchFailed => '无法打开 Music Tag Editor。';

  @override
  String get songPageMetadataDialogTitle => '音频元信息';

  @override
  String get songPageMetadataReadFailed => '无法读取该文件的元信息。';

  @override
  String get songPageShareFileNotFound => '磁盘上找不到该文件。';

  @override
  String get songPageDeleteDiskWarningTitle => '从磁盘删除？';

  @override
  String get songPageDeleteDiskWarningBody =>
      '将从设备存储中永久删除该音频文件，且不可恢复；并从歌单与播放历史中移除。';

  @override
  String get songPageDeleteContinue => '继续删除';

  @override
  String get songPageDeleteFinalConfirmTitle => '确认删除';

  @override
  String songPageDeleteFinalConfirmBody(Object fileName) {
    return '确定删除「$fileName」吗？';
  }

  @override
  String get songPageMetaFieldTitle => '标题';

  @override
  String get songPageMetaFieldArtist => '艺术家';

  @override
  String get songPageMetaFieldAlbum => '专辑';

  @override
  String get songPageMetaFieldDuration => '时长';

  @override
  String get songPageMetaFieldBitrate => '比特率';

  @override
  String get songPageMetaFieldSampleRate => '采样率';

  @override
  String get songPageMetaFieldYear => '年份';

  @override
  String get songPageMetaFieldTrack => '音轨';

  @override
  String get songPageMetaFieldDisc => '碟片';

  @override
  String get songPageMetaFieldPath => '路径';

  @override
  String get songPageMetaFieldSize => '文件大小';

  @override
  String get songPageMetaFieldGenre => '流派';

  @override
  String get songPageMetaFieldPerformers => '其它艺人';

  @override
  String get songPageMetaFieldLanguage => '语言';

  @override
  String get songPageMetaFieldEmbeddedLyrics => '嵌入式歌词';

  @override
  String get songPageMetaFieldFormat => '格式';

  @override
  String get songPageMetaSectionTags => '标签信息';

  @override
  String get songPageMetaSectionAudio => '音频参数';

  @override
  String get songPageMetaSectionFile => '文件';

  @override
  String get tooltipFolderInfo => '目录信息';

  @override
  String get tooltipReloadSongs => '重新加载歌曲';

  @override
  String get tooltipEdit => '编辑';

  @override
  String get tooltipRemoveFolder => '移除目录';

  @override
  String get actionDelete => '删除';

  @override
  String get actionSave => '保存';

  @override
  String get actionCreate => '创建';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionGotIt => '我知道了';

  @override
  String get actionOK => '确定';

  @override
  String get settingsRowHelpTooltip => '说明';

  @override
  String get fieldName => '名称';

  @override
  String get fieldNewNameHint => '新名称';

  @override
  String get folderAppBarTitle => '文件夹';

  @override
  String folderSongsCount(int n) {
    return '$n 首';
  }

  @override
  String get folderInfoAlias => '文件夹别名：';

  @override
  String get folderInfoPath => '文件夹路径：';

  @override
  String get folderInfoSongCount => '歌曲数量：';

  @override
  String get folderInfoAdded => '加入时间：';

  @override
  String get folderAddLoadingTitle => '正在加载歌曲';

  @override
  String get folderReloading => '正在重新加载';

  @override
  String get folderScanningWait => '正在扫描文件夹，请稍候…';

  @override
  String folderLoadOk(int n) {
    return '成功加载 $n 首歌曲';
  }

  @override
  String folderLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get folderRemoveTitle => '确认移除？';

  @override
  String folderRemoveMessage(String name) {
    return '是否移除目录：$name（仅移除引用，不删磁盘上音乐文件）';
  }

  @override
  String get folderDuplicateDialogTitle => '提示';

  @override
  String folderDuplicateMessage(String path) {
    return '添加了重复的文件夹：$path';
  }

  @override
  String folderAddOk(int n) {
    return '成功添加 $n 首歌曲';
  }

  @override
  String get folderAddErrorTitle => '错误';

  @override
  String folderAddErrorMessage(String error) {
    return '加载文件夹失败：$error';
  }

  @override
  String get folderAddNoSelection => '未选择文件夹（已取消或关闭选择框）。';

  @override
  String get folderRenameDialogTitle => '重命名文件夹';

  @override
  String get playlistPageTitle => '歌单';

  @override
  String get playlistNotFound => '歌单不存在';

  @override
  String get playlistNotFoundMessage => '该歌单可能已被删除';

  @override
  String get playlistEmptyNoSongs => '暂无可用歌曲\n（请先在「音乐源」扫描，或歌曲路径已失效）';

  @override
  String get playlistDeleteTitle => '删除歌单';

  @override
  String get playlistDeleteMessage => '确定删除该歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。';

  @override
  String get playlistDeleteBatchTitle => '批量删除歌单';

  @override
  String playlistDeleteBatchMessage(int n) {
    return '确定删除已选的 $n 个歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。';
  }

  @override
  String get playlistDeletedOne => '已删除歌单';

  @override
  String get importDialogBody =>
      '歌曲以「完整文件路径」区分：同名、同歌手、不同文件或不同音质会对应不同路径，导入后不会误合并。\n\n• 合并导入：与本地「歌单 id」相同的条目会合并曲目列表（路径去重）；备份中有而本地没有的歌单会新建。\n• 替换全部：先清空本地全部歌单，再按备份恢复（谨慎操作）。';

  @override
  String playlistCreatedOn(String date) {
    return '创建于 $date';
  }

  @override
  String get recentPlaysEmptyTitle => '还没有播放记录';

  @override
  String get quickEntryReorderHint => '拖动手柄可调整顺序。关闭「在首页显示」后该入口在首页隐藏。';

  @override
  String get quickEntryShowOnHome => '在首页显示';

  @override
  String get playlistSearchHint => '搜索歌曲、艺术家或文件名…';

  @override
  String get searchNoMatchingSongs => '未找到匹配的歌曲';

  @override
  String get playlistRenameTitle => '重命名歌单';

  @override
  String get playlistCoverStyleTitle => '歌单封面颜色';

  @override
  String get playlistCoverStyleSubtitle =>
      '应用于首页横滑卡片与音乐源歌单列表左侧预览；选择轮换预设则按列表顺序自动配色；渐变可使用自选双色以增强对比。';

  @override
  String get playlistCoverUseDefaultPalette => '使用轮换预设配色';

  @override
  String get playlistCoverSolidSection => '单色';

  @override
  String get playlistCoverGradientSection => '渐变';

  @override
  String get playlistCoverCustomGradientTitle => '自定义渐变';

  @override
  String get playlistCoverGradientStartColor => '起始色';

  @override
  String get playlistCoverGradientEndColor => '结束色';

  @override
  String get playlistCoverGradientSwapColors => '交换两端颜色';

  @override
  String get playlistCoverGradientDirectionTitle => '渐变方向';

  @override
  String get playlistCoverGradientDirHorizontalLR => '左→右';

  @override
  String get playlistCoverGradientDirHorizontalRL => '右→左';

  @override
  String get playlistCoverGradientDirVerticalTB => '上→下';

  @override
  String get playlistCoverGradientDirVerticalBT => '下→上';

  @override
  String get playlistCoverGradientDirDiagonalTLBR => '对角 ↘（左上→右下）';

  @override
  String get playlistCoverGradientDirDiagonalTRBL => '对角 ↙（右上→左下）';

  @override
  String get playlistCoverGradientDirDiagonalBRTL => '对角 ↖（右下→左上）';

  @override
  String get playlistCoverGradientDirDiagonalBLTR => '对角 ↗（左下→右上）';

  @override
  String get playlistCoverRgbTitle => '自定义 RGB';

  @override
  String get playlistCoverRgbRed => '红';

  @override
  String get playlistCoverRgbGreen => '绿';

  @override
  String get playlistCoverRgbBlue => '蓝';

  @override
  String get playlistCoverRgbPreview => '预览';

  @override
  String get playlistCoverPreviewLabel => '当前效果';

  @override
  String get playlistCoverMenuItem => '封面颜色…';

  @override
  String get playlistCoverPictureSection => '图片';

  @override
  String get playlistCoverPickImage => '选择图片…';

  @override
  String get playlistCoverRemoveImage => '移除图片';

  @override
  String get imageCropTitle => '裁剪图片';

  @override
  String get imageCropFailure => '无法裁剪该图片。';

  @override
  String get exportCannot => '无法导出该歌单';

  @override
  String exportSaved(String path) {
    return '已导出：$path';
  }

  @override
  String get exportCancelled => '已取消导出';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get exportDialogTitle => '导出歌单';

  @override
  String get menuRename => '重命名';

  @override
  String get menuExportThis => '导出本歌单…';

  @override
  String get menuDeletePlaylist => '删除歌单';

  @override
  String get exportSelectFirst => '请先选择要导出的歌单';

  @override
  String get exportNoneToExport => '没有可导出的歌单，请检查选择';

  @override
  String get exportAllPlaylists => '导出全部歌单';

  @override
  String get exportSelectedPlaylists => '导出所选歌单';

  @override
  String get exportSelected => '导出所选';

  @override
  String get exportAll => '导出全部';

  @override
  String get importCannotRead => '无法读取文件（可尝试较小备份或检查权限）';

  @override
  String importParseError(String message) {
    return '无法解析：$message';
  }

  @override
  String get importMerge => '合并导入';

  @override
  String get importReplaceAll => '替换全部';

  @override
  String get importMerged => '已合并导入';

  @override
  String get importReplaced => '已替换导入';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String playlistsDeletedN(int n) {
    return '已删除 $n 个歌单';
  }

  @override
  String librarySongsDeletedN(int n) {
    return '已删除 $n 首歌曲';
  }

  @override
  String get fabNewPlaylist => '新建歌单';

  @override
  String get emptyPlaylistsHint =>
      '还没有歌单\n在播放页或歌曲列表可将歌曲加入歌单\n\n可在右上角「⋮」中导入、单选/多选';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByPath => '按路径';

  @override
  String get sortByCreated => '按创建时间';

  @override
  String get sortByUpdated => '按更新时间';

  @override
  String get sortByAddedToPlaylist => '按加入歌单时间';

  @override
  String get sortByAddedToPlaylistSub => '正序：先加入在前 · 反序：后加入在前';

  @override
  String get lyricAlignLeft => '左';

  @override
  String get lyricAlignCenter => '中';

  @override
  String get lyricAlignRight => '右';

  @override
  String get addToPlaylistHint => '新建歌单名称';

  @override
  String addToPlaylistUpdatedN(int n) {
    return '已更新歌单（$n 个）';
  }

  @override
  String get noLyrics => '暂无歌词';

  @override
  String get songNotFound => '歌曲不存在';

  @override
  String get pageUnknownTitle => '未知标题';

  @override
  String get queueNoTracks => '暂无曲目';

  @override
  String get playQueueTitle => '播放队列';

  @override
  String get queuePendingPlayAfterCurrentSection => '下一曲播放（待播）';

  @override
  String get playbackModeTitle => '播放模式';

  @override
  String get playbackSequential => '顺序播放';

  @override
  String get playbackShuffle => '随机播放';

  @override
  String get playbackSingleLoop => '单曲循环';

  @override
  String get playbackOnce => '仅播放一次';

  @override
  String get playbackTimer => '定时关闭';

  @override
  String get sleepTimerSheetTitle => '定时关闭';

  @override
  String get sleepTimerCancel => '取消定时关闭';

  @override
  String sleepTimerMinutesN(int n) {
    return '$n 分钟';
  }

  @override
  String get sleepTimerCustom => '自定义时间';

  @override
  String sleepTimerCurrentN(int n) {
    return '当前 $n 分钟';
  }

  @override
  String get sleepTimerLabelMinutes => '分钟';

  @override
  String sleepTimerInvalidRange(int min, int max) {
    return '请输入 $min–$max 之间的整数';
  }

  @override
  String sleepTimerPlayedMinutes(int minutes) {
    return '定时关闭：已播放 $minutes 分钟';
  }

  @override
  String get songPageKeepScreenAwake => '播放页屏幕常亮';

  @override
  String get lyricStyleKeepScreenAwakeSub => '在播放页查看歌词时不自动熄屏';

  @override
  String get lyricModeEmptyHint => '切换显示模式';

  @override
  String get lyricModeAllLines => '多行歌词：全部行（点击为单行）';

  @override
  String lyricModeSingleLineN(int n) {
    return '多行歌词：仅第 $n 行（继续点击切换）';
  }

  @override
  String get sortOptionsTitle => '排序方式';

  @override
  String addToPlaylistTitle(String name) {
    return '加入歌单 · $name';
  }

  @override
  String get addToPlaylistMultiHelp => '可多选；取消勾选将从对应歌单移除该歌曲';

  @override
  String get addToPlaylistNoPlaylistsYet => '暂无歌单，请先输入名称并创建';

  @override
  String get quickEntrySettingsTitle => '快捷入口';

  @override
  String get playlistSelectModeSingle => '单选';

  @override
  String get playlistSelectModeMulti => '多选';

  @override
  String get menuImportPlaylists => '导入歌单';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String playlistSelectCount(int n, int m) {
    return '已选 $n / $m';
  }

  @override
  String get lyricStyleSyncSubtitle => '与当前播放页歌词同步';

  @override
  String get lyricStyleSectionDisplay => '显示';

  @override
  String get lyricStyleSectionDisplaySub => '原文与多行译文的开关';

  @override
  String get lyricStyleShowOriginal => '显示原文';

  @override
  String get lyricStyleShowOriginalSub => '每个时间戳第 1 行';

  @override
  String get lyricStyleShowTranslation => '显示翻译/附加行';

  @override
  String get lyricStyleShowTranslationSub => '第 2 行及以后';

  @override
  String get lyricStyleSectionTypography => '字号与行距';

  @override
  String get lyricStyleSectionTypographySub => '滑条调节后即时生效';

  @override
  String get lyricStyleFontOriginal => '原文字号';

  @override
  String get lyricStyleFontTranslation => '翻译字号';

  @override
  String get lyricStyleLineSpacing => '行间距';

  @override
  String get lyricStyleSectionLineAlign => '行对齐';

  @override
  String get lyricStyleSectionStateColors => '行状态颜色';

  @override
  String get lyricStyleSectionStateColorsSub => '正在播放、已播过、未播到';

  @override
  String get lyricStyleStateNowPlaying => '正在播放行';

  @override
  String get lyricStyleStatePlayed => '已播过的行';

  @override
  String get lyricStyleStateUpcoming => '未播到的行';

  @override
  String get lyricStyleColorNowOriginal => '正在播放 — 原文';

  @override
  String get lyricStyleColorNowTranslation => '正在播放 — 译文';

  @override
  String get lyricStyleColorPlayedOriginal => '已播过 — 原文';

  @override
  String get lyricStyleColorPlayedTranslation => '已播过 — 译文';

  @override
  String get lyricStyleColorUpcomingOriginal => '未播到 — 原文';

  @override
  String get lyricStyleColorUpcomingTranslation => '未播到 — 译文';

  @override
  String get lyricStyleColorPersistNote => '颜色将写入本地设置，切歌后仍保留。';

  @override
  String get lyricStyleActiveGradientTitle => '正在播放行渐变';

  @override
  String get lyricStyleStateGradientSub => '开启后，该双色渐变优先于上方原文/译文纯色；关闭则仅用纯色。';

  @override
  String get lyricStyleActiveGradientTune => '编辑渐变';

  @override
  String get lyricStyleActiveGradientDialogTitle => '正在播放行渐变';

  @override
  String get lyricStylePlayedGradientTitle => '已播过行渐变';

  @override
  String get lyricStyleUpcomingGradientTitle => '未播到行渐变';

  @override
  String get lyricStylePlayedGradientDialogTitle => '已播过行渐变';

  @override
  String get lyricStyleUpcomingGradientDialogTitle => '未播到行渐变';

  @override
  String get lyricColorPickerHint => '点选色块';

  @override
  String get lyricLabelOriginal => '原文';

  @override
  String get lyricLabelTranslation => '译文';

  @override
  String get libraryBatchSelect => '多选';

  @override
  String get libraryBatchDone => '完成';

  @override
  String get libraryBatchSelectAll => '全选';

  @override
  String get libraryBatchDelete => '删除';

  @override
  String get libraryBatchRename => '重命名';

  @override
  String get libraryBatchUploadOneDrive => '上传到 OneDrive';

  @override
  String get libraryBatchDeleteConfirmTitle => '删除所选歌曲？';

  @override
  String get libraryBatchDeleteConfirmMessage => '将从本机删除文件，并更新歌单与最近播放。此操作不可撤销。';

  @override
  String get libraryBatchNoneSelected => '请先选择歌曲';

  @override
  String get libraryBatchRenameTitle => '批量重命名';

  @override
  String get libraryBatchRenameHint => '名称模板，用 %n 表示递增序号（如 曲目 %n）';

  @override
  String get libraryBatchRenameStart => '起始编号';

  @override
  String get libraryRenameSingleTitle => '重命名单曲';

  @override
  String get libraryRenameSingleHint => '只填主文件名，扩展名保持不变。';

  @override
  String get libraryRenameSingleFieldLabel => '文件名';

  @override
  String get libraryRenameSingleDone => '已重命名';

  @override
  String get libraryCloneSong => '克隆歌曲';

  @override
  String get libraryCloneSongTitle => '克隆为新文件';

  @override
  String get libraryCloneSongHint => '输入副本的主文件名（扩展名与原文件相同），保存在同一文件夹。';

  @override
  String get libraryCloneSongDefaultSuffix => ' 副本';

  @override
  String get libraryCloneSongDone => '已克隆';

  @override
  String get libraryCloneSongFailed => '克隆失败';

  @override
  String get libraryCloneSongProgressTitle => '正在克隆歌曲';

  @override
  String get libraryCloneSongProgressMessage => '正在复制文件并刷新曲库…';

  @override
  String get libraryBatchUploadNeedSignIn => '请先在设置中登录 OneDrive';

  @override
  String get libraryBatchUploadNeedCloudFolder => '请先在 OneDrive 设置中选择云端应用文件夹';

  @override
  String get libraryBatchUploadNeedParentFolder =>
      '请先在 OneDrive 设置中选择「上传音乐」文件夹或云端应用文件夹。';

  @override
  String get libraryBatchUploadQueued => '已加入传输队列';

  @override
  String get libraryBatchOpenQueue => '查看队列';

  @override
  String get libraryBatchAddToPlaylist => '添加到歌单';

  @override
  String libraryBatchAddToPlaylistSheetTitle(int count) {
    return '将 $count 首歌添加到用户歌单';
  }

  @override
  String get libraryBatchAddToPlaylistSheetHelp =>
      '已勾选的歌单是「当前所选曲目均已在其中」的歌单；确定后为所选每一首歌同步勾选状态。';

  @override
  String get libraryBatchAddToPlaylistDone => '歌单归属已更新';

  @override
  String get libraryReloadMetadata => '重新加载元信息';

  @override
  String get libraryReloadMetadataDone => '已从文件重新加载元信息';

  @override
  String get oneDriveUploadStatusUploading => '上传中';

  @override
  String get oneDriveTaskDirectionUpload => '上传';

  @override
  String get homeEntrySongRecognizer => '听歌识曲';

  @override
  String get songRecognizerTitle => '听歌识曲';

  @override
  String get songRecognizerModeInApp => '应用内';

  @override
  String get songRecognizerModeAmbient => '环境聆听';

  @override
  String get songRecognizerModeInAppHelp =>
      '请保持在本页，将手机靠近正在播放的音乐，约录制 10 秒以获得较高识别率。';

  @override
  String get songRecognizerModeAmbientHelp =>
      '在本页开启后，每隔约 20 秒自动采样识别。请将手机靠近外放或其他 App 播放的扬声器；离开应用后部分机型可能中断麦克风。';

  @override
  String get songRecognizerStart => '开始识别';

  @override
  String get songRecognizerSnackbarStarted => '开始识别…';

  @override
  String get songRecognizerSnackbarCancelled => '已取消识别';

  @override
  String get songRecognizerStopAmbient => '停止环境聆听';

  @override
  String get songRecognizerListening => '聆听中…';

  @override
  String get songRecognizerRecognizing => '识别中…';

  @override
  String get songRecognizerHistory => '识别记录';

  @override
  String get songRecognizerHistoryEmpty => '暂无记录';

  @override
  String get songRecognizerHistoryFilterAll => '全部';

  @override
  String get songRecognizerHistoryFilterMatched => '成功匹配';

  @override
  String get songRecognizerHistoryFilterArchived => '收藏';

  @override
  String get songRecognizerHistoryEmptyMatched => '暂无成功匹配的记录';

  @override
  String get songRecognizerHistoryEmptyArchived => '暂无收藏记录';

  @override
  String get songRecognizerDeleteHistoryEntryTitle => '删除记录';

  @override
  String get songRecognizerDeleteHistoryEntryMessage => '确定删除这条识别记录？';

  @override
  String get songRecognizerSwipeArchive => '收藏';

  @override
  String get songRecognizerSwipeRestore => '取消收藏';

  @override
  String get songRecognizerSwipeDelete => '删除';

  @override
  String get songRecognizerEntryArchived => '已收藏';

  @override
  String get songRecognizerEntryRestoredFromArchive => '已取消收藏';

  @override
  String get songRecognizerCopyEntry => '复制';

  @override
  String get songRecognizerEntryCopied => '已复制到剪贴板';

  @override
  String get songRecognizerCopyLabelTime => '时间：';

  @override
  String get songRecognizerCopyLabelMode => '采集方式：';

  @override
  String get songRecognizerCopyLabelService => '识别服务：';

  @override
  String get songRecognizerCopyLabelSong => '歌曲：';

  @override
  String get songRecognizerCopyLabelArtist => '歌手：';

  @override
  String get songRecognizerCopyLabelAlbum => '专辑：';

  @override
  String get songRecognizerCopyLabelReleased => '发行日期：';

  @override
  String get songRecognizerCopyLabelAppleMusic => 'Apple Music：';

  @override
  String get songRecognizerCopyLabelSpotify => 'Spotify：';

  @override
  String get songRecognizerCopyLabelNoMatch => '结果：';

  @override
  String get songRecognizerCopyLabelError => '错误：';

  @override
  String get songRecognizerClearHistory => '清空记录';

  @override
  String get songRecognizerClearHistoryConfirm => '确定删除全部识别历史？';

  @override
  String get songRecognizerNoMatch => '未匹配到歌曲，可在更安静环境重试或靠近声源。';

  @override
  String get songRecognizerOpenAppleMusic => 'Apple Music';

  @override
  String get songRecognizerOpenSpotify => 'Spotify';

  @override
  String get songRecognizerApiKey => 'AudD API Token';

  @override
  String get songRecognizerApiKeyHelp =>
      '正式使用建议在 audd.io 控制台创建 Token 并粘贴到此；留空将使用公开试用 Token（额度极低、易被限流）。';

  @override
  String get songRecognizerSave => '保存';

  @override
  String get songRecognizerMicDenied => '需要麦克风权限才能识曲';

  @override
  String get songRecognizerWebUnsupported => '当前浏览器版本暂不支持听歌识曲。';

  @override
  String get songRecognizerAccuracyTip => '建议：安静环境、片段约 10–12 秒、手机靠近扬声器，识别更准确。';

  @override
  String get songRecognizerDuplicateSkipped => '与最近一条结果相同，未重复写入';

  @override
  String get songRecognizerError => '识别失败';

  @override
  String get songRecognizerAmbientActive => '环境聆听进行中';

  @override
  String get songRecognizerTokenMenu => 'API Token';

  @override
  String get songRecognizerCredentialsMenu => '账号与密钥';

  @override
  String get songRecognizerProviderLabel => '识别服务';

  @override
  String get songRecognizerProviderAudd => 'AudD';

  @override
  String get songRecognizerProviderAcrcloud => 'ACRCloud';

  @override
  String get songRecognizerModeLabel => '采集方式';

  @override
  String get songRecognizerAcrTitle => 'ACRCloud 项目';

  @override
  String get songRecognizerAcrHelp =>
      '填写控制台中的 Host（如 identify-eu-west-1.acrcloud.com，不要带 https:// 或路径）、Access Key 与 Access Secret（音视频识别项目）。';

  @override
  String get songRecognizerAcrHost => '主机 Host';

  @override
  String get songRecognizerAcrHostHint => 'identify-….acrcloud.com';

  @override
  String get songRecognizerAcrAccessKey => 'Access Key';

  @override
  String get songRecognizerAcrSecret => 'Secret Key';

  @override
  String get songRecognizerAcrIncomplete =>
      '请在本页填写并保存 ACRCloud 的 Host、Access Key 与 Secret Key 后再识别。';

  @override
  String get songRecognizerSectionApiConfig => '接口配置';

  @override
  String get songRecognizerConfigHint => '在识曲主页选择使用哪一家；在此页分别填写并保存两套密钥（仅保存在本机）。';

  @override
  String get songRecognizerConfigSaved => '已保存';

  @override
  String get songRecognizerAuddCardSubtitle =>
      '来自 audd.io 的控制台 Token；留空则使用额度极低的公开试用。';

  @override
  String get songRecognizerAcrCardTitle => 'ACRCloud';

  @override
  String get songRecognizerAcrCardSubtitle =>
      '控制台中的 Host、Access Key、Secret Key（音视频识别项目）。';

  @override
  String get songRecognizerOpenApiConfigSubtitle =>
      'AudD Token 与 ACRCloud 的 Host、Access Key、Secret Key';

  @override
  String get songRecognizerMatchConfirmTitle => '识别结果';

  @override
  String get songRecognizerMatchConfirmArtistLabel => '艺人';

  @override
  String get songRecognizerMatchConfirmAlbumLabel => '专辑';

  @override
  String get songRecognizerMatchConfirmReleaseLabel => '发行日期';

  @override
  String get songRecognizerMatchConfirmYes => '是这首歌';

  @override
  String get songRecognizerMatchConfirmNo => '不是这首，继续识别';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'Yeah Music';

  @override
  String get menuHome => '主页';

  @override
  String get menuSongList => '歌曲列表';

  @override
  String get menuPlaylists => '歌单';

  @override
  String get menuMusicSource => '音乐源';

  @override
  String get menuStatistics => '统计';

  @override
  String get menuSettings => '设置';

  @override
  String get statisticsTitle => '统计';

  @override
  String get statisticsSubtitle => '曲库、收听习惯与歌单概览';

  @override
  String get statisticsReloadTooltip => '刷新';

  @override
  String get statisticsReloadStarted => '正在刷新播放统计…';

  @override
  String get statisticsReloadDone => '播放统计已更新';

  @override
  String get statisticsReloadFailed => '无法刷新播放统计';

  @override
  String get statisticsSectionLibrary => '曲库';

  @override
  String get statisticsSectionPlayback => '播放';

  @override
  String get statisticsSectionPlaylists => '歌单';

  @override
  String get statisticsSectionOneDrive => 'OneDrive';

  @override
  String get statisticsTracksLabel => '曲目总数';

  @override
  String get statisticsFoldersLabel => '音乐文件夹';

  @override
  String get statisticsDurationLabel => '估算总时长';

  @override
  String get statisticsDurationHint => '仅统计元数据中带有有效时长的曲目';

  @override
  String get statisticsFormatsLabel => '格式分布';

  @override
  String get statisticsFormatsOther => '其他';

  @override
  String statisticsFormatsMore(int count) {
    return '另有 $count 种扩展名';
  }

  @override
  String get statisticsQualityLabel => '音质分布';

  @override
  String get statisticsQualityHint => '与曲库音质标识相同规则：在元数据可读时根据格式、码率与采样率推断分级';

  @override
  String get statisticsQualityUnknown => '未知';

  @override
  String get statisticsHistoricalListeningLabel => '历史听歌时长';

  @override
  String get statisticsHistoricalListeningHint =>
      '仅在播放器处于播放状态时累计墙上时钟（暂停、停止不计）；倍速不改变累计规则。自本版本起写入本地；强制退出可能丢失尚未落盘的数秒（按批写入）。';

  @override
  String get statisticsPlaybackTotalLabel => '听的总歌数';

  @override
  String get statisticsPlaybackTotalSubtitle => '本地累计播放次数（每次开始播放计一次）';

  @override
  String get statisticsPlaybackDistinctLabel => '有播放记录的曲目数';

  @override
  String get statisticsRecentEntriesLabel => '最近播放列表条数';

  @override
  String statisticsRecentEntriesSubtitle(int max) {
    return '本地最多保留 $max 条路径';
  }

  @override
  String get statisticsPlaylistsCountLabel => '自建歌单数量';

  @override
  String get statisticsPlaylistRefsLabel => '歌单内曲目条目';

  @override
  String get statisticsPlaylistRefsSubtitle => '各歌单路径数相加；同一首歌在多歌单中会重复计数';

  @override
  String get statisticsOneDriveIndexedLabel => '云端索引曲目';

  @override
  String get statisticsOneDriveCachedLabel => '已缓存 / 下载到本地';

  @override
  String get statisticsOneDriveUnavailable => '登录 OneDrive 后查看云端统计';

  @override
  String get statisticsNotInitialized => '正在初始化曲库…';

  @override
  String statisticsDurationHM(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String statisticsDurationMOnly(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get statisticsDurationUnknown => '无法估算';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsBackgroundTheme => '背景主题';

  @override
  String get settingsBackgroundThemeSubtitle => '纯色、自定义颜色或背景图';

  @override
  String get settingsBackgroundThemeDesc => '可选择纯色、自定义强调色或全屏背景图，具体项在下一页调整。';

  @override
  String get settingsSystemInfo => '系统信息';

  @override
  String get settingsSystemInfoSubtitle => '本机与存储空间';

  @override
  String get settingsSystemInfoDesc => '查看设备相关信息与磁盘剩余空间；展开后可查看各目录占用。';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutSubtitle => '版本与开源许可';

  @override
  String get settingsAboutDesc => '应用名称与版本、致谢与开源协议全文。';

  @override
  String get settingsHomeGreetingTitle => '首页问候';

  @override
  String get settingsHomeGreetingListSubtitle => '自定义句子与内置默认轮换展示';

  @override
  String get settingsHomeGreetingHelp =>
      '首页问候卡片第二行会先有一条内置、随界面语言变化的默认文案。下列每一条为你的自定义句子（不限条数）；保存后与默认文案一起轮播，轮播方式可在下方选择顺序或随机。';

  @override
  String get settingsHomeGreetingLineHint => '输入问候文案';

  @override
  String get settingsHomeGreetingRotationTitle => '轮播方式';

  @override
  String get settingsHomeGreetingRotationSequential => '顺序';

  @override
  String get settingsHomeGreetingRotationRandom => '随机';

  @override
  String get settingsHomeGreetingEmptyHint => '暂无自定义句子，点击下方添加一行';

  @override
  String get settingsHomeGreetingAddLine => '添加一行';

  @override
  String get settingsHomeGreetingSave => '保存';

  @override
  String get settingsHomeGreetingSaved => '已保存';

  @override
  String get settingsAboutDialogAuthor => '作者';

  @override
  String get settingsAboutDialogRepo => '仓库';

  @override
  String get settingsAboutDialogLicense => '许可证';

  @override
  String get settingsAboutDialogCopyright => '版权';

  @override
  String get settingsAboutDialogClose => '关闭';

  @override
  String settingsAboutDialogVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutDialogBuildLabel(String buildNumber) {
    return '构建号 $buildNumber';
  }

  @override
  String get settingsAboutDialogVersionTapHint => '点击检查更新';

  @override
  String get settingsAboutUpdateChecking => '正在检查更新…';

  @override
  String get settingsAboutUpdateAlreadyLatest => '已是最新版本';

  @override
  String get settingsAboutUpdateAvailableTitle => '发现新版本';

  @override
  String settingsAboutUpdateAvailableBody(String latest, String current) {
    return '远程版本为 v$latest，当前为 v$current。';
  }

  @override
  String get settingsAboutUpdateOpenReleases => '打开发行页面';

  @override
  String get settingsAboutUpdateCheckFailed => '检查更新失败';

  @override
  String get settingsAboutUpdateNoRelease => '仓库尚无 GitHub Release';

  @override
  String get settingsSponsorTitle => '赞助与支持';

  @override
  String get settingsSponsorSubtitle => '应用免费 · Star 或自愿打赏';

  @override
  String get settingsSponsorSectionFreeTitle => 'Yeah Music 完全免费';

  @override
  String get settingsSponsorSectionFreeBody =>
      'Yeah Music 免费提供完整功能，不设「付费解锁」或「必须订阅」。请勿向声称「售卖本软件」的第三方付费；商店中出现的收费上架如遇非官方账号请谨慎甄别。维护占用业余时间；下列支持均为自愿，不影响任何功能。';

  @override
  String get settingsSponsorSectionStarTitle => '在 GitHub 点 Star';

  @override
  String get settingsSponsorSectionStarHint =>
      'Star 不花钱，能帮助仓库被更多人看到，也方便你接收动态与发行说明。';

  @override
  String get settingsSponsorRepoYeahMusicTitle => 'Yeah Music';

  @override
  String get settingsSponsorRepoYeahMusicSubtitle => '本播放器源码仓库';

  @override
  String get settingsSponsorRepoDynamicSql2Title => 'Dynamic-SQL2';

  @override
  String get settingsSponsorRepoDynamicSql2Subtitle =>
      '动态 SQL2 / Java DSL 开源仓库';

  @override
  String get settingsSponsorEasterEggTriggerLine => '查看付费打赏方法';

  @override
  String get settingsSponsorEasterEggDialogTitle => '想得美';

  @override
  String get settingsSponsorEasterEggDialogBody => '想付钱？门都没有！此项目用爱发电。';

  @override
  String get settingsSponsorExternalHint =>
      '打开链接后将离开本应用，请在可信页面完成操作；打赏不会解锁任何功能。';

  @override
  String get settingsSponsorCopyLink => '复制链接';

  @override
  String get settingsSponsorLinkCopied => '已复制链接';

  @override
  String get settingsSponsorLaunchFailed => '无法打开链接';

  @override
  String get settingsSysinfoSectionDevice => '设备信息';

  @override
  String get settingsSysinfoSectionStorage => '存储空间';

  @override
  String get settingsSysinfoPlatformLabel => '运行平台';

  @override
  String get settingsSysinfoTotalSpace => '总空间';

  @override
  String get settingsSysinfoUsedSpace => '已使用';

  @override
  String get settingsSysinfoFreeSpace => '剩余空间';

  @override
  String get settingsSysinfoStorageUnavailable => '存储信息暂时无法获取';

  @override
  String get settingsSysinfoDeviceModel => '设备型号';

  @override
  String get settingsSysinfoManufacturer => '制造商';

  @override
  String get settingsSysinfoOsVersion => '系统版本';

  @override
  String get settingsSysinfoSdkVersion => 'SDK 版本';

  @override
  String get settingsSysinfoDeviceName => '设备名称';

  @override
  String get settingsSysinfoHostName => '主机名';

  @override
  String get settingsSysinfoKernelVersion => '内核版本';

  @override
  String get settingsSysinfoDistroLabel => '版本';

  @override
  String get settingsSysinfoBuildNumber => '构建号';

  @override
  String get settingsSysinfoError => '错误';

  @override
  String get settingsSysinfoFetchFailed => '无法获取设备信息';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '界面显示语言';

  @override
  String get settingsLanguageDesc => '设置菜单与界面文案语言；曲目信息仍以文件内嵌元数据为准。';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle => '微软账号同步、目录与下载位置';

  @override
  String get settingsOneDriveDesc =>
      '使用 Microsoft 登录（正式版无需填写客户端 ID）。可选音乐浏览根目录、云端应用数据文件夹与本地下载目录；点播时若自定义目录存在则写入该处，否则使用应用数据下的默认存储。';

  @override
  String get settingsPlaybackShortcutsTitle => '快捷键';

  @override
  String get settingsPlaybackShortcutsSubtitle => '播放、暂停、上一曲、下一曲';

  @override
  String get settingsPlaybackShortcutsPlayPause => '播放 / 暂停';

  @override
  String get settingsPlaybackShortcutsPrevious => '上一曲';

  @override
  String get settingsPlaybackShortcutsNext => '下一曲';

  @override
  String get settingsPlaybackShortcutsChange => '更改…';

  @override
  String get settingsPlaybackShortcutsDisable => '关闭';

  @override
  String get settingsPlaybackShortcutsEnable => '开启';

  @override
  String get settingsPlaybackShortcutsDisabledLabel => '已关闭';

  @override
  String get settingsPlaybackShortcutsPressKey => '录制快捷键';

  @override
  String get settingsPlaybackShortcutsPressKeyHint => '请按下新的组合键。Esc 取消。';

  @override
  String get settingsPlaybackShortcutsUnavailableBody =>
      '快捷键仅在 Windows / macOS / Linux 桌面版可自定义。';

  @override
  String get settingsWireRemoteTitle => '耳机线控';

  @override
  String get settingsWireRemoteSubtitle => '有线连击与蓝牙独立下一曲/上一曲键';

  @override
  String get settingsWireRemoteSubtitleOtherPlatforms =>
      '自定义线控仅在 Android 版、应用位于前台时生效。';

  @override
  String get settingsWireRemoteUnavailableTitle => '此处不可编辑';

  @override
  String get settingsWireRemoteUnavailableBody =>
      '耳机按键自定义仅在 Android、应用位于前台时生效（含蓝牙独立键）。桌面端请使用「快捷键」；iOS 由系统处理。';

  @override
  String get settingsWireRemoteUseCustom => '使用自定义线控';

  @override
  String get settingsWireRemoteUseCustomSubtitle => '关闭后由系统按默认方式处理耳机按键。';

  @override
  String get wireRemoteSingleTitle => '单击';

  @override
  String get wireRemoteDoubleTitle => '双击';

  @override
  String get wireRemoteTripleTitle => '三击';

  @override
  String get wireRemoteMediaNextTitle => '「下一曲」媒体键（蓝牙等）';

  @override
  String get wireRemoteMediaPreviousTitle => '「上一曲」媒体键（蓝牙等）';

  @override
  String get wireRemoteActionPlayPause => '播放 / 暂停';

  @override
  String get wireRemoteActionNext => '下一曲';

  @override
  String get wireRemoteActionPrevious => '上一曲';

  @override
  String get wireRemoteActionNone => '无';

  @override
  String get wireRemotePickActionTitle => '选择动作';

  @override
  String get settingsMacosMenuBarLyrics => '菜单栏歌词';

  @override
  String get settingsMacosMenuBarLyricsSubtitle => '菜单栏单行紧凑歌词';

  @override
  String get settingsMacosMenuBarLyricsDesc => '在系统菜单栏显示单行歌词（macOS）';

  @override
  String get settingsDesktopLyricsGroupTitle => '桌面歌词';

  @override
  String get settingsDesktopLyricsGroupSubtitle => '悬浮窗与 macOS 菜单栏歌词';

  @override
  String get settingsDesktopLyricsGroupDetail =>
      '桌面歌词包含可拖动的悬浮歌词窗，以及 macOS 上可选的菜单栏单行歌词。\n\n悬浮窗与播放页使用同一套歌词样式（颜色、多行模式、翻译等）。可锁定位置、调节背景透明度，并设置当前时间轴行上下各显示多少行。\n\n菜单栏歌词（仅 macOS）为紧凑单行，不需要悬浮窗时可在菜单栏常驻查看。';

  @override
  String get settingsDesktopFloatingLyrics => '悬浮歌词';

  @override
  String get settingsDesktopFloatingLyricsSubtitle => '可拖动的当前歌词浮窗';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      '在应用窗口上方显示可拖动的当前歌词，与播放页歌词样式设置一致。';

  @override
  String get settingsDesktopFloatingBgOpacity => '背景透明度';

  @override
  String get settingsDesktopFloatingBgOpacitySubtitle => '歌词板背景的透明程度';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      '歌词面板背景的明暗程度；0 为完全无背景，仅显示文字。';

  @override
  String get settingsDesktopFloatingLinesBefore => '当前行之前';

  @override
  String get settingsDesktopFloatingLinesBeforeSubtitle => '当前行上方时间轴行数';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      '以当前时间轴行为基准，向上允许显示多少行（不含当前行）。';

  @override
  String get settingsDesktopFloatingLinesAfter => '当前行之后';

  @override
  String get settingsDesktopFloatingLinesAfterSubtitle => '当前行下方时间轴行数';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      '以当前时间轴行为基准，向下允许显示多少行（不含当前行）。';

  @override
  String get settingsDesktopFloatingDragLock => '锁定位置';

  @override
  String get settingsDesktopFloatingDragLockSubtitle => '禁止拖动悬浮窗';

  @override
  String get settingsDesktopFloatingDragLockDesc => '开启后悬浮歌词窗口不可拖动。';

  @override
  String get settingsCarLyricsGroupTitle => '车载歌词';

  @override
  String get settingsCarLyricsGroupSubtitle => '媒体通知、蓝牙与 Android Auto';

  @override
  String get settingsCarLyricsGroupDetail =>
      '使用 Android 媒体会话，让锁屏、蓝牙耳机与 Android Auto 等显示正在播放内容并提供控制。\n\n开启：在播放器中构建完整队列，通知与车机上的上一首/下一首对应真实切歌；播放/暂停与单曲循环在支持范围内与 App 一致。\n\n封面：将内嵌封面送到通知与支持显示封面车机。\n\n歌词：在支持的系统上把媒体副标题更新为当前歌词行，规则与 App 内其它歌词展示一致。\n\n随机、仅播一次等模式仍以 App 内「播放模式」为准；车机上的列表循环/随机可能与部分模式不完全一致。';

  @override
  String get settingsCarLyricsEnabled => '启用车载歌词';

  @override
  String get settingsCarLyricsEnabledSubtitle => '通知栏队列与切歌';

  @override
  String get settingsCarLyricsEnabledDesc =>
      '显示媒体通知与队列，支持车机/耳机切歌；单曲循环与系统重复模式同步。';

  @override
  String get settingsCarLyricsShowCover => '显示封面';

  @override
  String get settingsCarLyricsShowCoverSubtitle => '通知与车机展示封面';

  @override
  String get settingsCarLyricsShowCoverDesc => '在通知与支持的车机上展示内嵌封面图。';

  @override
  String get settingsCarLyricsSyncLyrics => '同步当前歌词行';

  @override
  String get settingsCarLyricsSyncLyricsSubtitle => '副标题显示当前歌词';

  @override
  String get settingsCarLyricsSyncLyricsDesc => '在支持的系统上将副标题更新为当前歌词。';

  @override
  String get settingsCarLyricsOnlyAndroidHint =>
      '仅 Android 可生效与修改；当前设备上开关为只读，仅展示已保存的选项。';

  @override
  String get menuBarLyricsIdle => 'Yeah Music · 未在播放';

  @override
  String get menuBarLyricsNoLyrics => '暂无歌词';

  @override
  String get menuBarContextPlay => '播放';

  @override
  String get menuBarContextPause => '暂停';

  @override
  String get menuBarContextPrevious => '上一曲';

  @override
  String get menuBarContextNext => '下一曲';

  @override
  String get oneDriveSettingsTitle => 'OneDrive';

  @override
  String get oneDriveSectionAccount => '账户';

  @override
  String get oneDriveSectionPaths => '目录与存储';

  @override
  String get oneDriveSectionSync => '云端同步';

  @override
  String get oneDriveSyncMasterTitle => '同步到 OneDrive';

  @override
  String get oneDriveSyncMasterSubtitle =>
      '按需勾选同步类别。每次上传会在云端应用文件夹下创建「设备型号 / yyyyMMddTHHmmss」目录。';

  @override
  String get oneDriveSyncItemUserPlaylists => '我的歌单';

  @override
  String get oneDriveSyncItemUserPlaylistsSubtitle =>
      '封面、配色、歌单列表与曲目顺序（按设备目录保存）。';

  @override
  String get oneDriveSyncItemHomeGreeting => '首页问候（首张卡片）';

  @override
  String get oneDriveSyncItemHomeGreetingSubtitle => '与设置 → 首页问候为同一数据源。';

  @override
  String get oneDriveSyncItemQuickEntry => '首页快捷入口';

  @override
  String get oneDriveSyncItemQuickEntrySubtitle => '排序与各入口显示开关。';

  @override
  String get oneDriveSyncItemPlaybackListsStats => '最新 / 最多播放与播放统计';

  @override
  String get oneDriveSyncItemPlaybackListsStatsSubtitle =>
      '最近播放列表、播放次数与累计收听时长。';

  @override
  String get oneDriveSyncItemLyricsUi => '歌词与播放页';

  @override
  String get oneDriveSyncItemLyricsUiSubtitle => '歌词样式、桌面 / 车载歌词与播放页屏幕常亮等。';

  @override
  String get oneDriveSyncItemSongRecognition => '听歌识曲与记录';

  @override
  String get oneDriveSyncItemSongRecognitionSubtitle =>
      '所用引擎及 AudD / ACRCloud 密钥、本地识别历史。';

  @override
  String get oneDriveSyncItemTheme => '背景主题';

  @override
  String get oneDriveSyncItemThemeSubtitle => '渐变、预设 / 自定义颜色与背景图片等（不含界面语言）。';

  @override
  String get oneDriveSyncFrequencyLabel => '同步频率';

  @override
  String get oneDriveSyncFreqManual => '仅手动';

  @override
  String get oneDriveSyncFreq1h => '每 1 小时';

  @override
  String get oneDriveSyncFreq6h => '每 6 小时';

  @override
  String get oneDriveSyncFreq12h => '每 12 小时';

  @override
  String get oneDriveSyncFreq24h => '每 24 小时';

  @override
  String get oneDriveSyncNow => '立即同步';

  @override
  String get oneDriveSyncNowDescription =>
      '立即上传已勾选类别：写入云端应用文件夹下的「设备型号 / yyyyMMddTHHmmss」。';

  @override
  String get oneDriveSyncNowNeedLogin => '请先登录微软账号。';

  @override
  String get oneDriveSyncNowNeedCloudFolder => '请先在上方选好「云端应用数据文件夹」，才知道备份往哪儿放。';

  @override
  String get oneDriveSyncNowFinished => '已上传到云端应用文件夹下的同步目录。';

  @override
  String oneDriveSyncNowFailed(String message) {
    return '备份失败：$message';
  }

  @override
  String get oneDriveRestoreFromCloud => '从云端恢复';

  @override
  String get oneDriveRestoreSubtitle => '选择备份条目（旧版平铺文件或按设备会话目录），再勾选要恢复的内容。';

  @override
  String get oneDriveRestoreSheetTitle => '选择备份时间点';

  @override
  String get oneDriveRestoreGroupThisDevice => '本设备';

  @override
  String get oneDriveRestoreGroupOtherDevices => '其他设备';

  @override
  String get oneDriveRestoreGroupLegacyFlat => '旧版平铺';

  @override
  String get oneDriveRestoreContentSectionTitle => '要恢复的内容';

  @override
  String get oneDriveRestoreLoadMore => '加载更多';

  @override
  String oneDriveRestoreListShowing(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get oneDriveRestoreTabUnknownDevice => '未知设备';

  @override
  String get oneDriveRestoreEmpty => '尚未发现备份文件。请先使用下方「立即同步」上传歌单或设置。';

  @override
  String get oneDriveRestorePlaylistCheckbox => '歌单';

  @override
  String get oneDriveRestoreLegacySettingsCheckbox => '旧版整块设置 JSON';

  @override
  String get oneDriveRestoreSliceHomeGreeting => '首页问候';

  @override
  String get oneDriveRestoreSliceQuickEntry => '首页快捷入口';

  @override
  String get oneDriveRestoreSlicePlaybackLists => '最近播放与统计 Hive';

  @override
  String get oneDriveRestoreSliceLyricsUi => '歌词与屏幕常亮';

  @override
  String get oneDriveRestoreSliceSongRecognition => '听歌识曲与记录';

  @override
  String get oneDriveRestoreSliceTheme => '背景主题';

  @override
  String get oneDriveRestorePlaylistModeMerge => '合并到本地（同 id 歌单合并曲目）';

  @override
  String get oneDriveRestorePlaylistModeReplace => '覆盖本地歌单（先清空再导入）';

  @override
  String get oneDriveRestoreAction => '恢复';

  @override
  String get oneDriveRestoreNeedPickContent => '请至少勾选一项要恢复的内容。';

  @override
  String get oneDriveRestoreMissingPlaylistsFile => '该备份中没有歌单文件。';

  @override
  String get oneDriveRestoreMissingSettingsFile => '该备份中没有旧版整块设置文件。';

  @override
  String oneDriveBackupSnapshotDeviceSession(
    String deviceName,
    String sessionStamp,
  ) {
    return '$deviceName · $sessionStamp';
  }

  @override
  String get oneDriveSyncNowNeedMasterOn => '请先开启上方的「同步到 OneDrive」。';

  @override
  String get oneDriveSyncNowNothingSelected => '请先在上方勾选至少一项同步类别。';

  @override
  String get oneDriveRestoreFinished => '恢复完成。';

  @override
  String oneDriveRestoreFailed(String message) {
    return '恢复失败：$message';
  }

  @override
  String get oneDriveRestoreLoadingList => '正在读取备份列表…';

  @override
  String get oneDriveSyncNowInProgress => '同步中…';

  @override
  String get oneDriveRestoreInProgress => '恢复中…';

  @override
  String get oneDriveCloudAppDataTitle => '云端应用数据文件夹';

  @override
  String get oneDriveCloudAppDataSubtitle => '预留：设置备份、歌单与同步等。';

  @override
  String get oneDriveCloudAppFolderUnset => '未设置';

  @override
  String get oneDriveLocalDownloadTitle => '本地下载目录';

  @override
  String get oneDriveLocalDownloadSubtitle =>
      '从云端点播时：若此处路径存在则保存到该文件夹；未指定或路径不存在时使用下方默认存储空间。';

  @override
  String get oneDriveLocalDownloadUnset => '未设置（后续将使用默认路径）';

  @override
  String get oneDriveChooseCloudFolder => '在 OneDrive 中选择';

  @override
  String get oneDriveChooseLocalFolder => '选择本地文件夹…';

  @override
  String get oneDrivePickFolderForAppData => '选择用于应用数据与未来备份的文件夹。';

  @override
  String get oneDrivePickFolderForMusicUpload => '选择本设备上传音乐时使用的目标文件夹。';

  @override
  String get oneDriveMusicUploadFolderTitle => '上传音乐目标文件夹';

  @override
  String get oneDriveMusicUploadFolderSubtitle =>
      '从本机曲库上传到 OneDrive 时的默认父文件夹。未单独设置时，将使用上方的云端应用文件夹。';

  @override
  String get oneDriveMusicUploadFolderFallback => '与云端应用文件夹相同';

  @override
  String get oneDriveAppMissingClientConfig => '这一版暂时还不能用微软账号登录，下一版本也许会加入该功能';

  @override
  String get oneDriveNeedSignInForPicker => '请先登录后再选择 OneDrive 文件夹。';

  @override
  String get oneDriveClear => '清除';

  @override
  String get oneDriveSignIn => '使用 Microsoft 登录';

  @override
  String get oneDriveSignOut => '退出登录';

  @override
  String get oneDriveSignOutDone => '已退出 OneDrive 账号';

  @override
  String get oneDriveSignedIn => '已登录';

  @override
  String get oneDriveNotSignedIn => '未登录';

  @override
  String get oneDriveLinuxUnsupported => '当前平台暂不支持 OneDrive 登录。';

  @override
  String get oneDriveSignInFailed => '未能登录，请检查网络后重试。';

  @override
  String get oneDriveCacheNote =>
      '默认存储为应用数据下的 onedrive_cache；仅当上方自定义文件夹存在且为目录时才写入该处。';

  @override
  String get oneDriveOpenBrowser => '打开 OneDrive';

  @override
  String get homeEntryOneDrive => 'OneDrive';

  @override
  String get oneDriveBrowserTitle => 'OneDrive';

  @override
  String get oneDriveEmptyFolder => '此文件夹为空';

  @override
  String get oneDrivePlayAll => '播放本文件夹全部';

  @override
  String get oneDrivePreparing => '正在准备…';

  @override
  String get oneDriveDownloadQueueTitle => 'OneDrive 下载队列';

  @override
  String get oneDriveTransferQueueTitle => 'OneDrive 传输队列';

  @override
  String get oneDriveTransferTabDownload => '下载';

  @override
  String get oneDriveTransferTabUpload => '上传';

  @override
  String get oneDriveDownloadPause => '暂停';

  @override
  String get oneDriveDownloadResume => '继续';

  @override
  String get oneDriveDownloadStopAll => '全部停止';

  @override
  String get oneDriveDownloadContinueAll => '全部继续';

  @override
  String get oneDriveDownloadAutoPlayWhenDone => '队列全部完成后自动播放';

  @override
  String get oneDriveDownloadPlayDownloaded => '播放已下载的歌曲';

  @override
  String get oneDriveDownloadStatusPending => '等待中';

  @override
  String get oneDriveDownloadStatusDownloading => '下载中';

  @override
  String get oneDriveDownloadStatusDone => '已完成';

  @override
  String get oneDriveDownloadStatusFailed => '失败';

  @override
  String get oneDriveDownloadStatusCancelled => '已取消';

  @override
  String get oneDriveDownloadCloseJustPanel => '关闭面板（下载继续在后台）';

  @override
  String get oneDriveDownloadQueueEmpty =>
      '暂无批量下载任务。\n在云端曲库或 OneDrive 浏览器中使用「播放全部」即可在此查看；关闭抽屉不会中断下载。';

  @override
  String get oneDriveUploadQueueEmpty =>
      '暂无上传任务。\n在本地曲库中通过多选栏的「上传到 OneDrive」添加；关闭界面不会中断后台传输。';

  @override
  String get oneDriveTransferQueueEmpty => '当前队列中还没有任务。';

  @override
  String get oneDriveDownloadQueuePageHint => '在此暂停、继续或停止批量下载。关闭抽屉不会取消后台任务。';

  @override
  String get oneDriveUploadQueuePageHint =>
      '本机发起的上传会显示在此，可用上方按钮暂停、继续或停止；清空记录会同时影响下载与上传历史。';

  @override
  String get oneDriveDownloadQueueSubtitle => '查看与控制上传、下载与播放';

  @override
  String get oneDriveDownloadQueueTooltip => '下载队列';

  @override
  String get oneDriveBrowserRefreshTooltip => '刷新本页（清除列表缓存并从云端重新加载）';

  @override
  String oneDriveEnqueueAddedSingle(String name) {
    return '已将「$name」添加到下载队列';
  }

  @override
  String oneDriveEnqueueAddedMany(int count) {
    return '已将 $count 首添加到下载队列';
  }

  @override
  String get oneDriveDownloadViewQueue => '查看队列';

  @override
  String get oneDriveDownloadClearHistory => '清空记录';

  @override
  String get oneDriveTransferClearDownloadsList => '清空下载列表';

  @override
  String get oneDriveTransferClearUploadsList => '清空上传列表';

  @override
  String oneDriveError(String message) {
    return 'OneDrive 错误：$message';
  }

  @override
  String get oneDriveUp => '上级';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · 云端曲库';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      '添加的文件夹会递归扫描出音频列表；点曲目按需下载（自定义目录存在则用该目录，否则用默认缓存），已下载的可离线播放。';

  @override
  String get oneDriveCloudLibraryEmpty =>
      '还没有索引。\n请先点「在网盘中选择文件夹」，选好一个或多个音乐目录后，再点「重新扫描」。';

  @override
  String get oneDriveCachedPlaylistTitle => 'OneDrive · 缓存下载';

  @override
  String get oneDriveCachedPlaylistEmpty =>
      '暂无从 OneDrive 下载到本机的曲目。请在云端曲库点播歌曲；文件会保存到应用缓存或你设置的本地下载目录。';

  @override
  String get oneDriveIndexRootsLabel => '已索引目录';

  @override
  String get oneDriveRescanIndex => '重新扫描';

  @override
  String get oneDriveBrowseFolders => '在网盘中选择文件夹';

  @override
  String get oneDrivePickFolderForIndex => '点文件夹右侧的 +，或进入文件夹后点「使用此文件夹」。';

  @override
  String get oneDriveUseCurrentFolder => '使用此文件夹';

  @override
  String get oneDrivePickMultipleFoldersHint => '勾选文件夹进行选择；点右侧箭头进入子文件夹继续选择。';

  @override
  String get oneDriveIncludeOpenFolderInSelection => '包含当前文件夹';

  @override
  String oneDriveAddSelectedFoldersAction(int count) {
    return '添加（$count）';
  }

  @override
  String get oneDriveAddFolderTooltip => '加入云端曲库';

  @override
  String get oneDriveIndexingEllipsis => '正在扫描目录…';

  @override
  String oneDriveLastIndexed(String time) {
    return '上次扫描：$time';
  }

  @override
  String get oneDrivePlayAllTracks => '播放全部';

  @override
  String oneDriveTracksCount(int count) {
    return '$count 首';
  }

  @override
  String get oneDriveCloudSearchHint => '搜索文件名或路径…';

  @override
  String get oneDriveNoIndexRoots => '尚未配置目录，请先「在网盘中选择文件夹」。';

  @override
  String get oneDriveLastIndexedNever => '上次扫描：—';

  @override
  String get oneDriveIndexFoldersRecursiveHint => '扫描会递归包含各文件夹及其子目录下的所有音频文件。';

  @override
  String get oneDriveRemoveIndexFolderTitle => '移除索引文件夹？';

  @override
  String oneDriveRemoveIndexFolderMessage(String name) {
    return '要从索引中移除「$name」吗？该文件夹及其子文件夹中的曲目将不再出现在列表中，需要时可重新添加。';
  }

  @override
  String get oneDriveRemoveIndexFolderAction => '移除';

  @override
  String get languageSettingsTitle => '语言';

  @override
  String get languageSettingsDescription =>
      '选择应用界面显示语言。选择「跟随系统」时，在已提供翻译的情况下将跟随设备语言。';

  @override
  String get langFollowSystem => '跟随系统';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langSimplifiedChinese => '简体中文';

  @override
  String get langTraditionalChinese => '繁體中文';

  @override
  String get themeSettingsTitle => '主题设置';

  @override
  String get globalTheme => '全局主题';

  @override
  String get globalThemeDesc => '控制应用界面整体为浅色、深色或跟随系统；将保存到本机。';

  @override
  String get themeLight => '白天模式';

  @override
  String get themeDark => '夜晚模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get sectionThemeType => '主题类型';

  @override
  String get themeTypeSolid => '预设颜色';

  @override
  String get themeTypeCustom => '自定义颜色';

  @override
  String get themeTypeImage => '背景图片';

  @override
  String get sectionPresetColors => '预设颜色';

  @override
  String get sectionCustomColor => '自定义颜色';

  @override
  String get sectionBackgroundImage => '背景图片';

  @override
  String get primaryColor => '主色调';

  @override
  String get secondaryColor => '次色调';

  @override
  String get themeGradientRgbSectionTitle => '渐变背景';

  @override
  String get themeGradientRgbSectionSubtitle => '渐变 RGB 滑块，可同时微调两端颜色和渐变方向。';

  @override
  String get themeGradientRgbFineTune => '编辑双色与方向…';

  @override
  String get themeGradientRgbDialogTitle => '背景渐变';

  @override
  String get actionSelect => '选择';

  @override
  String get fogBackground => '背景雾化';

  @override
  String get fogBackgroundDesc =>
      '虚化并压暗壁纸，减少对文字图标的干扰。即使调低也会保留轻度整幅压暗与上下边缘渐晕；花纹多或反差大的图建议再调高。默认 45%。';

  @override
  String get fogWeak => '弱';

  @override
  String get fogStrong => '强';

  @override
  String get actionPickImage => '选择图片';

  @override
  String get actionRemove => '移除';

  @override
  String cannotSaveBackground(String error) {
    return '无法保存背景图（请重试或换一张）：$error';
  }

  @override
  String get themeWallpaperSavedRestartHint => '壁纸已保存。若界面仍未更新，请完全退出应用后重新打开。';

  @override
  String get colorDialogTitlePrimary => '选择主色调';

  @override
  String get colorDialogTitleSecondary => '选择次色调';

  @override
  String get actionCancel => '取消';

  @override
  String get actionRetry => '重试';

  @override
  String startupFailed(String error) {
    return '启动失败：$error';
  }

  @override
  String get welcomeTagline => '每一次聆听，都从这里开始';

  @override
  String get welcomeEnter => '进入应用';

  @override
  String get welcomeEnterWait => '进入应用（需等待加载完成）';

  @override
  String get welcomeHintWhenReady => '加载已完成，可随时进入主页。';

  @override
  String get welcomeHintWhenNotReady => '启动完成后将自动进入主页。';

  @override
  String get welcomePreparing => '正在完成启动准备…';

  @override
  String get welcomeCountdownLabel => '启动时间';

  @override
  String get welcomeCountdownSubDoneReady => '首页资源已就绪，可立即进入';

  @override
  String get welcomeStartupSubLoading => '正在加载首页所需数据…完成后自动进入';

  @override
  String get secondsUnit => '秒';

  @override
  String get welcomeNotReadyMessage => '请稍等，资源尚未加载完成。';

  @override
  String welcomeLoadError(String error) {
    return '加载出错了。请检查存储权限或稍后重试。\n\n$error';
  }

  @override
  String get welcomeFakeUserSettings => '正在加载用户设置';

  @override
  String get welcomeFakeLibrary => '正在加载曲库';

  @override
  String get welcomeFakePlaylists => '正在加载歌单';

  @override
  String get welcomeFakeOther => '正在加载其他数据';

  @override
  String get welcomeFakeFinishing => '正在完成初始化';

  @override
  String get homeGreetingLateNight => '夜深了';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homePullLoftTitle => '从本机重新载入';

  @override
  String get homePullReleaseHint => '松手即可载入已保存的配置';

  @override
  String get homePullEmptyTease => '这里什么也没有，再拉也没有用呀';

  @override
  String get homePullStepThemeWallpaper => '主题：配色、渐变与壁纸';

  @override
  String get homePullStepBrightnessMode => '外观：浅色 / 深色模式';

  @override
  String get homePullStepLanguage => '界面语言';

  @override
  String get homePullStepPlaylistsCarousel => '歌单与首页横滑顺序';

  @override
  String get homePullStepShortcuts => '首页快捷入口';

  @override
  String get homePullStepRecentTopPlayed => '最近播放与播放次数';

  @override
  String get homePullStepLyricsDisplay => '歌词显示（从存储重新读取）';

  @override
  String get homePullStepPlaybackPrefs => '播放模式（随机 / 循环等）';

  @override
  String get homePullRefreshDone => '已从本机存储重新载入配置。';

  @override
  String homePullRefreshFailed(String error) {
    return '本机载入失败：$error';
  }

  @override
  String get homeMenuTooltip => '菜单';

  @override
  String get homeSearchTooltip => '搜索';

  @override
  String get homeQuickEntryEmpty => '暂无快捷入口，点击「管理」可显示本地曲库、我的歌单、OneDrive 缓存歌单等';

  @override
  String get homeEntryLibrary => '本地曲库';

  @override
  String get homeEntryMyPlaylists => '我的歌单';

  @override
  String get homeEntryRecent => '最近播放';

  @override
  String get homeEntryMostPlayed => '最多播放';

  @override
  String get homeEntryDiscover => '发现';

  @override
  String get homeEntryCloudLibrary => '云端曲库';

  @override
  String get homeEntryOneDriveCachePlaylist => '缓存歌单';

  @override
  String get homeSectionQuickEntry => '快捷入口';

  @override
  String get homeActionManage => '管理';

  @override
  String get homeSectionMyPlaylists => '我的歌单';

  @override
  String get homeActionMore => '更多';

  @override
  String get homeLoadingLibrary => '正在加载曲库…';

  @override
  String get homeRecentEmpty => '暂无最近播放，在曲库或歌单中播放歌曲后会显示';

  @override
  String get homeSectionMostPlayed => '最多播放';

  @override
  String get homeSectionRecentPlays => '最近播放';

  @override
  String get homeActionAll => '全部';

  @override
  String get homeMostPlayedPathMismatch =>
      '已有播放次数记录，但路径与当前曲库不一致（重命名/移动后请重扫音乐目录，再播几次会恢复）';

  @override
  String get homeMostPlayedEmpty => '暂无播放次数统计，在曲库或歌单中多播几次歌后会按次数排行';

  @override
  String get mostPlayedSwitchSortAscending => '切换为按播放次数正序（少→多）';

  @override
  String get mostPlayedSwitchSortDescending => '切换为按播放次数倒序（多→少）';

  @override
  String homePlayCount(int c) {
    return '已播放 $c 次';
  }

  @override
  String homePlayCountWithBase(String base, int c) {
    return '$base · 已播放 $c 次';
  }

  @override
  String homeGreetingLine(String greeting) {
    return '$greeting，今天想听点什么？';
  }

  @override
  String get homeGreetingSub => '从下面继续上次的歌，或选一张歌单开始';

  @override
  String get homeSearchHint => '搜索歌曲、歌手、歌单';

  @override
  String get homeContinuePlaying => '继续播放';

  @override
  String get homeUnknownTitle => '未知';

  @override
  String get homeNowPlayingAlbum => '正在播放';

  @override
  String get homeNothingPlaying => '还没有在播放';

  @override
  String get homeOpenLibraryToPlay => '去本地曲库选一首歌开始';

  @override
  String get homeAllSongsLoading => '加载中…';

  @override
  String get homeScanMusicFolder => '去扫描音乐目录';

  @override
  String homeTrackCount(int n) {
    return '$n 首';
  }

  @override
  String get homeAllSongs => '全部歌曲';

  @override
  String get homeCreatePlaylist => '创建歌单';

  @override
  String get homeCreatePlaylistSub => '集中收藏你喜欢的歌';

  @override
  String get homeEmptyPlaylist => '空歌单';

  @override
  String get songsListEmpty => '暂无歌曲';

  @override
  String get tooltipSort => '排序';

  @override
  String get playbackFailedSnackMessage => '无法播放该曲目，文件可能缺失、无法读取或格式不支持。';

  @override
  String get languageRestartNotice => '部分界面需重启应用后才会完全应用所选语言。';

  @override
  String get locateNotInList => '当前播放不在本列表';

  @override
  String get locateToCurrent => '定位到当前';

  @override
  String get locateToCurrentPlaying => '定位到当前播放';

  @override
  String get locateToLyricLine => '定位到当前歌词';

  @override
  String get tooltipBack => '返回';

  @override
  String get tooltipAddToPlaylist => '加入歌单';

  @override
  String get menuPlayNextAfterCurrent => '下一曲播放';

  @override
  String get libraryPlayNextAfterCurrentQueued => '当前曲目结束后将播放所选歌曲';

  @override
  String get libraryPlayNextAfterCurrentNotInQueue => '所选歌曲不在当前播放队列中';

  @override
  String get tooltipDone => '完成';

  @override
  String get tooltipMoreActions => '操作';

  @override
  String get tooltipMore => '更多';

  @override
  String get tooltipLyricStyle => '歌词样式';

  @override
  String get songPageMoreSheetTitle => '更多操作';

  @override
  String get songPageMoreQueryMetadata => '查询歌曲元信息';

  @override
  String get songPageMoreUploadOneDrive => '上传至 OneDrive';

  @override
  String get songPageMoreShare => '分享';

  @override
  String get songPageMoreEditMusicTagsExternal => '使用音乐标签编辑…';

  @override
  String get songPageMoreEditMusicTagsInline => '编辑内嵌标签…';

  @override
  String get songPageInlineTagsUnstableTitle => '提示';

  @override
  String get songPageInlineTagsUnstableBody =>
      '此功能尚未完全稳定，写入时可能损坏音频文件内的元数据。建议先克隆或复制该歌曲作为备份后再继续。';

  @override
  String get songPageInlineTagsUnstableContinue => '仍要继续';

  @override
  String get songPageInlineTagsUnstableCancel => '取消';

  @override
  String get songPageInlineTagsEditorTitle => '编辑内嵌标签';

  @override
  String get songPageInlineTagsFieldTitle => '标题';

  @override
  String get songPageInlineTagsFieldArtist => '艺术家';

  @override
  String get songPageInlineTagsFieldAlbum => '专辑';

  @override
  String get songPageInlineTagsCoverSection => '内嵌封面';

  @override
  String get songPageInlineTagsCoverReplace => '选择图片并裁剪…';

  @override
  String get songPageInlineTagsCoverRemove => '移除封面';

  @override
  String get songPageInlineTagsCoverInvalid => '请选择 JPEG 或 PNG 图片。';

  @override
  String get songPageInlineTagsFieldYear => '年份';

  @override
  String get songPageInlineTagsFieldTrackNumber => '曲目编号';

  @override
  String get songPageInlineTagsFieldTrackTotal => '曲目总数';

  @override
  String get songPageInlineTagsFieldDiscNumber => '碟片编号';

  @override
  String get songPageInlineTagsFieldDiscTotal => '碟片总数';

  @override
  String get songPageInlineTagsFieldLyrics => '歌词';

  @override
  String get songPageInlineTagsSave => '保存';

  @override
  String get songPageInlineTagsSaved => '已写入文件';

  @override
  String songPageInlineTagsSaveFailed(Object error) {
    return '无法保存标签：$error';
  }

  @override
  String get songPageStorageManageAllFilesHint =>
      '修改或删除外部存储中的音频需要「所有文件访问」权限，请在系统设置中为本应用开启后重试。';

  @override
  String get audioQualityTierLq => '流畅';

  @override
  String get audioQualityTierStd => '标准';

  @override
  String get audioQualityTierHq => '高品质';

  @override
  String get audioQualityTierSq => '无损（CD 级）';

  @override
  String get audioQualityTierHr => '高解析';

  @override
  String get audioQualityTierDsd => '顶级发烧';

  @override
  String get songPageMoreEditLyricsExternal => '使用 SyncedLyricEditor 编辑…';

  @override
  String get songPageSyncedLyricEditorNotInstalled =>
      '未安装 SyncedLyric Editor，无法跳转编辑。';

  @override
  String get songPageSyncedLyricEditorLaunchFailed =>
      '无法打开 SyncedLyric Editor。';

  @override
  String get songPageMusicTagEditorUnsupportedPlatform =>
      '外部标签编辑仅在 Android 上可用。';

  @override
  String get songPageMusicTagEditorFileNotFound => '未找到音频文件。';

  @override
  String get songPageMusicTagEditorNotInstalled =>
      '未安装 Music Tag Editor，无法跳转编辑。';

  @override
  String get songPageMusicTagEditorCannotSharePath => '无法从当前路径向其它应用打开该文件。';

  @override
  String get songPageMusicTagEditorLaunchFailed => '无法打开 Music Tag Editor。';

  @override
  String get songPageMetadataDialogTitle => '音频元信息';

  @override
  String get songPageMetadataReadFailed => '无法读取该文件的元信息。';

  @override
  String get songPageShareFileNotFound => '磁盘上找不到该文件。';

  @override
  String get songPageDeleteDiskWarningTitle => '从磁盘删除？';

  @override
  String get songPageDeleteDiskWarningBody =>
      '将从设备存储中永久删除该音频文件，且不可恢复；并从歌单与播放历史中移除。';

  @override
  String get songPageDeleteContinue => '继续删除';

  @override
  String get songPageDeleteFinalConfirmTitle => '确认删除';

  @override
  String songPageDeleteFinalConfirmBody(Object fileName) {
    return '确定删除「$fileName」吗？';
  }

  @override
  String get songPageMetaFieldTitle => '标题';

  @override
  String get songPageMetaFieldArtist => '艺术家';

  @override
  String get songPageMetaFieldAlbum => '专辑';

  @override
  String get songPageMetaFieldDuration => '时长';

  @override
  String get songPageMetaFieldBitrate => '比特率';

  @override
  String get songPageMetaFieldSampleRate => '采样率';

  @override
  String get songPageMetaFieldYear => '年份';

  @override
  String get songPageMetaFieldTrack => '音轨';

  @override
  String get songPageMetaFieldDisc => '碟片';

  @override
  String get songPageMetaFieldPath => '路径';

  @override
  String get songPageMetaFieldSize => '文件大小';

  @override
  String get songPageMetaFieldGenre => '流派';

  @override
  String get songPageMetaFieldPerformers => '其它艺人';

  @override
  String get songPageMetaFieldLanguage => '语言';

  @override
  String get songPageMetaFieldEmbeddedLyrics => '嵌入式歌词';

  @override
  String get songPageMetaFieldFormat => '格式';

  @override
  String get songPageMetaSectionTags => '标签信息';

  @override
  String get songPageMetaSectionAudio => '音频参数';

  @override
  String get songPageMetaSectionFile => '文件';

  @override
  String get tooltipFolderInfo => '目录信息';

  @override
  String get tooltipReloadSongs => '重新加载歌曲';

  @override
  String get tooltipEdit => '编辑';

  @override
  String get tooltipRemoveFolder => '移除目录';

  @override
  String get actionDelete => '删除';

  @override
  String get actionSave => '保存';

  @override
  String get actionCreate => '创建';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionGotIt => '我知道了';

  @override
  String get actionOK => '确定';

  @override
  String get settingsRowHelpTooltip => '说明';

  @override
  String get fieldName => '名称';

  @override
  String get fieldNewNameHint => '新名称';

  @override
  String get folderAppBarTitle => '文件夹';

  @override
  String folderSongsCount(int n) {
    return '$n 首';
  }

  @override
  String get folderInfoAlias => '文件夹别名：';

  @override
  String get folderInfoPath => '文件夹路径：';

  @override
  String get folderInfoSongCount => '歌曲数量：';

  @override
  String get folderInfoAdded => '加入时间：';

  @override
  String get folderAddLoadingTitle => '正在加载歌曲';

  @override
  String get folderReloading => '正在重新加载';

  @override
  String get folderScanningWait => '正在扫描文件夹，请稍候…';

  @override
  String folderLoadOk(int n) {
    return '成功加载 $n 首歌曲';
  }

  @override
  String folderLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get folderRemoveTitle => '确认移除？';

  @override
  String folderRemoveMessage(String name) {
    return '是否移除目录：$name（仅移除引用，不删磁盘上音乐文件）';
  }

  @override
  String get folderDuplicateDialogTitle => '提示';

  @override
  String folderDuplicateMessage(String path) {
    return '添加了重复的文件夹：$path';
  }

  @override
  String folderAddOk(int n) {
    return '成功添加 $n 首歌曲';
  }

  @override
  String get folderAddErrorTitle => '错误';

  @override
  String folderAddErrorMessage(String error) {
    return '加载文件夹失败：$error';
  }

  @override
  String get folderAddNoSelection => '未选择文件夹（已取消或关闭选择框）。';

  @override
  String get folderRenameDialogTitle => '重命名文件夹';

  @override
  String get playlistPageTitle => '歌单';

  @override
  String get playlistNotFound => '歌单不存在';

  @override
  String get playlistNotFoundMessage => '该歌单可能已被删除';

  @override
  String get playlistEmptyNoSongs => '暂无可用歌曲\n（请先在「音乐源」扫描，或歌曲路径已失效）';

  @override
  String get playlistDeleteTitle => '删除歌单';

  @override
  String get playlistDeleteMessage => '确定删除该歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。';

  @override
  String get playlistDeleteBatchTitle => '批量删除歌单';

  @override
  String playlistDeleteBatchMessage(int n) {
    return '确定删除已选的 $n 个歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。';
  }

  @override
  String get playlistDeletedOne => '已删除歌单';

  @override
  String get importDialogBody =>
      '歌曲以「完整文件路径」区分：同名、同歌手、不同文件或不同音质会对应不同路径，导入后不会误合并。\n\n• 合并导入：与本地「歌单 id」相同的条目会合并曲目列表（路径去重）；备份中有而本地没有的歌单会新建。\n• 替换全部：先清空本地全部歌单，再按备份恢复（谨慎操作）。';

  @override
  String playlistCreatedOn(String date) {
    return '创建于 $date';
  }

  @override
  String get recentPlaysEmptyTitle => '还没有播放记录';

  @override
  String get quickEntryReorderHint => '拖动手柄可调整顺序。关闭「在首页显示」后该入口在首页隐藏。';

  @override
  String get quickEntryShowOnHome => '在首页显示';

  @override
  String get playlistSearchHint => '搜索歌曲、艺术家或文件名…';

  @override
  String get searchNoMatchingSongs => '未找到匹配的歌曲';

  @override
  String get playlistRenameTitle => '重命名歌单';

  @override
  String get playlistCoverStyleTitle => '歌单封面颜色';

  @override
  String get playlistCoverStyleSubtitle =>
      '应用于首页横滑卡片与音乐源歌单列表左侧预览；选择轮换预设则按列表顺序自动配色；渐变可使用自选双色以增强对比。';

  @override
  String get playlistCoverUseDefaultPalette => '使用轮换预设配色';

  @override
  String get playlistCoverSolidSection => '单色';

  @override
  String get playlistCoverGradientSection => '渐变';

  @override
  String get playlistCoverCustomGradientTitle => '自定义渐变';

  @override
  String get playlistCoverGradientStartColor => '起始色';

  @override
  String get playlistCoverGradientEndColor => '结束色';

  @override
  String get playlistCoverGradientSwapColors => '交换两端颜色';

  @override
  String get playlistCoverGradientDirectionTitle => '渐变方向';

  @override
  String get playlistCoverGradientDirHorizontalLR => '左→右';

  @override
  String get playlistCoverGradientDirHorizontalRL => '右→左';

  @override
  String get playlistCoverGradientDirVerticalTB => '上→下';

  @override
  String get playlistCoverGradientDirVerticalBT => '下→上';

  @override
  String get playlistCoverGradientDirDiagonalTLBR => '对角 ↘（左上→右下）';

  @override
  String get playlistCoverGradientDirDiagonalTRBL => '对角 ↙（右上→左下）';

  @override
  String get playlistCoverGradientDirDiagonalBRTL => '对角 ↖（右下→左上）';

  @override
  String get playlistCoverGradientDirDiagonalBLTR => '对角 ↗（左下→右上）';

  @override
  String get playlistCoverRgbTitle => '自定义 RGB';

  @override
  String get playlistCoverRgbRed => '红';

  @override
  String get playlistCoverRgbGreen => '绿';

  @override
  String get playlistCoverRgbBlue => '蓝';

  @override
  String get playlistCoverRgbPreview => '预览';

  @override
  String get playlistCoverPreviewLabel => '当前效果';

  @override
  String get playlistCoverMenuItem => '封面颜色…';

  @override
  String get playlistCoverPictureSection => '图片';

  @override
  String get playlistCoverPickImage => '选择图片…';

  @override
  String get playlistCoverRemoveImage => '移除图片';

  @override
  String get imageCropTitle => '裁剪图片';

  @override
  String get imageCropFailure => '无法裁剪该图片。';

  @override
  String get exportCannot => '无法导出该歌单';

  @override
  String exportSaved(String path) {
    return '已导出：$path';
  }

  @override
  String get exportCancelled => '已取消导出';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get exportDialogTitle => '导出歌单';

  @override
  String get menuRename => '重命名';

  @override
  String get menuExportThis => '导出本歌单…';

  @override
  String get menuDeletePlaylist => '删除歌单';

  @override
  String get exportSelectFirst => '请先选择要导出的歌单';

  @override
  String get exportNoneToExport => '没有可导出的歌单，请检查选择';

  @override
  String get exportAllPlaylists => '导出全部歌单';

  @override
  String get exportSelectedPlaylists => '导出所选歌单';

  @override
  String get exportSelected => '导出所选';

  @override
  String get exportAll => '导出全部';

  @override
  String get importCannotRead => '无法读取文件（可尝试较小备份或检查权限）';

  @override
  String importParseError(String message) {
    return '无法解析：$message';
  }

  @override
  String get importMerge => '合并导入';

  @override
  String get importReplaceAll => '替换全部';

  @override
  String get importMerged => '已合并导入';

  @override
  String get importReplaced => '已替换导入';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String playlistsDeletedN(int n) {
    return '已删除 $n 个歌单';
  }

  @override
  String librarySongsDeletedN(int n) {
    return '已删除 $n 首歌曲';
  }

  @override
  String get fabNewPlaylist => '新建歌单';

  @override
  String get emptyPlaylistsHint =>
      '还没有歌单\n在播放页或歌曲列表可将歌曲加入歌单\n\n可在右上角「⋮」中导入、单选/多选';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByPath => '按路径';

  @override
  String get sortByCreated => '按创建时间';

  @override
  String get sortByUpdated => '按更新时间';

  @override
  String get sortByAddedToPlaylist => '按加入歌单时间';

  @override
  String get sortByAddedToPlaylistSub => '正序：先加入在前 · 反序：后加入在前';

  @override
  String get lyricAlignLeft => '左';

  @override
  String get lyricAlignCenter => '中';

  @override
  String get lyricAlignRight => '右';

  @override
  String get addToPlaylistHint => '新建歌单名称';

  @override
  String addToPlaylistUpdatedN(int n) {
    return '已更新歌单（$n 个）';
  }

  @override
  String get noLyrics => '暂无歌词';

  @override
  String get songNotFound => '歌曲不存在';

  @override
  String get pageUnknownTitle => '未知标题';

  @override
  String get queueNoTracks => '暂无曲目';

  @override
  String get playQueueTitle => '播放队列';

  @override
  String get queuePendingPlayAfterCurrentSection => '下一曲播放（待播）';

  @override
  String get playbackModeTitle => '播放模式';

  @override
  String get playbackSequential => '顺序播放';

  @override
  String get playbackShuffle => '随机播放';

  @override
  String get playbackSingleLoop => '单曲循环';

  @override
  String get playbackOnce => '仅播放一次';

  @override
  String get playbackTimer => '定时关闭';

  @override
  String get sleepTimerSheetTitle => '定时关闭';

  @override
  String get sleepTimerCancel => '取消定时关闭';

  @override
  String sleepTimerMinutesN(int n) {
    return '$n 分钟';
  }

  @override
  String get sleepTimerCustom => '自定义时间';

  @override
  String sleepTimerCurrentN(int n) {
    return '当前 $n 分钟';
  }

  @override
  String get sleepTimerLabelMinutes => '分钟';

  @override
  String sleepTimerInvalidRange(int min, int max) {
    return '请输入 $min–$max 之间的整数';
  }

  @override
  String sleepTimerPlayedMinutes(int minutes) {
    return '定时关闭：已播放 $minutes 分钟';
  }

  @override
  String get songPageKeepScreenAwake => '播放页屏幕常亮';

  @override
  String get lyricStyleKeepScreenAwakeSub => '在播放页查看歌词时不自动熄屏';

  @override
  String get lyricModeEmptyHint => '切换显示模式';

  @override
  String get lyricModeAllLines => '多行歌词：全部行（点击为单行）';

  @override
  String lyricModeSingleLineN(int n) {
    return '多行歌词：仅第 $n 行（继续点击切换）';
  }

  @override
  String get sortOptionsTitle => '排序方式';

  @override
  String addToPlaylistTitle(String name) {
    return '加入歌单 · $name';
  }

  @override
  String get addToPlaylistMultiHelp => '可多选；取消勾选将从对应歌单移除该歌曲';

  @override
  String get addToPlaylistNoPlaylistsYet => '暂无歌单，请先输入名称并创建';

  @override
  String get quickEntrySettingsTitle => '快捷入口';

  @override
  String get playlistSelectModeSingle => '单选';

  @override
  String get playlistSelectModeMulti => '多选';

  @override
  String get menuImportPlaylists => '导入歌单';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String playlistSelectCount(int n, int m) {
    return '已选 $n / $m';
  }

  @override
  String get lyricStyleSyncSubtitle => '与当前播放页歌词同步';

  @override
  String get lyricStyleSectionDisplay => '显示';

  @override
  String get lyricStyleSectionDisplaySub => '原文与多行译文的开关';

  @override
  String get lyricStyleShowOriginal => '显示原文';

  @override
  String get lyricStyleShowOriginalSub => '每个时间戳第 1 行';

  @override
  String get lyricStyleShowTranslation => '显示翻译/附加行';

  @override
  String get lyricStyleShowTranslationSub => '第 2 行及以后';

  @override
  String get lyricStyleSectionTypography => '字号与行距';

  @override
  String get lyricStyleSectionTypographySub => '滑条调节后即时生效';

  @override
  String get lyricStyleFontOriginal => '原文字号';

  @override
  String get lyricStyleFontTranslation => '翻译字号';

  @override
  String get lyricStyleLineSpacing => '行间距';

  @override
  String get lyricStyleSectionLineAlign => '行对齐';

  @override
  String get lyricStyleSectionStateColors => '行状态颜色';

  @override
  String get lyricStyleSectionStateColorsSub => '正在播放、已播过、未播到';

  @override
  String get lyricStyleStateNowPlaying => '正在播放行';

  @override
  String get lyricStyleStatePlayed => '已播过的行';

  @override
  String get lyricStyleStateUpcoming => '未播到的行';

  @override
  String get lyricStyleColorNowOriginal => '正在播放 — 原文';

  @override
  String get lyricStyleColorNowTranslation => '正在播放 — 译文';

  @override
  String get lyricStyleColorPlayedOriginal => '已播过 — 原文';

  @override
  String get lyricStyleColorPlayedTranslation => '已播过 — 译文';

  @override
  String get lyricStyleColorUpcomingOriginal => '未播到 — 原文';

  @override
  String get lyricStyleColorUpcomingTranslation => '未播到 — 译文';

  @override
  String get lyricStyleColorPersistNote => '颜色将写入本地设置，切歌后仍保留。';

  @override
  String get lyricStyleActiveGradientTitle => '正在播放行渐变';

  @override
  String get lyricStyleStateGradientSub => '开启后，该双色渐变优先于上方原文/译文纯色；关闭则仅用纯色。';

  @override
  String get lyricStyleActiveGradientTune => '编辑渐变';

  @override
  String get lyricStyleActiveGradientDialogTitle => '正在播放行渐变';

  @override
  String get lyricStylePlayedGradientTitle => '已播过行渐变';

  @override
  String get lyricStyleUpcomingGradientTitle => '未播到行渐变';

  @override
  String get lyricStylePlayedGradientDialogTitle => '已播过行渐变';

  @override
  String get lyricStyleUpcomingGradientDialogTitle => '未播到行渐变';

  @override
  String get lyricColorPickerHint => '点选色块';

  @override
  String get lyricLabelOriginal => '原文';

  @override
  String get lyricLabelTranslation => '译文';

  @override
  String get libraryBatchSelect => '多选';

  @override
  String get libraryBatchDone => '完成';

  @override
  String get libraryBatchSelectAll => '全选';

  @override
  String get libraryBatchDelete => '删除';

  @override
  String get libraryBatchRename => '重命名';

  @override
  String get libraryBatchUploadOneDrive => '上传到 OneDrive';

  @override
  String get libraryBatchDeleteConfirmTitle => '删除所选歌曲？';

  @override
  String get libraryBatchDeleteConfirmMessage => '将从本机删除文件，并更新歌单与最近播放。此操作不可撤销。';

  @override
  String get libraryBatchNoneSelected => '请先选择歌曲';

  @override
  String get libraryBatchRenameTitle => '批量重命名';

  @override
  String get libraryBatchRenameHint => '名称模板，用 %n 表示递增序号（如 曲目 %n）';

  @override
  String get libraryBatchRenameStart => '起始编号';

  @override
  String get libraryRenameSingleTitle => '重命名单曲';

  @override
  String get libraryRenameSingleHint => '只填主文件名，扩展名保持不变。';

  @override
  String get libraryRenameSingleFieldLabel => '文件名';

  @override
  String get libraryRenameSingleDone => '已重命名';

  @override
  String get libraryCloneSong => '克隆歌曲';

  @override
  String get libraryCloneSongTitle => '克隆为新文件';

  @override
  String get libraryCloneSongHint => '输入副本的主文件名（扩展名与原文件相同），保存在同一文件夹。';

  @override
  String get libraryCloneSongDefaultSuffix => ' 副本';

  @override
  String get libraryCloneSongDone => '已克隆';

  @override
  String get libraryCloneSongFailed => '克隆失败';

  @override
  String get libraryCloneSongProgressTitle => '正在克隆歌曲';

  @override
  String get libraryCloneSongProgressMessage => '正在复制文件并刷新曲库…';

  @override
  String get libraryBatchUploadNeedSignIn => '请先在设置中登录 OneDrive';

  @override
  String get libraryBatchUploadNeedCloudFolder => '请先在 OneDrive 设置中选择云端应用文件夹';

  @override
  String get libraryBatchUploadNeedParentFolder =>
      '请先在 OneDrive 设置中选择「上传音乐」文件夹或云端应用文件夹。';

  @override
  String get libraryBatchUploadQueued => '已加入传输队列';

  @override
  String get libraryBatchOpenQueue => '查看队列';

  @override
  String get libraryBatchAddToPlaylist => '添加到歌单';

  @override
  String libraryBatchAddToPlaylistSheetTitle(int count) {
    return '将 $count 首歌添加到用户歌单';
  }

  @override
  String get libraryBatchAddToPlaylistSheetHelp =>
      '已勾选的歌单是「当前所选曲目均已在其中」的歌单；确定后为所选每一首歌同步勾选状态。';

  @override
  String get libraryBatchAddToPlaylistDone => '歌单归属已更新';

  @override
  String get libraryReloadMetadata => '重新加载元信息';

  @override
  String get libraryReloadMetadataDone => '已从文件重新加载元信息';

  @override
  String get oneDriveUploadStatusUploading => '上传中';

  @override
  String get oneDriveTaskDirectionUpload => '上传';

  @override
  String get homeEntrySongRecognizer => '听歌识曲';

  @override
  String get songRecognizerTitle => '听歌识曲';

  @override
  String get songRecognizerModeInApp => '应用内';

  @override
  String get songRecognizerModeAmbient => '环境聆听';

  @override
  String get songRecognizerModeInAppHelp =>
      '请保持在本页，将手机靠近正在播放的音乐，约录制 10 秒以获得较高识别率。';

  @override
  String get songRecognizerModeAmbientHelp =>
      '在本页开启后，每隔约 20 秒自动采样识别。请将手机靠近外放或其他 App 播放的扬声器；离开应用后部分机型可能中断麦克风。';

  @override
  String get songRecognizerStart => '开始识别';

  @override
  String get songRecognizerSnackbarStarted => '开始识别…';

  @override
  String get songRecognizerSnackbarCancelled => '已取消识别';

  @override
  String get songRecognizerStopAmbient => '停止环境聆听';

  @override
  String get songRecognizerListening => '聆听中…';

  @override
  String get songRecognizerRecognizing => '识别中…';

  @override
  String get songRecognizerHistory => '识别记录';

  @override
  String get songRecognizerHistoryEmpty => '暂无记录';

  @override
  String get songRecognizerHistoryFilterAll => '全部';

  @override
  String get songRecognizerHistoryFilterMatched => '成功匹配';

  @override
  String get songRecognizerHistoryFilterArchived => '收藏';

  @override
  String get songRecognizerHistoryEmptyMatched => '暂无成功匹配的记录';

  @override
  String get songRecognizerHistoryEmptyArchived => '暂无收藏记录';

  @override
  String get songRecognizerDeleteHistoryEntryTitle => '删除记录';

  @override
  String get songRecognizerDeleteHistoryEntryMessage => '确定删除这条识别记录？';

  @override
  String get songRecognizerSwipeArchive => '收藏';

  @override
  String get songRecognizerSwipeRestore => '取消收藏';

  @override
  String get songRecognizerSwipeDelete => '删除';

  @override
  String get songRecognizerEntryArchived => '已收藏';

  @override
  String get songRecognizerEntryRestoredFromArchive => '已取消收藏';

  @override
  String get songRecognizerCopyEntry => '复制';

  @override
  String get songRecognizerEntryCopied => '已复制到剪贴板';

  @override
  String get songRecognizerCopyLabelTime => '时间：';

  @override
  String get songRecognizerCopyLabelMode => '采集方式：';

  @override
  String get songRecognizerCopyLabelService => '识别服务：';

  @override
  String get songRecognizerCopyLabelSong => '歌曲：';

  @override
  String get songRecognizerCopyLabelArtist => '歌手：';

  @override
  String get songRecognizerCopyLabelAlbum => '专辑：';

  @override
  String get songRecognizerCopyLabelReleased => '发行日期：';

  @override
  String get songRecognizerCopyLabelAppleMusic => 'Apple Music：';

  @override
  String get songRecognizerCopyLabelSpotify => 'Spotify：';

  @override
  String get songRecognizerCopyLabelNoMatch => '结果：';

  @override
  String get songRecognizerCopyLabelError => '错误：';

  @override
  String get songRecognizerClearHistory => '清空记录';

  @override
  String get songRecognizerClearHistoryConfirm => '确定删除全部识别历史？';

  @override
  String get songRecognizerNoMatch => '未匹配到歌曲，可在更安静环境重试或靠近声源。';

  @override
  String get songRecognizerOpenAppleMusic => 'Apple Music';

  @override
  String get songRecognizerOpenSpotify => 'Spotify';

  @override
  String get songRecognizerApiKey => 'AudD API Token';

  @override
  String get songRecognizerApiKeyHelp =>
      '正式使用建议在 audd.io 控制台创建 Token 并粘贴到此；留空将使用公开试用 Token（额度极低、易被限流）。';

  @override
  String get songRecognizerSave => '保存';

  @override
  String get songRecognizerMicDenied => '需要麦克风权限才能识曲';

  @override
  String get songRecognizerWebUnsupported => '当前浏览器版本暂不支持听歌识曲。';

  @override
  String get songRecognizerAccuracyTip => '建议：安静环境、片段约 10–12 秒、手机靠近扬声器，识别更准确。';

  @override
  String get songRecognizerDuplicateSkipped => '与最近一条结果相同，未重复写入';

  @override
  String get songRecognizerError => '识别失败';

  @override
  String get songRecognizerAmbientActive => '环境聆听进行中';

  @override
  String get songRecognizerTokenMenu => 'API Token';

  @override
  String get songRecognizerCredentialsMenu => '账号与密钥';

  @override
  String get songRecognizerProviderLabel => '识别服务';

  @override
  String get songRecognizerProviderAudd => 'AudD';

  @override
  String get songRecognizerProviderAcrcloud => 'ACRCloud';

  @override
  String get songRecognizerModeLabel => '采集方式';

  @override
  String get songRecognizerAcrTitle => 'ACRCloud 项目';

  @override
  String get songRecognizerAcrHelp =>
      '填写控制台中的 Host（如 identify-eu-west-1.acrcloud.com，不要带 https:// 或路径）、Access Key 与 Access Secret（音视频识别项目）。';

  @override
  String get songRecognizerAcrHost => '主机 Host';

  @override
  String get songRecognizerAcrHostHint => 'identify-….acrcloud.com';

  @override
  String get songRecognizerAcrAccessKey => 'Access Key';

  @override
  String get songRecognizerAcrSecret => 'Secret Key';

  @override
  String get songRecognizerAcrIncomplete =>
      '请在本页填写并保存 ACRCloud 的 Host、Access Key 与 Secret Key 后再识别。';

  @override
  String get songRecognizerSectionApiConfig => '接口配置';

  @override
  String get songRecognizerConfigHint => '在识曲主页选择使用哪一家；在此页分别填写并保存两套密钥（仅保存在本机）。';

  @override
  String get songRecognizerConfigSaved => '已保存';

  @override
  String get songRecognizerAuddCardSubtitle =>
      '来自 audd.io 的控制台 Token；留空则使用额度极低的公开试用。';

  @override
  String get songRecognizerAcrCardTitle => 'ACRCloud';

  @override
  String get songRecognizerAcrCardSubtitle =>
      '控制台中的 Host、Access Key、Secret Key（音视频识别项目）。';

  @override
  String get songRecognizerOpenApiConfigSubtitle =>
      'AudD Token 与 ACRCloud 的 Host、Access Key、Secret Key';

  @override
  String get songRecognizerMatchConfirmTitle => '识别结果';

  @override
  String get songRecognizerMatchConfirmArtistLabel => '艺人';

  @override
  String get songRecognizerMatchConfirmAlbumLabel => '专辑';

  @override
  String get songRecognizerMatchConfirmReleaseLabel => '发行日期';

  @override
  String get songRecognizerMatchConfirmYes => '是这首歌';

  @override
  String get songRecognizerMatchConfirmNo => '不是这首，继续识别';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Yeah Music';

  @override
  String get menuHome => '主頁';

  @override
  String get menuSongList => '歌曲列表';

  @override
  String get menuPlaylists => '歌單';

  @override
  String get menuMusicSource => '音樂來源';

  @override
  String get menuStatistics => '統計';

  @override
  String get menuSettings => '設定';

  @override
  String get statisticsTitle => '統計';

  @override
  String get statisticsSubtitle => '曲庫、收聽習慣與歌單概覽';

  @override
  String get statisticsReloadTooltip => '重新整理';

  @override
  String get statisticsReloadStarted => '正在重新整理播放統計…';

  @override
  String get statisticsReloadDone => '播放統計已更新';

  @override
  String get statisticsReloadFailed => '無法重新整理播放統計';

  @override
  String get statisticsSectionLibrary => '曲庫';

  @override
  String get statisticsSectionPlayback => '播放';

  @override
  String get statisticsSectionPlaylists => '歌單';

  @override
  String get statisticsSectionOneDrive => 'OneDrive';

  @override
  String get statisticsTracksLabel => '曲目總數';

  @override
  String get statisticsFoldersLabel => '音樂資料夾';

  @override
  String get statisticsDurationLabel => '估算總長度';

  @override
  String get statisticsDurationHint => '僅統計詮釋資料中含有效長度的曲目';

  @override
  String get statisticsFormatsLabel => '格式分布';

  @override
  String get statisticsFormatsOther => '其他';

  @override
  String statisticsFormatsMore(int count) {
    return '另有 $count 種副檔名';
  }

  @override
  String get statisticsQualityLabel => '音質分布';

  @override
  String get statisticsQualityHint => '與曲庫音質標識相同規則：在詮釋資料可讀時依格式、位元率與取樣率推斷分級';

  @override
  String get statisticsQualityUnknown => '未知';

  @override
  String get statisticsHistoricalListeningLabel => '歷史聽歌時長';

  @override
  String get statisticsHistoricalListeningHint =>
      '僅在播放器處於播放狀態時累計墙上時鐘（暫停、停止不計）；倍速不改變累計規則。自本版本起寫入本機；強制結束可能遺失尚未寫入的數秒（分批寫入）。';

  @override
  String get statisticsPlaybackTotalLabel => '聽的總歌數';

  @override
  String get statisticsPlaybackTotalSubtitle => '本機累計播放次數（每次開始播放計一次）';

  @override
  String get statisticsPlaybackDistinctLabel => '有播放記錄的曲目數';

  @override
  String get statisticsRecentEntriesLabel => '最近播放列表筆數';

  @override
  String statisticsRecentEntriesSubtitle(int max) {
    return '本機最多保留 $max 筆路徑';
  }

  @override
  String get statisticsPlaylistsCountLabel => '自建歌單數量';

  @override
  String get statisticsPlaylistRefsLabel => '歌單內曲目條目';

  @override
  String get statisticsPlaylistRefsSubtitle => '各歌單路徑數相加；同一首歌在多歌單中會重複計數';

  @override
  String get statisticsOneDriveIndexedLabel => '雲端索引曲目';

  @override
  String get statisticsOneDriveCachedLabel => '已快取 / 下載到本機';

  @override
  String get statisticsOneDriveUnavailable => '登入 OneDrive 後查看雲端統計';

  @override
  String get statisticsNotInitialized => '正在初始化曲庫…';

  @override
  String statisticsDurationHM(int hours, int minutes) {
    return '$hours 小時 $minutes 分鐘';
  }

  @override
  String statisticsDurationMOnly(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get statisticsDurationUnknown => '無法估算';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsBackgroundTheme => '背景主題';

  @override
  String get settingsBackgroundThemeSubtitle => '純色、自訂顏色或背景圖';

  @override
  String get settingsBackgroundThemeDesc => '可選擇純色、自訂強調色或全螢幕背景圖，細項在下一頁調整。';

  @override
  String get settingsSystemInfo => '系統資訊';

  @override
  String get settingsSystemInfoSubtitle => '本機與儲存空間';

  @override
  String get settingsSystemInfoDesc => '檢視裝置相關資訊與磁碟剩餘空間；展開後可檢視各目錄占用。';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsAboutSubtitle => '版本與開源授權';

  @override
  String get settingsAboutDesc => '應用程式名稱與版本、致謝與開源授權全文。';

  @override
  String get settingsHomeGreetingTitle => '首頁問候';

  @override
  String get settingsHomeGreetingListSubtitle => '自訂句子與內建預設輪換展示';

  @override
  String get settingsHomeGreetingHelp =>
      '首頁問候卡片第二行會先有一句內建、隨介面語言變化的預設文案。下列每一則為你的自訂句子（不限則數）；儲存後與預設文案一起輪播，輪播方式可在下方選擇順序或隨機。';

  @override
  String get settingsHomeGreetingLineHint => '輸入問候文案';

  @override
  String get settingsHomeGreetingRotationTitle => '輪播方式';

  @override
  String get settingsHomeGreetingRotationSequential => '順序';

  @override
  String get settingsHomeGreetingRotationRandom => '隨機';

  @override
  String get settingsHomeGreetingEmptyHint => '尚無自訂句子，點下方新增一行';

  @override
  String get settingsHomeGreetingAddLine => '新增一行';

  @override
  String get settingsHomeGreetingSave => '儲存';

  @override
  String get settingsHomeGreetingSaved => '已儲存';

  @override
  String get settingsAboutDialogAuthor => '作者';

  @override
  String get settingsAboutDialogRepo => '存放庫';

  @override
  String get settingsAboutDialogLicense => '授權條款';

  @override
  String get settingsAboutDialogCopyright => '版權';

  @override
  String get settingsAboutDialogClose => '關閉';

  @override
  String settingsAboutDialogVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutDialogBuildLabel(String buildNumber) {
    return '建置編號 $buildNumber';
  }

  @override
  String get settingsAboutDialogVersionTapHint => '點一下檢查更新';

  @override
  String get settingsAboutUpdateChecking => '正在檢查更新…';

  @override
  String get settingsAboutUpdateAlreadyLatest => '已是最新版本';

  @override
  String get settingsAboutUpdateAvailableTitle => '發現新版本';

  @override
  String settingsAboutUpdateAvailableBody(String latest, String current) {
    return '遠端版本為 v$latest，目前為 v$current。';
  }

  @override
  String get settingsAboutUpdateOpenReleases => '打開發行頁面';

  @override
  String get settingsAboutUpdateCheckFailed => '檢查更新失敗';

  @override
  String get settingsAboutUpdateNoRelease => '存放庫尚無 GitHub Release';

  @override
  String get settingsSponsorTitle => '贊助與支援';

  @override
  String get settingsSponsorSubtitle => '應用程式免費 · Star 或自願打賞';

  @override
  String get settingsSponsorSectionFreeTitle => 'Yeah Music 完全免費';

  @override
  String get settingsSponsorSectionFreeBody =>
      'Yeah Music 免費提供完整功能，沒有「付費解鎖」或「必須訂閱」。請勿向聲稱「販售本軟體」的第三方付費；商店若出現收費上架且非官方帳號請謹慎辨識。維護占用業餘時間；下列支援皆為自願，不影響任何功能。';

  @override
  String get settingsSponsorSectionStarTitle => '在 GitHub 點 Star';

  @override
  String get settingsSponsorSectionStarHint =>
      'Star 不需要費用，能讓更多人看見專案，也方便您接收更新與發行說明。';

  @override
  String get settingsSponsorRepoYeahMusicTitle => 'Yeah Music';

  @override
  String get settingsSponsorRepoYeahMusicSubtitle => '本播放器原始碼存放庫';

  @override
  String get settingsSponsorRepoDynamicSql2Title => 'Dynamic-SQL2';

  @override
  String get settingsSponsorRepoDynamicSql2Subtitle =>
      '動態 SQL2 / Java DSL 開源存放庫';

  @override
  String get settingsSponsorEasterEggTriggerLine => '查看付費打賞方法';

  @override
  String get settingsSponsorEasterEggDialogTitle => '想得美';

  @override
  String get settingsSponsorEasterEggDialogBody => '想付錢？門都沒有！此專案用愛發電。';

  @override
  String get settingsSponsorExternalHint =>
      '開啟連結後將離開本應用程式，請在可信頁面操作；打賞不會解鎖任何功能。';

  @override
  String get settingsSponsorCopyLink => '複製連結';

  @override
  String get settingsSponsorLinkCopied => '已複製連結';

  @override
  String get settingsSponsorLaunchFailed => '無法開啟連結';

  @override
  String get settingsSysinfoSectionDevice => '裝置資訊';

  @override
  String get settingsSysinfoSectionStorage => '儲存空間';

  @override
  String get settingsSysinfoPlatformLabel => '執行平台';

  @override
  String get settingsSysinfoTotalSpace => '總空間';

  @override
  String get settingsSysinfoUsedSpace => '已使用';

  @override
  String get settingsSysinfoFreeSpace => '剩餘空間';

  @override
  String get settingsSysinfoStorageUnavailable => '儲存資訊暫時無法取得';

  @override
  String get settingsSysinfoDeviceModel => '裝置型號';

  @override
  String get settingsSysinfoManufacturer => '製造商';

  @override
  String get settingsSysinfoOsVersion => '系統版本';

  @override
  String get settingsSysinfoSdkVersion => 'SDK 版本';

  @override
  String get settingsSysinfoDeviceName => '裝置名稱';

  @override
  String get settingsSysinfoHostName => '主機名稱';

  @override
  String get settingsSysinfoKernelVersion => '核心版本';

  @override
  String get settingsSysinfoDistroLabel => '版本';

  @override
  String get settingsSysinfoBuildNumber => '組建編號';

  @override
  String get settingsSysinfoError => '錯誤';

  @override
  String get settingsSysinfoFetchFailed => '無法取得裝置資訊';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSubtitle => '介面顯示語言';

  @override
  String get settingsLanguageDesc => '設定選單與介面文案語言；曲目資訊仍以檔案內嵌詮釋資料為準。';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle => '微軟帳戶同步、目錄與下載位置';

  @override
  String get settingsOneDriveDesc =>
      '使用 Microsoft 登入（正式版無需填寫用戶端 ID）。可選音樂瀏覽根目錄、雲端應用程式資料夾與本機下載目錄；點播時若自訂目錄存在則寫入該處，否則使用應用程式資料下的預設儲存。';

  @override
  String get settingsPlaybackShortcutsTitle => '快速鍵';

  @override
  String get settingsPlaybackShortcutsSubtitle => '播放、暫停、上一曲、下一曲';

  @override
  String get settingsPlaybackShortcutsPlayPause => '播放 / 暫停';

  @override
  String get settingsPlaybackShortcutsPrevious => '上一曲';

  @override
  String get settingsPlaybackShortcutsNext => '下一曲';

  @override
  String get settingsPlaybackShortcutsChange => '更改…';

  @override
  String get settingsPlaybackShortcutsDisable => '關閉';

  @override
  String get settingsPlaybackShortcutsEnable => '開啟';

  @override
  String get settingsPlaybackShortcutsDisabledLabel => '已關閉';

  @override
  String get settingsPlaybackShortcutsPressKey => '錄製快速鍵';

  @override
  String get settingsPlaybackShortcutsPressKeyHint => '請按下新的組合鍵。Esc 取消。';

  @override
  String get settingsPlaybackShortcutsUnavailableBody =>
      '快捷鍵僅在 Windows / macOS / Linux 桌面版可自訂。';

  @override
  String get settingsWireRemoteTitle => '耳機線控';

  @override
  String get settingsWireRemoteSubtitle => '有線連擊與藍牙獨立下一曲／上一曲鍵';

  @override
  String get settingsWireRemoteSubtitleOtherPlatforms =>
      '自訂線控僅在 Android 版、應用程式在前景時生效。';

  @override
  String get settingsWireRemoteUnavailableTitle => '此處無法編輯';

  @override
  String get settingsWireRemoteUnavailableBody =>
      '耳機按鍵自訂僅在 Android、應用程式在前景時生效（含藍牙獨立鍵）。桌面版請使用「快速鍵」；iOS 由系統處理。';

  @override
  String get settingsWireRemoteUseCustom => '使用自訂線控';

  @override
  String get settingsWireRemoteUseCustomSubtitle => '關閉後由系統依預設方式處理耳機按鍵。';

  @override
  String get wireRemoteSingleTitle => '單擊';

  @override
  String get wireRemoteDoubleTitle => '雙擊';

  @override
  String get wireRemoteTripleTitle => '三擊';

  @override
  String get wireRemoteMediaNextTitle => '「下一曲」媒體鍵（藍牙等）';

  @override
  String get wireRemoteMediaPreviousTitle => '「上一曲」媒體鍵（藍牙等）';

  @override
  String get wireRemoteActionPlayPause => '播放 / 暫停';

  @override
  String get wireRemoteActionNext => '下一曲';

  @override
  String get wireRemoteActionPrevious => '上一曲';

  @override
  String get wireRemoteActionNone => '無';

  @override
  String get wireRemotePickActionTitle => '選擇動作';

  @override
  String get settingsMacosMenuBarLyrics => '選單列歌詞';

  @override
  String get settingsMacosMenuBarLyricsSubtitle => '選單列單行精簡歌詞';

  @override
  String get settingsMacosMenuBarLyricsDesc => '在系統選單列顯示單行歌詞（macOS）';

  @override
  String get settingsDesktopLyricsGroupTitle => '桌面歌詞';

  @override
  String get settingsDesktopLyricsGroupSubtitle => '懸浮視窗與 macOS 選單列歌詞';

  @override
  String get settingsDesktopLyricsGroupDetail =>
      '桌面歌詞包含可拖曳的懸浮歌詞視窗，以及 macOS 上可選的選單列單行歌詞。\n\n懸浮視窗與播放頁使用同一套歌詞樣式（顏色、多行模式、翻譯等）。可鎖定位置、調節背景透明度，並設定目前時間軸列上下各顯示多少列。\n\n選單列歌詞（僅 macOS）為精簡單行，不需要懸浮視窗時可在選單列常駐查看。';

  @override
  String get settingsDesktopFloatingLyrics => '懸浮歌詞';

  @override
  String get settingsDesktopFloatingLyricsSubtitle => '可拖曳的目前歌詞浮窗';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      '在應用視窗上方顯示可拖曳的目前歌詞，與播放頁歌詞樣式設定一致。';

  @override
  String get settingsDesktopFloatingBgOpacity => '背景透明度';

  @override
  String get settingsDesktopFloatingBgOpacitySubtitle => '歌詞板背景的透明程度';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      '歌詞面板背景的明暗程度；0 為完全無背景，僅顯示文字。';

  @override
  String get settingsDesktopFloatingLinesBefore => '目前列之前';

  @override
  String get settingsDesktopFloatingLinesBeforeSubtitle => '目前列上方時間軸列數';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      '以目前時間軸行為基準，向上允許顯示多少列（不含目前列）。';

  @override
  String get settingsDesktopFloatingLinesAfter => '目前列之後';

  @override
  String get settingsDesktopFloatingLinesAfterSubtitle => '目前列下方時間軸列數';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      '以目前時間軸行為基準，向下允許顯示多少列（不含目前列）。';

  @override
  String get settingsDesktopFloatingDragLock => '鎖定位置';

  @override
  String get settingsDesktopFloatingDragLockSubtitle => '禁止拖曳懸浮視窗';

  @override
  String get settingsDesktopFloatingDragLockDesc => '開啟後懸浮歌詞視窗不可拖曳。';

  @override
  String get settingsCarLyricsGroupTitle => '車載歌詞';

  @override
  String get settingsCarLyricsGroupSubtitle => '媒體通知、藍牙與 Android Auto';

  @override
  String get settingsCarLyricsGroupDetail =>
      '使用 Android 媒體工作階段，讓鎖屏、藍牙耳機與 Android Auto 等顯示正在播放內容並提供控制。\n\n開啟：在播放器中建立完整佇列，通知與車機上的上一首／下一首對應真實切歌；播放／暫停與單曲循環在支援範圍內與 App 一致。\n\n封面：將內嵌封面送到通知與支援顯示封面的車機。\n\n歌詞：在支援的系統上把媒體副標題更新為目前歌詞行，規則與 App 內其它歌詞展示一致。\n\n隨機、僅播一次等模式仍以 App 內「播放模式」為準；車機上的列表循環／隨機可能與部分模式不完全一致。';

  @override
  String get settingsCarLyricsEnabled => '啟用車載歌詞';

  @override
  String get settingsCarLyricsEnabledSubtitle => '通知列佇列與切歌';

  @override
  String get settingsCarLyricsEnabledDesc =>
      '顯示媒體通知與佇列，支援車機／耳機切歌；單曲循環與系統重複模式同步。';

  @override
  String get settingsCarLyricsShowCover => '顯示封面';

  @override
  String get settingsCarLyricsShowCoverSubtitle => '通知與車機展示封面';

  @override
  String get settingsCarLyricsShowCoverDesc => '在通知與支援的車機上展示內嵌封面圖。';

  @override
  String get settingsCarLyricsSyncLyrics => '同步目前歌詞行';

  @override
  String get settingsCarLyricsSyncLyricsSubtitle => '副標題顯示目前歌詞';

  @override
  String get settingsCarLyricsSyncLyricsDesc => '在支援的系統上將副標題更新為目前歌詞。';

  @override
  String get settingsCarLyricsOnlyAndroidHint =>
      '僅 Android 可生效與修改；目前裝置上開關為唯讀，僅顯示已儲存的選項。';

  @override
  String get menuBarLyricsIdle => 'Yeah Music · 未在播放';

  @override
  String get menuBarLyricsNoLyrics => '無歌詞';

  @override
  String get menuBarContextPlay => '播放';

  @override
  String get menuBarContextPause => '暫停';

  @override
  String get menuBarContextPrevious => '上一曲';

  @override
  String get menuBarContextNext => '下一曲';

  @override
  String get oneDriveSettingsTitle => 'OneDrive';

  @override
  String get oneDriveSectionAccount => '帳戶';

  @override
  String get oneDriveSectionPaths => '目錄與儲存空間';

  @override
  String get oneDriveSectionSync => '雲端同步';

  @override
  String get oneDriveSyncMasterTitle => '同步到 OneDrive';

  @override
  String get oneDriveSyncMasterSubtitle =>
      '按需勾選同步類別。每次上傳會在雲端應用程式資料夾下建立「裝置型號 / yyyyMMddTHHmmss」目錄。';

  @override
  String get oneDriveSyncItemUserPlaylists => '我的歌單';

  @override
  String get oneDriveSyncItemUserPlaylistsSubtitle =>
      '封面、配色、歌單列表與曲目順序（按裝置目錄儲存）。';

  @override
  String get oneDriveSyncItemHomeGreeting => '首頁問候（首張卡片）';

  @override
  String get oneDriveSyncItemHomeGreetingSubtitle => '與設定 → 首頁問候為同一資料來源。';

  @override
  String get oneDriveSyncItemQuickEntry => '首頁快捷入口';

  @override
  String get oneDriveSyncItemQuickEntrySubtitle => '排序與各入口顯示開關。';

  @override
  String get oneDriveSyncItemPlaybackListsStats => '最新 / 最多播放與播放統計';

  @override
  String get oneDriveSyncItemPlaybackListsStatsSubtitle =>
      '最近播放列表、播放次數與累計收聽時長。';

  @override
  String get oneDriveSyncItemLyricsUi => '歌詞與播放頁';

  @override
  String get oneDriveSyncItemLyricsUiSubtitle => '歌詞樣式、桌面 / 車載歌詞與播放頁螢幕恆亮等。';

  @override
  String get oneDriveSyncItemSongRecognition => '聽歌識曲與紀錄';

  @override
  String get oneDriveSyncItemSongRecognitionSubtitle =>
      '所用引擎及 AudD / ACRCloud 金鑰、本地辨識歷史。';

  @override
  String get oneDriveSyncItemTheme => '背景主題';

  @override
  String get oneDriveSyncItemThemeSubtitle => '漸層、預設 / 自訂顏色與背景圖片等（不含介面語言）。';

  @override
  String get oneDriveSyncFrequencyLabel => '同步頻率';

  @override
  String get oneDriveSyncFreqManual => '僅手動';

  @override
  String get oneDriveSyncFreq1h => '每 1 小時';

  @override
  String get oneDriveSyncFreq6h => '每 6 小時';

  @override
  String get oneDriveSyncFreq12h => '每 12 小時';

  @override
  String get oneDriveSyncFreq24h => '每 24 小時';

  @override
  String get oneDriveSyncNow => '立即同步';

  @override
  String get oneDriveSyncNowDescription =>
      '立即上傳已勾選類別：寫入雲端應用程式資料夾下的「裝置型號 / yyyyMMddTHHmmss」。';

  @override
  String get oneDriveSyncNowNeedLogin => '請先登入 Microsoft 帳戶。';

  @override
  String get oneDriveSyncNowNeedCloudFolder => '請先在上方選好「雲端應用程式資料夾」，我們才知道備份位置。';

  @override
  String get oneDriveSyncNowFinished => '已上傳至雲端應用程式資料夾下的同步目錄。';

  @override
  String oneDriveSyncNowFailed(String message) {
    return '備份失敗：$message';
  }

  @override
  String get oneDriveRestoreFromCloud => '從雲端還原';

  @override
  String get oneDriveRestoreSubtitle => '選擇備份項目（舊版平鋪檔案或按裝置工作階段目錄），再勾選要還原的內容。';

  @override
  String get oneDriveRestoreSheetTitle => '選擇備份時間點';

  @override
  String get oneDriveRestoreGroupThisDevice => '本裝置';

  @override
  String get oneDriveRestoreGroupOtherDevices => '其他裝置';

  @override
  String get oneDriveRestoreGroupLegacyFlat => '舊版平面備份';

  @override
  String get oneDriveRestoreContentSectionTitle => '要還原的內容';

  @override
  String get oneDriveRestoreLoadMore => '載入更多';

  @override
  String oneDriveRestoreListShowing(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get oneDriveRestoreTabUnknownDevice => '未知裝置';

  @override
  String get oneDriveRestoreEmpty => '尚未發現備份檔案。請先使用下方「立即同步」上傳歌單或設定。';

  @override
  String get oneDriveRestorePlaylistCheckbox => '歌單';

  @override
  String get oneDriveRestoreLegacySettingsCheckbox => '舊版整塊設定 JSON';

  @override
  String get oneDriveRestoreSliceHomeGreeting => '首頁問候';

  @override
  String get oneDriveRestoreSliceQuickEntry => '首頁快捷入口';

  @override
  String get oneDriveRestoreSlicePlaybackLists => '最近播放與統計 Hive';

  @override
  String get oneDriveRestoreSliceLyricsUi => '歌詞與螢幕恆亮';

  @override
  String get oneDriveRestoreSliceSongRecognition => '聽歌識曲與紀錄';

  @override
  String get oneDriveRestoreSliceTheme => '背景主題';

  @override
  String get oneDriveRestorePlaylistModeMerge => '合併到本機（相同 id 歌單合併曲目）';

  @override
  String get oneDriveRestorePlaylistModeReplace => '覆寫本機歌單（先清空再匯入）';

  @override
  String get oneDriveRestoreAction => '還原';

  @override
  String get oneDriveRestoreNeedPickContent => '請至少勾選一項要還原的內容。';

  @override
  String get oneDriveRestoreMissingPlaylistsFile => '此備份中沒有歌單檔案。';

  @override
  String get oneDriveRestoreMissingSettingsFile => '此備份中沒有舊版整塊設定檔案。';

  @override
  String oneDriveBackupSnapshotDeviceSession(
    String deviceName,
    String sessionStamp,
  ) {
    return '$deviceName · $sessionStamp';
  }

  @override
  String get oneDriveSyncNowNeedMasterOn => '請先開啟上方的「同步到 OneDrive」。';

  @override
  String get oneDriveSyncNowNothingSelected => '請先在上方勾選至少一項同步類別。';

  @override
  String get oneDriveRestoreFinished => '還原完成。';

  @override
  String oneDriveRestoreFailed(String message) {
    return '還原失敗：$message';
  }

  @override
  String get oneDriveRestoreLoadingList => '正在讀取備份列表…';

  @override
  String get oneDriveSyncNowInProgress => '同步中…';

  @override
  String get oneDriveRestoreInProgress => '還原中…';

  @override
  String get oneDriveCloudAppDataTitle => '雲端應用程式資料夾';

  @override
  String get oneDriveCloudAppDataSubtitle => '預留：設定備份、歌單與同步等。';

  @override
  String get oneDriveCloudAppFolderUnset => '未設定';

  @override
  String get oneDriveLocalDownloadTitle => '本機下載目錄';

  @override
  String get oneDriveLocalDownloadSubtitle =>
      '從雲端點播時：若此處路徑存在則儲存到該資料夾；未指定或路徑不存在時使用下方預設儲存空間。';

  @override
  String get oneDriveLocalDownloadUnset => '未設定（稍後將使用預設路徑）';

  @override
  String get oneDriveChooseCloudFolder => '在 OneDrive 中選擇';

  @override
  String get oneDriveChooseLocalFolder => '選擇本機資料夾…';

  @override
  String get oneDrivePickFolderForAppData => '選擇應用程式資料與未來備份要用的資料夾。';

  @override
  String get oneDrivePickFolderForMusicUpload => '選擇從本裝置上傳音樂時的目標資料夾。';

  @override
  String get oneDriveMusicUploadFolderTitle => '上傳音樂目標資料夾';

  @override
  String get oneDriveMusicUploadFolderSubtitle =>
      '從本機曲庫上傳到 OneDrive 時的預設父資料夾。未另外設定時，會使用上方的雲端應用程式資料夾。';

  @override
  String get oneDriveMusicUploadFolderFallback => '與雲端應用程式資料夾相同';

  @override
  String get oneDriveAppMissingClientConfig => '這一版暫時還不能使用微軟帳號登入，下一版本或許會加入該功能。';

  @override
  String get oneDriveNeedSignInForPicker => '請先登入後再選擇 OneDrive 資料夾。';

  @override
  String get oneDriveClear => '清除';

  @override
  String get oneDriveSignIn => '使用 Microsoft 登入';

  @override
  String get oneDriveSignOut => '登出';

  @override
  String get oneDriveSignOutDone => '已登出 OneDrive';

  @override
  String get oneDriveSignedIn => '已登入';

  @override
  String get oneDriveNotSignedIn => '未登入';

  @override
  String get oneDriveLinuxUnsupported => '此平台尚不支援 OneDrive 登入。';

  @override
  String get oneDriveSignInFailed => '未能登入，請檢查網路後再試。';

  @override
  String get oneDriveCacheNote =>
      '預設儲存為應用程式資料下的 onedrive_cache；僅當上方自訂資料夾存在且為目錄時才寫入該處。';

  @override
  String get oneDriveOpenBrowser => '開啟 OneDrive';

  @override
  String get homeEntryOneDrive => 'OneDrive';

  @override
  String get oneDriveBrowserTitle => 'OneDrive';

  @override
  String get oneDriveEmptyFolder => '此資料夾是空的';

  @override
  String get oneDrivePlayAll => '播放此資料夾全部';

  @override
  String get oneDrivePreparing => '準備中…';

  @override
  String get oneDriveDownloadQueueTitle => 'OneDrive 下載佇列';

  @override
  String get oneDriveTransferQueueTitle => 'OneDrive 傳輸佇列';

  @override
  String get oneDriveTransferTabDownload => '下載';

  @override
  String get oneDriveTransferTabUpload => '上傳';

  @override
  String get oneDriveDownloadPause => '暫停';

  @override
  String get oneDriveDownloadResume => '繼續';

  @override
  String get oneDriveDownloadStopAll => '全部停止';

  @override
  String get oneDriveDownloadContinueAll => '全部繼續';

  @override
  String get oneDriveDownloadAutoPlayWhenDone => '佇列全部完成後自動播放';

  @override
  String get oneDriveDownloadPlayDownloaded => '播放已下載的歌曲';

  @override
  String get oneDriveDownloadStatusPending => '等待中';

  @override
  String get oneDriveDownloadStatusDownloading => '下載中';

  @override
  String get oneDriveDownloadStatusDone => '已完成';

  @override
  String get oneDriveDownloadStatusFailed => '失敗';

  @override
  String get oneDriveDownloadStatusCancelled => '已取消';

  @override
  String get oneDriveDownloadCloseJustPanel => '關閉面板（下載繼續在背景）';

  @override
  String get oneDriveDownloadQueueEmpty =>
      '尚無批量下載。\n在雲端曲庫或 OneDrive 瀏覽器使用「播放全部」後會顯示於此；關閉抽屜不會中斷下載。';

  @override
  String get oneDriveUploadQueueEmpty =>
      '尚無上傳工作。\n在本機曲庫用多選列的「上傳到 OneDrive」加入；關閉畫面不會中斷背景傳輸。';

  @override
  String get oneDriveTransferQueueEmpty => '目前佇列中尚無工作。';

  @override
  String get oneDriveDownloadQueuePageHint => '在此暫停、繼續或停止批量下載。關閉抽屜不會取消背景任務。';

  @override
  String get oneDriveUploadQueuePageHint =>
      '從本機發起的上傳會顯示於此，可用上方按鈕暫停、繼續或停止；清空紀錄會同時影響下載與上傳歷史。';

  @override
  String get oneDriveDownloadQueueSubtitle => '檢視與控制上傳、下載與播放';

  @override
  String get oneDriveDownloadQueueTooltip => '下載佇列';

  @override
  String get oneDriveBrowserRefreshTooltip => '重新整理本頁（清除列表快取並從雲端重新載入）';

  @override
  String oneDriveEnqueueAddedSingle(String name) {
    return '已將「$name」加入下載佇列';
  }

  @override
  String oneDriveEnqueueAddedMany(int count) {
    return '已將 $count 首加入下載佇列';
  }

  @override
  String get oneDriveDownloadViewQueue => '檢視佇列';

  @override
  String get oneDriveDownloadClearHistory => '清空紀錄';

  @override
  String get oneDriveTransferClearDownloadsList => '清空下載列表';

  @override
  String get oneDriveTransferClearUploadsList => '清空上傳列表';

  @override
  String oneDriveError(String message) {
    return 'OneDrive 錯誤：$message';
  }

  @override
  String get oneDriveUp => '上層';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · 雲端曲庫';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      '加入的資料夾會遞迴掃描出音訊清單；點曲目按需下載（自訂目錄存在則用該目錄，否則用預設快取），已下載者可離線播放。';

  @override
  String get oneDriveCloudLibraryEmpty =>
      '尚未建立索引。\n請先點「在網路磁碟選擇資料夾」，選好音樂目錄後再點「重新掃描」。';

  @override
  String get oneDriveCachedPlaylistTitle => 'OneDrive · 快取下載';

  @override
  String get oneDriveCachedPlaylistEmpty =>
      '目前沒有從 OneDrive 下載到本機的歌曲。請在雲端曲庫播放；檔案會儲存在應用程式快取或你設定的本機下載目錄。';

  @override
  String get oneDriveIndexRootsLabel => '已索引目錄';

  @override
  String get oneDriveRescanIndex => '重新掃描';

  @override
  String get oneDriveBrowseFolders => '在網路磁碟選擇資料夾';

  @override
  String get oneDrivePickFolderForIndex => '點資料夾右側 +，或進入資料夾後點「使用此資料夾」。';

  @override
  String get oneDriveUseCurrentFolder => '使用此資料夾';

  @override
  String get oneDrivePickMultipleFoldersHint => '勾選資料夾；點右側箭頭進入子資料夾繼續選擇。';

  @override
  String get oneDriveIncludeOpenFolderInSelection => '包含目前資料夾';

  @override
  String oneDriveAddSelectedFoldersAction(int count) {
    return '新增（$count）';
  }

  @override
  String get oneDriveAddFolderTooltip => '加入雲端曲庫';

  @override
  String get oneDriveIndexingEllipsis => '正在掃描目錄…';

  @override
  String oneDriveLastIndexed(String time) {
    return '上次掃描：$time';
  }

  @override
  String get oneDrivePlayAllTracks => '播放全部';

  @override
  String oneDriveTracksCount(int count) {
    return '$count 曲';
  }

  @override
  String get oneDriveCloudSearchHint => '搜尋檔名或路徑…';

  @override
  String get oneDriveNoIndexRoots => '尚未設定目錄，請先用「在網路磁碟選擇資料夾」。';

  @override
  String get oneDriveLastIndexedNever => '上次掃描：—';

  @override
  String get oneDriveIndexFoldersRecursiveHint => '掃描會遞迴包含各資料夾及其子目錄下的所有音訊檔案。';

  @override
  String get oneDriveRemoveIndexFolderTitle => '移除索引資料夾？';

  @override
  String oneDriveRemoveIndexFolderMessage(String name) {
    return '要從索引中移除「$name」嗎？該資料夾及其子資料夾中的曲目將不再出現在列表中，需要時可重新新增。';
  }

  @override
  String get oneDriveRemoveIndexFolderAction => '移除';

  @override
  String get languageSettingsTitle => '語言';

  @override
  String get languageSettingsDescription =>
      '選擇應用程式介面顯示語言。選擇「跟隨系統」時，在已提供翻譯的情況下將跟隨裝置語言。';

  @override
  String get langFollowSystem => '跟隨系統';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langSimplifiedChinese => '簡體中文';

  @override
  String get langTraditionalChinese => '繁體中文';

  @override
  String get themeSettingsTitle => '主題設定';

  @override
  String get globalTheme => '全域主題';

  @override
  String get globalThemeDesc => '控制應用程式介面為淺色、深色或跟隨系統；將儲存於本裝置。';

  @override
  String get themeLight => '日間模式';

  @override
  String get themeDark => '夜間模式';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get sectionThemeType => '主題類型';

  @override
  String get themeTypeSolid => '預設顏色';

  @override
  String get themeTypeCustom => '自訂顏色';

  @override
  String get themeTypeImage => '背景圖片';

  @override
  String get sectionPresetColors => '預設顏色';

  @override
  String get sectionCustomColor => '自訂顏色';

  @override
  String get sectionBackgroundImage => '背景圖片';

  @override
  String get primaryColor => '主色調';

  @override
  String get secondaryColor => '次色調';

  @override
  String get themeGradientRgbSectionTitle => '漸層背景';

  @override
  String get themeGradientRgbSectionSubtitle => '漸變 RGB 滑桿，可同時微調兩端顏色與漸變方向。';

  @override
  String get themeGradientRgbFineTune => '編輯雙色與方向…';

  @override
  String get themeGradientRgbDialogTitle => '背景漸層';

  @override
  String get actionSelect => '選擇';

  @override
  String get fogBackground => '背景霧化';

  @override
  String get fogBackgroundDesc =>
      '霧化並調暗背景圖，降低對文字的干擾。即使調低也會保留輕壓暗與上下邊緣漸暗；花色或反差強的圖可再調高。預設 45%。';

  @override
  String get fogWeak => '弱';

  @override
  String get fogStrong => '強';

  @override
  String get actionPickImage => '選擇圖片';

  @override
  String get actionRemove => '移除';

  @override
  String cannotSaveBackground(String error) {
    return '無法儲存背景圖（請重試或換一張）：$error';
  }

  @override
  String get themeWallpaperSavedRestartHint =>
      '桌布已儲存。若畫面仍未更新，請完全關閉 App 後再重新開啟。';

  @override
  String get colorDialogTitlePrimary => '選擇主色調';

  @override
  String get colorDialogTitleSecondary => '選擇次色調';

  @override
  String get actionCancel => '取消';

  @override
  String get actionRetry => '重試';

  @override
  String startupFailed(String error) {
    return '啟動失敗：$error';
  }

  @override
  String get welcomeTagline => '每一次聆聽，都從這裡開始';

  @override
  String get welcomeEnter => '進入應用';

  @override
  String get welcomeEnterWait => '進入應用（需等待載入完成）';

  @override
  String get welcomeHintWhenReady => '載入已完成，可隨時進入主頁。';

  @override
  String get welcomeHintWhenNotReady => '啟動完成後將自動進入主頁。';

  @override
  String get welcomePreparing => '正在完成啟動準備…';

  @override
  String get welcomeCountdownLabel => '啟動時間';

  @override
  String get welcomeCountdownSubDoneReady => '首頁資源已就緒，可立即進入';

  @override
  String get welcomeStartupSubLoading => '正在載入主頁資料…完成後自動進入';

  @override
  String get secondsUnit => '秒';

  @override
  String get welcomeNotReadyMessage => '請稍等，資源尚未載入完成。';

  @override
  String welcomeLoadError(String error) {
    return '載入出錯。請檢查儲存權限或稍後重試。\n\n$error';
  }

  @override
  String get welcomeFakeUserSettings => '正在載入使用者設定';

  @override
  String get welcomeFakeLibrary => '正在載入曲庫';

  @override
  String get welcomeFakePlaylists => '正在載入歌單';

  @override
  String get welcomeFakeOther => '正在載入其他數據';

  @override
  String get welcomeFakeFinishing => '正在完成初始化';

  @override
  String get homeGreetingLateNight => '夜深了';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homePullLoftTitle => '從本機重新載入';

  @override
  String get homePullReleaseHint => '放手即可載入已儲存的設定';

  @override
  String get homePullEmptyTease => '這裡什麼也沒有，再拉也沒有用呀';

  @override
  String get homePullStepThemeWallpaper => '主題：配色、漸層與桌布';

  @override
  String get homePullStepBrightnessMode => '外觀：淺色 / 深色模式';

  @override
  String get homePullStepLanguage => '介面語言';

  @override
  String get homePullStepPlaylistsCarousel => '歌單與首頁橫滑順序';

  @override
  String get homePullStepShortcuts => '首頁捷徑';

  @override
  String get homePullStepRecentTopPlayed => '最近播放與播放次數';

  @override
  String get homePullStepLyricsDisplay => '歌詞顯示（從儲存重新讀取）';

  @override
  String get homePullStepPlaybackPrefs => '播放模式（隨機 / 循環等）';

  @override
  String get homePullRefreshDone => '已從本機儲存重新載入設定。';

  @override
  String homePullRefreshFailed(String error) {
    return '本機載入失敗：$error';
  }

  @override
  String get homeMenuTooltip => '選單';

  @override
  String get homeSearchTooltip => '搜尋';

  @override
  String get homeQuickEntryEmpty => '暫無捷徑，點「管理」可顯示本機曲庫、我的歌單、OneDrive 快取歌單等';

  @override
  String get homeEntryLibrary => '本機曲庫';

  @override
  String get homeEntryMyPlaylists => '我的歌單';

  @override
  String get homeEntryRecent => '最近播放';

  @override
  String get homeEntryMostPlayed => '最多播放';

  @override
  String get homeEntryDiscover => '探索';

  @override
  String get homeEntryCloudLibrary => '雲端曲庫';

  @override
  String get homeEntryOneDriveCachePlaylist => '快取歌單';

  @override
  String get homeSectionQuickEntry => '捷徑';

  @override
  String get homeActionManage => '管理';

  @override
  String get homeSectionMyPlaylists => '我的歌單';

  @override
  String get homeActionMore => '更多';

  @override
  String get homeLoadingLibrary => '正在載入曲庫…';

  @override
  String get homeRecentEmpty => '暫無最近播放，在曲庫或歌單中播放歌曲後會顯示';

  @override
  String get homeSectionMostPlayed => '最多播放';

  @override
  String get homeSectionRecentPlays => '最近播放';

  @override
  String get homeActionAll => '全部';

  @override
  String get homeMostPlayedPathMismatch =>
      '已有播放次數記錄，但路徑與目前曲庫不一致（重新命名/移動後請重掃音樂目錄，再播幾次會恢復）';

  @override
  String get homeMostPlayedEmpty => '暫無播放次數統計，在曲庫或歌單中多播幾首歌後會依次數排行';

  @override
  String get mostPlayedSwitchSortAscending => '切換為按播放次數正序（少→多）';

  @override
  String get mostPlayedSwitchSortDescending => '切換為按播放次數倒序（多→少）';

  @override
  String homePlayCount(int c) {
    return '已播放 $c 次';
  }

  @override
  String homePlayCountWithBase(String base, int c) {
    return '$base · 已播放 $c 次';
  }

  @override
  String homeGreetingLine(String greeting) {
    return '$greeting，今天想聽點什麼？';
  }

  @override
  String get homeGreetingSub => '從下面接續上次，或選一張歌單開始';

  @override
  String get homeSearchHint => '搜尋歌曲、歌手、歌單';

  @override
  String get homeContinuePlaying => '繼續播放';

  @override
  String get homeUnknownTitle => '未知';

  @override
  String get homeNowPlayingAlbum => '正在播放';

  @override
  String get homeNothingPlaying => '還沒有在播放';

  @override
  String get homeOpenLibraryToPlay => '去本機曲庫選一首歌開始';

  @override
  String get homeAllSongsLoading => '載入中…';

  @override
  String get homeScanMusicFolder => '去掃描音樂目錄';

  @override
  String homeTrackCount(int n) {
    return '$n 首';
  }

  @override
  String get homeAllSongs => '全部歌曲';

  @override
  String get homeCreatePlaylist => '建立歌單';

  @override
  String get homeCreatePlaylistSub => '集中收藏你喜歡的歌';

  @override
  String get homeEmptyPlaylist => '空歌單';

  @override
  String get songsListEmpty => '暫無歌曲';

  @override
  String get tooltipSort => '排序';

  @override
  String get playbackFailedSnackMessage => '無法播放此曲目，檔案可能遺失、無法讀取或格式不支援。';

  @override
  String get languageRestartNotice => '部分介面需重新啟動應用程式後才會完全套用所選語言。';

  @override
  String get locateNotInList => '目前播放不在本清單';

  @override
  String get locateToCurrent => '定位到目前';

  @override
  String get locateToCurrentPlaying => '定位到目前播放';

  @override
  String get locateToLyricLine => '定位到目前歌詞';

  @override
  String get tooltipBack => '返回';

  @override
  String get tooltipAddToPlaylist => '加入歌單';

  @override
  String get menuPlayNextAfterCurrent => '下一曲播放';

  @override
  String get libraryPlayNextAfterCurrentQueued => '目前曲目結束後將播放所選歌曲';

  @override
  String get libraryPlayNextAfterCurrentNotInQueue => '所選歌曲不在目前播放佇列中';

  @override
  String get tooltipDone => '完成';

  @override
  String get tooltipMoreActions => '操作';

  @override
  String get tooltipMore => '更多';

  @override
  String get tooltipLyricStyle => '歌詞樣式';

  @override
  String get songPageMoreSheetTitle => '更多操作';

  @override
  String get songPageMoreQueryMetadata => '查詢歌曲元資訊';

  @override
  String get songPageMoreUploadOneDrive => '上傳至 OneDrive';

  @override
  String get songPageMoreShare => '分享';

  @override
  String get songPageMoreEditMusicTagsExternal => '使用音樂標籤編輯…';

  @override
  String get songPageMoreEditMusicTagsInline => '編輯內嵌標籤…';

  @override
  String get songPageInlineTagsUnstableTitle => '提示';

  @override
  String get songPageInlineTagsUnstableBody =>
      '此功能尚未完全穩定，寫入時可能損壞音訊檔內的詮釋資料。建議先複製或拷貝該歌曲作備份後再繼續。';

  @override
  String get songPageInlineTagsUnstableContinue => '仍要繼續';

  @override
  String get songPageInlineTagsUnstableCancel => '取消';

  @override
  String get songPageInlineTagsEditorTitle => '編輯內嵌標籤';

  @override
  String get songPageInlineTagsFieldTitle => '標題';

  @override
  String get songPageInlineTagsFieldArtist => '演出者';

  @override
  String get songPageInlineTagsFieldAlbum => '專輯';

  @override
  String get songPageInlineTagsCoverSection => '內嵌封面';

  @override
  String get songPageInlineTagsCoverReplace => '選擇圖片並裁剪…';

  @override
  String get songPageInlineTagsCoverRemove => '移除封面';

  @override
  String get songPageInlineTagsCoverInvalid => '請選擇 JPEG 或 PNG 圖片。';

  @override
  String get songPageInlineTagsFieldYear => '年份';

  @override
  String get songPageInlineTagsFieldTrackNumber => '曲目編號';

  @override
  String get songPageInlineTagsFieldTrackTotal => '曲目總數';

  @override
  String get songPageInlineTagsFieldDiscNumber => '碟片編號';

  @override
  String get songPageInlineTagsFieldDiscTotal => '碟片總數';

  @override
  String get songPageInlineTagsFieldLyrics => '歌詞';

  @override
  String get songPageInlineTagsSave => '儲存';

  @override
  String get songPageInlineTagsSaved => '已寫入檔案';

  @override
  String songPageInlineTagsSaveFailed(Object error) {
    return '無法儲存標籤：$error';
  }

  @override
  String get songPageStorageManageAllFilesHint =>
      '修改或刪除外部儲存中的音訊需要「所有檔案存取」權限，請在系統設定中為本應用程式開啟後重試。';

  @override
  String get audioQualityTierLq => '流暢';

  @override
  String get audioQualityTierStd => '標準';

  @override
  String get audioQualityTierHq => '高品質';

  @override
  String get audioQualityTierSq => '無損（CD 級）';

  @override
  String get audioQualityTierHr => '高解析';

  @override
  String get audioQualityTierDsd => '頂級發燒';

  @override
  String get songPageMoreEditLyricsExternal => '使用 SyncedLyricEditor 編輯…';

  @override
  String get songPageSyncedLyricEditorNotInstalled =>
      '未安裝 SyncedLyric Editor，無法跳轉編輯。';

  @override
  String get songPageSyncedLyricEditorLaunchFailed =>
      '無法開啟 SyncedLyric Editor。';

  @override
  String get songPageMusicTagEditorUnsupportedPlatform =>
      '外部標籤編輯僅在 Android 上可用。';

  @override
  String get songPageMusicTagEditorFileNotFound => '找不到音訊檔案。';

  @override
  String get songPageMusicTagEditorNotInstalled =>
      '未安裝 Music Tag Editor，無法跳轉編輯。';

  @override
  String get songPageMusicTagEditorCannotSharePath => '無法從目前路徑向其它應用程式開啟該檔案。';

  @override
  String get songPageMusicTagEditorLaunchFailed => '無法開啟 Music Tag Editor。';

  @override
  String get songPageMetadataDialogTitle => '音訊元資訊';

  @override
  String get songPageMetadataReadFailed => '無法讀取該檔案的元資訊。';

  @override
  String get songPageShareFileNotFound => '磁碟上找不到該檔案。';

  @override
  String get songPageDeleteDiskWarningTitle => '從磁碟刪除？';

  @override
  String get songPageDeleteDiskWarningBody =>
      '將從裝置儲存空間永久刪除此音訊檔案，且無法復原；並從歌單與播放紀錄中移除。';

  @override
  String get songPageDeleteContinue => '繼續刪除';

  @override
  String get songPageDeleteFinalConfirmTitle => '確認刪除';

  @override
  String songPageDeleteFinalConfirmBody(Object fileName) {
    return '確定刪除「$fileName」嗎？';
  }

  @override
  String get songPageMetaFieldTitle => '標題';

  @override
  String get songPageMetaFieldArtist => '演出者';

  @override
  String get songPageMetaFieldAlbum => '專輯';

  @override
  String get songPageMetaFieldDuration => '時長';

  @override
  String get songPageMetaFieldBitrate => '位元率';

  @override
  String get songPageMetaFieldSampleRate => '取樣率';

  @override
  String get songPageMetaFieldYear => '年份';

  @override
  String get songPageMetaFieldTrack => '曲目';

  @override
  String get songPageMetaFieldDisc => '片號';

  @override
  String get songPageMetaFieldPath => '路徑';

  @override
  String get songPageMetaFieldSize => '檔案大小';

  @override
  String get songPageMetaFieldGenre => '流派';

  @override
  String get songPageMetaFieldPerformers => '其它藝人';

  @override
  String get songPageMetaFieldLanguage => '語言';

  @override
  String get songPageMetaFieldEmbeddedLyrics => '嵌入式歌詞';

  @override
  String get songPageMetaFieldFormat => '格式';

  @override
  String get songPageMetaSectionTags => '標籤資訊';

  @override
  String get songPageMetaSectionAudio => '音訊參數';

  @override
  String get songPageMetaSectionFile => '檔案';

  @override
  String get tooltipFolderInfo => '目錄資訊';

  @override
  String get tooltipReloadSongs => '重新載入歌曲';

  @override
  String get tooltipEdit => '編輯';

  @override
  String get tooltipRemoveFolder => '移除目錄';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionSave => '儲存';

  @override
  String get actionCreate => '建立';

  @override
  String get actionConfirm => '確認';

  @override
  String get actionGotIt => '我知道了';

  @override
  String get actionOK => '確定';

  @override
  String get settingsRowHelpTooltip => '說明';

  @override
  String get fieldName => '名稱';

  @override
  String get fieldNewNameHint => '新名稱';

  @override
  String get folderAppBarTitle => '資料夾';

  @override
  String folderSongsCount(int n) {
    return '$n 首';
  }

  @override
  String get folderInfoAlias => '資料夾別名：';

  @override
  String get folderInfoPath => '資料夾路徑：';

  @override
  String get folderInfoSongCount => '歌曲數量：';

  @override
  String get folderInfoAdded => '加入時間：';

  @override
  String get folderAddLoadingTitle => '正在載入歌曲';

  @override
  String get folderReloading => '正在重新載入';

  @override
  String get folderScanningWait => '正在掃描資料夾，請稍候…';

  @override
  String folderLoadOk(int n) {
    return '成功載入 $n 首歌曲';
  }

  @override
  String folderLoadFailed(String error) {
    return '載入失敗：$error';
  }

  @override
  String get folderRemoveTitle => '確認移除？';

  @override
  String folderRemoveMessage(String name) {
    return '是否移除目錄：$name（僅移除參考，不刪磁碟上音樂檔）';
  }

  @override
  String get folderDuplicateDialogTitle => '提示';

  @override
  String folderDuplicateMessage(String path) {
    return '此資料夾已存在：$path';
  }

  @override
  String folderAddOk(int n) {
    return '成功新增 $n 首歌曲';
  }

  @override
  String get folderAddErrorTitle => '錯誤';

  @override
  String folderAddErrorMessage(String error) {
    return '載入資料夾失敗：$error';
  }

  @override
  String get folderAddNoSelection => '未選擇資料夾（已取消或關閉選擇框）。';

  @override
  String get folderRenameDialogTitle => '重新命名資料夾';

  @override
  String get playlistPageTitle => '歌單';

  @override
  String get playlistNotFound => '找不到歌單';

  @override
  String get playlistNotFoundMessage => '此歌單可能已被刪除';

  @override
  String get playlistEmptyNoSongs => '暫無可播放歌曲\n（請先於「音樂來源」掃描，或歌曲路徑已失效）';

  @override
  String get playlistDeleteTitle => '刪除歌單';

  @override
  String get playlistDeleteMessage => '確定刪除此歌單？清單內的參考會遺失，不會刪除磁碟上的音樂檔。';

  @override
  String get playlistDeleteBatchTitle => '大量刪除歌單';

  @override
  String playlistDeleteBatchMessage(int n) {
    return '確定刪除已選的 $n 個歌單？清單內的參考會遺失，不會刪除磁碟上的音樂檔。';
  }

  @override
  String get playlistDeletedOne => '已刪除歌單';

  @override
  String get importDialogBody =>
      '歌曲以「完整檔案路徑」區分：同名、同演出者、不同檔案或不同音質會對應不同路徑，匯入後不會誤合併。\n\n• 合併匯入：與本機「歌單 id」相同的項目會合併曲目清單（路徑去重）；備份中有而本機沒有的歌單會新增。\n• 全部取代：先清空本機全部歌單，再依備份還原（請謹慎操作）。';

  @override
  String playlistCreatedOn(String date) {
    return '建立於 $date';
  }

  @override
  String get recentPlaysEmptyTitle => '還沒有播放記錄';

  @override
  String get quickEntryReorderHint => '拖曳控點可調整順序。關閉「在首頁顯示」後，該入口會在首頁隱藏。';

  @override
  String get quickEntryShowOnHome => '在首頁顯示';

  @override
  String get playlistSearchHint => '搜尋歌曲、演出者或檔名…';

  @override
  String get searchNoMatchingSongs => '找不到符合的歌曲';

  @override
  String get playlistRenameTitle => '重新命名歌單';

  @override
  String get playlistCoverStyleTitle => '歌單封面顏色';

  @override
  String get playlistCoverStyleSubtitle =>
      '套用於首頁橫滑卡片與音樂來源歌單列表左側預覽；選擇輪換預設則依列表順序自動配色；漸層可使用自選雙色以增強對比。';

  @override
  String get playlistCoverUseDefaultPalette => '使用輪換預設配色';

  @override
  String get playlistCoverSolidSection => '單色';

  @override
  String get playlistCoverGradientSection => '漸層';

  @override
  String get playlistCoverCustomGradientTitle => '自訂漸層';

  @override
  String get playlistCoverGradientStartColor => '起始色';

  @override
  String get playlistCoverGradientEndColor => '結束色';

  @override
  String get playlistCoverGradientSwapColors => '交換兩端顏色';

  @override
  String get playlistCoverGradientDirectionTitle => '漸層方向';

  @override
  String get playlistCoverGradientDirHorizontalLR => '左→右';

  @override
  String get playlistCoverGradientDirHorizontalRL => '右→左';

  @override
  String get playlistCoverGradientDirVerticalTB => '上→下';

  @override
  String get playlistCoverGradientDirVerticalBT => '下→上';

  @override
  String get playlistCoverGradientDirDiagonalTLBR => '對角 ↘（左上→右下）';

  @override
  String get playlistCoverGradientDirDiagonalTRBL => '對角 ↙（右上→左下）';

  @override
  String get playlistCoverGradientDirDiagonalBRTL => '對角 ↖（右下→左上）';

  @override
  String get playlistCoverGradientDirDiagonalBLTR => '對角 ↗（左下→右上）';

  @override
  String get playlistCoverRgbTitle => '自訂 RGB';

  @override
  String get playlistCoverRgbRed => '紅';

  @override
  String get playlistCoverRgbGreen => '綠';

  @override
  String get playlistCoverRgbBlue => '藍';

  @override
  String get playlistCoverRgbPreview => '預覽';

  @override
  String get playlistCoverPreviewLabel => '目前效果';

  @override
  String get playlistCoverMenuItem => '封面顏色…';

  @override
  String get playlistCoverPictureSection => '圖片';

  @override
  String get playlistCoverPickImage => '選擇圖片…';

  @override
  String get playlistCoverRemoveImage => '移除圖片';

  @override
  String get imageCropTitle => '裁剪圖片';

  @override
  String get imageCropFailure => '無法裁剪該圖片。';

  @override
  String get exportCannot => '無法匯出此歌單';

  @override
  String exportSaved(String path) {
    return '已匯出：$path';
  }

  @override
  String get exportCancelled => '已取消匯出';

  @override
  String exportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get exportDialogTitle => '匯出歌單';

  @override
  String get menuRename => '重新命名';

  @override
  String get menuExportThis => '匯出本歌單…';

  @override
  String get menuDeletePlaylist => '刪除歌單';

  @override
  String get exportSelectFirst => '請先選擇要匯出的歌單';

  @override
  String get exportNoneToExport => '沒有可匯出的歌單，請檢查所選內容';

  @override
  String get exportAllPlaylists => '匯出全部歌單';

  @override
  String get exportSelectedPlaylists => '匯出所選歌單';

  @override
  String get exportSelected => '匯出所選';

  @override
  String get exportAll => '匯出全部';

  @override
  String get importCannotRead => '無法讀取檔案（可嘗試較小備份或檢查權限）';

  @override
  String importParseError(String message) {
    return '無法解析：$message';
  }

  @override
  String get importMerge => '合併匯入';

  @override
  String get importReplaceAll => '全部取代';

  @override
  String get importMerged => '已合併匯入';

  @override
  String get importReplaced => '已取代匯入';

  @override
  String importFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String playlistsDeletedN(int n) {
    return '已刪除 $n 個歌單';
  }

  @override
  String librarySongsDeletedN(int n) {
    return '已刪除 $n 首歌曲';
  }

  @override
  String get fabNewPlaylist => '新增歌單';

  @override
  String get emptyPlaylistsHint =>
      '尚無歌單\n在播放頁面或歌曲清單可將歌曲加入歌單\n\n可於右上角「⋮」匯入、單選／多選';

  @override
  String get sortByName => '依名稱';

  @override
  String get sortByPath => '依路徑';

  @override
  String get sortByCreated => '依建立時間';

  @override
  String get sortByUpdated => '依更新時間';

  @override
  String get sortByAddedToPlaylist => '依加入歌單時間';

  @override
  String get sortByAddedToPlaylistSub => '正序：先加入在前 · 反序：後加入在前';

  @override
  String get lyricAlignLeft => '左';

  @override
  String get lyricAlignCenter => '中';

  @override
  String get lyricAlignRight => '右';

  @override
  String get addToPlaylistHint => '新歌單名稱';

  @override
  String addToPlaylistUpdatedN(int n) {
    return '已更新歌單（$n 個）';
  }

  @override
  String get noLyrics => '暫無歌詞';

  @override
  String get songNotFound => '歌曲不存在';

  @override
  String get pageUnknownTitle => '未知標題';

  @override
  String get queueNoTracks => '暫無曲目';

  @override
  String get playQueueTitle => '播放佇列';

  @override
  String get queuePendingPlayAfterCurrentSection => '下一曲播放（待播）';

  @override
  String get playbackModeTitle => '播放模式';

  @override
  String get playbackSequential => '循序播放';

  @override
  String get playbackShuffle => '隨機播放';

  @override
  String get playbackSingleLoop => '單曲循環';

  @override
  String get playbackOnce => '僅播放一次';

  @override
  String get playbackTimer => '定時關閉';

  @override
  String get sleepTimerSheetTitle => '定時關閉';

  @override
  String get sleepTimerCancel => '取消定時關閉';

  @override
  String sleepTimerMinutesN(int n) {
    return '$n 分鐘';
  }

  @override
  String get sleepTimerCustom => '自訂時間';

  @override
  String sleepTimerCurrentN(int n) {
    return '目前 $n 分鐘';
  }

  @override
  String get sleepTimerLabelMinutes => '分鐘';

  @override
  String sleepTimerInvalidRange(int min, int max) {
    return '請輸入 $min–$max 之間的整數';
  }

  @override
  String sleepTimerPlayedMinutes(int minutes) {
    return '定時關閉：已播放 $minutes 分鐘';
  }

  @override
  String get songPageKeepScreenAwake => '播放頁螢幕恆亮';

  @override
  String get lyricStyleKeepScreenAwakeSub => '在播放頁查看歌詞時不自動鎖屏';

  @override
  String get lyricModeEmptyHint => '切換顯示模式';

  @override
  String get lyricModeAllLines => '多行歌詞：全部行（點一下改單行）';

  @override
  String lyricModeSingleLineN(int n) {
    return '多行歌詞：僅第 $n 行（再點可切換）';
  }

  @override
  String get sortOptionsTitle => '排序方式';

  @override
  String addToPlaylistTitle(String name) {
    return '加入歌單 · $name';
  }

  @override
  String get addToPlaylistMultiHelp => '可複選；取消勾選將從對應歌單移除此曲';

  @override
  String get addToPlaylistNoPlaylistsYet => '尚無歌單，請先輸入名稱並建立';

  @override
  String get quickEntrySettingsTitle => '捷徑';

  @override
  String get playlistSelectModeSingle => '單選';

  @override
  String get playlistSelectModeMulti => '多選';

  @override
  String get menuImportPlaylists => '匯入歌單';

  @override
  String get selectAll => '全選';

  @override
  String get deselectAll => '取消全選';

  @override
  String playlistSelectCount(int n, int m) {
    return '已選 $n / $m';
  }

  @override
  String get lyricStyleSyncSubtitle => '與目前播放頁歌詞同步';

  @override
  String get lyricStyleSectionDisplay => '顯示';

  @override
  String get lyricStyleSectionDisplaySub => '原文與多行譯文的開關';

  @override
  String get lyricStyleShowOriginal => '顯示原文';

  @override
  String get lyricStyleShowOriginalSub => '每個時間戳第 1 行';

  @override
  String get lyricStyleShowTranslation => '顯示翻譯/附加行';

  @override
  String get lyricStyleShowTranslationSub => '第 2 行以後';

  @override
  String get lyricStyleSectionTypography => '字級與行距';

  @override
  String get lyricStyleSectionTypographySub => '以滑桿調整後立即生效';

  @override
  String get lyricStyleFontOriginal => '原文字級';

  @override
  String get lyricStyleFontTranslation => '翻譯字級';

  @override
  String get lyricStyleLineSpacing => '行距';

  @override
  String get lyricStyleSectionLineAlign => '行對齊';

  @override
  String get lyricStyleSectionStateColors => '行狀態顏色';

  @override
  String get lyricStyleSectionStateColorsSub => '正在播放、已播過、未播到';

  @override
  String get lyricStyleStateNowPlaying => '正在播放行';

  @override
  String get lyricStyleStatePlayed => '已播過的行';

  @override
  String get lyricStyleStateUpcoming => '未播到的行';

  @override
  String get lyricStyleColorNowOriginal => '正在播放 — 原文';

  @override
  String get lyricStyleColorNowTranslation => '正在播放 — 譯文';

  @override
  String get lyricStyleColorPlayedOriginal => '已播過 — 原文';

  @override
  String get lyricStyleColorPlayedTranslation => '已播過 — 譯文';

  @override
  String get lyricStyleColorUpcomingOriginal => '未播到 — 原文';

  @override
  String get lyricStyleColorUpcomingTranslation => '未播到 — 譯文';

  @override
  String get lyricStyleColorPersistNote => '顏色會寫入本機設定，換歌後仍保留。';

  @override
  String get lyricStyleActiveGradientTitle => '正在播放行漸層';

  @override
  String get lyricStyleStateGradientSub => '開啟後，此雙色漸層優先於上方原文/譯文純色；關閉則僅用純色。';

  @override
  String get lyricStyleActiveGradientTune => '編輯漸層';

  @override
  String get lyricStyleActiveGradientDialogTitle => '正在播放行漸層';

  @override
  String get lyricStylePlayedGradientTitle => '已播過行漸層';

  @override
  String get lyricStyleUpcomingGradientTitle => '未播到行漸層';

  @override
  String get lyricStylePlayedGradientDialogTitle => '已播過行漸層';

  @override
  String get lyricStyleUpcomingGradientDialogTitle => '未播到行漸層';

  @override
  String get lyricColorPickerHint => '點選色塊';

  @override
  String get lyricLabelOriginal => '原文';

  @override
  String get lyricLabelTranslation => '譯文';

  @override
  String get libraryBatchSelect => '多選';

  @override
  String get libraryBatchDone => '完成';

  @override
  String get libraryBatchSelectAll => '全選';

  @override
  String get libraryBatchDelete => '刪除';

  @override
  String get libraryBatchRename => '重新命名';

  @override
  String get libraryBatchUploadOneDrive => '上傳到 OneDrive';

  @override
  String get libraryBatchDeleteConfirmTitle => '刪除所選歌曲？';

  @override
  String get libraryBatchDeleteConfirmMessage => '將從本機刪除檔案，並更新歌單與最近播放。此操作無法復原。';

  @override
  String get libraryBatchNoneSelected => '請先選擇歌曲';

  @override
  String get libraryBatchRenameTitle => '批次重新命名';

  @override
  String get libraryBatchRenameHint => '名稱範本，用 %n 表示遞增序號（如 曲目 %n）';

  @override
  String get libraryBatchRenameStart => '起始編號';

  @override
  String get libraryRenameSingleTitle => '重新命名單曲';

  @override
  String get libraryRenameSingleHint => '只填主檔名，副檔名不變。';

  @override
  String get libraryRenameSingleFieldLabel => '檔名';

  @override
  String get libraryRenameSingleDone => '已重新命名';

  @override
  String get libraryCloneSong => '複製歌曲';

  @override
  String get libraryCloneSongTitle => '複製為新檔案';

  @override
  String get libraryCloneSongHint => '輸入副本的主檔名（副檔名與原檔相同），儲存在同一資料夾。';

  @override
  String get libraryCloneSongDefaultSuffix => ' 副本';

  @override
  String get libraryCloneSongDone => '已複製';

  @override
  String get libraryCloneSongFailed => '複製失敗';

  @override
  String get libraryCloneSongProgressTitle => '正在複製歌曲';

  @override
  String get libraryCloneSongProgressMessage => '正在複製檔案並重新整理曲庫…';

  @override
  String get libraryBatchUploadNeedSignIn => '請先在設定中登入 OneDrive';

  @override
  String get libraryBatchUploadNeedCloudFolder => '請先在 OneDrive 設定中選擇雲端應用程式資料夾';

  @override
  String get libraryBatchUploadNeedParentFolder =>
      '請先在 OneDrive 設定中選擇「上傳音樂」資料夾或雲端應用程式資料夾。';

  @override
  String get libraryBatchUploadQueued => '已加入傳輸佇列';

  @override
  String get libraryBatchOpenQueue => '查看佇列';

  @override
  String get libraryBatchAddToPlaylist => '新增至播放清單';

  @override
  String libraryBatchAddToPlaylistSheetTitle(int count) {
    return '將 $count 首歌新增至使用者播放清單';
  }

  @override
  String get libraryBatchAddToPlaylistSheetHelp =>
      '已勾選的播放清單為「目前所選曲目均已於其中」的清單；確定後為所選每一首歌同步勾選狀態。';

  @override
  String get libraryBatchAddToPlaylistDone => '播放清單歸屬已更新';

  @override
  String get libraryReloadMetadata => '重新載入中繼資料';

  @override
  String get libraryReloadMetadataDone => '已從檔案重新載入中繼資料';

  @override
  String get oneDriveUploadStatusUploading => '上傳中';

  @override
  String get oneDriveTaskDirectionUpload => '上傳';

  @override
  String get homeEntrySongRecognizer => '聽歌識曲';

  @override
  String get songRecognizerTitle => '聽歌識曲';

  @override
  String get songRecognizerModeInApp => '應用程式內';

  @override
  String get songRecognizerModeAmbient => '環境聆聽';

  @override
  String get songRecognizerModeInAppHelp =>
      '請留在本頁，將手機靠近正在播放的音樂，約錄製 10 秒以提高辨識率。';

  @override
  String get songRecognizerModeAmbientHelp =>
      '在本頁開啟後，約每 20 秒自動取樣辨識。請將手機靠近揚聲器或其他 App 播放的聲音；離開應用程式後部分裝置可能中斷麥克風。';

  @override
  String get songRecognizerStart => '開始辨識';

  @override
  String get songRecognizerSnackbarStarted => '開始辨識…';

  @override
  String get songRecognizerSnackbarCancelled => '已取消辨識';

  @override
  String get songRecognizerStopAmbient => '停止環境聆聽';

  @override
  String get songRecognizerListening => '聆聽中…';

  @override
  String get songRecognizerRecognizing => '辨識中…';

  @override
  String get songRecognizerHistory => '辨識紀錄';

  @override
  String get songRecognizerHistoryEmpty => '尚無紀錄';

  @override
  String get songRecognizerHistoryFilterAll => '全部';

  @override
  String get songRecognizerHistoryFilterMatched => '成功匹配';

  @override
  String get songRecognizerHistoryFilterArchived => '收藏';

  @override
  String get songRecognizerHistoryEmptyMatched => '暫無成功匹配的紀錄';

  @override
  String get songRecognizerHistoryEmptyArchived => '暫無收藏紀錄';

  @override
  String get songRecognizerDeleteHistoryEntryTitle => '刪除紀錄';

  @override
  String get songRecognizerDeleteHistoryEntryMessage => '確定刪除這筆辨識紀錄？';

  @override
  String get songRecognizerSwipeArchive => '收藏';

  @override
  String get songRecognizerSwipeRestore => '取消收藏';

  @override
  String get songRecognizerSwipeDelete => '刪除';

  @override
  String get songRecognizerEntryArchived => '已收藏';

  @override
  String get songRecognizerEntryRestoredFromArchive => '已取消收藏';

  @override
  String get songRecognizerCopyEntry => '複製';

  @override
  String get songRecognizerEntryCopied => '已複製到剪貼簿';

  @override
  String get songRecognizerCopyLabelTime => '時間：';

  @override
  String get songRecognizerCopyLabelMode => '取樣方式：';

  @override
  String get songRecognizerCopyLabelService => '辨識服務：';

  @override
  String get songRecognizerCopyLabelSong => '歌曲：';

  @override
  String get songRecognizerCopyLabelArtist => '歌手：';

  @override
  String get songRecognizerCopyLabelAlbum => '專輯：';

  @override
  String get songRecognizerCopyLabelReleased => '發行日期：';

  @override
  String get songRecognizerCopyLabelAppleMusic => 'Apple Music：';

  @override
  String get songRecognizerCopyLabelSpotify => 'Spotify：';

  @override
  String get songRecognizerCopyLabelNoMatch => '結果：';

  @override
  String get songRecognizerCopyLabelError => '錯誤：';

  @override
  String get songRecognizerClearHistory => '清空紀錄';

  @override
  String get songRecognizerClearHistoryConfirm => '確定刪除全部辨識紀錄？';

  @override
  String get songRecognizerNoMatch => '沒有相符歌曲，請在較安靜環境重試或靠近音源。';

  @override
  String get songRecognizerOpenAppleMusic => 'Apple Music';

  @override
  String get songRecognizerOpenSpotify => 'Spotify';

  @override
  String get songRecognizerApiKey => 'AudD API Token';

  @override
  String get songRecognizerApiKeyHelp =>
      '建議至 audd.io 建立 Token 並貼上；留空則使用公開試用 Token（額度極低）。';

  @override
  String get songRecognizerSave => '儲存';

  @override
  String get songRecognizerMicDenied => '需要麥克風權限';

  @override
  String get songRecognizerWebUnsupported => '此瀏覽器版本不支援聽歌識曲。';

  @override
  String get songRecognizerAccuracyTip => '建議：安靜環境、取樣約 10–12 秒、手機靠近喇叭，辨識較準。';

  @override
  String get songRecognizerDuplicateSkipped => '與最近一筆相同，未重複寫入';

  @override
  String get songRecognizerError => '辨識失敗';

  @override
  String get songRecognizerAmbientActive => '環境聆聽進行中';

  @override
  String get songRecognizerTokenMenu => 'API Token';

  @override
  String get songRecognizerCredentialsMenu => '帳號與金鑰';

  @override
  String get songRecognizerProviderLabel => '辨識服務';

  @override
  String get songRecognizerProviderAudd => 'AudD';

  @override
  String get songRecognizerProviderAcrcloud => 'ACRCloud';

  @override
  String get songRecognizerModeLabel => '取樣方式';

  @override
  String get songRecognizerAcrTitle => 'ACRCloud 專案';

  @override
  String get songRecognizerAcrHelp =>
      '請填寫控制台中的 Host（例如 identify-eu-west-1.acrcloud.com，勿含 https:// 或路徑）、Access Key 與 Access Secret（音訊／視訊辨識專案）。';

  @override
  String get songRecognizerAcrHost => '主機 Host';

  @override
  String get songRecognizerAcrHostHint => 'identify-….acrcloud.com';

  @override
  String get songRecognizerAcrAccessKey => 'Access Key';

  @override
  String get songRecognizerAcrSecret => 'Secret Key';

  @override
  String get songRecognizerAcrIncomplete =>
      '請在本頁填寫並儲存 ACRCloud 的 Host、Access Key 與 Secret Key 後再辨識。';

  @override
  String get songRecognizerSectionApiConfig => '介面設定';

  @override
  String get songRecognizerConfigHint => '在識曲首頁選擇使用哪一家；在此頁分別填寫並儲存兩套金鑰（僅存在本機）。';

  @override
  String get songRecognizerConfigSaved => '已儲存';

  @override
  String get songRecognizerAuddCardSubtitle =>
      '來自 audd.io 控制台的 Token；留空則使用額度極低的公開試用。';

  @override
  String get songRecognizerAcrCardTitle => 'ACRCloud';

  @override
  String get songRecognizerAcrCardSubtitle =>
      '控制台中的 Host、Access Key、Secret Key（音視頻辨識專案）。';

  @override
  String get songRecognizerOpenApiConfigSubtitle =>
      'AudD Token 與 ACRCloud 的 Host、Access Key、Secret Key';

  @override
  String get songRecognizerMatchConfirmTitle => '辨識結果';

  @override
  String get songRecognizerMatchConfirmArtistLabel => '藝人';

  @override
  String get songRecognizerMatchConfirmAlbumLabel => '專輯';

  @override
  String get songRecognizerMatchConfirmReleaseLabel => '發行日期';

  @override
  String get songRecognizerMatchConfirmYes => '是這首歌';

  @override
  String get songRecognizerMatchConfirmNo => '不是這首，繼續辨識';
}
