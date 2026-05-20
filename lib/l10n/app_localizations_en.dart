// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yeah Music';

  @override
  String get menuHome => 'Home';

  @override
  String get menuSongList => 'Songs';

  @override
  String get menuArtists => 'Artists';

  @override
  String get artistsUnknownArtist => 'Unknown artist';

  @override
  String get artistsSearchHint => 'Search artists';

  @override
  String get albumsSearchHint => 'Search albums';

  @override
  String get menuAlbums => 'Albums';

  @override
  String get albumsUnknownAlbum => 'Unknown album';

  @override
  String get menuPlaylists => 'Playlists';

  @override
  String get menuMusicSource => 'Media folders';

  @override
  String get songPageTheaterNowPlaying => 'Now playing';

  @override
  String get songPageTheaterUpNext => 'Up next';

  @override
  String get menuStatistics => 'Statistics';

  @override
  String get menuSettings => 'Settings';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statisticsSubtitle =>
      'Overview of your library, listening activity, and playlists';

  @override
  String get statisticsReloadTooltip => 'Refresh';

  @override
  String get statisticsReloadStarted => 'Refreshing playback statistics…';

  @override
  String get statisticsReloadDone => 'Playback statistics updated.';

  @override
  String get statisticsReloadFailed => 'Couldn\'t refresh playback statistics.';

  @override
  String get statisticsSectionLibrary => 'Library';

  @override
  String get statisticsSectionPlayback => 'Playback';

  @override
  String get statisticsSectionPlaylists => 'Playlists';

  @override
  String get statisticsSectionOneDrive => 'OneDrive';

  @override
  String get statisticsTracksLabel => 'Tracks';

  @override
  String get statisticsFoldersLabel => 'Media folders';

  @override
  String get statisticsDurationLabel => 'Estimated duration';

  @override
  String get statisticsDurationHint =>
      'Sum of durations where metadata is available';

  @override
  String get statisticsFormatsLabel => 'Formats';

  @override
  String get statisticsFormatsOther => 'Other';

  @override
  String statisticsFormatsMore(int count) {
    return '$count more types';
  }

  @override
  String get statisticsQualityLabel => 'Audio quality';

  @override
  String get statisticsQualityHint =>
      'Same tiers as library badges: format, bitrate, and sample rate when tags allow classification.';

  @override
  String get statisticsQualityUnknown => 'Unknown';

  @override
  String get statisticsHistoricalListeningLabel => 'Listening time';

  @override
  String get statisticsHistoricalListeningHint =>
      'Wall-clock time while playback is active (paused time excluded). Total does not scale with playback speed. Stored from this version onward; force-quitting may lose a few seconds not yet flushed (~8s batches).';

  @override
  String get statisticsPlaybackTotalLabel => 'Total listens';

  @override
  String get statisticsPlaybackTotalSubtitle =>
      'Stored play starts—each time playback begins counts once.';

  @override
  String get statisticsPlaybackDistinctLabel => 'Tracks with play history';

  @override
  String get statisticsRecentEntriesLabel => 'Recent plays entries';

  @override
  String statisticsRecentEntriesSubtitle(int max) {
    return 'Up to $max paths kept locally';
  }

  @override
  String get statisticsPlaylistsCountLabel => 'Your playlists';

  @override
  String get statisticsPlaylistRefsLabel => 'Playlist entries';

  @override
  String get statisticsPlaylistRefsSubtitle =>
      'Paths across playlists; duplicates count separately';

  @override
  String get statisticsOneDriveIndexedLabel => 'Cloud library tracks';

  @override
  String get statisticsOneDriveCachedLabel => 'Cached / downloaded locally';

  @override
  String get statisticsOneDriveUnavailable => 'Sign in for cloud statistics';

  @override
  String get statisticsNotInitialized => 'Initializing library…';

  @override
  String statisticsDurationHM(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statisticsDurationMOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get statisticsDurationUnknown => 'Could not estimate';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBackgroundTheme => 'Background & theme';

  @override
  String get settingsBackgroundThemeSubtitle =>
      'Solid color, custom color, or wallpaper';

  @override
  String get settingsBackgroundThemeDesc =>
      'Choose a solid color, pick a custom accent, or set a full-screen background image. Options are adjusted on the next screen.';

  @override
  String get settingsSystemInfo => 'System information';

  @override
  String get settingsSystemInfoSubtitle => 'Device and storage space';

  @override
  String get settingsSystemInfoDesc =>
      'View device-related details and how much disk space is available. Expanded section shows a per-folder breakdown.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle => 'Version, credits, licenses';

  @override
  String get settingsAboutDesc =>
      'App name and version, acknowledgements, and open-source license texts.';

  @override
  String get settingsHomeGreetingTitle => 'Home greeting';

  @override
  String get settingsHomeGreetingListSubtitle =>
      'Custom lines rotate with the built-in default';

  @override
  String get settingsHomeGreetingHelp =>
      'The greeting card always includes one built-in localized line. Each row below is an optional extra line; together they rotate with that default. Choose sequential order or random rotation below.';

  @override
  String get settingsHomeGreetingLineHint => 'Greeting text';

  @override
  String get settingsHomeGreetingRotationTitle => 'Rotation';

  @override
  String get settingsHomeGreetingRotationSequential => 'Sequential';

  @override
  String get settingsHomeGreetingRotationRandom => 'Random';

  @override
  String get settingsHomeGreetingEmptyHint =>
      'No custom lines yet. Tap below to add.';

  @override
  String get settingsHomeGreetingAddLine => 'Add a line';

  @override
  String get settingsHomeGreetingSave => 'Save';

  @override
  String get settingsHomeGreetingSaved => 'Saved';

  @override
  String get settingsAudioQualityTitle => 'Audio quality';

  @override
  String get settingsAudioQualityListSubtitle =>
      'How library badges are classified (low to high)';

  @override
  String get settingsAudioQualityHelp =>
      'When bitrate and sample rate are available in file tags, Yeah Music assigns one of the tiers below for display in your library and recent plays.';

  @override
  String get settingsAboutDialogAuthor => 'Author';

  @override
  String get settingsAboutDialogRepo => 'Repository';

  @override
  String get settingsAboutDialogLicense => 'License';

  @override
  String get settingsAboutDialogPrivacy => 'Privacy';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicyBody =>
      '**This Privacy Policy applies to Yeah Music.**\n**Last updated: May 11, 2026**\n**Effective date: May 11, 2026**\n\nYeah Music is an open-source, free, local-first music player. Yeah Music does not provide a developer-operated account system, does not run advertising services, does not integrate third-party analytics SDKs for advertising profiles or user behavior tracking, and does not sell your personal information.\n\n**1. Local music and media library**\nAfter you grant system permissions or choose music folders, Yeah Music reads local audio files, file names, file paths, audio tags, artwork, lyrics, playlists, and playback history to show your library, play music, edit tags, count plays, restore playback position, and build playlists. By default, this data stays on your device and is not uploaded to a developer-operated server by Yeah Music.\n\n**2. OneDrive features**\nWhen you enable OneDrive sign-in, cloud library, sync, upload, or download, Yeah Music communicates with Microsoft OneDrive. Access tokens are stored in secure device storage. Library indexes, sync slices, uploaded files, and downloaded files are exchanged with OneDrive only according to your actions. Microsoft services are governed by Microsoft\'s own terms and privacy policy.\n\n**3. Music recognition**\nWhen you use music recognition, Yeah Music records a short audio sample and sends it to the recognition provider you choose or configure, such as AudD or ACRCloud. Recognition results may include song title, artist, album, and related metadata. Do not use this feature in situations where you do not want audio to be processed by a third-party service.\n\n**4. Diagnostic logs**\nDiagnostic logging is off by default. When enabled, Yeah Music stores runtime logs locally. On Android it also records headset/media-button events for troubleshooting. Logs are size-limited and can be viewed, copied, shared, or cleared in Settings. Before sharing logs, please check whether they contain file paths, file names, error details, or other information you do not want to disclose.\n\n**5. Update checks and external links**\nWhen you tap the version in About to check for updates, Yeah Music accesses GitHub Release information. Repository, sponsor, and other external links open in your browser or system handler. External websites and third-party services process data under their own privacy policies.\n\n**6. Permissions**\nYeah Music may request storage/media library, microphone, notification, background media playback, and network permissions. These are used only for their related features, such as playing and managing local music, recording recognition samples, showing media notifications, handling headset or lock-screen controls, accessing OneDrive, and checking for updates. You can revoke permissions in system settings, but related features may stop working.\n\n**7. Data retention and deletion**\nLocal library indexes, playback history, playlists, app settings, OneDrive configuration, and diagnostic logs are stored on your device until you clear them in the app, sign out, disable or clear related features, or uninstall the app. Uninstalling the app usually removes data in the app-private directory, but music files you selected, files downloaded to public folders, and files you exported are not deleted by uninstalling.\n\n**8. Children\'s privacy**\nYeah Music is not directed to children and does not knowingly collect children\'s personal information. Minors should use features involving network access, recording, or cloud services with guardian consent and guidance.\n\n**9. Changes and contact**\nYeah Music may update this policy as features change. Major changes may be communicated through app updates or release notes. If you have questions about privacy or data handling, contact via GitHub Issues at https://github.com/pengweizhong/yeah_music.';

  @override
  String get settingsAboutDialogCopyright => 'Copyright';

  @override
  String get settingsAboutDialogClose => 'Close';

  @override
  String settingsAboutDialogVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutDialogBuildLabel(String buildNumber) {
    return 'Build $buildNumber';
  }

  @override
  String get settingsAboutDialogVersionTapHint => 'Tap to check for updates';

  @override
  String get settingsAboutUpdateChecking => 'Checking for updates…';

  @override
  String get settingsAboutUpdateAlreadyLatest =>
      'You\'re on the latest version';

  @override
  String get settingsAboutUpdateAvailableTitle => 'Update available';

  @override
  String settingsAboutUpdateAvailableBody(String latest, String current) {
    return 'Latest release is v$latest. You\'re on v$current.';
  }

  @override
  String get settingsAboutUpdateOpenReleases => 'Open releases';

  @override
  String get settingsAboutUpdateCheckFailed => 'Couldn\'t check for updates';

  @override
  String get settingsAboutUpdateNoRelease =>
      'No GitHub release found for this repo yet.';

  @override
  String get settingsSponsorTitle => 'Support';

  @override
  String get settingsSponsorSubtitle => 'Free app · Stars & optional tips';

  @override
  String get settingsSponsorSectionFreeTitle => 'Yeah Music is completely free';

  @override
  String get settingsSponsorSectionFreeBody =>
      'Yeah Music is free to use. There is no paid unlock or subscription required for core features. Do not pay third parties claiming to sell this app—unofficial paid listings may be impersonation. Maintenance is done in spare time; anything below is voluntary and does not change features.';

  @override
  String get settingsSponsorSectionStarTitle => 'Star on GitHub';

  @override
  String get settingsSponsorSectionStarHint =>
      'A GitHub Star costs nothing and helps others discover the repositories.';

  @override
  String get settingsSponsorRepoYeahMusicTitle => 'Yeah Music';

  @override
  String get settingsSponsorRepoYeahMusicSubtitle =>
      'Source code for this music player';

  @override
  String get settingsSponsorRepoDynamicSql2Title => 'Dynamic-SQL2';

  @override
  String get settingsSponsorRepoDynamicSql2Subtitle =>
      'Dynamic SQL2 / Java DSL library';

  @override
  String get settingsSponsorEasterEggTriggerLine => 'How to pay / tip';

  @override
  String get settingsSponsorEasterEggDialogTitle => 'Nice try';

  @override
  String get settingsSponsorEasterEggDialogBody =>
      'Want to pay? Fat chance—there\'s nothing to buy. This project runs on enthusiasm.';

  @override
  String get settingsSponsorExternalHint =>
      'Links open outside this app. Only complete transactions on pages you trust. Tipping does not unlock anything.';

  @override
  String get settingsSponsorCopyLink => 'Copy link';

  @override
  String get settingsSponsorLinkCopied => 'Link copied';

  @override
  String get settingsSponsorLaunchFailed => 'Could not open link';

  @override
  String get diagnosticLogTitle => 'Diagnostic log';

  @override
  String get diagnosticLogSubtitle =>
      'View, copy, and share headset control diagnostics';

  @override
  String get diagnosticLogEnableTitle => 'Enable diagnostic logging';

  @override
  String get diagnosticLogEnableSubtitle =>
      'Off by default. When enabled, app logs are saved locally; Android also records headset/media-button events.';

  @override
  String get diagnosticLogDescription =>
      'Diagnostic logging helps troubleshoot playback, platform integration, and headset controls. It is capped on disk and can be cleared here.';

  @override
  String get diagnosticLogEmpty =>
      'No diagnostic log yet. Enable logging, reproduce the issue, then return here and refresh.';

  @override
  String get diagnosticLogRefresh => 'Refresh';

  @override
  String get diagnosticLogCopy => 'Copy';

  @override
  String get diagnosticLogCopied => 'Copied to clipboard';

  @override
  String get diagnosticLogShare => 'Share';

  @override
  String get diagnosticLogClear => 'Clear';

  @override
  String get diagnosticLogCleared => 'Log cleared';

  @override
  String diagnosticLogShareFailed(String error) {
    return 'Could not share log: $error';
  }

  @override
  String get settingsSysinfoSectionDevice => 'Device';

  @override
  String get settingsSysinfoSectionStorage => 'Storage';

  @override
  String get settingsSysinfoPlatformLabel => 'Platform';

  @override
  String get settingsSysinfoTotalSpace => 'Total space';

  @override
  String get settingsSysinfoUsedSpace => 'Used';

  @override
  String get settingsSysinfoFreeSpace => 'Free space';

  @override
  String get settingsSysinfoStorageUnavailable =>
      'Storage details are unavailable.';

  @override
  String get settingsSysinfoDeviceModel => 'Model';

  @override
  String get settingsSysinfoManufacturer => 'Manufacturer';

  @override
  String get settingsSysinfoOsVersion => 'OS version';

  @override
  String get settingsSysinfoSdkVersion => 'SDK version';

  @override
  String get settingsSysinfoDeviceName => 'Device name';

  @override
  String get settingsSysinfoHostName => 'Computer name';

  @override
  String get settingsSysinfoKernelVersion => 'Kernel';

  @override
  String get settingsSysinfoDistroLabel => 'Version';

  @override
  String get settingsSysinfoBuildNumber => 'Build';

  @override
  String get settingsSysinfoError => 'Error';

  @override
  String get settingsSysinfoFetchFailed => 'Could not load device information.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Interface language';

  @override
  String get settingsLanguageDesc =>
      'Choose the language used for menus, settings, and in-app messages. Some content still follows track metadata language.';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle =>
      'Microsoft account sync, folders, downloads';

  @override
  String get settingsOneDriveDesc =>
      'Sign in with Microsoft (no app ID to type in release builds). Pick music and app folders on OneDrive, and optionally a local folder for downloads while playing. If that folder is missing or unset, playback uses the default cache under app data.';

  @override
  String get settingsPlaybackShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get settingsPlaybackShortcutsSubtitle =>
      'Play, pause, previous, and next track';

  @override
  String get settingsPlaybackShortcutsPlayPause => 'Play / pause';

  @override
  String get settingsPlaybackShortcutsPrevious => 'Previous track';

  @override
  String get settingsPlaybackShortcutsNext => 'Next track';

  @override
  String get settingsPlaybackShortcutsChange => 'Change…';

  @override
  String get settingsPlaybackShortcutsDisable => 'Off';

  @override
  String get settingsPlaybackShortcutsEnable => 'On';

  @override
  String get settingsPlaybackShortcutsDisabledLabel => 'Off';

  @override
  String get settingsPlaybackShortcutsPressKey => 'New shortcut';

  @override
  String get settingsPlaybackShortcutsPressKeyHint =>
      'Press the key combination to use. Esc cancels.';

  @override
  String get settingsPlaybackShortcutsUnavailableBody =>
      'Keyboard shortcuts can be customized on Windows, macOS, and Linux desktop builds.';

  @override
  String get settingsWireRemoteTitle => 'Headset controls';

  @override
  String get settingsWireRemoteSubtitle =>
      'Wired multi‑click control and Bluetooth‑independent next/previous track buttons';

  @override
  String get settingsWireRemoteSubtitleOtherPlatforms =>
      'Customization works on the Android app in the foreground.';

  @override
  String get settingsWireRemoteUnavailableTitle => 'Not editable here';

  @override
  String get settingsWireRemoteUnavailableBody =>
      'Headset button mapping applies only on Android when the app is in the foreground (wired multi-press and Bluetooth media keys). On desktop use Keyboard shortcuts; on iOS the system handles headset buttons.';

  @override
  String get settingsWireRemoteUseCustom => 'Custom headset mapping';

  @override
  String get settingsWireRemoteUseCustomSubtitle =>
      'When off, headset buttons use the system default.';

  @override
  String get wireRemoteSingleTitle => 'Single press';

  @override
  String get wireRemoteDoubleTitle => 'Double press';

  @override
  String get wireRemoteTripleTitle => 'Triple press';

  @override
  String get wireRemoteMediaNextTitle => '\"Next\" media key (Bluetooth, etc.)';

  @override
  String get wireRemoteMediaPreviousTitle =>
      '\"Previous\" media key (Bluetooth, etc.)';

  @override
  String get wireRemoteActionPlayPause => 'Play / pause';

  @override
  String get wireRemoteActionNext => 'Next track';

  @override
  String get wireRemoteActionPrevious => 'Previous track';

  @override
  String get wireRemoteActionNone => 'None';

  @override
  String get wireRemotePickActionTitle => 'Choose action';

  @override
  String get settingsMacosMenuBarLyrics => 'Menu bar lyrics';

  @override
  String get settingsMacosMenuBarLyricsSubtitle =>
      'Compact line in the menu bar';

  @override
  String get settingsMacosMenuBarLyricsDesc =>
      'Single line in the macOS menu bar (compact)';

  @override
  String get settingsDesktopLyricsGroupTitle => 'Desktop lyrics';

  @override
  String get settingsDesktopLyricsGroupSubtitle =>
      'Floating line and optional macOS menu bar';

  @override
  String get settingsDesktopLyricsGroupDetail =>
      'Desktop lyrics include a floating, draggable line above other windows and—on macOS—an optional compact line in the menu bar.\n\nFloating lyrics use the same lyric styling (colors, multi-line mode, translations) as the now playing screen. You can lock the window position, tune background opacity, and choose how many timed lines appear before and after the current line.\n\nMenu bar lyrics (macOS only) show a single compact line; enable the toggle when you want lyrics always visible without the floating window.';

  @override
  String get settingsDesktopFloatingLyrics => 'Floating lyrics';

  @override
  String get settingsDesktopFloatingLyricsSubtitle => 'Draggable overlay line';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      'Shows the current lyric line in a small window you can drag over other apps. Styling matches the now playing lyric panel.';

  @override
  String get settingsDesktopFloatingBgOpacity => 'Background opacity';

  @override
  String get settingsDesktopFloatingBgOpacitySubtitle =>
      'How solid the panel behind text is';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      'Panel fill behind lyrics. 0 means fully transparent (text only).';

  @override
  String get settingsDesktopFloatingLinesBefore => 'Lines before current';

  @override
  String get settingsDesktopFloatingLinesBeforeSubtitle =>
      'Timed lines above the active line';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      'How many timed lines to show above the active line.';

  @override
  String get settingsDesktopFloatingLinesAfter => 'Lines after current';

  @override
  String get settingsDesktopFloatingLinesAfterSubtitle =>
      'Timed lines below the active line';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      'How many timed lines to show below the active line.';

  @override
  String get settingsDesktopFloatingDragLock => 'Lock position';

  @override
  String get settingsDesktopFloatingDragLockSubtitle =>
      'Disable dragging the floating window';

  @override
  String get settingsDesktopFloatingDragLockDesc =>
      'When on, the floating window cannot be dragged.';

  @override
  String get settingsCarLyricsGroupTitle => 'Notification & car lyrics';

  @override
  String get settingsCarLyricsGroupSubtitle =>
      'Media notification, Bluetooth & Android Auto';

  @override
  String get settingsCarLyricsGroupDetail =>
      'Uses the Android media session so lock screen, Bluetooth accessories, and Android Auto can show what is playing and offer transport controls.\n\nIf changes don\'t apply immediately, restart Yeah Music.';

  @override
  String get settingsCarLyricsEnabled => 'Enable notification & car lyrics';

  @override
  String get settingsCarLyricsEnabledSubtitle =>
      'Notification, queue, prev/next';

  @override
  String get settingsCarLyricsEnabledDesc =>
      'Show a playback notification with queue, previous/next, play/pause, and repeat (single-loop) aligned with the app.';

  @override
  String get settingsCarLyricsShowCover => 'Show artwork';

  @override
  String get settingsCarLyricsShowCoverSubtitle =>
      'Cover in notification & car display';

  @override
  String get settingsCarLyricsShowCoverDesc =>
      'Use embedded cover art in the notification and on supported head units.';

  @override
  String get settingsCarLyricsSyncLyrics => 'Sync current lyric line';

  @override
  String get settingsCarLyricsSyncLyricsSubtitle =>
      'Notification title shows live lyrics';

  @override
  String get settingsCarLyricsSyncLyricsDesc =>
      'When enabled, the Android notification title updates with the current lyric line as playback advances (same rules as the player). When off, the song title is shown.';

  @override
  String get settingsCarLyricsOnlyAndroidHint =>
      'Only configurable on Android. Switches show saved values and are disabled on this device.';

  @override
  String get settingsCarLyricsApplyRestartHint =>
      'Could not apply immediately. Resume playback or restart the app and try again.';

  @override
  String get menuBarLyricsIdle => 'Yeah Music · Not playing';

  @override
  String get menuBarLyricsNoLyrics => 'No lyrics';

  @override
  String get menuBarContextPlay => 'Play';

  @override
  String get menuBarContextPause => 'Pause';

  @override
  String get menuBarContextPrevious => 'Previous Track';

  @override
  String get menuBarContextNext => 'Next Track';

  @override
  String get oneDriveSettingsTitle => 'OneDrive';

  @override
  String get oneDriveSectionAccount => 'Account';

  @override
  String get oneDriveSectionPaths => 'Folders & storage';

  @override
  String get oneDriveSectionSync => 'Cloud sync';

  @override
  String get oneDriveSyncMasterTitle => 'Sync to OneDrive';

  @override
  String get oneDriveSyncMasterSubtitle =>
      'Choose categories to sync. Each upload creates folder Device model / timestamp under your cloud app folder.';

  @override
  String get oneDriveSyncItemUserPlaylists => 'My playlists';

  @override
  String get oneDriveSyncItemUserPlaylistsSubtitle =>
      'Covers, colors, playlists and song order (saved per device folder).';

  @override
  String get oneDriveSyncItemHomeGreeting => 'Home greeting (first card)';

  @override
  String get oneDriveSyncItemHomeGreetingSubtitle =>
      'Same source as Settings → Home greeting.';

  @override
  String get oneDriveSyncItemQuickEntry => 'Home shortcuts';

  @override
  String get oneDriveSyncItemQuickEntrySubtitle =>
      'Shortcut order and visibility.';

  @override
  String get oneDriveSyncItemPlaybackListsStats =>
      'Recent / top played & playback stats';

  @override
  String get oneDriveSyncItemPlaybackListsStatsSubtitle =>
      'Recent plays list, play counts and listened duration used by Home and Statistics.';

  @override
  String get oneDriveSyncItemLyricsUi => 'Lyrics & playback screen';

  @override
  String get oneDriveSyncItemLyricsUiSubtitle =>
      'Lyric styling plus floating, notification & car lyrics, and keep screen awake.';

  @override
  String get oneDriveSyncItemSongRecognition => 'Song ID & recognition history';

  @override
  String get oneDriveSyncItemSongRecognitionSubtitle =>
      'Service choice (AudD / ACRCloud), API tokens, and recognition log stored on device.';

  @override
  String get oneDriveSyncItemTheme => 'Background theme';

  @override
  String get oneDriveSyncItemThemeSubtitle =>
      'Gradient, preset/custom colors and background image paths.';

  @override
  String get oneDriveSyncFrequencyLabel => 'Sync frequency';

  @override
  String get oneDriveSyncFreqManual => 'Manual only';

  @override
  String get oneDriveSyncFreq1h => 'Every hour';

  @override
  String get oneDriveSyncFreq6h => 'Every 6 hours';

  @override
  String get oneDriveSyncFreq12h => 'Every 12 hours';

  @override
  String get oneDriveSyncFreq24h => 'Every 24 hours';

  @override
  String get oneDriveSyncNow => 'Sync now';

  @override
  String get oneDriveSyncNowDescription =>
      'Upload selected categories now into Device folder / yyyyMMddTHHmmss under your cloud app folder.';

  @override
  String get oneDriveSyncNowNeedLogin => 'Sign in with Microsoft first.';

  @override
  String get oneDriveSyncNowNeedCloudFolder =>
      'Pick a cloud app folder above first, so we know where to put your backup.';

  @override
  String get oneDriveSyncNowFinished =>
      'Backup uploaded under your cloud app folder.';

  @override
  String oneDriveSyncNowFailed(String message) {
    return 'Backup failed: $message';
  }

  @override
  String get oneDriveRestoreFromCloud => 'Restore from cloud';

  @override
  String get oneDriveRestoreSubtitle =>
      'Pick a backup entry (legacy flat files or device sessions). Choose what to restore.';

  @override
  String get oneDriveRestoreSheetTitle => 'Choose a backup';

  @override
  String get oneDriveRestoreGroupThisDevice => 'This device';

  @override
  String get oneDriveRestoreGroupOtherDevices => 'Other devices';

  @override
  String get oneDriveRestoreGroupLegacyFlat => 'Legacy flat backups';

  @override
  String get oneDriveRestoreContentSectionTitle => 'What to restore';

  @override
  String get oneDriveRestoreLoadMore => 'Load more';

  @override
  String oneDriveRestoreListShowing(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get oneDriveRestoreTabUnknownDevice => 'Unknown device';

  @override
  String get oneDriveRestoreEmpty =>
      'No backup files yet. Use “Sync now” to upload first.';

  @override
  String get oneDriveRestorePlaylistCheckbox => 'Playlists';

  @override
  String get oneDriveRestoreLegacySettingsCheckbox =>
      'Legacy combined settings file';

  @override
  String get oneDriveRestoreSliceHomeGreeting => 'Home greeting';

  @override
  String get oneDriveRestoreSliceQuickEntry => 'Home shortcuts';

  @override
  String get oneDriveRestoreSlicePlaybackLists => 'Recent plays & stats Hive';

  @override
  String get oneDriveRestoreSliceLyricsUi => 'Lyrics & screen awake';

  @override
  String get oneDriveRestoreSliceSongRecognition =>
      'Song ID & recognition history';

  @override
  String get oneDriveRestoreSliceTheme => 'Background theme';

  @override
  String get oneDriveRestorePlaylistModeMerge => 'Merge with local playlists';

  @override
  String get oneDriveRestorePlaylistModeReplace =>
      'Replace playlists (clear local first)';

  @override
  String get oneDriveRestoreAction => 'Restore';

  @override
  String get oneDriveRestoreNeedPickContent =>
      'Select at least one item to restore.';

  @override
  String get oneDriveRestoreMissingPlaylistsFile =>
      'No playlists file in this backup.';

  @override
  String get oneDriveRestoreMissingSettingsFile =>
      'No legacy combined settings file in this backup.';

  @override
  String oneDriveBackupSnapshotDeviceSession(
    String deviceName,
    String sessionStamp,
  ) {
    return '$deviceName · $sessionStamp';
  }

  @override
  String get oneDriveSyncNowNeedMasterOn =>
      'Turn on “Sync to OneDrive” above before syncing.';

  @override
  String get oneDriveSyncNowNothingSelected =>
      'Enable at least one sync category above before syncing.';

  @override
  String get oneDriveRestoreFinished => 'Restore completed.';

  @override
  String oneDriveRestoreFailed(String message) {
    return 'Restore failed: $message';
  }

  @override
  String get oneDriveRestoreLoadingList => 'Loading backups…';

  @override
  String get oneDriveSyncNowInProgress => 'Syncing…';

  @override
  String get oneDriveRestoreInProgress => 'Restoring…';

  @override
  String get oneDriveCloudAppDataTitle => 'Cloud app folder';

  @override
  String get oneDriveCloudAppDataSubtitle =>
      'Reserved for settings backup, playlists, and sync.';

  @override
  String get oneDriveCloudAppFolderUnset => 'Not set';

  @override
  String get oneDriveLocalDownloadTitle => 'Local download folder';

  @override
  String get oneDriveLocalDownloadSubtitle =>
      'While playing from OneDrive, files are saved here if this folder exists. If unset or the path is missing, the app uses its default cache under app data.';

  @override
  String get oneDriveLocalDownloadUnset =>
      'Not set — a default will be used later';

  @override
  String get oneDriveChooseCloudFolder => 'Choose in OneDrive';

  @override
  String get oneDriveChooseLocalFolder => 'Choose folder…';

  @override
  String get oneDrivePickFolderForAppData =>
      'Pick a folder for app data and future backups.';

  @override
  String get oneDrivePickFolderForMusicUpload =>
      'Pick the folder where uploads from this device should go.';

  @override
  String get oneDriveMusicUploadFolderTitle => 'Music upload folder';

  @override
  String get oneDriveMusicUploadFolderSubtitle =>
      'Default folder for uploads from this device. If unset, the cloud app folder is used.';

  @override
  String get oneDriveMusicUploadFolderFallback => 'Uses cloud app folder';

  @override
  String get oneDriveAppMissingClientConfig =>
      'This version does not support signing in with a Microsoft account yet, but the feature may be added in the next release.';

  @override
  String get oneDriveNeedSignInForPicker =>
      'Sign in first to pick a OneDrive folder.';

  @override
  String get oneDriveClear => 'Clear';

  @override
  String get oneDriveSignIn => 'Sign in with Microsoft';

  @override
  String get oneDriveSignOut => 'Sign out';

  @override
  String get oneDriveSignOutDone => 'Signed out from OneDrive';

  @override
  String get oneDriveSignedIn => 'Signed in';

  @override
  String get oneDriveNotSignedIn => 'Not signed in';

  @override
  String get oneDriveLinuxUnsupported =>
      'This device does not support OneDrive.';

  @override
  String get oneDriveSignInFailed =>
      'Couldn’t sign in. Check your connection and try again.';

  @override
  String get oneDriveSigningIn => 'Signing in…';

  @override
  String get oneDriveSignInInProgress =>
      'Sign-in already in progress. Please wait.';

  @override
  String get oneDriveSignInCancelled => 'Sign-in was cancelled.';

  @override
  String get oneDriveOAuthPlatformError =>
      'Sign-in failed due to a platform error.';

  @override
  String get oneDriveSignInMissingAccessToken =>
      'Sign-in response did not include an access token.';

  @override
  String get oneDriveSignInMissingRefreshToken =>
      'Sign-in response did not include a refresh token. Check that offline_access is granted.';

  @override
  String oneDriveSignInTokenSaveFailed(String error) {
    return 'Could not save sign-in tokens: $error';
  }

  @override
  String oneDriveSignInDeviceCodeFailed(int statusCode) {
    return 'Could not get a device code ($statusCode).';
  }

  @override
  String oneDriveSignInInterrupted(String reason) {
    return 'Sign-in was interrupted: $reason';
  }

  @override
  String get oneDriveSignInTimedOut => 'Sign-in timed out. Please try again.';

  @override
  String get oneDriveSignInNoValidToken => 'Could not obtain a valid token.';

  @override
  String get oneDriveClientIdNotConfigured =>
      'OneDrive client ID is not configured.';

  @override
  String get oneDriveClientIdDialogTitle => 'OneDrive client ID';

  @override
  String get oneDriveClientIdDialogLabel => 'Azure application (client) ID';

  @override
  String get oneDriveClientIdDialogHint =>
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

  @override
  String oneDriveOAuthErrorWithDetail(String error, String description) {
    return '$error: $description';
  }

  @override
  String get oneDriveCacheNote =>
      'Default storage is the private onedrive_cache folder under app data. A custom folder above is used only when it exists.';

  @override
  String get oneDriveOpenBrowser => 'Open OneDrive';

  @override
  String get homeEntryOneDrive => 'OneDrive';

  @override
  String get oneDriveBrowserTitle => 'OneDrive';

  @override
  String get oneDriveEmptyFolder => 'This folder is empty';

  @override
  String get oneDrivePlayAll => 'Play all in folder';

  @override
  String get oneDrivePreparing => 'Preparing…';

  @override
  String get oneDriveDownloadQueueTitle => 'OneDrive downloads';

  @override
  String get oneDriveTransferQueueTitle => 'OneDrive transfers';

  @override
  String get oneDriveTransferTabDownload => 'Downloads';

  @override
  String get oneDriveTransferTabUpload => 'Uploads';

  @override
  String get oneDriveDownloadPause => 'Pause';

  @override
  String get oneDriveDownloadResume => 'Resume';

  @override
  String get oneDriveDownloadStopAll => 'Stop all';

  @override
  String get oneDriveDownloadContinueAll => 'Continue all';

  @override
  String get oneDriveDownloadAutoPlayWhenDone =>
      'Play automatically when the queue finishes';

  @override
  String get oneDriveDownloadPlayDownloaded => 'Play downloaded songs';

  @override
  String get oneDriveDownloadStatusPending => 'Waiting';

  @override
  String get oneDriveDownloadStatusDownloading => 'Downloading';

  @override
  String get oneDriveDownloadStatusDone => 'Done';

  @override
  String get oneDriveDownloadStatusFailed => 'Failed';

  @override
  String get oneDriveDownloadStatusCancelled => 'Cancelled';

  @override
  String get oneDriveDownloadCloseJustPanel =>
      'Close panel (downloads continue)';

  @override
  String get oneDriveDownloadQueueEmpty =>
      'No batch download yet.\nUse “Play all” in the cloud library or OneDrive browser — you can close this panel and downloads keep running.';

  @override
  String get oneDriveUploadQueueEmpty =>
      'No upload tasks yet.\nUse “Upload to OneDrive” from the local library.';

  @override
  String get oneDriveTransferQueueEmpty => 'No tasks in the queue yet.';

  @override
  String get oneDriveDownloadQueuePageHint =>
      'Pause, resume, or stop downloads here. Closing the sheet does not cancel background downloads.';

  @override
  String get oneDriveUploadQueuePageHint =>
      'Library uploads appear here. Use the same controls to pause, resume, or stop.';

  @override
  String get oneDriveDownloadQueueSubtitle =>
      'Upload & download queue and playback';

  @override
  String get oneDriveDownloadQueueTooltip => 'Download queue';

  @override
  String get oneDriveBrowserRefreshTooltip =>
      'Refresh this folder (clear listing cache and reload from cloud)';

  @override
  String oneDriveEnqueueAddedSingle(String name) {
    return 'Added \"$name\" to the download queue.';
  }

  @override
  String oneDriveEnqueueAddedMany(int count) {
    return 'Added $count tracks to the download queue.';
  }

  @override
  String get oneDriveDownloadViewQueue => 'View queue';

  @override
  String get oneDriveDownloadClearHistory => 'Clear history';

  @override
  String get oneDriveTransferClearDownloadsList => 'Clear download list';

  @override
  String get oneDriveTransferClearUploadsList => 'Clear upload list';

  @override
  String oneDriveError(String message) {
    return 'OneDrive error: $message';
  }

  @override
  String get oneDriveUp => 'Up';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · Cloud library';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      'Folders you add are scanned recursively. Tap a song to fetch on demand (to your chosen download folder if it exists, otherwise the default cache); already-downloaded files play offline.';

  @override
  String get oneDriveCloudLibraryEmpty =>
      'No tracks indexed yet.\nTap “Choose folders”, pick one or more music folders in OneDrive, then “Rescan”.';

  @override
  String get oneDriveCachedPlaylistTitle => 'OneDrive · Cached downloads';

  @override
  String get oneDriveCachedPlaylistEmpty =>
      'No tracks downloaded from OneDrive yet. Play from the cloud library — files are saved to your cache or chosen folder.';

  @override
  String get oneDriveIndexRootsLabel => 'Indexed folders';

  @override
  String get oneDriveRescanIndex => 'Rescan';

  @override
  String get oneDriveBrowseFolders => 'Choose folders';

  @override
  String get oneDrivePickFolderForIndex =>
      'Tap a folder’s + icon, or enter a folder and use “Use this folder”.';

  @override
  String get oneDriveUseCurrentFolder => 'Use this folder';

  @override
  String get oneDrivePickMultipleFoldersHint =>
      'Tap the checkboxes to select folders. Use the arrow to open a folder and select more inside.';

  @override
  String get oneDriveIncludeOpenFolderInSelection => 'Include open folder';

  @override
  String oneDriveAddSelectedFoldersAction(int count) {
    return 'Add ($count)';
  }

  @override
  String get oneDriveAddFolderTooltip => 'Add folder to cloud library';

  @override
  String get oneDriveIndexingEllipsis => 'Scanning folders…';

  @override
  String oneDriveLastIndexed(String time) {
    return 'Last scanned: $time';
  }

  @override
  String get oneDrivePlayAllTracks => 'Play all';

  @override
  String oneDriveTracksCount(int count) {
    return '$count songs';
  }

  @override
  String get oneDriveCloudSearchHint => 'Search file names or paths…';

  @override
  String get oneDriveNoIndexRoots =>
      'No folders configured. Tap “Choose folders” first.';

  @override
  String get oneDriveLastIndexedNever => 'Last scanned: —';

  @override
  String get oneDriveIndexFoldersRecursiveHint =>
      'Scan includes all subfolders; every audio file under each bound folder is listed.';

  @override
  String get oneDriveRemoveIndexFolderTitle => 'Remove this folder?';

  @override
  String oneDriveRemoveIndexFolderMessage(String name) {
    return 'Remove \"$name\" from the index? Tracks under this folder (including subfolders) will disappear until you add it again.';
  }

  @override
  String get oneDriveRemoveIndexFolderAction => 'Remove';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSettingsDescription =>
      'Choose the app interface language. “Follow system” uses your device language when a translation is available.';

  @override
  String get langFollowSystem => 'Follow system';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langSimplifiedChinese => 'Simplified Chinese';

  @override
  String get langTraditionalChinese => 'Traditional Chinese';

  @override
  String get themeSettingsTitle => 'Theme settings';

  @override
  String get globalTheme => 'App theme';

  @override
  String get globalThemeDesc =>
      'Use light, dark, or follow the system. Settings are saved on this device.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get sectionThemeType => 'Theme type';

  @override
  String get themeTypeSolid => 'Presets';

  @override
  String get themeTypeCustom => 'Custom color';

  @override
  String get themeTypeImage => 'Background image';

  @override
  String get sectionPresetColors => 'Preset colors';

  @override
  String get sectionCustomColor => 'Custom color';

  @override
  String get sectionBackgroundImage => 'Background image';

  @override
  String get primaryColor => 'Primary color';

  @override
  String get secondaryColor => 'Secondary color';

  @override
  String get themeGradientRgbSectionTitle => 'Gradient background';

  @override
  String get themeGradientRgbSectionSubtitle =>
      'Gradient RGB slider with simultaneous fine‑tuning of both end colors and the gradient direction.';

  @override
  String get themeGradientRgbFineTune => 'Edit colors & direction…';

  @override
  String get themeGradientRgbDialogTitle => 'Background gradient';

  @override
  String get actionSelect => 'Select';

  @override
  String get fogBackground => 'Background blur & dim';

  @override
  String get fogBackgroundDesc =>
      'Blur and dim the wallpaper so labels stay readable. A light overall dim plus subtle darker top/bottom edges are kept even at low strength; bump it up for busy or high‑contrast photos. Default 45%.';

  @override
  String get fogWeak => 'Subtle';

  @override
  String get fogStrong => 'Strong';

  @override
  String get actionPickImage => 'Choose image';

  @override
  String get actionRemove => 'Remove';

  @override
  String cannotSaveBackground(String error) {
    return 'Could not save the background image. Try again or use another: $error';
  }

  @override
  String get themeWallpaperSavedRestartHint =>
      'Wallpaper saved. If it doesn\'t show yet, fully quit the app and reopen.';

  @override
  String get colorDialogTitlePrimary => 'Primary color';

  @override
  String get colorDialogTitleSecondary => 'Secondary color';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String startupFailed(String error) {
    return 'Startup failed: $error';
  }

  @override
  String get welcomeTagline => 'Every listen starts here';

  @override
  String get welcomeEnter => 'Enter';

  @override
  String get welcomeEnterWait => 'Enter (wait for loading to finish)';

  @override
  String get welcomeHintWhenReady =>
      'Loading is done — tap to enter, or we open automatically.';

  @override
  String get welcomeHintWhenNotReady =>
      'Opens automatically once startup completes.';

  @override
  String get welcomePreparing => 'Preparing the app…';

  @override
  String get welcomeCountdownLabel => 'Startup time';

  @override
  String get welcomeCountdownSubDoneReady =>
      'Home screen is ready — you can enter';

  @override
  String get welcomeStartupSubLoading =>
      'Loading home resources — auto-enter when done';

  @override
  String get secondsUnit => 's';

  @override
  String get welcomeNotReadyMessage =>
      'Please wait; resources are not ready yet.';

  @override
  String welcomeLoadError(String error) {
    return 'Something went wrong. Check storage access or try again later.\n\n$error';
  }

  @override
  String get welcomeFakeUserSettings => 'Loading user settings';

  @override
  String get welcomeFakeLibrary => 'Loading library';

  @override
  String get welcomeFakePlaylists => 'Loading playlists';

  @override
  String get welcomeFakeOther => 'Loading other data';

  @override
  String get welcomeFakeFinishing => 'Finishing initialization';

  @override
  String get homeGreetingLateNight => 'Still up?';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homePullLoftTitle => 'Reload from this device';

  @override
  String get homePullReleaseHint => 'Release to reload saved settings';

  @override
  String get homePullEmptyTease =>
      'There\'s nothing here — pulling more won\'t help.';

  @override
  String get homePullStepThemeWallpaper =>
      'Theme: colors, gradient & wallpaper';

  @override
  String get homePullStepBrightnessMode => 'Appearance: light or dark mode';

  @override
  String get homePullStepLanguage => 'Interface language';

  @override
  String get homePullStepPlaylistsCarousel => 'Playlists & home carousel order';

  @override
  String get homePullStepShortcuts => 'Home shortcuts';

  @override
  String get homePullStepRecentTopPlayed => 'Recent plays & play counts';

  @override
  String get homePullStepLyricsDisplay =>
      'Lyrics display (re-read from storage)';

  @override
  String get homePullStepPlaybackPrefs => 'Playback mode (shuffle / repeat)';

  @override
  String get homePullRefreshDone => 'Reloaded settings from local storage.';

  @override
  String homePullRefreshFailed(String error) {
    return 'Could not reload from local storage: $error';
  }

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String get homeSearchTooltip => 'Search';

  @override
  String get homeQuickEntryEmpty =>
      'No shortcuts. Tap “Manage” to show library, playlists, OneDrive cache, and more.';

  @override
  String get homeEntryLibrary => 'Library';

  @override
  String get homeEntryMyPlaylists => 'My playlists';

  @override
  String get homeEntryRecent => 'Recent';

  @override
  String get homeEntryMostPlayed => 'Top plays';

  @override
  String get homeEntryDiscover => 'Discover';

  @override
  String get homeEntryCloudLibrary => 'Cloud library';

  @override
  String get homeEntryOneDriveCachePlaylist => 'Cached playlist';

  @override
  String get homeEntryOneDriveTransferQueue => 'Transfer queue';

  @override
  String get homeSectionQuickEntry => 'Shortcuts';

  @override
  String get homeActionManage => 'Manage';

  @override
  String get homeSectionMyPlaylists => 'My playlists';

  @override
  String get homeActionMore => 'More';

  @override
  String get homeLoadingLibrary => 'Loading library…';

  @override
  String get homeRecentEmpty =>
      'No recent plays. Play a song in the library or a playlist to see it here.';

  @override
  String get homeSectionMostPlayed => 'Top plays';

  @override
  String get homeSectionRecentPlays => 'Recent plays';

  @override
  String get homeActionAll => 'All';

  @override
  String get homeMostPlayedPathMismatch =>
      'Play counts no longer match the library. Rescan your music folder if files moved, then play a few more times.';

  @override
  String get homeMostPlayedEmpty =>
      'No play stats yet. Play more songs in the library or a playlist to build a top list.';

  @override
  String get mostPlayedSwitchSortAscending =>
      'Switch to ascending play count (least plays first)';

  @override
  String get mostPlayedSwitchSortDescending =>
      'Switch to descending play count (most plays first)';

  @override
  String homePlayCount(int c) {
    return 'Played $c times';
  }

  @override
  String homePlayCountWithBase(String base, int c) {
    return '$base · Played $c times';
  }

  @override
  String homeGreetingLine(String greeting) {
    return '$greeting, what would you like to listen to today?';
  }

  @override
  String get homeGreetingSub => 'Pick up below or start from a playlist.';

  @override
  String get homeSearchHint => 'Search songs, artists, playlists';

  @override
  String get homeContinuePlaying => 'Continue';

  @override
  String get homeUnknownTitle => 'Unknown';

  @override
  String get homeNowPlayingAlbum => 'Now playing';

  @override
  String get homeNothingPlaying => 'Nothing playing';

  @override
  String get homeOpenLibraryToPlay => 'Open the library and pick a song';

  @override
  String get homeAllSongsLoading => 'Loading…';

  @override
  String get homeScanMusicFolder => 'Scan a music folder';

  @override
  String homeTrackCount(int n) {
    return '$n songs';
  }

  @override
  String get homeAllSongs => 'All songs';

  @override
  String get homeCreatePlaylist => 'New playlist';

  @override
  String get homeCreatePlaylistSub => 'Collect the songs you love';

  @override
  String get homeEmptyPlaylist => 'Empty';

  @override
  String get songsListEmpty => 'No songs in the library';

  @override
  String get tooltipSort => 'Sort';

  @override
  String get playbackFailedSnackMessage =>
      'Couldn\'t play this track. It may be missing, unreadable, or in an unsupported format.';

  @override
  String get languageRestartNotice =>
      'You may need to restart the app for all interface text to update.';

  @override
  String get locateNotInList => 'The playing track is not in this list';

  @override
  String get locateToCurrent => 'Scroll to now playing';

  @override
  String get locateToCurrentPlaying => 'Show the playing track';

  @override
  String get locateToLyricLine => 'Scroll to the current line';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipAddToPlaylist => 'Add to playlist';

  @override
  String get menuPlayNextAfterCurrent => 'Play after current track';

  @override
  String get libraryPlayNextAfterCurrentQueued =>
      'This track will play when the current one ends.';

  @override
  String get libraryPlayNextAfterCurrentNotInQueue =>
      'This track is not in the current playback queue.';

  @override
  String get tooltipDone => 'Done';

  @override
  String get tooltipMoreActions => 'Actions';

  @override
  String get tooltipMore => 'More';

  @override
  String get tooltipLyricStyle => 'Lyric style';

  @override
  String get songPageMoreSheetTitle => 'More actions';

  @override
  String get songPageMoreSoundEffects => 'Sound effects';

  @override
  String get songPageMoreSoundEffectsSubtitle => 'EQ presets (Android)';

  @override
  String get playbackSoundPresetSheetTitle => 'Sound effects';

  @override
  String get playbackSoundPresetUnsupportedBody =>
      'Hardware EQ is only applied on Android while audio is playing. On other platforms you can still pick a preset; it will apply the next time you play on a supported device.';

  @override
  String get playbackSoundPresetStabilityAndroidHint =>
      'This feature may still be unstable. If you hear pops or crackling, choose \"Original\" (flat).';

  @override
  String get playbackSoundPresetStandard => 'Original';

  @override
  String get playbackSoundPresetPureVocals => 'Vocal clarity';

  @override
  String get playbackSoundPresetSpatialWide => '3D wide';

  @override
  String get playbackSoundPresetRock => 'Rock';

  @override
  String get playbackSoundPresetPop => 'Pop';

  @override
  String get playbackSoundPresetElectronic => 'Electronic';

  @override
  String get playbackSoundPresetClassical => 'Classical';

  @override
  String get playbackSoundPresetJazz => 'Jazz';

  @override
  String get playbackSoundPresetLiveStage => 'Live stage';

  @override
  String get playbackSoundPresetCozyRoom => 'Room (bath-like)';

  @override
  String get playbackSoundPresetPodcast => 'Podcast & voice';

  @override
  String get playbackSoundPresetMetal => 'Metal';

  @override
  String get playbackSoundPresetHipHop => 'Hip-hop';

  @override
  String get playbackSoundPresetLoFi => 'Lo-fi';

  @override
  String get playbackSoundPresetNight => 'Night listening';

  @override
  String get playbackSoundPresetBassBoost => 'Bass boost';

  @override
  String get playbackSoundPresetCustom => 'Custom';

  @override
  String get playbackSoundCustomTileSubtitle =>
      'Adjust each frequency band (Android)';

  @override
  String get playbackSoundCustomSheetTitle => 'Custom equalizer';

  @override
  String get playbackSoundCustomReset => 'Flat (reset)';

  @override
  String get playbackSoundCustomSaveApply => 'Save & apply';

  @override
  String get playbackSoundCustomLoadError =>
      'Could not load the equalizer. Start playback, then open this screen again.';

  @override
  String get songPageMoreQueryMetadata => 'View audio metadata';

  @override
  String get songPageMoreUploadOneDrive => 'Upload to OneDrive';

  @override
  String get songPageMoreShare => 'Share';

  @override
  String get songPageMoreEditMusicTagsExternal => 'Edit tags in external app…';

  @override
  String get songPageMoreEditMusicTagsInline => 'Edit embedded tags…';

  @override
  String get songPageInlineTagsUnstableTitle => 'Notice';

  @override
  String get songPageInlineTagsUnstableBody =>
      'Embedded tag editing isn’t fully stable yet and may corrupt metadata in the file. We recommend copying or duplicating the song as a backup before you continue.';

  @override
  String get songPageInlineTagsUnstableContinue => 'Continue anyway';

  @override
  String get songPageInlineTagsUnstableCancel => 'Cancel';

  @override
  String get songPageInlineTagsEditorTitle => 'Edit embedded tags';

  @override
  String get songPageInlineTagsFieldTitle => 'Title';

  @override
  String get songPageInlineTagsFieldArtist => 'Artist';

  @override
  String get songPageInlineTagsFieldAlbum => 'Album';

  @override
  String get songPageInlineTagsCoverSection => 'Embedded cover';

  @override
  String get songPageInlineTagsCoverReplace => 'Choose image to crop…';

  @override
  String get songPageInlineTagsCoverRemove => 'Remove cover';

  @override
  String get songPageInlineTagsCoverInvalid =>
      'Please choose a JPEG or PNG image.';

  @override
  String get songPageInlineTagsFieldYear => 'Year';

  @override
  String get songPageInlineTagsFieldTrackNumber => 'Track #';

  @override
  String get songPageInlineTagsFieldTrackTotal => 'Total tracks';

  @override
  String get songPageInlineTagsFieldDiscNumber => 'Disc #';

  @override
  String get songPageInlineTagsFieldDiscTotal => 'Total discs';

  @override
  String get songPageInlineTagsFieldLyrics => 'Lyrics';

  @override
  String get songPageInlineTagsSave => 'Save';

  @override
  String get songPageInlineTagsSaved => 'Tags saved to file';

  @override
  String songPageInlineTagsSaveFailed(Object error) {
    return 'Could not save tags: $error';
  }

  @override
  String get songPageStorageManageAllFilesHint =>
      'Editing or deleting audio under shared storage needs “All files access”. Grant it for this app in system settings, then try again.';

  @override
  String get audioQualityTierLq => 'Economy';

  @override
  String get audioQualityTierStd => 'Standard';

  @override
  String get audioQualityTierHq => 'High quality';

  @override
  String get audioQualityTierSq => 'Lossless (CD equivalent)';

  @override
  String get audioQualityTierHr => 'Hi-Res';

  @override
  String get audioQualityTierDsd => 'DSD · audiophile';

  @override
  String get audioQualityTierLqDesc =>
      'Lossy audio below about 96 kbps (e.g. low-bitrate MP3).';

  @override
  String get audioQualityTierStdDesc =>
      'Lossy about 96–255 kbps (typical streaming or MP3).';

  @override
  String get audioQualityTierHqDesc =>
      'Lossy 256 kbps and above (e.g. 320 kbps MP3, high VBR).';

  @override
  String get audioQualityTierSqDesc =>
      'Lossless FLAC, WAV, APE, etc. at CD sample rates (up to 48 kHz).';

  @override
  String get audioQualityTierHrDesc =>
      'Lossless or very high bitrate with sample rate at least 88.2 kHz (Hi-Res).';

  @override
  String get audioQualityTierDsdDesc =>
      'DSD formats (.dsf / .dff); highest tier in the library.';

  @override
  String get songPageMoreEditLyricsExternal => 'Edit with SyncedLyricEditor…';

  @override
  String get songPageSyncedLyricEditorNotInstalled =>
      'SyncedLyric Editor is not installed.';

  @override
  String get songPageSyncedLyricEditorLaunchFailed =>
      'Could not open SyncedLyric Editor.';

  @override
  String get songPageMusicTagEditorUnsupportedPlatform =>
      'External tag editing is only available on Android.';

  @override
  String get songPageMusicTagEditorFileNotFound => 'Audio file not found.';

  @override
  String get songPageMusicTagEditorNotInstalled =>
      'Music Tag Editor is not installed.';

  @override
  String get songPageMusicTagEditorCannotSharePath =>
      'This file cannot be opened from its current location.';

  @override
  String get songPageMusicTagEditorLaunchFailed =>
      'Could not open Music Tag Editor.';

  @override
  String get songPageMetadataDialogTitle => 'Audio metadata';

  @override
  String get songPageMetadataReadFailed =>
      'Could not read metadata for this file.';

  @override
  String get songPageShareFileNotFound => 'This file was not found on disk.';

  @override
  String get songPageDeleteDiskWarningTitle => 'Delete from disk?';

  @override
  String get songPageDeleteDiskWarningBody =>
      'This permanently removes the audio file from device storage. This cannot be undone. The song will also be removed from playlists and history.';

  @override
  String get songPageDeleteContinue => 'Continue';

  @override
  String get songPageDeleteFinalConfirmTitle => 'Confirm deletion';

  @override
  String songPageDeleteFinalConfirmBody(Object fileName) {
    return 'Delete \"$fileName\"?';
  }

  @override
  String get songPageMetaFieldTitle => 'Title';

  @override
  String get songPageMetaFieldArtist => 'Artist';

  @override
  String get songPageMetaFieldAlbum => 'Album';

  @override
  String get songPageMetaFieldDuration => 'Duration';

  @override
  String get songPageMetaFieldBitrate => 'Bitrate';

  @override
  String get songPageMetaFieldSampleRate => 'Sample rate';

  @override
  String get songPageMetaFieldYear => 'Year';

  @override
  String get songPageMetaFieldTrack => 'Track';

  @override
  String get songPageMetaFieldDisc => 'Disc';

  @override
  String get songPageMetaFieldPath => 'Path';

  @override
  String get songPageMetaFieldSize => 'File size';

  @override
  String get songPageMetaFieldGenre => 'Genre';

  @override
  String get songPageMetaFieldPerformers => 'Performers';

  @override
  String get songPageMetaFieldLanguage => 'Language';

  @override
  String get songPageMetaFieldEmbeddedLyrics => 'Embedded lyrics';

  @override
  String get songPageMetaFieldFormat => 'Format';

  @override
  String get songPageMetaSectionTags => 'Tags';

  @override
  String get songPageMetaSectionAudio => 'Audio';

  @override
  String get songPageMetaSectionFile => 'File';

  @override
  String get tooltipFolderInfo => 'Folder details';

  @override
  String get tooltipReloadSongs => 'Rescan folder';

  @override
  String get tooltipEdit => 'Edit';

  @override
  String get tooltipRemoveFolder => 'Remove folder';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get actionOK => 'OK';

  @override
  String get settingsRowHelpTooltip => 'Details';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNewNameHint => 'New name';

  @override
  String get folderAppBarTitle => 'Folders';

  @override
  String folderSongsCount(int n) {
    return '$n songs';
  }

  @override
  String get folderInfoAlias => 'Alias:';

  @override
  String get folderInfoPath => 'Path:';

  @override
  String get folderInfoSongCount => 'Songs:';

  @override
  String get folderInfoAdded => 'Added:';

  @override
  String get folderAddLoadingTitle => 'Loading songs';

  @override
  String get folderReloading => 'Rescanning';

  @override
  String get folderScanningWait => 'Scanning folders…';

  @override
  String folderLoadOk(int n) {
    return 'Loaded $n songs';
  }

  @override
  String folderLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get libraryReloadPullNoFolders =>
      'Add a media folder in Music source first.';

  @override
  String get libraryReloadNoMusicDetected =>
      'No playable music found. Add a media folder in Music source or add tracks to a playlist, and make sure files still exist.';

  @override
  String get folderRemoveTitle => 'Remove this folder?';

  @override
  String folderRemoveMessage(String name) {
    return 'Remove $name from the library? Music files on disk are not deleted.';
  }

  @override
  String get folderDuplicateDialogTitle => 'Notice';

  @override
  String folderDuplicateMessage(String path) {
    return 'This folder was already added: $path';
  }

  @override
  String folderAddOk(int n) {
    return 'Added $n songs';
  }

  @override
  String get folderAddErrorTitle => 'Error';

  @override
  String folderAddErrorMessage(String error) {
    return 'Could not add folder: $error';
  }

  @override
  String get folderAddNoSelection => 'No folder was selected.';

  @override
  String get folderRenameDialogTitle => 'Rename folder';

  @override
  String get playlistPageTitle => 'Playlists';

  @override
  String get playlistNotFound => 'Playlist not found';

  @override
  String get playlistNotFoundMessage => 'It may have been deleted.';

  @override
  String get playlistEmptyNoSongs =>
      'No playable songs. Scan a media folder or some paths may be missing.';

  @override
  String get playlistDeleteTitle => 'Delete playlist';

  @override
  String get playlistDeleteMessage =>
      'Delete this playlist? References will be lost; music files on disk are not removed.';

  @override
  String get playlistDeleteBatchTitle => 'Delete multiple playlists';

  @override
  String playlistDeleteBatchMessage(int n) {
    return 'Delete the $n selected playlists? References will be lost; music files on disk are not removed.';
  }

  @override
  String get playlistDeletedOne => 'Playlist deleted';

  @override
  String get importDialogBody =>
      'Songs are identified by full file path: same title and artist but different files or quality map to different paths and will not be merged by mistake.\n\n• Merge import: playlists with the same id as local ones merge track lists (paths deduplicated); playlists only in the backup are created.\n• Replace all: clears all local playlists first, then restores from the backup (use with care).';

  @override
  String playlistCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String get recentPlaysEmptyTitle => 'No play history';

  @override
  String get quickEntryReorderHint =>
      'Drag the handle to reorder. Turn off “Show on home” to hide an entry from the home screen.';

  @override
  String get quickEntryShowOnHome => 'Show on home';

  @override
  String get playlistSearchHint => 'Search songs, artists, or file names…';

  @override
  String get searchNoMatchingSongs => 'No matching songs';

  @override
  String get playlistRenameTitle => 'Rename playlist';

  @override
  String get playlistCoverStyleTitle => 'Cover color';

  @override
  String get playlistCoverStyleSubtitle =>
      'Solid or gradient for playlist cards on Home and in the library list. Rotating presets follow list order; you can also build a custom two-color gradient for stronger contrast.';

  @override
  String get playlistCoverUseDefaultPalette => 'Use rotating preset colors';

  @override
  String get playlistCoverSolidSection => 'Solid';

  @override
  String get playlistCoverGradientSection => 'Gradient';

  @override
  String get playlistCoverCustomGradientTitle => 'Custom gradient';

  @override
  String get playlistCoverGradientStartColor => 'Start color';

  @override
  String get playlistCoverGradientEndColor => 'End color';

  @override
  String get playlistCoverGradientSwapColors => 'Swap colors';

  @override
  String get playlistCoverGradientDirectionTitle => 'Gradient direction';

  @override
  String get playlistCoverGradientDirHorizontalLR => 'Left to right';

  @override
  String get playlistCoverGradientDirHorizontalRL => 'Right to left';

  @override
  String get playlistCoverGradientDirVerticalTB => 'Top to bottom';

  @override
  String get playlistCoverGradientDirVerticalBT => 'Bottom to top';

  @override
  String get playlistCoverGradientDirDiagonalTLBR =>
      'Diagonal top-left → bottom-right';

  @override
  String get playlistCoverGradientDirDiagonalTRBL =>
      'Diagonal top-right → bottom-left';

  @override
  String get playlistCoverGradientDirDiagonalBRTL =>
      'Diagonal bottom-right → top-left';

  @override
  String get playlistCoverGradientDirDiagonalBLTR =>
      'Diagonal bottom-left → top-right';

  @override
  String get playlistCoverRgbTitle => 'Custom RGB color';

  @override
  String get playlistCoverRgbRed => 'Red';

  @override
  String get playlistCoverRgbGreen => 'Green';

  @override
  String get playlistCoverRgbBlue => 'Blue';

  @override
  String get playlistCoverRgbPreview => 'Preview';

  @override
  String get playlistCoverPreviewLabel => 'Current appearance';

  @override
  String get playlistCoverMenuItem => 'Cover color…';

  @override
  String get playlistCoverPictureSection => 'Picture';

  @override
  String get playlistCoverPickImage => 'Choose image…';

  @override
  String get playlistCoverRemoveImage => 'Remove picture';

  @override
  String get imageCropTitle => 'Crop image';

  @override
  String get imageCropFailure => 'Could not crop this image.';

  @override
  String get exportCannot => 'This playlist cannot be exported';

  @override
  String exportSaved(String path) {
    return 'Exported: $path';
  }

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportDialogTitle => 'Export playlist';

  @override
  String get menuRename => 'Rename';

  @override
  String get menuExportThis => 'Export this playlist…';

  @override
  String get menuDeletePlaylist => 'Delete playlist';

  @override
  String get exportSelectFirst => 'Select playlists to export first';

  @override
  String get exportNoneToExport => 'Nothing to export; check the selection';

  @override
  String get exportAllPlaylists => 'Export all playlists';

  @override
  String get exportSelectedPlaylists => 'Export selected playlists';

  @override
  String get exportSelected => 'Export selected';

  @override
  String get exportAll => 'Export all';

  @override
  String get importCannotRead =>
      'Could not read the file (try a smaller backup or check permissions)';

  @override
  String importParseError(String message) {
    return 'Could not parse: $message';
  }

  @override
  String get importMerge => 'Merge import';

  @override
  String get importReplaceAll => 'Replace all';

  @override
  String get importMerged => 'Imported (merged)';

  @override
  String get importReplaced => 'Imported (replaced)';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String playlistsDeletedN(int n) {
    return 'Deleted $n playlist(s)';
  }

  @override
  String librarySongsDeletedN(int n) {
    return 'Deleted $n song(s)';
  }

  @override
  String get fabNewPlaylist => 'New playlist';

  @override
  String get emptyPlaylistsHint =>
      'No playlists yet.\nAdd songs from the player or song lists to playlists.\n\nUse the top-right menu to import and multi-select.';

  @override
  String get sortByName => 'By name';

  @override
  String get sortByPath => 'By path';

  @override
  String get sortByCreated => 'By date created';

  @override
  String get sortByUpdated => 'By date updated';

  @override
  String get sortByAddedToPlaylist => 'By time added to playlist';

  @override
  String get sortByAddedToPlaylistSub =>
      'Ascending: oldest first · Descending: newest first';

  @override
  String get lyricAlignLeft => 'Left';

  @override
  String get lyricAlignCenter => 'Center';

  @override
  String get lyricAlignRight => 'Right';

  @override
  String get addToPlaylistHint => 'New playlist name';

  @override
  String addToPlaylistUpdatedN(int n) {
    return 'Updated $n playlist(s)';
  }

  @override
  String get noLyrics => 'No lyrics';

  @override
  String get songNotFound => 'Song not found';

  @override
  String get pageUnknownTitle => 'Unknown title';

  @override
  String get queueNoTracks => 'No tracks in queue';

  @override
  String get playQueueTitle => 'Play queue';

  @override
  String get queuePendingPlayAfterCurrentSection => 'Play next (queued)';

  @override
  String get playbackModeTitle => 'Playback mode';

  @override
  String get playbackSequential => 'Play in order';

  @override
  String get playbackShuffle => 'Shuffle';

  @override
  String get playbackSingleLoop => 'Repeat one';

  @override
  String get playbackOnce => 'Play once and stop';

  @override
  String get playbackTimer => 'Stop after timer';

  @override
  String get sleepTimerSheetTitle => 'Stop playback later';

  @override
  String get sleepTimerCancel => 'Cancel sleep timer';

  @override
  String sleepTimerMinutesN(int n) {
    return '$n min';
  }

  @override
  String get sleepTimerCustom => 'Custom duration';

  @override
  String sleepTimerCurrentN(int n) {
    return 'Current: $n min';
  }

  @override
  String get sleepTimerLabelMinutes => 'Minutes';

  @override
  String sleepTimerInvalidRange(int min, int max) {
    return 'Enter a whole number between $min and $max.';
  }

  @override
  String sleepTimerPlayedMinutes(int minutes) {
    return 'Sleep timer: played for $minutes min';
  }

  @override
  String get songPageKeepScreenAwake => 'Keep screen on';

  @override
  String get lyricStyleKeepScreenAwakeSub =>
      'Stays awake while you read lyrics on this screen';

  @override
  String get lyricModeEmptyHint => 'Change display mode';

  @override
  String get lyricModeAllLines => 'Multi-line: all lines (tap for single line)';

  @override
  String lyricModeSingleLineN(int n) {
    return 'Multi-line: line $n only (tap to cycle)';
  }

  @override
  String get sortOptionsTitle => 'Sort by';

  @override
  String addToPlaylistTitle(String name) {
    return 'Add to playlist · $name';
  }

  @override
  String get addToPlaylistMultiHelp =>
      'Select multiple. Uncheck to remove the song from a playlist.';

  @override
  String get addToPlaylistNoPlaylistsYet =>
      'No playlists yet. Type a name above to create one.';

  @override
  String get quickEntrySettingsTitle => 'Shortcuts';

  @override
  String get playlistSelectModeSingle => 'Single select';

  @override
  String get playlistSelectModeMulti => 'Multi select';

  @override
  String get menuImportPlaylists => 'Import playlists';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String playlistSelectCount(int n, int m) {
    return '$n of $m selected';
  }

  @override
  String get lyricStyleSyncSubtitle =>
      'Same as the lyrics on the now playing screen';

  @override
  String get lyricStyleSectionDisplay => 'Display';

  @override
  String get lyricStyleSectionDisplaySub =>
      'Original and extra translation lines';

  @override
  String get lyricStyleShowOriginal => 'Show original';

  @override
  String get lyricStyleShowOriginalSub => 'First line of each timestamp';

  @override
  String get lyricStyleShowTranslation => 'Show translation / extra lines';

  @override
  String get lyricStyleShowTranslationSub => 'Second line and below';

  @override
  String get lyricStyleSectionTypography => 'Size & line spacing';

  @override
  String get lyricStyleSectionTypographySub =>
      'Adjust with sliders; applies immediately';

  @override
  String get lyricStyleFontOriginal => 'Original font size';

  @override
  String get lyricStyleFontTranslation => 'Translation font size';

  @override
  String get lyricStyleLineSpacing => 'Line spacing';

  @override
  String get lyricStyleSectionLineAlign => 'Line alignment';

  @override
  String get lyricStyleSectionStateColors => 'Line state colors';

  @override
  String get lyricStyleSectionStateColorsSub => 'Now playing, played, not yet';

  @override
  String get lyricStyleStateNowPlaying => 'Current line';

  @override
  String get lyricStyleStatePlayed => 'Past lines';

  @override
  String get lyricStyleStateUpcoming => 'Upcoming lines';

  @override
  String get lyricStyleColorNowOriginal => 'Now playing — original';

  @override
  String get lyricStyleColorNowTranslation => 'Now playing — translation';

  @override
  String get lyricStyleColorPlayedOriginal => 'Played — original';

  @override
  String get lyricStyleColorPlayedTranslation => 'Played — translation';

  @override
  String get lyricStyleColorUpcomingOriginal => 'Upcoming — original';

  @override
  String get lyricStyleColorUpcomingTranslation => 'Upcoming — translation';

  @override
  String get lyricStyleColorPersistNote =>
      'Colors are saved locally and kept after you change tracks.';

  @override
  String get lyricStyleActiveGradientTitle => 'Gradient: current line';

  @override
  String get lyricStyleStateGradientSub =>
      'When on, this two-color gradient overrides the solid picks above for both original and translation.';

  @override
  String get lyricStyleActiveGradientTune => 'Edit gradient';

  @override
  String get lyricStyleActiveGradientDialogTitle => 'Current line gradient';

  @override
  String get lyricStylePlayedGradientTitle => 'Gradient: played lines';

  @override
  String get lyricStyleUpcomingGradientTitle => 'Gradient: upcoming lines';

  @override
  String get lyricStylePlayedGradientDialogTitle => 'Played lines gradient';

  @override
  String get lyricStyleUpcomingGradientDialogTitle => 'Upcoming lines gradient';

  @override
  String get lyricColorPickerHint => 'Tap a swatch';

  @override
  String get lyricLabelOriginal => 'Original';

  @override
  String get lyricLabelTranslation => 'Translation';

  @override
  String get libraryBatchSelect => 'Select';

  @override
  String get libraryBatchDone => 'Done';

  @override
  String get libraryBatchSelectAll => 'All';

  @override
  String get libraryBatchDelete => 'Delete';

  @override
  String get libraryBatchRename => 'Rename';

  @override
  String get libraryBatchUploadOneDrive => 'Upload to OneDrive';

  @override
  String get libraryBatchDeleteConfirmTitle => 'Delete selected songs?';

  @override
  String get libraryBatchDeleteConfirmMessage =>
      'Files will be removed from this device and references cleaned up. This cannot be undone.';

  @override
  String get libraryBatchNoneSelected => 'Select songs first';

  @override
  String get libraryBatchRenameTitle => 'Batch rename';

  @override
  String get libraryBatchRenameHint =>
      'Pattern; use %n for a number (e.g. Track %n)';

  @override
  String get libraryBatchRenameStart => 'Start at';

  @override
  String get libraryRenameSingleTitle => 'Rename track';

  @override
  String get libraryRenameSingleHint =>
      'Main filename only; the extension is kept.';

  @override
  String get libraryRenameSingleFieldLabel => 'Name';

  @override
  String get libraryRenameSingleDone => 'Renamed';

  @override
  String get libraryCloneSong => 'Clone song';

  @override
  String get libraryCloneSongTitle => 'Clone to new file';

  @override
  String get libraryCloneSongHint =>
      'Enter a name for the copy (extension is kept). Saved next to the original.';

  @override
  String get libraryCloneSongDefaultSuffix => ' copy';

  @override
  String get libraryCloneSongDone => 'Song cloned';

  @override
  String get libraryCloneSongFailed => 'Could not clone song';

  @override
  String get libraryCloneSongProgressTitle => 'Cloning song';

  @override
  String get libraryCloneSongProgressMessage =>
      'Copying file and refreshing library…';

  @override
  String get libraryBatchUploadNeedSignIn => 'Sign in to OneDrive in Settings';

  @override
  String get libraryBatchUploadNeedCloudFolder =>
      'Choose an OneDrive cloud app folder in Settings first';

  @override
  String get libraryBatchUploadNeedParentFolder =>
      'Choose a music upload folder or cloud app folder under OneDrive settings first.';

  @override
  String get libraryBatchUploadQueued => 'Added to transfer queue';

  @override
  String get libraryBatchOpenQueue => 'Open queue';

  @override
  String get libraryBatchAddToPlaylist => 'Add to playlists';

  @override
  String libraryBatchAddToPlaylistSheetTitle(int count) {
    return 'Add $count tracks to playlists';
  }

  @override
  String get libraryBatchAddToPlaylistSheetHelp =>
      'Checked playlists already contain every selected track. Confirm applies these memberships to all selected tracks.';

  @override
  String get libraryBatchAddToPlaylistDone => 'Playlists updated';

  @override
  String get libraryReloadMetadata => 'Reload embedded metadata';

  @override
  String get libraryReloadMetadataDone => 'Metadata reloaded from file';

  @override
  String get oneDriveUploadStatusUploading => 'Uploading';

  @override
  String get oneDriveTaskDirectionUpload => 'Upload';

  @override
  String get homeEntrySongRecognizer => 'Song ID';

  @override
  String get songRecognizerTitle => 'Song recognition';

  @override
  String get songRecognizerModeInApp => 'In-app';

  @override
  String get songRecognizerModeAmbient => 'Ambient';

  @override
  String get songRecognizerModeInAppHelp =>
      'Stay on this screen. We record ~10s from the microphone for best accuracy.';

  @override
  String get songRecognizerModeAmbientHelp =>
      'Listen continuously every ~20s while this page is open. Hold the phone near the speaker playing music (other apps or devices). May not work if you leave the app—keep it foreground for reliability.';

  @override
  String get songRecognizerStart => 'Listen';

  @override
  String get songRecognizerSnackbarStarted => 'Recognizing…';

  @override
  String get songRecognizerSnackbarCancelled => 'Recognition cancelled';

  @override
  String get songRecognizerStopAmbient => 'Stop ambient listen';

  @override
  String get songRecognizerListening => 'Listening…';

  @override
  String get songRecognizerRecognizing => 'Identifying…';

  @override
  String get songRecognizerHistory => 'History';

  @override
  String get songRecognizerHistoryEmpty => 'No results yet';

  @override
  String get songRecognizerHistoryFilterAll => 'All';

  @override
  String get songRecognizerHistoryFilterMatched => 'Matched';

  @override
  String get songRecognizerHistoryFilterArchived => 'Favorites';

  @override
  String get songRecognizerHistoryEmptyMatched =>
      'No matched songs in history yet.';

  @override
  String get songRecognizerHistoryEmptyArchived => 'No favorites yet.';

  @override
  String get songRecognizerDeleteHistoryEntryTitle => 'Delete entry';

  @override
  String get songRecognizerDeleteHistoryEntryMessage =>
      'Delete this recognition log?';

  @override
  String get songRecognizerSwipeArchive => 'Favorite';

  @override
  String get songRecognizerSwipeRestore => 'Remove';

  @override
  String get songRecognizerSwipeDelete => 'Delete';

  @override
  String get songRecognizerEntryArchived => 'Saved to favorites';

  @override
  String get songRecognizerEntryRestoredFromArchive => 'Removed from favorites';

  @override
  String get songRecognizerCopyEntry => 'Copy';

  @override
  String get songRecognizerEntryCopied => 'Copied to clipboard';

  @override
  String get songRecognizerCopyLabelTime => 'Time: ';

  @override
  String get songRecognizerCopyLabelMode => 'Mode: ';

  @override
  String get songRecognizerCopyLabelService => 'Service: ';

  @override
  String get songRecognizerCopyLabelSong => 'Song: ';

  @override
  String get songRecognizerCopyLabelArtist => 'Artist: ';

  @override
  String get songRecognizerCopyLabelAlbum => 'Album: ';

  @override
  String get songRecognizerCopyLabelReleased => 'Released: ';

  @override
  String get songRecognizerCopyLabelAppleMusic => 'Apple Music: ';

  @override
  String get songRecognizerCopyLabelSpotify => 'Spotify: ';

  @override
  String get songRecognizerCopyLabelNoMatch => 'Result: ';

  @override
  String get songRecognizerCopyLabelError => 'Error: ';

  @override
  String get songRecognizerClearHistory => 'Clear history';

  @override
  String get songRecognizerClearHistoryConfirm =>
      'Delete all recognition history?';

  @override
  String get songRecognizerNoMatch =>
      'No match—try a clearer sample or less noise.';

  @override
  String get songRecognizerOpenAppleMusic => 'Apple Music';

  @override
  String get songRecognizerOpenSpotify => 'Spotify';

  @override
  String get songRecognizerApiKey => 'AudD API token';

  @override
  String get songRecognizerApiKeyHelp =>
      'For accurate, quota-backed recognition, create a token at audd.io and paste it here. Empty uses the public “test” token (very limited).';

  @override
  String get songRecognizerSave => 'Save';

  @override
  String get songRecognizerMicDenied => 'Microphone permission is required';

  @override
  String get songRecognizerWebUnsupported =>
      'Song recognition is not available in this browser build.';

  @override
  String get songRecognizerAccuracyTip =>
      'Tip: 10–12s samples, 44.1kHz; minimize background noise for best results.';

  @override
  String get songRecognizerDuplicateSkipped =>
      'Same as recent result—skipped log';

  @override
  String get songRecognizerError => 'Recognition failed';

  @override
  String get songRecognizerAmbientActive => 'Ambient listening on';

  @override
  String get songRecognizerTokenMenu => 'API token';

  @override
  String get songRecognizerCredentialsMenu => 'Recognition credentials';

  @override
  String get songRecognizerProviderLabel => 'Recognition service';

  @override
  String get songRecognizerProviderAudd => 'AudD';

  @override
  String get songRecognizerProviderAcrcloud => 'ACRCloud';

  @override
  String get songRecognizerModeLabel => 'Capture mode';

  @override
  String get songRecognizerAcrTitle => 'ACRCloud project';

  @override
  String get songRecognizerAcrHelp =>
      'Enter the host and keys from your ACRCloud console (Audio / Video recognition project). Host example: identify-eu-west-1.acrcloud.com — do not include https:// or paths.';

  @override
  String get songRecognizerAcrHost => 'Host';

  @override
  String get songRecognizerAcrHostHint => 'identify-…​.acrcloud.com';

  @override
  String get songRecognizerAcrAccessKey => 'Access Key';

  @override
  String get songRecognizerAcrSecret => 'Secret Key';

  @override
  String get songRecognizerAcrIncomplete =>
      'Please fill in and save Host, Access Key, and Secret Key for ACRCloud below before recognizing.';

  @override
  String get songRecognizerSectionApiConfig => 'API credentials';

  @override
  String get songRecognizerConfigHint =>
      'Choose which engine to use on the song ID screen. Enter and save each provider’s credentials on this page.';

  @override
  String get songRecognizerConfigSaved => 'Saved';

  @override
  String get songRecognizerAuddCardSubtitle =>
      'Token from audd.io — optional; empty uses limited public test quota.';

  @override
  String get songRecognizerAcrCardTitle => 'ACRCloud';

  @override
  String get songRecognizerAcrCardSubtitle =>
      'Host, Access Key, Secret Key from your ACRCloud console.';

  @override
  String get songRecognizerOpenApiConfigSubtitle =>
      'AudD token & ACRCloud Host / keys';

  @override
  String get songRecognizerMatchConfirmTitle => 'Is this the right song?';

  @override
  String get songRecognizerMatchConfirmArtistLabel => 'Artist';

  @override
  String get songRecognizerMatchConfirmAlbumLabel => 'Album';

  @override
  String get songRecognizerMatchConfirmReleaseLabel => 'Released';

  @override
  String get songRecognizerMatchConfirmYes => 'Yes, that’s the one';

  @override
  String get songRecognizerMatchConfirmNo => 'No, try again';
}
