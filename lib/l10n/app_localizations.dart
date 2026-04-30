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

  /// No description provided for @menuStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get menuStatistics;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @statisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overview of your library, listening activity, and playlists'**
  String get statisticsSubtitle;

  /// No description provided for @statisticsReloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get statisticsReloadTooltip;

  /// No description provided for @statisticsReloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Refreshing playback statistics…'**
  String get statisticsReloadStarted;

  /// No description provided for @statisticsReloadDone.
  ///
  /// In en, this message translates to:
  /// **'Playback statistics updated.'**
  String get statisticsReloadDone;

  /// No description provided for @statisticsReloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh playback statistics.'**
  String get statisticsReloadFailed;

  /// No description provided for @statisticsSectionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get statisticsSectionLibrary;

  /// No description provided for @statisticsSectionPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get statisticsSectionPlayback;

  /// No description provided for @statisticsSectionPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get statisticsSectionPlaylists;

  /// No description provided for @statisticsSectionOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get statisticsSectionOneDrive;

  /// No description provided for @statisticsTracksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get statisticsTracksLabel;

  /// No description provided for @statisticsFoldersLabel.
  ///
  /// In en, this message translates to:
  /// **'Media folders'**
  String get statisticsFoldersLabel;

  /// No description provided for @statisticsDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get statisticsDurationLabel;

  /// No description provided for @statisticsDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Sum of durations where metadata is available'**
  String get statisticsDurationHint;

  /// No description provided for @statisticsFormatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Formats'**
  String get statisticsFormatsLabel;

  /// No description provided for @statisticsFormatsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get statisticsFormatsOther;

  /// No description provided for @statisticsFormatsMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more types'**
  String statisticsFormatsMore(int count);

  /// No description provided for @statisticsQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio quality'**
  String get statisticsQualityLabel;

  /// No description provided for @statisticsQualityHint.
  ///
  /// In en, this message translates to:
  /// **'Same tiers as library badges: format, bitrate, and sample rate when tags allow classification.'**
  String get statisticsQualityHint;

  /// No description provided for @statisticsQualityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statisticsQualityUnknown;

  /// No description provided for @statisticsHistoricalListeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening time'**
  String get statisticsHistoricalListeningLabel;

  /// No description provided for @statisticsHistoricalListeningHint.
  ///
  /// In en, this message translates to:
  /// **'Wall-clock time while playback is active (paused time excluded). Total does not scale with playback speed. Stored from this version onward; force-quitting may lose a few seconds not yet flushed (~8s batches).'**
  String get statisticsHistoricalListeningHint;

  /// No description provided for @statisticsPlaybackTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total listens'**
  String get statisticsPlaybackTotalLabel;

  /// No description provided for @statisticsPlaybackTotalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stored play starts—each time playback begins counts once.'**
  String get statisticsPlaybackTotalSubtitle;

  /// No description provided for @statisticsPlaybackDistinctLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracks with play history'**
  String get statisticsPlaybackDistinctLabel;

  /// No description provided for @statisticsRecentEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent plays entries'**
  String get statisticsRecentEntriesLabel;

  /// No description provided for @statisticsRecentEntriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} paths kept locally'**
  String statisticsRecentEntriesSubtitle(int max);

  /// No description provided for @statisticsPlaylistsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get statisticsPlaylistsCountLabel;

  /// No description provided for @statisticsPlaylistRefsLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist entries'**
  String get statisticsPlaylistRefsLabel;

  /// No description provided for @statisticsPlaylistRefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paths across playlists; duplicates count separately'**
  String get statisticsPlaylistRefsSubtitle;

  /// No description provided for @statisticsOneDriveIndexedLabel.
  ///
  /// In en, this message translates to:
  /// **'Cloud library tracks'**
  String get statisticsOneDriveIndexedLabel;

  /// No description provided for @statisticsOneDriveCachedLabel.
  ///
  /// In en, this message translates to:
  /// **'Cached / downloaded locally'**
  String get statisticsOneDriveCachedLabel;

  /// No description provided for @statisticsOneDriveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in for cloud statistics'**
  String get statisticsOneDriveUnavailable;

  /// No description provided for @statisticsNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Initializing library…'**
  String get statisticsNotInitialized;

  /// No description provided for @statisticsDurationHM.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String statisticsDurationHM(int hours, int minutes);

  /// No description provided for @statisticsDurationMOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String statisticsDurationMOnly(int minutes);

  /// No description provided for @statisticsDurationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not estimate'**
  String get statisticsDurationUnknown;

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

  /// No description provided for @settingsAboutDialogAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get settingsAboutDialogAuthor;

  /// No description provided for @settingsAboutDialogRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get settingsAboutDialogRepo;

  /// No description provided for @settingsAboutDialogLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsAboutDialogLicense;

  /// No description provided for @settingsAboutDialogCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get settingsAboutDialogCopyright;

  /// No description provided for @settingsAboutDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsAboutDialogClose;

  /// No description provided for @settingsAboutDialogVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String settingsAboutDialogVersionLabel(String version);

  /// No description provided for @settingsSysinfoSectionDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsSysinfoSectionDevice;

  /// No description provided for @settingsSysinfoSectionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsSysinfoSectionStorage;

  /// No description provided for @settingsSysinfoPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get settingsSysinfoPlatformLabel;

  /// No description provided for @settingsSysinfoTotalSpace.
  ///
  /// In en, this message translates to:
  /// **'Total space'**
  String get settingsSysinfoTotalSpace;

  /// No description provided for @settingsSysinfoUsedSpace.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get settingsSysinfoUsedSpace;

  /// No description provided for @settingsSysinfoFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'Free space'**
  String get settingsSysinfoFreeSpace;

  /// No description provided for @settingsSysinfoStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Storage details are unavailable.'**
  String get settingsSysinfoStorageUnavailable;

  /// No description provided for @settingsSysinfoDeviceModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsSysinfoDeviceModel;

  /// No description provided for @settingsSysinfoManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get settingsSysinfoManufacturer;

  /// No description provided for @settingsSysinfoOsVersion.
  ///
  /// In en, this message translates to:
  /// **'OS version'**
  String get settingsSysinfoOsVersion;

  /// No description provided for @settingsSysinfoSdkVersion.
  ///
  /// In en, this message translates to:
  /// **'SDK version'**
  String get settingsSysinfoSdkVersion;

  /// No description provided for @settingsSysinfoDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get settingsSysinfoDeviceName;

  /// No description provided for @settingsSysinfoHostName.
  ///
  /// In en, this message translates to:
  /// **'Computer name'**
  String get settingsSysinfoHostName;

  /// No description provided for @settingsSysinfoKernelVersion.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get settingsSysinfoKernelVersion;

  /// No description provided for @settingsSysinfoDistroLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsSysinfoDistroLabel;

  /// No description provided for @settingsSysinfoBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get settingsSysinfoBuildNumber;

  /// No description provided for @settingsSysinfoError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get settingsSysinfoError;

  /// No description provided for @settingsSysinfoFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load device information.'**
  String get settingsSysinfoFetchFailed;

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
  /// **'Microsoft account, folders, downloads'**
  String get settingsOneDriveSubtitle;

  /// No description provided for @settingsOneDriveDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Microsoft (no app ID to type in release builds). Pick music and app folders on OneDrive, and optionally a local folder for downloads while playing. If that folder is missing or unset, playback uses the default cache under app data.'**
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

  /// No description provided for @settingsWireRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Headset controls'**
  String get settingsWireRemoteTitle;

  /// No description provided for @settingsWireRemoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wired multi-press and Bluetooth next/prev keys while the app is open'**
  String get settingsWireRemoteSubtitle;

  /// No description provided for @settingsWireRemoteSubtitleOtherPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Customization works on the Android app in the foreground.'**
  String get settingsWireRemoteSubtitleOtherPlatforms;

  /// No description provided for @settingsWireRemoteUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not editable here'**
  String get settingsWireRemoteUnavailableTitle;

  /// No description provided for @settingsWireRemoteUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Headset button mapping applies only on Android when the app is in the foreground (wired multi-press and Bluetooth media keys). On desktop use Keyboard shortcuts; on iOS the system handles headset buttons.'**
  String get settingsWireRemoteUnavailableBody;

  /// No description provided for @settingsWireRemoteUseCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom headset mapping'**
  String get settingsWireRemoteUseCustom;

  /// No description provided for @settingsWireRemoteUseCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, headset buttons use the system default.'**
  String get settingsWireRemoteUseCustomSubtitle;

  /// No description provided for @wireRemoteSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Single press'**
  String get wireRemoteSingleTitle;

  /// No description provided for @wireRemoteDoubleTitle.
  ///
  /// In en, this message translates to:
  /// **'Double press'**
  String get wireRemoteDoubleTitle;

  /// No description provided for @wireRemoteTripleTitle.
  ///
  /// In en, this message translates to:
  /// **'Triple press'**
  String get wireRemoteTripleTitle;

  /// No description provided for @wireRemoteMediaNextTitle.
  ///
  /// In en, this message translates to:
  /// **'\"Next\" media key (Bluetooth, etc.)'**
  String get wireRemoteMediaNextTitle;

  /// No description provided for @wireRemoteMediaPreviousTitle.
  ///
  /// In en, this message translates to:
  /// **'\"Previous\" media key (Bluetooth, etc.)'**
  String get wireRemoteMediaPreviousTitle;

  /// No description provided for @wireRemoteActionPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get wireRemoteActionPlayPause;

  /// No description provided for @wireRemoteActionNext.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get wireRemoteActionNext;

  /// No description provided for @wireRemoteActionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get wireRemoteActionPrevious;

  /// No description provided for @wireRemoteActionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get wireRemoteActionNone;

  /// No description provided for @wireRemotePickActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose action'**
  String get wireRemotePickActionTitle;

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

  /// No description provided for @oneDriveSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get oneDriveSectionAccount;

  /// No description provided for @oneDriveSectionPaths.
  ///
  /// In en, this message translates to:
  /// **'Folders & storage'**
  String get oneDriveSectionPaths;

  /// No description provided for @oneDriveSectionSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get oneDriveSectionSync;

  /// No description provided for @oneDriveSyncMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync to OneDrive'**
  String get oneDriveSyncMasterTitle;

  /// No description provided for @oneDriveSyncMasterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back up playlists and app settings on a schedule. Each upload is saved as timestamped JSON files in your cloud app folder. Scheduled timers will run in a later update.'**
  String get oneDriveSyncMasterSubtitle;

  /// No description provided for @oneDriveSyncItemPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get oneDriveSyncItemPlaylists;

  /// No description provided for @oneDriveSyncItemPlaylistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include playlist data when syncing.'**
  String get oneDriveSyncItemPlaylistsSubtitle;

  /// No description provided for @oneDriveSyncItemSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get oneDriveSyncItemSettings;

  /// No description provided for @oneDriveSyncItemSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, shortcuts, lyrics options, and other preferences.'**
  String get oneDriveSyncItemSettingsSubtitle;

  /// No description provided for @oneDriveSyncFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync frequency'**
  String get oneDriveSyncFrequencyLabel;

  /// No description provided for @oneDriveSyncFreqManual.
  ///
  /// In en, this message translates to:
  /// **'Manual only'**
  String get oneDriveSyncFreqManual;

  /// No description provided for @oneDriveSyncFreq1h.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get oneDriveSyncFreq1h;

  /// No description provided for @oneDriveSyncFreq6h.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get oneDriveSyncFreq6h;

  /// No description provided for @oneDriveSyncFreq12h.
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get oneDriveSyncFreq12h;

  /// No description provided for @oneDriveSyncFreq24h.
  ///
  /// In en, this message translates to:
  /// **'Every 24 hours'**
  String get oneDriveSyncFreq24h;

  /// No description provided for @oneDriveSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get oneDriveSyncNow;

  /// No description provided for @oneDriveSyncNowDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload playlists and settings now. Files are named with the local date and time, for example playlists and settings snapshots from the same moment share the same timestamp.'**
  String get oneDriveSyncNowDescription;

  /// No description provided for @oneDriveSyncNowNeedLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Microsoft first.'**
  String get oneDriveSyncNowNeedLogin;

  /// No description provided for @oneDriveSyncNowNeedCloudFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick a cloud app folder above first, so we know where to put your backup.'**
  String get oneDriveSyncNowNeedCloudFolder;

  /// No description provided for @oneDriveSyncNowFinished.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded as timestamped JSON in your cloud app folder.'**
  String get oneDriveSyncNowFinished;

  /// No description provided for @oneDriveSyncNowFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {message}'**
  String oneDriveSyncNowFailed(String message);

  /// No description provided for @oneDriveRestoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get oneDriveRestoreFromCloud;

  /// No description provided for @oneDriveRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a timestamped backup from your cloud app folder.'**
  String get oneDriveRestoreSubtitle;

  /// No description provided for @oneDriveRestoreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup'**
  String get oneDriveRestoreSheetTitle;

  /// No description provided for @oneDriveRestoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backup files yet. Use “Sync now” to upload first.'**
  String get oneDriveRestoreEmpty;

  /// No description provided for @oneDriveRestorePlaylistCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get oneDriveRestorePlaylistCheckbox;

  /// No description provided for @oneDriveRestoreSettingsCheckbox.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get oneDriveRestoreSettingsCheckbox;

  /// No description provided for @oneDriveRestorePlaylistModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge with local playlists'**
  String get oneDriveRestorePlaylistModeMerge;

  /// No description provided for @oneDriveRestorePlaylistModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace playlists (clear local first)'**
  String get oneDriveRestorePlaylistModeReplace;

  /// No description provided for @oneDriveRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get oneDriveRestoreAction;

  /// No description provided for @oneDriveRestoreNeedPickContent.
  ///
  /// In en, this message translates to:
  /// **'Select at least playlists or settings.'**
  String get oneDriveRestoreNeedPickContent;

  /// No description provided for @oneDriveRestoreMissingPlaylistsFile.
  ///
  /// In en, this message translates to:
  /// **'No playlists file in this backup.'**
  String get oneDriveRestoreMissingPlaylistsFile;

  /// No description provided for @oneDriveRestoreMissingSettingsFile.
  ///
  /// In en, this message translates to:
  /// **'No settings file in this backup.'**
  String get oneDriveRestoreMissingSettingsFile;

  /// No description provided for @oneDriveRestoreFinished.
  ///
  /// In en, this message translates to:
  /// **'Restore completed.'**
  String get oneDriveRestoreFinished;

  /// No description provided for @oneDriveRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {message}'**
  String oneDriveRestoreFailed(String message);

  /// No description provided for @oneDriveRestoreLoadingList.
  ///
  /// In en, this message translates to:
  /// **'Loading backups…'**
  String get oneDriveRestoreLoadingList;

  /// No description provided for @oneDriveSyncNowInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get oneDriveSyncNowInProgress;

  /// No description provided for @oneDriveRestoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get oneDriveRestoreInProgress;

  /// No description provided for @oneDriveCloudAppDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud app folder'**
  String get oneDriveCloudAppDataTitle;

  /// No description provided for @oneDriveCloudAppDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reserved for settings backup, playlists, and sync.'**
  String get oneDriveCloudAppDataSubtitle;

  /// No description provided for @oneDriveCloudAppFolderUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get oneDriveCloudAppFolderUnset;

  /// No description provided for @oneDriveLocalDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Local download folder'**
  String get oneDriveLocalDownloadTitle;

  /// No description provided for @oneDriveLocalDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'While playing from OneDrive, files are saved here if this folder exists. If unset or the path is missing, the app uses its default cache under app data.'**
  String get oneDriveLocalDownloadSubtitle;

  /// No description provided for @oneDriveLocalDownloadUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set — a default will be used later'**
  String get oneDriveLocalDownloadUnset;

  /// No description provided for @oneDriveChooseCloudFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose in OneDrive'**
  String get oneDriveChooseCloudFolder;

  /// No description provided for @oneDriveChooseLocalFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder…'**
  String get oneDriveChooseLocalFolder;

  /// No description provided for @oneDrivePickFolderForAppData.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder for app data and future backups.'**
  String get oneDrivePickFolderForAppData;

  /// No description provided for @oneDrivePickFolderForMusicUpload.
  ///
  /// In en, this message translates to:
  /// **'Pick the folder where uploads from this device should go.'**
  String get oneDrivePickFolderForMusicUpload;

  /// No description provided for @oneDriveMusicUploadFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Music upload folder'**
  String get oneDriveMusicUploadFolderTitle;

  /// No description provided for @oneDriveMusicUploadFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default folder for uploads from this device. If unset, the cloud app folder is used.'**
  String get oneDriveMusicUploadFolderSubtitle;

  /// No description provided for @oneDriveMusicUploadFolderFallback.
  ///
  /// In en, this message translates to:
  /// **'Uses cloud app folder'**
  String get oneDriveMusicUploadFolderFallback;

  /// No description provided for @oneDriveTroubleshootTitle.
  ///
  /// In en, this message translates to:
  /// **'Having trouble signing in?'**
  String get oneDriveTroubleshootTitle;

  /// No description provided for @oneDriveAppMissingClientConfig.
  ///
  /// In en, this message translates to:
  /// **'Microsoft sign-in isn’t available in this copy of the app. Grab the version from the store or check for an update.'**
  String get oneDriveAppMissingClientConfig;

  /// No description provided for @oneDriveNeedSignInForPicker.
  ///
  /// In en, this message translates to:
  /// **'Sign in first to pick a OneDrive folder.'**
  String get oneDriveNeedSignInForPicker;

  /// No description provided for @oneDriveClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get oneDriveClear;

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

  /// No description provided for @oneDriveSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t finish signing in—check your connection and try again, or skim the tips under “Having trouble signing in?”'**
  String get oneDriveSignInFailed;

  /// No description provided for @oneDriveTroubleshootUpload403.
  ///
  /// In en, this message translates to:
  /// **'Upload HTTP 403: In Azure → App registration → API permissions, add Microsoft Graph delegated Files.ReadWrite.All (and grant admin consent if required), then sign out and sign in again in this app.'**
  String get oneDriveTroubleshootUpload403;

  /// No description provided for @oneDriveAzureRedirectIntro.
  ///
  /// In en, this message translates to:
  /// **'Nine times out of ten it’s the network: switch Wi‑Fi, pause VPN for a moment, or update the app. If the page says the link is invalid or you keep bouncing back without finishing, keep the line below—you might need it for your own troubleshooting or if you report the issue somewhere.'**
  String get oneDriveAzureRedirectIntro;

  /// No description provided for @oneDriveAzureRedirectUriCaption.
  ///
  /// In en, this message translates to:
  /// **'Technical link (only for deeper troubleshooting):'**
  String get oneDriveAzureRedirectUriCaption;

  /// No description provided for @oneDriveRedirectCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get oneDriveRedirectCopyTooltip;

  /// No description provided for @oneDriveRedirectCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get oneDriveRedirectCopied;

  /// No description provided for @oneDriveCacheNote.
  ///
  /// In en, this message translates to:
  /// **'Default storage is the private onedrive_cache folder under app data. A custom folder above is used only when it exists.'**
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

  /// No description provided for @oneDriveDownloadQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive downloads'**
  String get oneDriveDownloadQueueTitle;

  /// No description provided for @oneDriveTransferQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive transfers'**
  String get oneDriveTransferQueueTitle;

  /// No description provided for @oneDriveTransferTabDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get oneDriveTransferTabDownload;

  /// No description provided for @oneDriveTransferTabUpload.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get oneDriveTransferTabUpload;

  /// No description provided for @oneDriveDownloadPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get oneDriveDownloadPause;

  /// No description provided for @oneDriveDownloadResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get oneDriveDownloadResume;

  /// No description provided for @oneDriveDownloadStopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get oneDriveDownloadStopAll;

  /// No description provided for @oneDriveDownloadContinueAll.
  ///
  /// In en, this message translates to:
  /// **'Continue all'**
  String get oneDriveDownloadContinueAll;

  /// No description provided for @oneDriveDownloadAutoPlayWhenDone.
  ///
  /// In en, this message translates to:
  /// **'Play automatically when the queue finishes'**
  String get oneDriveDownloadAutoPlayWhenDone;

  /// No description provided for @oneDriveDownloadPlayDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Play downloaded songs'**
  String get oneDriveDownloadPlayDownloaded;

  /// No description provided for @oneDriveDownloadStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get oneDriveDownloadStatusPending;

  /// No description provided for @oneDriveDownloadStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get oneDriveDownloadStatusDownloading;

  /// No description provided for @oneDriveDownloadStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get oneDriveDownloadStatusDone;

  /// No description provided for @oneDriveDownloadStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get oneDriveDownloadStatusFailed;

  /// No description provided for @oneDriveDownloadStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get oneDriveDownloadStatusCancelled;

  /// No description provided for @oneDriveDownloadCloseJustPanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel (downloads continue)'**
  String get oneDriveDownloadCloseJustPanel;

  /// No description provided for @oneDriveDownloadQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No batch download yet.\nUse “Play all” in the cloud library or OneDrive browser — you can close this panel and downloads keep running.'**
  String get oneDriveDownloadQueueEmpty;

  /// No description provided for @oneDriveUploadQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upload tasks yet.\nUse “Upload to OneDrive” from the local library.'**
  String get oneDriveUploadQueueEmpty;

  /// No description provided for @oneDriveTransferQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks in the queue yet.'**
  String get oneDriveTransferQueueEmpty;

  /// No description provided for @oneDriveDownloadQueuePageHint.
  ///
  /// In en, this message translates to:
  /// **'Pause, resume, or stop downloads here. Closing the sheet does not cancel background downloads.'**
  String get oneDriveDownloadQueuePageHint;

  /// No description provided for @oneDriveUploadQueuePageHint.
  ///
  /// In en, this message translates to:
  /// **'Library uploads appear here. Use the same controls to pause, resume, or stop.'**
  String get oneDriveUploadQueuePageHint;

  /// No description provided for @oneDriveDownloadQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload & download queue and playback'**
  String get oneDriveDownloadQueueSubtitle;

  /// No description provided for @oneDriveDownloadQueueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download queue'**
  String get oneDriveDownloadQueueTooltip;

  /// No description provided for @oneDriveEnqueueAddedSingle.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to the download queue.'**
  String oneDriveEnqueueAddedSingle(String name);

  /// No description provided for @oneDriveEnqueueAddedMany.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to the download queue.'**
  String oneDriveEnqueueAddedMany(int count);

  /// No description provided for @oneDriveDownloadViewQueue.
  ///
  /// In en, this message translates to:
  /// **'View queue'**
  String get oneDriveDownloadViewQueue;

  /// No description provided for @oneDriveDownloadClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get oneDriveDownloadClearHistory;

  /// No description provided for @oneDriveTransferClearDownloadsList.
  ///
  /// In en, this message translates to:
  /// **'Clear download list'**
  String get oneDriveTransferClearDownloadsList;

  /// No description provided for @oneDriveTransferClearUploadsList.
  ///
  /// In en, this message translates to:
  /// **'Clear upload list'**
  String get oneDriveTransferClearUploadsList;

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
  /// **'Folders you add are scanned recursively. Tap a song to fetch on demand (to your chosen download folder if it exists, otherwise the default cache); already-downloaded files play offline.'**
  String get oneDriveCloudLibrarySubtitle;

  /// No description provided for @oneDriveCloudLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tracks indexed yet.\nTap “Choose folders”, pick one or more music folders in OneDrive, then “Rescan”.'**
  String get oneDriveCloudLibraryEmpty;

  /// No description provided for @oneDriveCachedPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'OneDrive · Cached downloads'**
  String get oneDriveCachedPlaylistTitle;

  /// No description provided for @oneDriveCachedPlaylistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tracks downloaded from OneDrive yet. Play from the cloud library — files are saved to your cache or chosen folder.'**
  String get oneDriveCachedPlaylistEmpty;

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

  /// No description provided for @oneDrivePickMultipleFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the checkboxes to select folders. Use the arrow to open a folder and select more inside.'**
  String get oneDrivePickMultipleFoldersHint;

  /// No description provided for @oneDriveIncludeOpenFolderInSelection.
  ///
  /// In en, this message translates to:
  /// **'Include open folder'**
  String get oneDriveIncludeOpenFolderInSelection;

  /// No description provided for @oneDriveAddSelectedFoldersAction.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String oneDriveAddSelectedFoldersAction(int count);

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

  /// No description provided for @oneDriveLastIndexedNever.
  ///
  /// In en, this message translates to:
  /// **'Last scanned: —'**
  String get oneDriveLastIndexedNever;

  /// No description provided for @oneDriveIndexFoldersRecursiveHint.
  ///
  /// In en, this message translates to:
  /// **'Scan includes all subfolders; every audio file under each bound folder is listed.'**
  String get oneDriveIndexFoldersRecursiveHint;

  /// No description provided for @oneDriveRemoveIndexFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this folder?'**
  String get oneDriveRemoveIndexFolderTitle;

  /// No description provided for @oneDriveRemoveIndexFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the index? Tracks under this folder (including subfolders) will disappear until you add it again.'**
  String oneDriveRemoveIndexFolderMessage(String name);

  /// No description provided for @oneDriveRemoveIndexFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get oneDriveRemoveIndexFolderAction;

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

  /// No description provided for @themeGradientRgbSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradient background'**
  String get themeGradientRgbSectionTitle;

  /// No description provided for @themeGradientRgbSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune both gradient colors and direction with RGB sliders (same as playlist cover editor).'**
  String get themeGradientRgbSectionSubtitle;

  /// No description provided for @themeGradientRgbFineTune.
  ///
  /// In en, this message translates to:
  /// **'Edit colors & direction…'**
  String get themeGradientRgbFineTune;

  /// No description provided for @themeGradientRgbDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Background gradient'**
  String get themeGradientRgbDialogTitle;

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

  /// No description provided for @themeWallpaperSavedRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper saved. If it doesn\'t show yet, fully quit the app and reopen.'**
  String get themeWallpaperSavedRestartHint;

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

  /// No description provided for @homePullLoftTitle.
  ///
  /// In en, this message translates to:
  /// **'Reload from this device'**
  String get homePullLoftTitle;

  /// No description provided for @homePullReleaseHint.
  ///
  /// In en, this message translates to:
  /// **'Release to reload saved settings'**
  String get homePullReleaseHint;

  /// No description provided for @homePullEmptyTease.
  ///
  /// In en, this message translates to:
  /// **'There\'s nothing here — pulling more won\'t help.'**
  String get homePullEmptyTease;

  /// No description provided for @homePullStepThemeWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Theme: colors, gradient & wallpaper'**
  String get homePullStepThemeWallpaper;

  /// No description provided for @homePullStepBrightnessMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance: light or dark mode'**
  String get homePullStepBrightnessMode;

  /// No description provided for @homePullStepLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get homePullStepLanguage;

  /// No description provided for @homePullStepPlaylistsCarousel.
  ///
  /// In en, this message translates to:
  /// **'Playlists & home carousel order'**
  String get homePullStepPlaylistsCarousel;

  /// No description provided for @homePullStepShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Home shortcuts'**
  String get homePullStepShortcuts;

  /// No description provided for @homePullStepRecentTopPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recent plays & play counts'**
  String get homePullStepRecentTopPlayed;

  /// No description provided for @homePullStepLyricsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Lyrics display (re-read from storage)'**
  String get homePullStepLyricsDisplay;

  /// No description provided for @homePullStepPlaybackPrefs.
  ///
  /// In en, this message translates to:
  /// **'Playback mode (shuffle / repeat)'**
  String get homePullStepPlaybackPrefs;

  /// No description provided for @homePullRefreshDone.
  ///
  /// In en, this message translates to:
  /// **'Reloaded settings from local storage.'**
  String get homePullRefreshDone;

  /// No description provided for @homePullRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reload from local storage: {error}'**
  String homePullRefreshFailed(String error);

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
  /// **'No shortcuts. Tap “Manage” to show library, playlists, OneDrive cache, and more.'**
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

  /// No description provided for @homeEntryMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Top plays'**
  String get homeEntryMostPlayed;

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

  /// No description provided for @homeEntryOneDriveCachePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Cached playlist'**
  String get homeEntryOneDriveCachePlaylist;

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

  /// No description provided for @mostPlayedSwitchSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Switch to ascending play count (least plays first)'**
  String get mostPlayedSwitchSortAscending;

  /// No description provided for @mostPlayedSwitchSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Switch to descending play count (most plays first)'**
  String get mostPlayedSwitchSortDescending;

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

  /// No description provided for @playbackFailedSnackMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play this track. It may be missing, unreadable, or in an unsupported format.'**
  String get playbackFailedSnackMessage;

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

  /// No description provided for @menuPlayNextAfterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Play after current track'**
  String get menuPlayNextAfterCurrent;

  /// No description provided for @libraryPlayNextAfterCurrentQueued.
  ///
  /// In en, this message translates to:
  /// **'This track will play when the current one ends.'**
  String get libraryPlayNextAfterCurrentQueued;

  /// No description provided for @libraryPlayNextAfterCurrentNotInQueue.
  ///
  /// In en, this message translates to:
  /// **'This track is not in the current playback queue.'**
  String get libraryPlayNextAfterCurrentNotInQueue;

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

  /// No description provided for @songPageMoreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get songPageMoreSheetTitle;

  /// No description provided for @songPageMoreQueryMetadata.
  ///
  /// In en, this message translates to:
  /// **'View audio metadata'**
  String get songPageMoreQueryMetadata;

  /// No description provided for @songPageMoreUploadOneDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload to OneDrive'**
  String get songPageMoreUploadOneDrive;

  /// No description provided for @songPageMoreShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get songPageMoreShare;

  /// No description provided for @songPageMoreEditMusicTagsExternal.
  ///
  /// In en, this message translates to:
  /// **'Edit tags in external app…'**
  String get songPageMoreEditMusicTagsExternal;

  /// No description provided for @songPageMoreEditMusicTagsInline.
  ///
  /// In en, this message translates to:
  /// **'Edit embedded tags…'**
  String get songPageMoreEditMusicTagsInline;

  /// No description provided for @songPageInlineTagsEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit embedded tags'**
  String get songPageInlineTagsEditorTitle;

  /// No description provided for @songPageInlineTagsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get songPageInlineTagsFieldTitle;

  /// No description provided for @songPageInlineTagsFieldArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get songPageInlineTagsFieldArtist;

  /// No description provided for @songPageInlineTagsFieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get songPageInlineTagsFieldAlbum;

  /// No description provided for @songPageInlineTagsCoverSection.
  ///
  /// In en, this message translates to:
  /// **'Embedded cover'**
  String get songPageInlineTagsCoverSection;

  /// No description provided for @songPageInlineTagsCoverReplace.
  ///
  /// In en, this message translates to:
  /// **'Choose image to crop…'**
  String get songPageInlineTagsCoverReplace;

  /// No description provided for @songPageInlineTagsCoverRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get songPageInlineTagsCoverRemove;

  /// No description provided for @songPageInlineTagsCoverInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please choose a JPEG or PNG image.'**
  String get songPageInlineTagsCoverInvalid;

  /// No description provided for @songPageInlineTagsFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get songPageInlineTagsFieldYear;

  /// No description provided for @songPageInlineTagsFieldTrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track #'**
  String get songPageInlineTagsFieldTrackNumber;

  /// No description provided for @songPageInlineTagsFieldTrackTotal.
  ///
  /// In en, this message translates to:
  /// **'Total tracks'**
  String get songPageInlineTagsFieldTrackTotal;

  /// No description provided for @songPageInlineTagsFieldDiscNumber.
  ///
  /// In en, this message translates to:
  /// **'Disc #'**
  String get songPageInlineTagsFieldDiscNumber;

  /// No description provided for @songPageInlineTagsFieldDiscTotal.
  ///
  /// In en, this message translates to:
  /// **'Total discs'**
  String get songPageInlineTagsFieldDiscTotal;

  /// No description provided for @songPageInlineTagsFieldLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get songPageInlineTagsFieldLyrics;

  /// No description provided for @songPageInlineTagsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get songPageInlineTagsSave;

  /// No description provided for @songPageInlineTagsSaved.
  ///
  /// In en, this message translates to:
  /// **'Tags saved to file'**
  String get songPageInlineTagsSaved;

  /// No description provided for @songPageInlineTagsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save tags: {error}'**
  String songPageInlineTagsSaveFailed(Object error);

  /// No description provided for @songPageStorageManageAllFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Editing or deleting audio under shared storage needs “All files access”. Grant it for this app in system settings, then try again.'**
  String get songPageStorageManageAllFilesHint;

  /// No description provided for @audioQualityTierLq.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get audioQualityTierLq;

  /// No description provided for @audioQualityTierStd.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get audioQualityTierStd;

  /// No description provided for @audioQualityTierHq.
  ///
  /// In en, this message translates to:
  /// **'High quality'**
  String get audioQualityTierHq;

  /// No description provided for @audioQualityTierSq.
  ///
  /// In en, this message translates to:
  /// **'Lossless (CD equivalent)'**
  String get audioQualityTierSq;

  /// No description provided for @audioQualityTierHr.
  ///
  /// In en, this message translates to:
  /// **'Hi-Res'**
  String get audioQualityTierHr;

  /// No description provided for @audioQualityTierDsd.
  ///
  /// In en, this message translates to:
  /// **'DSD · audiophile'**
  String get audioQualityTierDsd;

  /// No description provided for @songPageMoreEditLyricsExternal.
  ///
  /// In en, this message translates to:
  /// **'Edit with SyncedLyricEditor…'**
  String get songPageMoreEditLyricsExternal;

  /// No description provided for @songPageSyncedLyricEditorNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'SyncedLyric Editor is not installed.'**
  String get songPageSyncedLyricEditorNotInstalled;

  /// No description provided for @songPageSyncedLyricEditorLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open SyncedLyric Editor.'**
  String get songPageSyncedLyricEditorLaunchFailed;

  /// No description provided for @songPageMusicTagEditorUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'External tag editing is only available on Android.'**
  String get songPageMusicTagEditorUnsupportedPlatform;

  /// No description provided for @songPageMusicTagEditorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found.'**
  String get songPageMusicTagEditorFileNotFound;

  /// No description provided for @songPageMusicTagEditorNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Music Tag Editor is not installed.'**
  String get songPageMusicTagEditorNotInstalled;

  /// No description provided for @songPageMusicTagEditorCannotSharePath.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be opened from its current location.'**
  String get songPageMusicTagEditorCannotSharePath;

  /// No description provided for @songPageMusicTagEditorLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Music Tag Editor.'**
  String get songPageMusicTagEditorLaunchFailed;

  /// No description provided for @songPageMetadataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio metadata'**
  String get songPageMetadataDialogTitle;

  /// No description provided for @songPageMetadataReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read metadata for this file.'**
  String get songPageMetadataReadFailed;

  /// No description provided for @songPageShareFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'This file was not found on disk.'**
  String get songPageShareFileNotFound;

  /// No description provided for @songPageDeleteDiskWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from disk?'**
  String get songPageDeleteDiskWarningTitle;

  /// No description provided for @songPageDeleteDiskWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the audio file from device storage. This cannot be undone. The song will also be removed from playlists and history.'**
  String get songPageDeleteDiskWarningBody;

  /// No description provided for @songPageDeleteContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get songPageDeleteContinue;

  /// No description provided for @songPageDeleteFinalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get songPageDeleteFinalConfirmTitle;

  /// No description provided for @songPageDeleteFinalConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{fileName}\"?'**
  String songPageDeleteFinalConfirmBody(Object fileName);

  /// No description provided for @songPageMetaFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get songPageMetaFieldTitle;

  /// No description provided for @songPageMetaFieldArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get songPageMetaFieldArtist;

  /// No description provided for @songPageMetaFieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get songPageMetaFieldAlbum;

  /// No description provided for @songPageMetaFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get songPageMetaFieldDuration;

  /// No description provided for @songPageMetaFieldBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get songPageMetaFieldBitrate;

  /// No description provided for @songPageMetaFieldSampleRate.
  ///
  /// In en, this message translates to:
  /// **'Sample rate'**
  String get songPageMetaFieldSampleRate;

  /// No description provided for @songPageMetaFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get songPageMetaFieldYear;

  /// No description provided for @songPageMetaFieldTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get songPageMetaFieldTrack;

  /// No description provided for @songPageMetaFieldDisc.
  ///
  /// In en, this message translates to:
  /// **'Disc'**
  String get songPageMetaFieldDisc;

  /// No description provided for @songPageMetaFieldPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get songPageMetaFieldPath;

  /// No description provided for @songPageMetaFieldSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get songPageMetaFieldSize;

  /// No description provided for @songPageMetaFieldGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get songPageMetaFieldGenre;

  /// No description provided for @songPageMetaFieldPerformers.
  ///
  /// In en, this message translates to:
  /// **'Performers'**
  String get songPageMetaFieldPerformers;

  /// No description provided for @songPageMetaFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get songPageMetaFieldLanguage;

  /// No description provided for @songPageMetaFieldEmbeddedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Embedded lyrics'**
  String get songPageMetaFieldEmbeddedLyrics;

  /// No description provided for @songPageMetaFieldFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get songPageMetaFieldFormat;

  /// No description provided for @songPageMetaSectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get songPageMetaSectionTags;

  /// No description provided for @songPageMetaSectionAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get songPageMetaSectionAudio;

  /// No description provided for @songPageMetaSectionFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get songPageMetaSectionFile;

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

  /// No description provided for @playlistCoverStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover color'**
  String get playlistCoverStyleTitle;

  /// No description provided for @playlistCoverStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solid or gradient for playlist cards on Home and in the library list. Rotating presets follow list order; you can also build a custom two-color gradient for stronger contrast.'**
  String get playlistCoverStyleSubtitle;

  /// No description provided for @playlistCoverUseDefaultPalette.
  ///
  /// In en, this message translates to:
  /// **'Use rotating preset colors'**
  String get playlistCoverUseDefaultPalette;

  /// No description provided for @playlistCoverSolidSection.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get playlistCoverSolidSection;

  /// No description provided for @playlistCoverGradientSection.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get playlistCoverGradientSection;

  /// No description provided for @playlistCoverCustomGradientTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom gradient'**
  String get playlistCoverCustomGradientTitle;

  /// No description provided for @playlistCoverGradientStartColor.
  ///
  /// In en, this message translates to:
  /// **'Start color'**
  String get playlistCoverGradientStartColor;

  /// No description provided for @playlistCoverGradientEndColor.
  ///
  /// In en, this message translates to:
  /// **'End color'**
  String get playlistCoverGradientEndColor;

  /// No description provided for @playlistCoverGradientSwapColors.
  ///
  /// In en, this message translates to:
  /// **'Swap colors'**
  String get playlistCoverGradientSwapColors;

  /// No description provided for @playlistCoverGradientDirectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradient direction'**
  String get playlistCoverGradientDirectionTitle;

  /// No description provided for @playlistCoverGradientDirHorizontalLR.
  ///
  /// In en, this message translates to:
  /// **'Left to right'**
  String get playlistCoverGradientDirHorizontalLR;

  /// No description provided for @playlistCoverGradientDirHorizontalRL.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get playlistCoverGradientDirHorizontalRL;

  /// No description provided for @playlistCoverGradientDirVerticalTB.
  ///
  /// In en, this message translates to:
  /// **'Top to bottom'**
  String get playlistCoverGradientDirVerticalTB;

  /// No description provided for @playlistCoverGradientDirVerticalBT.
  ///
  /// In en, this message translates to:
  /// **'Bottom to top'**
  String get playlistCoverGradientDirVerticalBT;

  /// No description provided for @playlistCoverGradientDirDiagonalTLBR.
  ///
  /// In en, this message translates to:
  /// **'Diagonal top-left → bottom-right'**
  String get playlistCoverGradientDirDiagonalTLBR;

  /// No description provided for @playlistCoverGradientDirDiagonalTRBL.
  ///
  /// In en, this message translates to:
  /// **'Diagonal top-right → bottom-left'**
  String get playlistCoverGradientDirDiagonalTRBL;

  /// No description provided for @playlistCoverGradientDirDiagonalBRTL.
  ///
  /// In en, this message translates to:
  /// **'Diagonal bottom-right → top-left'**
  String get playlistCoverGradientDirDiagonalBRTL;

  /// No description provided for @playlistCoverGradientDirDiagonalBLTR.
  ///
  /// In en, this message translates to:
  /// **'Diagonal bottom-left → top-right'**
  String get playlistCoverGradientDirDiagonalBLTR;

  /// No description provided for @playlistCoverRgbTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom RGB color'**
  String get playlistCoverRgbTitle;

  /// No description provided for @playlistCoverRgbRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get playlistCoverRgbRed;

  /// No description provided for @playlistCoverRgbGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get playlistCoverRgbGreen;

  /// No description provided for @playlistCoverRgbBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get playlistCoverRgbBlue;

  /// No description provided for @playlistCoverRgbPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get playlistCoverRgbPreview;

  /// No description provided for @playlistCoverPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Current appearance'**
  String get playlistCoverPreviewLabel;

  /// No description provided for @playlistCoverMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Cover color…'**
  String get playlistCoverMenuItem;

  /// No description provided for @playlistCoverPictureSection.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get playlistCoverPictureSection;

  /// No description provided for @playlistCoverPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image…'**
  String get playlistCoverPickImage;

  /// No description provided for @playlistCoverRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove picture'**
  String get playlistCoverRemoveImage;

  /// No description provided for @imageCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop image'**
  String get imageCropTitle;

  /// No description provided for @imageCropFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not crop this image.'**
  String get imageCropFailure;

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

  /// No description provided for @librarySongsDeletedN.
  ///
  /// In en, this message translates to:
  /// **'Deleted {n} song(s)'**
  String librarySongsDeletedN(int n);

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

  /// No description provided for @queuePendingPlayAfterCurrentSection.
  ///
  /// In en, this message translates to:
  /// **'Play next (queued)'**
  String get queuePendingPlayAfterCurrentSection;

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

  /// No description provided for @songPageKeepScreenAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get songPageKeepScreenAwake;

  /// No description provided for @lyricStyleKeepScreenAwakeSub.
  ///
  /// In en, this message translates to:
  /// **'Stays awake while you read lyrics on this screen'**
  String get lyricStyleKeepScreenAwakeSub;

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

  /// No description provided for @lyricStyleActiveGradientTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradient: current line'**
  String get lyricStyleActiveGradientTitle;

  /// No description provided for @lyricStyleStateGradientSub.
  ///
  /// In en, this message translates to:
  /// **'When on, this two-color gradient overrides the solid picks above for both original and translation. Direction and RGB sliders match the playlist cover editor.'**
  String get lyricStyleStateGradientSub;

  /// No description provided for @lyricStyleActiveGradientTune.
  ///
  /// In en, this message translates to:
  /// **'Edit gradient'**
  String get lyricStyleActiveGradientTune;

  /// No description provided for @lyricStyleActiveGradientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Current line gradient'**
  String get lyricStyleActiveGradientDialogTitle;

  /// No description provided for @lyricStylePlayedGradientTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradient: played lines'**
  String get lyricStylePlayedGradientTitle;

  /// No description provided for @lyricStyleUpcomingGradientTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradient: upcoming lines'**
  String get lyricStyleUpcomingGradientTitle;

  /// No description provided for @lyricStylePlayedGradientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Played lines gradient'**
  String get lyricStylePlayedGradientDialogTitle;

  /// No description provided for @lyricStyleUpcomingGradientDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming lines gradient'**
  String get lyricStyleUpcomingGradientDialogTitle;

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

  /// No description provided for @libraryBatchSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get libraryBatchSelect;

  /// No description provided for @libraryBatchDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get libraryBatchDone;

  /// No description provided for @libraryBatchSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryBatchSelectAll;

  /// No description provided for @libraryBatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get libraryBatchDelete;

  /// No description provided for @libraryBatchRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get libraryBatchRename;

  /// No description provided for @libraryBatchUploadOneDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload to OneDrive'**
  String get libraryBatchUploadOneDrive;

  /// No description provided for @libraryBatchDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected songs?'**
  String get libraryBatchDeleteConfirmTitle;

  /// No description provided for @libraryBatchDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Files will be removed from this device and references cleaned up. This cannot be undone.'**
  String get libraryBatchDeleteConfirmMessage;

  /// No description provided for @libraryBatchNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'Select songs first'**
  String get libraryBatchNoneSelected;

  /// No description provided for @libraryBatchRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch rename'**
  String get libraryBatchRenameTitle;

  /// No description provided for @libraryBatchRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Pattern; use %n for a number (e.g. Track %n)'**
  String get libraryBatchRenameHint;

  /// No description provided for @libraryBatchRenameStart.
  ///
  /// In en, this message translates to:
  /// **'Start at'**
  String get libraryBatchRenameStart;

  /// No description provided for @libraryRenameSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename track'**
  String get libraryRenameSingleTitle;

  /// No description provided for @libraryRenameSingleHint.
  ///
  /// In en, this message translates to:
  /// **'Main filename only; the extension is kept.'**
  String get libraryRenameSingleHint;

  /// No description provided for @libraryRenameSingleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get libraryRenameSingleFieldLabel;

  /// No description provided for @libraryRenameSingleDone.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get libraryRenameSingleDone;

  /// No description provided for @libraryCloneSong.
  ///
  /// In en, this message translates to:
  /// **'Clone song'**
  String get libraryCloneSong;

  /// No description provided for @libraryCloneSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone to new file'**
  String get libraryCloneSongTitle;

  /// No description provided for @libraryCloneSongHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the copy (extension is kept). Saved next to the original.'**
  String get libraryCloneSongHint;

  /// No description provided for @libraryCloneSongDefaultSuffix.
  ///
  /// In en, this message translates to:
  /// **' copy'**
  String get libraryCloneSongDefaultSuffix;

  /// No description provided for @libraryCloneSongDone.
  ///
  /// In en, this message translates to:
  /// **'Song cloned'**
  String get libraryCloneSongDone;

  /// No description provided for @libraryCloneSongFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clone song'**
  String get libraryCloneSongFailed;

  /// No description provided for @libraryCloneSongProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloning song'**
  String get libraryCloneSongProgressTitle;

  /// No description provided for @libraryCloneSongProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Copying file and refreshing library…'**
  String get libraryCloneSongProgressMessage;

  /// No description provided for @libraryBatchUploadNeedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to OneDrive in Settings'**
  String get libraryBatchUploadNeedSignIn;

  /// No description provided for @libraryBatchUploadNeedCloudFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose an OneDrive cloud app folder in Settings first'**
  String get libraryBatchUploadNeedCloudFolder;

  /// No description provided for @libraryBatchUploadNeedParentFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a music upload folder or cloud app folder under OneDrive settings first.'**
  String get libraryBatchUploadNeedParentFolder;

  /// No description provided for @libraryBatchUploadQueued.
  ///
  /// In en, this message translates to:
  /// **'Added to transfer queue'**
  String get libraryBatchUploadQueued;

  /// No description provided for @libraryBatchOpenQueue.
  ///
  /// In en, this message translates to:
  /// **'Open queue'**
  String get libraryBatchOpenQueue;

  /// No description provided for @libraryBatchAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlists'**
  String get libraryBatchAddToPlaylist;

  /// No description provided for @libraryBatchAddToPlaylistSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {count} tracks to playlists'**
  String libraryBatchAddToPlaylistSheetTitle(int count);

  /// No description provided for @libraryBatchAddToPlaylistSheetHelp.
  ///
  /// In en, this message translates to:
  /// **'Checked playlists already contain every selected track. Confirm applies these memberships to all selected tracks.'**
  String get libraryBatchAddToPlaylistSheetHelp;

  /// No description provided for @libraryBatchAddToPlaylistDone.
  ///
  /// In en, this message translates to:
  /// **'Playlists updated'**
  String get libraryBatchAddToPlaylistDone;

  /// No description provided for @libraryReloadMetadata.
  ///
  /// In en, this message translates to:
  /// **'Reload embedded metadata'**
  String get libraryReloadMetadata;

  /// No description provided for @libraryReloadMetadataDone.
  ///
  /// In en, this message translates to:
  /// **'Metadata reloaded from file'**
  String get libraryReloadMetadataDone;

  /// No description provided for @oneDriveUploadStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get oneDriveUploadStatusUploading;

  /// No description provided for @oneDriveTaskDirectionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get oneDriveTaskDirectionUpload;
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
