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
  String get menuPlaylists => 'Playlists';

  @override
  String get menuMusicSource => 'Media folders';

  @override
  String get menuSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBackgroundTheme => 'Background & theme';

  @override
  String get settingsBackgroundThemeDesc =>
      'Solid color, custom color, or image';

  @override
  String get settingsSystemInfo => 'System information';

  @override
  String get settingsSystemInfoDesc => 'Device and storage';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutDesc => 'App info, version, licenses';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc => 'Interface language';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveDesc =>
      'Sign in and set music root; files cache locally for playback';

  @override
  String get settingsMacosMenuBarLyrics => 'Menu bar lyrics';

  @override
  String get settingsMacosMenuBarLyricsDesc =>
      'Single line in the macOS menu bar (compact)';

  @override
  String get settingsDesktopLyricsGroupTitle => 'Desktop lyrics';

  @override
  String get settingsDesktopLyricsGroupSubtitle =>
      'Floating overlay and optional menu bar on macOS.';

  @override
  String get settingsDesktopFloatingLyrics => 'Floating lyrics';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      'Draggable line over the app; follows lyric display settings on the now playing screen.';

  @override
  String get settingsDesktopFloatingBgOpacity => 'Background opacity';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      'Panel fill behind lyrics. 0 means fully transparent (text only).';

  @override
  String get settingsDesktopFloatingLinesBefore => 'Lines before current';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      'How many timed lines to show above the active line.';

  @override
  String get settingsDesktopFloatingLinesAfter => 'Lines after current';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      'How many timed lines to show below the active line.';

  @override
  String get settingsDesktopFloatingDragLock => 'Lock position';

  @override
  String get settingsDesktopFloatingDragLockDesc =>
      'When on, the floating window cannot be dragged.';

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
  String get oneDriveClientIdLabel => 'Application (client) ID';

  @override
  String get oneDriveClientIdHint => 'From Azure Portal → your app → Overview';

  @override
  String get oneDriveMusicRootIdLabel => 'Music root folder (optional)';

  @override
  String get oneDriveMusicRootHint =>
      'OneDrive item id, or leave empty for drive root. Children of this folder are shown first.';

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
      'OneDrive sign-in is not available on this platform yet.';

  @override
  String get oneDriveNeedClientId =>
      'Set the Azure application client ID first.';

  @override
  String get oneDriveSignInFailed =>
      'Couldn\'t sign in. Check the client ID, redirect URI in Azure, and try again.';

  @override
  String get oneDriveAzureRedirectIntro =>
      'If you see redirect_uri invalid: Azure Portal → your app registration → Authentication → Add a platform → Mobile and desktop applications (not SPA or Web) → paste the URI below into Custom redirect URIs. It must match character-for-character.';

  @override
  String get oneDriveRedirectCopyTooltip => 'Copy redirect URI';

  @override
  String get oneDriveRedirectCopied => 'Redirect URI copied';

  @override
  String get oneDriveCacheNote =>
      'Audio is cached under the app data folder when you play.';

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
  String oneDriveError(String message) {
    return 'OneDrive error: $message';
  }

  @override
  String get oneDriveUp => 'Up';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · Cloud library';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      'Folders you add are scanned recursively. Tap a song to download on demand; played files stay cached offline.';

  @override
  String get oneDriveCloudLibraryEmpty =>
      'No tracks indexed yet.\nTap “Choose folders”, pick one or more music folders in OneDrive, then “Rescan”.';

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
  String get actionSelect => 'Select';

  @override
  String get fogBackground => 'Background blur & dim';

  @override
  String get fogBackgroundDesc =>
      'Blur and dim the image so text and icons stay readable. Default 45%.';

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
  String get homeMenuTooltip => 'Menu';

  @override
  String get homeSearchTooltip => 'Search';

  @override
  String get homeQuickEntryEmpty =>
      'No shortcuts. Tap “Manage” to show library, playlists, and more.';

  @override
  String get homeEntryLibrary => 'Library';

  @override
  String get homeEntryMyPlaylists => 'My playlists';

  @override
  String get homeEntryRecent => 'Recent';

  @override
  String get homeEntryDiscover => 'Discover';

  @override
  String get homeEntryCloudLibrary => 'Cloud library';

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
  String get tooltipDone => 'Done';

  @override
  String get tooltipMoreActions => 'Actions';

  @override
  String get tooltipMore => 'More';

  @override
  String get tooltipLyricStyle => 'Lyric style';

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
  String get fabNewPlaylist => 'New playlist';

  @override
  String get emptyPlaylistsHint =>
      'No playlists yet.\nAdd songs from the player or song lists to playlists.\n\nUse the top-right menu to import/export and multi-select.';

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
  String get lyricColorPickerHint => 'Tap a swatch';

  @override
  String get lyricLabelOriginal => 'Original';

  @override
  String get lyricLabelTranslation => 'Translation';
}
