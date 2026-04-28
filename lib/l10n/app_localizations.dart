import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yeah Music'**
  String get appTitle;

  /// No description provided for @menuHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menuHome;

  /// No description provided for @menuSongList.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get menuSongList;

  /// No description provided for @menuPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get menuPlaylists;

  /// No description provided for @menuMusicSource.
  ///
  /// In en, this message translates to:
  /// **'Media folders'**
  String get menuMusicSource;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBackgroundTheme.
  ///
  /// In en, this message translates to:
  /// **'Background & theme'**
  String get settingsBackgroundTheme;

  /// No description provided for @settingsBackgroundThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solid color, custom color, or wallpaper'**
  String get settingsBackgroundThemeSubtitle;

  /// No description provided for @settingsBackgroundThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a solid color, pick a custom accent, or set a full-screen background image. Options are adjusted on the next screen.'**
  String get settingsBackgroundThemeDesc;

  /// No description provided for @settingsSystemInfo.
  ///
  /// In en, this message translates to:
  /// **'System information'**
  String get settingsSystemInfo;

  /// No description provided for @settingsSystemInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device and storage space'**
  String get settingsSystemInfoSubtitle;

  /// No description provided for @settingsSystemInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'View device-related details and how much disk space is available. Expanded section shows a per-folder breakdown.'**
  String get settingsSystemInfoDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, credits, licenses'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'App name and version, acknowledgements, and open-source license texts.'**
  String get settingsAboutDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used for menus, settings, and in-app messages. Some content still follows track metadata language.'**
  String get settingsLanguageDesc;

  /// No description provided for @settingsOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get settingsOneDrive;

  /// No description provided for @settingsOneDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in, music folder, local cache'**
  String get settingsOneDriveSubtitle;

  /// No description provided for @settingsOneDriveDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Microsoft, choose your music root on OneDrive, and browse files. Audio is cached locally while playing so playback stays smooth offline after first load.'**
  String get settingsOneDriveDesc;

  /// No description provided for @settingsPlaybackShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsPlaybackShortcutsTitle;

  /// No description provided for @settingsPlaybackShortcutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play, pause, previous, and next track'**
  String get settingsPlaybackShortcutsSubtitle;

  /// No description provided for @settingsPlaybackShortcutsPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get settingsPlaybackShortcutsPlayPause;

  /// No description provided for @settingsPlaybackShortcutsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get settingsPlaybackShortcutsPrevious;

  /// No description provided for @settingsPlaybackShortcutsNext.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get settingsPlaybackShortcutsNext;

  /// No description provided for @settingsPlaybackShortcutsChange.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get settingsPlaybackShortcutsChange;

  /// No description provided for @settingsPlaybackShortcutsDisable.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsPlaybackShortcutsDisable;

  /// No description provided for @settingsPlaybackShortcutsEnable.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsPlaybackShortcutsEnable;

  /// No description provided for @settingsPlaybackShortcutsDisabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsPlaybackShortcutsDisabledLabel;

  /// No description provided for @settingsPlaybackShortcutsPressKey.
  ///
  /// In en, this message translates to:
  /// **'New shortcut'**
  String get settingsPlaybackShortcutsPressKey;

  /// No description provided for @settingsPlaybackShortcutsPressKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Press the key combination to use. Esc cancels.'**
  String get settingsPlaybackShortcutsPressKeyHint;

  /// No description provided for @settingsMacosMenuBarLyrics.
  ///
  /// In en, this message translates to:
  /// **'Menu bar lyrics'**
  String get settingsMacosMenuBarLyrics;

  /// No description provided for @settingsMacosMenuBarLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compact line in the menu bar'**
  String get settingsMacosMenuBarLyricsSubtitle;

  /// No description provided for @settingsMacosMenuBarLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Single line in the macOS menu bar (compact)'**
  String get settingsMacosMenuBarLyricsDesc;

  /// No description provided for @settingsDesktopLyricsGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop lyrics'**
  String get settingsDesktopLyricsGroupTitle;

  /// No description provided for @settingsDesktopLyricsGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Floating line and optional macOS menu bar'**
  String get settingsDesktopLyricsGroupSubtitle;

  /// No description provided for @settingsDesktopLyricsGroupDetail.
  ///
  /// In en, this message translates to:
  /// **'Desktop lyrics include a floating, draggable line above other windows and—on macOS—an optional compact line in the menu bar.\n\nFloating lyrics use the same lyric styling (colors, multi-line mode, translations) as the now playing screen. You can lock the window position, tune background opacity, and choose how many timed lines appear before and after the current line.\n\nMenu bar lyrics (macOS only) show a single compact line; enable the toggle when you want lyrics always visible without the floating window.'**
  String get settingsDesktopLyricsGroupDetail;

  /// No description provided for @settingsDesktopFloatingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Floating lyrics'**
  String get settingsDesktopFloatingLyrics;

  /// No description provided for @settingsDesktopFloatingLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Draggable overlay line'**
  String get settingsDesktopFloatingLyricsSubtitle;

  /// No description provided for @settingsDesktopFloatingLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows the current lyric line in a small window you can drag over other apps. Styling matches the now playing lyric panel.'**
  String get settingsDesktopFloatingLyricsDesc;

  /// No description provided for @settingsDesktopFloatingBgOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background opacity'**
  String get settingsDesktopFloatingBgOpacity;

  /// No description provided for @settingsDesktopFloatingBgOpacitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How solid the panel behind text is'**
  String get settingsDesktopFloatingBgOpacitySubtitle;

  /// No description provided for @settingsDesktopFloatingBgOpacityDesc.
  ///
  /// In en, this message translates to:
  /// **'Panel fill behind lyrics. 0 means fully transparent (text only).'**
  String get settingsDesktopFloatingBgOpacityDesc;

  /// No description provided for @settingsDesktopFloatingLinesBefore.
  ///
  /// In en, this message translates to:
  /// **'Lines before current'**
  String get settingsDesktopFloatingLinesBefore;

  /// No description provided for @settingsDesktopFloatingLinesBeforeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timed lines above the active line'**
  String get settingsDesktopFloatingLinesBeforeSubtitle;

  /// No description provided for @settingsDesktopFloatingLinesBeforeDesc.
  ///
  /// In en, this message translates to:
  /// **'How many timed lines to show above the active line.'**
  String get settingsDesktopFloatingLinesBeforeDesc;

  /// No description provided for @settingsDesktopFloatingLinesAfter.
  ///
  /// In en, this message translates to:
  /// **'Lines after current'**
  String get settingsDesktopFloatingLinesAfter;

  /// No description provided for @settingsDesktopFloatingLinesAfterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timed lines below the active line'**
  String get settingsDesktopFloatingLinesAfterSubtitle;

  /// No description provided for @settingsDesktopFloatingLinesAfterDesc.
  ///
  /// In en, this message translates to:
  /// **'How many timed lines to show below the active line.'**
  String get settingsDesktopFloatingLinesAfterDesc;

  /// No description provided for @settingsDesktopFloatingDragLock.
  ///
  /// In en, this message translates to:
  /// **'Lock position'**
  String get settingsDesktopFloatingDragLock;

  /// No description provided for @settingsDesktopFloatingDragLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable dragging the floating window'**
  String get settingsDesktopFloatingDragLockSubtitle;

  /// No description provided for @settingsDesktopFloatingDragLockDesc.
  ///
  /// In en, this message translates to:
  /// **'When on, the floating window cannot be dragged.'**
  String get settingsDesktopFloatingDragLockDesc;

  /// No description provided for @settingsCarLyricsGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Car & lock screen'**
  String get settingsCarLyricsGroupTitle;

  /// No description provided for @settingsCarLyricsGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Media notification, Bluetooth & Android Auto'**
  String get settingsCarLyricsGroupSubtitle;

  /// No description provided for @settingsCarLyricsGroupDetail.
  ///
  /// In en, this message translates to:
  /// **'Uses the Android media session so lock screen, Bluetooth accessories, and Android Auto can show what is playing and offer transport controls.\n\nEnable: builds a full playback queue in the player so previous/next in the notification and on car units skip real tracks; play/pause and single-track repeat stay aligned with the app where supported.\n\nArtwork: sends embedded cover art to the notification and to head units that display it.\n\nLyrics: periodically updates the media item subtitle with the current lyric line on systems that show it, using the same lyric line rules as elsewhere in the app.\n\nShuffle, play-once, and other modes are still driven from the app; hardware “repeat all/shuffle” may not mirror every in-app mode.'**
  String get settingsCarLyricsGroupDetail;

  /// No description provided for @settingsCarLyricsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable car lyrics'**
  String get settingsCarLyricsEnabled;

  /// No description provided for @settingsCarLyricsEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notification, queue, prev/next'**
  String get settingsCarLyricsEnabledSubtitle;

  /// No description provided for @settingsCarLyricsEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a playback notification with queue, previous/next, play/pause, and repeat (single-loop) aligned with the app.'**
  String get settingsCarLyricsEnabledDesc;

  /// No description provided for @settingsCarLyricsShowCover.
  ///
  /// In en, this message translates to:
  /// **'Show artwork'**
  String get settingsCarLyricsShowCover;

  /// No description provided for @settingsCarLyricsShowCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cover in notification & car display'**
  String get settingsCarLyricsShowCoverSubtitle;

  /// No description provided for @settingsCarLyricsShowCoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Use embedded cover art in the notification and on supported head units.'**
  String get settingsCarLyricsShowCoverDesc;

  /// No description provided for @settingsCarLyricsSyncLyrics.
  ///
  /// In en, this message translates to:
  /// **'Sync current lyric line'**
  String get settingsCarLyricsSyncLyrics;

  /// No description provided for @settingsCarLyricsSyncLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle shows active lyric'**
  String get settingsCarLyricsSyncLyricsSubtitle;

  /// No description provided for @settingsCarLyricsSyncLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Update the subtitle with the active line where the system supports it.'**
  String get settingsCarLyricsSyncLyricsDesc;

  /// No description provided for @settingsCarLyricsOnlyAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'Only configurable on Android. Switches show saved values and are disabled on this device.'**
  String get settingsCarLyricsOnlyAndroidHint;

  /// No description provided for @menuBarLyricsIdle.
  ///
  /// In en, this message translates to:
  /// **'Yeah Music · Not playing'**
  String get menuBarLyricsIdle;

  /// No description provided for @menuBarLyricsNoLyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get menuBarLyricsNoLyrics;

  /// No description provided for @menuBarContextPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get menuBarContextPlay;

  /// No description provided for @menuBarContextPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get menuBarContextPause;

  /// No description provided for @menuBarContextPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous Track'**
  String get menuBarContextPrevious;

  /// No description provided for @menuBarContextNext.
  ///
  /// In en, this message translates to:
  /// **'Next Track'**
  String get menuBarContextNext;

  /// No description provided for @oneDriveSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get oneDriveSettingsTitle;

  /// No description provided for @oneDriveClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Application (client) ID'**
  String get oneDriveClientIdLabel;

  /// No description provided for @oneDriveClientIdHint.
  ///
  /// In en, this message translates to:
  /// **'From Azure Portal → your app → Overview'**
  String get oneDriveClientIdHint;

  /// No description provided for @oneDriveMusicRootIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Music root folder (optional)'**
  String get oneDriveMusicRootIdLabel;

  /// No description provided for @oneDriveMusicRootHint.
  ///
  /// In en, this message translates to:
  /// **'OneDrive item id, or leave empty for drive root. Children of this folder are shown first.'**
  String get oneDriveMusicRootHint;

  /// No description provided for @oneDriveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Microsoft'**
  String get oneDriveSignIn;

  /// No description provided for @oneDriveSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get oneDriveSignOut;

  /// No description provided for @oneDriveSignOutDone.
  ///
  /// In en, this message translates to:
  /// **'Signed out from OneDrive'**
  String get oneDriveSignOutDone;

  /// No description provided for @oneDriveSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get oneDriveSignedIn;

  /// No description provided for @oneDriveNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get oneDriveNotSignedIn;

  /// No description provided for @oneDriveLinuxUnsupported.
  ///
  /// In en, this message translates to:
  /// **'OneDrive sign-in is not available on this platform yet.'**
  String get oneDriveLinuxUnsupported;

  /// No description provided for @oneDriveNeedClientId.
  ///
  /// In en, this message translates to:
  /// **'Set the Azure application client ID first.'**
  String get oneDriveNeedClientId;

  /// No description provided for @oneDriveSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Check the client ID, redirect URI in Azure, and try again.'**
  String get oneDriveSignInFailed;

  /// No description provided for @oneDriveAzureRedirectIntro.
  ///
  /// In en, this message translates to:
  /// **'If you see redirect_uri invalid: Azure Portal → your app registration → Authentication → Add a platform → Mobile and desktop applications (not SPA or Web) → paste the URI below into Custom redirect URIs. It must match character-for-character.'**
  String get oneDriveAzureRedirectIntro;

  /// No description provided for @oneDriveRedirectCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy redirect URI'**
  String get oneDriveRedirectCopyTooltip;

  /// No description provided for @oneDriveRedirectCopied.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI copied'**
  String get oneDriveRedirectCopied;

  /// No description provided for @oneDriveCacheNote.
  ///
  /// In en, this message translates to:
  /// **'Audio is cached under the app data folder when you play.'**
  String get oneDriveCacheNote;

  /// No description provided for @oneDriveOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open OneDrive'**
  String get oneDriveOpenBrowser;

  /// No description provided for @homeEntryOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get homeEntryOneDrive;

  /// No description provided for @oneDriveBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get oneDriveBrowserTitle;

  /// No description provided for @oneDriveEmptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get oneDriveEmptyFolder;

  /// No description provided for @oneDrivePlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all in folder'**
  String get oneDrivePlayAll;

  /// No description provided for @oneDrivePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get oneDrivePreparing;

  /// No description provided for @oneDriveError.
  ///
  /// In en, this message translates to:
  /// **'OneDrive error: {message}'**
  String oneDriveError(String message);

  /// No description provided for @oneDriveUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get oneDriveUp;

  /// No description provided for @oneDriveCloudLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive · Cloud library'**
  String get oneDriveCloudLibraryTitle;

  /// No description provided for @oneDriveCloudLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Folders you add are scanned recursively. Tap a song to download on demand; played files stay cached offline.'**
  String get oneDriveCloudLibrarySubtitle;

  /// No description provided for @oneDriveCloudLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tracks indexed yet.\nTap “Choose folders”, pick one or more music folders in OneDrive, then “Rescan”.'**
  String get oneDriveCloudLibraryEmpty;

  /// No description provided for @oneDriveIndexRootsLabel.
  ///
  /// In en, this message translates to:
  /// **'Indexed folders'**
  String get oneDriveIndexRootsLabel;

  /// No description provided for @oneDriveRescanIndex.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get oneDriveRescanIndex;

  /// No description provided for @oneDriveBrowseFolders.
  ///
  /// In en, this message translates to:
  /// **'Choose folders'**
  String get oneDriveBrowseFolders;

  /// No description provided for @oneDrivePickFolderForIndex.
  ///
  /// In en, this message translates to:
  /// **'Tap a folder’s + icon, or enter a folder and use “Use this folder”.'**
  String get oneDrivePickFolderForIndex;

  /// No description provided for @oneDriveUseCurrentFolder.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get oneDriveUseCurrentFolder;

  /// No description provided for @oneDriveAddFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add folder to cloud library'**
  String get oneDriveAddFolderTooltip;

  /// No description provided for @oneDriveIndexingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Scanning folders…'**
  String get oneDriveIndexingEllipsis;

  /// No description provided for @oneDriveLastIndexed.
  ///
  /// In en, this message translates to:
  /// **'Last scanned: {time}'**
  String oneDriveLastIndexed(String time);

  /// No description provided for @oneDrivePlayAllTracks.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get oneDrivePlayAllTracks;

  /// No description provided for @oneDriveTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String oneDriveTracksCount(int count);

  /// No description provided for @oneDriveCloudSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search file names or paths…'**
  String get oneDriveCloudSearchHint;

  /// No description provided for @oneDriveNoIndexRoots.
  ///
  /// In en, this message translates to:
  /// **'No folders configured. Tap “Choose folders” first.'**
  String get oneDriveNoIndexRoots;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the app interface language. “Follow system” uses your device language when a translation is available.'**
  String get languageSettingsDescription;

  /// No description provided for @langFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get langFollowSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get langJapanese;

  /// No description provided for @langSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get langSimplifiedChinese;

  /// No description provided for @langTraditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get langTraditionalChinese;

  /// No description provided for @themeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme settings'**
  String get themeSettingsTitle;

  /// No description provided for @globalTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get globalTheme;

  /// No description provided for @globalThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use light, dark, or follow the system. Settings are saved on this device.'**
  String get globalThemeDesc;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @sectionThemeType.
  ///
  /// In en, this message translates to:
  /// **'Theme type'**
  String get sectionThemeType;

  /// No description provided for @themeTypeSolid.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get themeTypeSolid;

  /// No description provided for @themeTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get themeTypeCustom;

  /// No description provided for @themeTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Background image'**
  String get themeTypeImage;

  /// No description provided for @sectionPresetColors.
  ///
  /// In en, this message translates to:
  /// **'Preset colors'**
  String get sectionPresetColors;

  /// No description provided for @sectionCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get sectionCustomColor;

  /// No description provided for @sectionBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Background image'**
  String get sectionBackgroundImage;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get secondaryColor;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @fogBackground.
  ///
  /// In en, this message translates to:
  /// **'Background blur & dim'**
  String get fogBackground;

  /// No description provided for @fogBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Blur and dim the image so text and icons stay readable. Default 45%.'**
  String get fogBackgroundDesc;

  /// No description provided for @fogWeak.
  ///
  /// In en, this message translates to:
  /// **'Subtle'**
  String get fogWeak;

  /// No description provided for @fogStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get fogStrong;

  /// No description provided for @actionPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get actionPickImage;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @cannotSaveBackground.
  ///
  /// In en, this message translates to:
  /// **'Could not save the background image. Try again or use another: {error}'**
  String cannotSaveBackground(String error);

  /// No description provided for @colorDialogTitlePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get colorDialogTitlePrimary;

  /// No description provided for @colorDialogTitleSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get colorDialogTitleSecondary;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @startupFailed.
  ///
  /// In en, this message translates to:
  /// **'Startup failed: {error}'**
  String startupFailed(String error);

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Every listen starts here'**
  String get welcomeTagline;

  /// No description provided for @welcomeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get welcomeEnter;

  /// No description provided for @welcomeEnterWait.
  ///
  /// In en, this message translates to:
  /// **'Enter (wait for loading to finish)'**
  String get welcomeEnterWait;

  /// No description provided for @welcomeHintWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Loading is done — tap to enter, or we open automatically.'**
  String get welcomeHintWhenReady;

  /// No description provided for @welcomeHintWhenNotReady.
  ///
  /// In en, this message translates to:
  /// **'Opens automatically once startup completes.'**
  String get welcomeHintWhenNotReady;

  /// No description provided for @welcomePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the app…'**
  String get welcomePreparing;

  /// No description provided for @welcomeCountdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Startup time'**
  String get welcomeCountdownLabel;

  /// No description provided for @welcomeCountdownSubDoneReady.
  ///
  /// In en, this message translates to:
  /// **'Home screen is ready — you can enter'**
  String get welcomeCountdownSubDoneReady;

  /// No description provided for @welcomeStartupSubLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading home resources — auto-enter when done'**
  String get welcomeStartupSubLoading;

  /// No description provided for @secondsUnit.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsUnit;

  /// No description provided for @welcomeNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait; resources are not ready yet.'**
  String get welcomeNotReadyMessage;

  /// No description provided for @welcomeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check storage access or try again later.\n\n{error}'**
  String welcomeLoadError(String error);

  /// No description provided for @welcomeFakeUserSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading user settings'**
  String get welcomeFakeUserSettings;

  /// No description provided for @welcomeFakeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading library'**
  String get welcomeFakeLibrary;

  /// No description provided for @welcomeFakePlaylists.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists'**
  String get welcomeFakePlaylists;

  /// No description provided for @welcomeFakeOther.
  ///
  /// In en, this message translates to:
  /// **'Loading other data'**
  String get welcomeFakeOther;

  /// No description provided for @welcomeFakeFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing initialization'**
  String get welcomeFakeFinishing;

  /// No description provided for @homeGreetingLateNight.
  ///
  /// In en, this message translates to:
  /// **'Still up?'**
  String get homeGreetingLateNight;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTooltip;

  /// No description provided for @homeSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchTooltip;

  /// No description provided for @homeQuickEntryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shortcuts. Tap “Manage” to show library, playlists, and more.'**
  String get homeQuickEntryEmpty;

  /// No description provided for @homeEntryLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get homeEntryLibrary;

  /// No description provided for @homeEntryMyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My playlists'**
  String get homeEntryMyPlaylists;

  /// No description provided for @homeEntryRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeEntryRecent;

  /// No description provided for @homeEntryDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeEntryDiscover;

  /// No description provided for @homeEntryCloudLibrary.
  ///
  /// In en, this message translates to:
  /// **'Cloud library'**
  String get homeEntryCloudLibrary;

  /// No description provided for @homeSectionQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get homeSectionQuickEntry;

  /// No description provided for @homeActionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get homeActionManage;

  /// No description provided for @homeSectionMyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My playlists'**
  String get homeSectionMyPlaylists;

  /// No description provided for @homeActionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get homeActionMore;

  /// No description provided for @homeLoadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading library…'**
  String get homeLoadingLibrary;

  /// No description provided for @homeRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent plays. Play a song in the library or a playlist to see it here.'**
  String get homeRecentEmpty;

  /// No description provided for @homeSectionMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Top plays'**
  String get homeSectionMostPlayed;

  /// No description provided for @homeSectionRecentPlays.
  ///
  /// In en, this message translates to:
  /// **'Recent plays'**
  String get homeSectionRecentPlays;

  /// No description provided for @homeActionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeActionAll;

  /// No description provided for @homeMostPlayedPathMismatch.
  ///
  /// In en, this message translates to:
  /// **'Play counts no longer match the library. Rescan your music folder if files moved, then play a few more times.'**
  String get homeMostPlayedPathMismatch;

  /// No description provided for @homeMostPlayedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No play stats yet. Play more songs in the library or a playlist to build a top list.'**
  String get homeMostPlayedEmpty;

  /// No description provided for @homePlayCount.
  ///
  /// In en, this message translates to:
  /// **'Played {c} times'**
  String homePlayCount(int c);

  /// No description provided for @homePlayCountWithBase.
  ///
  /// In en, this message translates to:
  /// **'{base} · Played {c} times'**
  String homePlayCountWithBase(String base, int c);

  /// No description provided for @homeGreetingLine.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, what would you like to listen to today?'**
  String homeGreetingLine(String greeting);

  /// No description provided for @homeGreetingSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up below or start from a playlist.'**
  String get homeGreetingSub;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, playlists'**
  String get homeSearchHint;

  /// No description provided for @homeContinuePlaying.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinuePlaying;

  /// No description provided for @homeUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get homeUnknownTitle;

  /// No description provided for @homeNowPlayingAlbum.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get homeNowPlayingAlbum;

  /// No description provided for @homeNothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get homeNothingPlaying;

  /// No description provided for @homeOpenLibraryToPlay.
  ///
  /// In en, this message translates to:
  /// **'Open the library and pick a song'**
  String get homeOpenLibraryToPlay;

  /// No description provided for @homeAllSongsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get homeAllSongsLoading;

  /// No description provided for @homeScanMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Scan a music folder'**
  String get homeScanMusicFolder;

  /// No description provided for @homeTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{n} songs'**
  String homeTrackCount(int n);

  /// No description provided for @homeAllSongs.
  ///
  /// In en, this message translates to:
  /// **'All songs'**
  String get homeAllSongs;

  /// No description provided for @homeCreatePlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get homeCreatePlaylist;

  /// No description provided for @homeCreatePlaylistSub.
  ///
  /// In en, this message translates to:
  /// **'Collect the songs you love'**
  String get homeCreatePlaylistSub;

  /// No description provided for @homeEmptyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get homeEmptyPlaylist;

  /// No description provided for @songsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No songs in the library'**
  String get songsListEmpty;

  /// No description provided for @tooltipSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get tooltipSort;

  /// No description provided for @languageRestartNotice.
  ///
  /// In en, this message translates to:
  /// **'You may need to restart the app for all interface text to update.'**
  String get languageRestartNotice;

  /// No description provided for @locateNotInList.
  ///
  /// In en, this message translates to:
  /// **'The playing track is not in this list'**
  String get locateNotInList;

  /// No description provided for @locateToCurrent.
  ///
  /// In en, this message translates to:
  /// **'Scroll to now playing'**
  String get locateToCurrent;

  /// No description provided for @locateToCurrentPlaying.
  ///
  /// In en, this message translates to:
  /// **'Show the playing track'**
  String get locateToCurrentPlaying;

  /// No description provided for @locateToLyricLine.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the current line'**
  String get locateToLyricLine;

  /// No description provided for @tooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tooltipBack;

  /// No description provided for @tooltipAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get tooltipAddToPlaylist;

  /// No description provided for @tooltipDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tooltipDone;

  /// No description provided for @tooltipMoreActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get tooltipMoreActions;

  /// No description provided for @tooltipMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tooltipMore;

  /// No description provided for @tooltipLyricStyle.
  ///
  /// In en, this message translates to:
  /// **'Lyric style'**
  String get tooltipLyricStyle;

  /// No description provided for @tooltipFolderInfo.
  ///
  /// In en, this message translates to:
  /// **'Folder details'**
  String get tooltipFolderInfo;

  /// No description provided for @tooltipReloadSongs.
  ///
  /// In en, this message translates to:
  /// **'Rescan folder'**
  String get tooltipReloadSongs;

  /// No description provided for @tooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltipEdit;

  /// No description provided for @tooltipRemoveFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove folder'**
  String get tooltipRemoveFolder;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// No description provided for @actionOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOK;

  /// No description provided for @settingsRowHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get settingsRowHelpTooltip;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldNewNameHint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get fieldNewNameHint;

  /// No description provided for @folderAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folderAppBarTitle;

  /// No description provided for @folderSongsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} songs'**
  String folderSongsCount(int n);

  /// No description provided for @folderInfoAlias.
  ///
  /// In en, this message translates to:
  /// **'Alias:'**
  String get folderInfoAlias;

  /// No description provided for @folderInfoPath.
  ///
  /// In en, this message translates to:
  /// **'Path:'**
  String get folderInfoPath;

  /// No description provided for @folderInfoSongCount.
  ///
  /// In en, this message translates to:
  /// **'Songs:'**
  String get folderInfoSongCount;

  /// No description provided for @folderInfoAdded.
  ///
  /// In en, this message translates to:
  /// **'Added:'**
  String get folderInfoAdded;

  /// No description provided for @folderAddLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading songs'**
  String get folderAddLoadingTitle;

  /// No description provided for @folderReloading.
  ///
  /// In en, this message translates to:
  /// **'Rescanning'**
  String get folderReloading;

  /// No description provided for @folderScanningWait.
  ///
  /// In en, this message translates to:
  /// **'Scanning folders…'**
  String get folderScanningWait;

  /// No description provided for @folderLoadOk.
  ///
  /// In en, this message translates to:
  /// **'Loaded {n} songs'**
  String folderLoadOk(int n);

  /// No description provided for @folderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String folderLoadFailed(String error);

  /// No description provided for @folderRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this folder?'**
  String get folderRemoveTitle;

  /// No description provided for @folderRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the library? Music files on disk are not deleted.'**
  String folderRemoveMessage(String name);

  /// No description provided for @folderDuplicateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get folderDuplicateDialogTitle;

  /// No description provided for @folderDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'This folder was already added: {path}'**
  String folderDuplicateMessage(String path);

  /// No description provided for @folderAddOk.
  ///
  /// In en, this message translates to:
  /// **'Added {n} songs'**
  String folderAddOk(int n);

  /// No description provided for @folderAddErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get folderAddErrorTitle;

  /// No description provided for @folderAddErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not add folder: {error}'**
  String folderAddErrorMessage(String error);

  /// No description provided for @folderAddNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No folder was selected.'**
  String get folderAddNoSelection;

  /// No description provided for @folderRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get folderRenameDialogTitle;

  /// No description provided for @playlistPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistPageTitle;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// No description provided for @playlistNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get playlistNotFoundMessage;

  /// No description provided for @playlistEmptyNoSongs.
  ///
  /// In en, this message translates to:
  /// **'No playable songs. Scan a media folder or some paths may be missing.'**
  String get playlistEmptyNoSongs;

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get playlistDeleteTitle;

  /// No description provided for @playlistDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this playlist? References will be lost; music files on disk are not removed.'**
  String get playlistDeleteMessage;

  /// No description provided for @playlistDeleteBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete multiple playlists'**
  String get playlistDeleteBatchTitle;

  /// No description provided for @playlistDeleteBatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the {n} selected playlists? References will be lost; music files on disk are not removed.'**
  String playlistDeleteBatchMessage(int n);

  /// No description provided for @playlistDeletedOne.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeletedOne;

  /// No description provided for @importDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Songs are identified by full file path: same title and artist but different files or quality map to different paths and will not be merged by mistake.\n\n• Merge import: playlists with the same id as local ones merge track lists (paths deduplicated); playlists only in the backup are created.\n• Replace all: clears all local playlists first, then restores from the backup (use with care).'**
  String get importDialogBody;

  /// No description provided for @playlistCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String playlistCreatedOn(String date);

  /// No description provided for @recentPlaysEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No play history'**
  String get recentPlaysEmptyTitle;

  /// No description provided for @quickEntryReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder. Turn off “Show on home” to hide an entry from the home screen.'**
  String get quickEntryReorderHint;

  /// No description provided for @quickEntryShowOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show on home'**
  String get quickEntryShowOnHome;

  /// No description provided for @playlistSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, or file names…'**
  String get playlistSearchHint;

  /// No description provided for @searchNoMatchingSongs.
  ///
  /// In en, this message translates to:
  /// **'No matching songs'**
  String get searchNoMatchingSongs;

  /// No description provided for @playlistRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get playlistRenameTitle;

  /// No description provided for @exportCannot.
  ///
  /// In en, this message translates to:
  /// **'This playlist cannot be exported'**
  String get exportCannot;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Exported: {path}'**
  String exportSaved(String path);

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @exportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export playlist'**
  String get exportDialogTitle;

  /// No description provided for @menuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get menuRename;

  /// No description provided for @menuExportThis.
  ///
  /// In en, this message translates to:
  /// **'Export this playlist…'**
  String get menuExportThis;

  /// No description provided for @menuDeletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get menuDeletePlaylist;

  /// No description provided for @exportSelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Select playlists to export first'**
  String get exportSelectFirst;

  /// No description provided for @exportNoneToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export; check the selection'**
  String get exportNoneToExport;

  /// No description provided for @exportAllPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Export all playlists'**
  String get exportAllPlaylists;

  /// No description provided for @exportSelectedPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Export selected playlists'**
  String get exportSelectedPlaylists;

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get exportSelected;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all'**
  String get exportAll;

  /// No description provided for @importCannotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file (try a smaller backup or check permissions)'**
  String get importCannotRead;

  /// No description provided for @importParseError.
  ///
  /// In en, this message translates to:
  /// **'Could not parse: {message}'**
  String importParseError(String message);

  /// No description provided for @importMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge import'**
  String get importMerge;

  /// No description provided for @importReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get importReplaceAll;

  /// No description provided for @importMerged.
  ///
  /// In en, this message translates to:
  /// **'Imported (merged)'**
  String get importMerged;

  /// No description provided for @importReplaced.
  ///
  /// In en, this message translates to:
  /// **'Imported (replaced)'**
  String get importReplaced;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @playlistsDeletedN.
  ///
  /// In en, this message translates to:
  /// **'Deleted {n} playlist(s)'**
  String playlistsDeletedN(int n);

  /// No description provided for @fabNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get fabNewPlaylist;

  /// No description provided for @emptyPlaylistsHint.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet.\nAdd songs from the player or song lists to playlists.\n\nUse the top-right menu to import/export and multi-select.'**
  String get emptyPlaylistsHint;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @sortByPath.
  ///
  /// In en, this message translates to:
  /// **'By path'**
  String get sortByPath;

  /// No description provided for @sortByCreated.
  ///
  /// In en, this message translates to:
  /// **'By date created'**
  String get sortByCreated;

  /// No description provided for @sortByUpdated.
  ///
  /// In en, this message translates to:
  /// **'By date updated'**
  String get sortByUpdated;

  /// No description provided for @sortByAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'By time added to playlist'**
  String get sortByAddedToPlaylist;

  /// No description provided for @sortByAddedToPlaylistSub.
  ///
  /// In en, this message translates to:
  /// **'Ascending: oldest first · Descending: newest first'**
  String get sortByAddedToPlaylistSub;

  /// No description provided for @lyricAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get lyricAlignLeft;

  /// No description provided for @lyricAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get lyricAlignCenter;

  /// No description provided for @lyricAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get lyricAlignRight;

  /// No description provided for @addToPlaylistHint.
  ///
  /// In en, this message translates to:
  /// **'New playlist name'**
  String get addToPlaylistHint;

  /// No description provided for @addToPlaylistUpdatedN.
  ///
  /// In en, this message translates to:
  /// **'Updated {n} playlist(s)'**
  String addToPlaylistUpdatedN(int n);

  /// No description provided for @noLyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get noLyrics;

  /// No description provided for @songNotFound.
  ///
  /// In en, this message translates to:
  /// **'Song not found'**
  String get songNotFound;

  /// No description provided for @pageUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown title'**
  String get pageUnknownTitle;

  /// No description provided for @queueNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks in queue'**
  String get queueNoTracks;

  /// No description provided for @playQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Play queue'**
  String get playQueueTitle;

  /// No description provided for @playbackModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback mode'**
  String get playbackModeTitle;

  /// No description provided for @playbackSequential.
  ///
  /// In en, this message translates to:
  /// **'Play in order'**
  String get playbackSequential;

  /// No description provided for @playbackShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playbackShuffle;

  /// No description provided for @playbackSingleLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get playbackSingleLoop;

  /// No description provided for @playbackOnce.
  ///
  /// In en, this message translates to:
  /// **'Play once and stop'**
  String get playbackOnce;

  /// No description provided for @playbackTimer.
  ///
  /// In en, this message translates to:
  /// **'Stop after timer'**
  String get playbackTimer;

  /// No description provided for @sleepTimerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop playback later'**
  String get sleepTimerSheetTitle;

  /// No description provided for @sleepTimerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel sleep timer'**
  String get sleepTimerCancel;

  /// No description provided for @sleepTimerMinutesN.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String sleepTimerMinutesN(int n);

  /// No description provided for @sleepTimerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get sleepTimerCustom;

  /// No description provided for @sleepTimerCurrentN.
  ///
  /// In en, this message translates to:
  /// **'Current: {n} min'**
  String sleepTimerCurrentN(int n);

  /// No description provided for @sleepTimerLabelMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepTimerLabelMinutes;

  /// No description provided for @sleepTimerInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number between {min} and {max}.'**
  String sleepTimerInvalidRange(int min, int max);

  /// No description provided for @sleepTimerPlayedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer: played for {minutes} min'**
  String sleepTimerPlayedMinutes(int minutes);

  /// No description provided for @lyricModeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Change display mode'**
  String get lyricModeEmptyHint;

  /// No description provided for @lyricModeAllLines.
  ///
  /// In en, this message translates to:
  /// **'Multi-line: all lines (tap for single line)'**
  String get lyricModeAllLines;

  /// No description provided for @lyricModeSingleLineN.
  ///
  /// In en, this message translates to:
  /// **'Multi-line: line {n} only (tap to cycle)'**
  String lyricModeSingleLineN(int n);

  /// No description provided for @sortOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortOptionsTitle;

  /// No description provided for @addToPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist · {name}'**
  String addToPlaylistTitle(String name);

  /// No description provided for @addToPlaylistMultiHelp.
  ///
  /// In en, this message translates to:
  /// **'Select multiple. Uncheck to remove the song from a playlist.'**
  String get addToPlaylistMultiHelp;

  /// No description provided for @addToPlaylistNoPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Type a name above to create one.'**
  String get addToPlaylistNoPlaylistsYet;

  /// No description provided for @quickEntrySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get quickEntrySettingsTitle;

  /// No description provided for @playlistSelectModeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single select'**
  String get playlistSelectModeSingle;

  /// No description provided for @playlistSelectModeMulti.
  ///
  /// In en, this message translates to:
  /// **'Multi select'**
  String get playlistSelectModeMulti;

  /// No description provided for @menuImportPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Import playlists'**
  String get menuImportPlaylists;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @playlistSelectCount.
  ///
  /// In en, this message translates to:
  /// **'{n} of {m} selected'**
  String playlistSelectCount(int n, int m);

  /// No description provided for @lyricStyleSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same as the lyrics on the now playing screen'**
  String get lyricStyleSyncSubtitle;

  /// No description provided for @lyricStyleSectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get lyricStyleSectionDisplay;

  /// No description provided for @lyricStyleSectionDisplaySub.
  ///
  /// In en, this message translates to:
  /// **'Original and extra translation lines'**
  String get lyricStyleSectionDisplaySub;

  /// No description provided for @lyricStyleShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get lyricStyleShowOriginal;

  /// No description provided for @lyricStyleShowOriginalSub.
  ///
  /// In en, this message translates to:
  /// **'First line of each timestamp'**
  String get lyricStyleShowOriginalSub;

  /// No description provided for @lyricStyleShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation / extra lines'**
  String get lyricStyleShowTranslation;

  /// No description provided for @lyricStyleShowTranslationSub.
  ///
  /// In en, this message translates to:
  /// **'Second line and below'**
  String get lyricStyleShowTranslationSub;

  /// No description provided for @lyricStyleSectionTypography.
  ///
  /// In en, this message translates to:
  /// **'Size & line spacing'**
  String get lyricStyleSectionTypography;

  /// No description provided for @lyricStyleSectionTypographySub.
  ///
  /// In en, this message translates to:
  /// **'Adjust with sliders; applies immediately'**
  String get lyricStyleSectionTypographySub;

  /// No description provided for @lyricStyleFontOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original font size'**
  String get lyricStyleFontOriginal;

  /// No description provided for @lyricStyleFontTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation font size'**
  String get lyricStyleFontTranslation;

  /// No description provided for @lyricStyleLineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lyricStyleLineSpacing;

  /// No description provided for @lyricStyleSectionLineAlign.
  ///
  /// In en, this message translates to:
  /// **'Line alignment'**
  String get lyricStyleSectionLineAlign;

  /// No description provided for @lyricStyleSectionStateColors.
  ///
  /// In en, this message translates to:
  /// **'Line state colors'**
  String get lyricStyleSectionStateColors;

  /// No description provided for @lyricStyleSectionStateColorsSub.
  ///
  /// In en, this message translates to:
  /// **'Now playing, played, not yet'**
  String get lyricStyleSectionStateColorsSub;

  /// No description provided for @lyricStyleStateNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Current line'**
  String get lyricStyleStateNowPlaying;

  /// No description provided for @lyricStyleStatePlayed.
  ///
  /// In en, this message translates to:
  /// **'Past lines'**
  String get lyricStyleStatePlayed;

  /// No description provided for @lyricStyleStateUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming lines'**
  String get lyricStyleStateUpcoming;

  /// No description provided for @lyricStyleColorNowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Now playing — original'**
  String get lyricStyleColorNowOriginal;

  /// No description provided for @lyricStyleColorNowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Now playing — translation'**
  String get lyricStyleColorNowTranslation;

  /// No description provided for @lyricStyleColorPlayedOriginal.
  ///
  /// In en, this message translates to:
  /// **'Played — original'**
  String get lyricStyleColorPlayedOriginal;

  /// No description provided for @lyricStyleColorPlayedTranslation.
  ///
  /// In en, this message translates to:
  /// **'Played — translation'**
  String get lyricStyleColorPlayedTranslation;

  /// No description provided for @lyricStyleColorUpcomingOriginal.
  ///
  /// In en, this message translates to:
  /// **'Upcoming — original'**
  String get lyricStyleColorUpcomingOriginal;

  /// No description provided for @lyricStyleColorUpcomingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Upcoming — translation'**
  String get lyricStyleColorUpcomingTranslation;

  /// No description provided for @lyricStyleColorPersistNote.
  ///
  /// In en, this message translates to:
  /// **'Colors are saved locally and kept after you change tracks.'**
  String get lyricStyleColorPersistNote;

  /// No description provided for @lyricColorPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a swatch'**
  String get lyricColorPickerHint;

  /// No description provided for @lyricLabelOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get lyricLabelOriginal;

  /// No description provided for @lyricLabelTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get lyricLabelTranslation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
