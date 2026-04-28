// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Yeah Music';

  @override
  String get menuHome => 'ホーム';

  @override
  String get menuSongList => '曲库';

  @override
  String get menuPlaylists => 'プレイリスト';

  @override
  String get menuMusicSource => '音楽フォルダ';

  @override
  String get menuSettings => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsBackgroundTheme => '背景とテーマ';

  @override
  String get settingsBackgroundThemeSubtitle => '単色・色・アートワーク';

  @override
  String get settingsBackgroundThemeDesc =>
      '単色、アクセント色、または全画面の背景画像を選べます。詳細は次の画面で設定します。';

  @override
  String get settingsSystemInfo => 'システム情報';

  @override
  String get settingsSystemInfoSubtitle => '端末と空き容量';

  @override
  String get settingsSystemInfoDesc =>
      '端末情報とストレージの空きを確認できます。展開するとフォルダ別の使用状況も表示されます。';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get settingsAboutSubtitle => 'バージョンとライセンス';

  @override
  String get settingsAboutDesc => 'アプリ名とバージョン、クレジット、オープンソースライセンスの全文です。';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSubtitle => 'UI の表示言語';

  @override
  String get settingsLanguageDesc => 'メニューや画面の言語を選びます。曲情報はファイルのタグに従います。';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle => 'サインイン・フォルダ・キャッシュ';

  @override
  String get settingsOneDriveDesc =>
      'Microsoft にサインインし、OneDrive 上の音楽ルートを選んで閲覧します。再生時にローカルへキャッシュするため、一度取得すればオフラインでもスムーズに再生できます。';

  @override
  String get settingsMacosMenuBarLyrics => 'メニューバーに歌詞';

  @override
  String get settingsMacosMenuBarLyricsSubtitle => 'メニューバーの 1 行表示';

  @override
  String get settingsMacosMenuBarLyricsDesc => 'macOS メニューバーに 1 行で表示';

  @override
  String get settingsDesktopLyricsGroupTitle => 'デスクトップ歌詞';

  @override
  String get settingsDesktopLyricsGroupSubtitle => 'フローティングと macOS メニューバー';

  @override
  String get settingsDesktopLyricsGroupDetail =>
      'デスクトップ歌詞には、他のウィンドウの上に表示できるフローティング歌詞と、macOS では任意のメニューバー 1 行表示があります。\n\nフローティングは再生中画面と同じ歌詞スタイル（色・複数行・翻訳など）を使います。位置の固定、背景の不透明度、現在行の前後に表示する行数を調整できます。\n\nメニューバー歌詞（macOS のみ）はコンパクトな 1 行で、フローティングなしで常に表示したいときに使います。';

  @override
  String get settingsDesktopFloatingLyrics => 'フローティング歌詞';

  @override
  String get settingsDesktopFloatingLyricsSubtitle => 'ドラッグできる現在行';

  @override
  String get settingsDesktopFloatingLyricsDesc =>
      '再生中画面の歌詞設定に合わせ、ウィンドウ上にドラッグ可能な 1 行を表示します。';

  @override
  String get settingsDesktopFloatingBgOpacity => '背景の不透明度';

  @override
  String get settingsDesktopFloatingBgOpacitySubtitle => '文字の後ろのパネルの濃さ';

  @override
  String get settingsDesktopFloatingBgOpacityDesc =>
      '歌詞パネルの背景の濃さ。0 で背景なし（文字のみ）。';

  @override
  String get settingsDesktopFloatingLinesBefore => '現在行より上';

  @override
  String get settingsDesktopFloatingLinesBeforeSubtitle => '現在行の上のタイムド行数';

  @override
  String get settingsDesktopFloatingLinesBeforeDesc =>
      'タイムライン上の現在行より上に、最大何行表示するか（現在行は含みません）。';

  @override
  String get settingsDesktopFloatingLinesAfter => '現在行より下';

  @override
  String get settingsDesktopFloatingLinesAfterSubtitle => '現在行の下のタイムド行数';

  @override
  String get settingsDesktopFloatingLinesAfterDesc =>
      'タイムライン上の現在行より下に、最大何行表示するか（現在行は含みません）。';

  @override
  String get settingsDesktopFloatingDragLock => '位置を固定';

  @override
  String get settingsDesktopFloatingDragLockSubtitle => 'フローティングをドラッグ不可に';

  @override
  String get settingsDesktopFloatingDragLockDesc =>
      'オンにするとフローティングウィンドウをドラッグできません。';

  @override
  String get settingsCarLyricsGroupTitle => '車載・ロック画面';

  @override
  String get settingsCarLyricsGroupSubtitle => '通知・Bluetooth・Android Auto';

  @override
  String get settingsCarLyricsGroupDetail =>
      'Android のメディアセッションを使い、ロック画面・Bluetooth・Android Auto などに再生情報と操作を提供します。\n\n有効化：プレイヤーにキューを構築し、通知や車載の前後曲が実際の曲送りに対応します。再生／一時停止や 1 曲リピートは環境が許す範囲でアプリと揃います。\n\nアートワーク：通知や対応ヘッドユニットに埋め込みジャケットを送ります。\n\n歌詞：対応端末では副題を現在の歌詞行に更新します。ルールはアプリ内の他の歌詞表示と同じです。\n\nシャッフルや 1 回だけ再生などはアプリ側の再生モードが優先されます。車載のリストリピート／シャッフルがすべてのモードと一致するとは限りません。';

  @override
  String get settingsCarLyricsEnabled => '車載歌詞を有効化';

  @override
  String get settingsCarLyricsEnabledSubtitle => '通知のキューと前後曲';

  @override
  String get settingsCarLyricsEnabledDesc =>
      '通知にキューと前後曲・再生／一時停止を表示。単曲ループはシステムのリピートと同期します。';

  @override
  String get settingsCarLyricsShowCover => 'アートワークを表示';

  @override
  String get settingsCarLyricsShowCoverSubtitle => '通知・車載にジャケット';

  @override
  String get settingsCarLyricsShowCoverDesc => '通知や対応ヘッドユニットに埋め込みジャケットを表示します。';

  @override
  String get settingsCarLyricsSyncLyrics => '現在の歌詞行を同期';

  @override
  String get settingsCarLyricsSyncLyricsSubtitle => '副題に現在の歌詞行';

  @override
  String get settingsCarLyricsSyncLyricsDesc => '対応環境では副題を現在の歌詞行に更新します。';

  @override
  String get settingsCarLyricsOnlyAndroidHint =>
      'Android でのみ変更・反映できます。この端末ではスイッチは読み取り専用で、保存済みの内容を表示します。';

  @override
  String get menuBarLyricsIdle => 'Yeah Music · 再生していません';

  @override
  String get menuBarLyricsNoLyrics => '歌詞がありません';

  @override
  String get menuBarContextPlay => '再生';

  @override
  String get menuBarContextPause => '一時停止';

  @override
  String get menuBarContextPrevious => '前の曲';

  @override
  String get menuBarContextNext => '次の曲';

  @override
  String get oneDriveSettingsTitle => 'OneDrive';

  @override
  String get oneDriveClientIdLabel => 'アプリケーション (クライアント) ID';

  @override
  String get oneDriveClientIdHint => 'Azure ポータル → アプリの概要';

  @override
  String get oneDriveMusicRootIdLabel => '音楽のルートフォルダ（任意）';

  @override
  String get oneDriveMusicRootHint => 'OneDrive のアイテム ID。空欄の場合はドライブのルートから。';

  @override
  String get oneDriveSignIn => 'Microsoft でサインイン';

  @override
  String get oneDriveSignOut => 'サインアウト';

  @override
  String get oneDriveSignOutDone => 'OneDrive からサインアウトしました';

  @override
  String get oneDriveSignedIn => 'サインイン済み';

  @override
  String get oneDriveNotSignedIn => '未サインイン';

  @override
  String get oneDriveLinuxUnsupported => 'このプラットフォームでは OneDrive サインインに未対応です。';

  @override
  String get oneDriveNeedClientId => '先に Azure のクライアント ID を入力してください。';

  @override
  String get oneDriveSignInFailed =>
      'サインインに失敗しました。クライアント ID と Azure のリダイレクト URI を確認するか、しばらくしてから試してください。';

  @override
  String get oneDriveAzureRedirectIntro =>
      'redirect_uri が無効となる場合は、Azure アプリの登録 → 認証 → プラットフォームを追加から「モバイル アプリケーションとデスクトップ アプリケーション」（Web／SPA は不可）を選び、カスタム リダイレクト URI に次の値を完全一致で追加してください。';

  @override
  String get oneDriveRedirectCopyTooltip => 'リダイレクト URI をコピー';

  @override
  String get oneDriveRedirectCopied => 'リダイレクト URI をコピーしました';

  @override
  String get oneDriveCacheNote => '再生時、音声はアプリのデータ領域に保存されます。';

  @override
  String get oneDriveOpenBrowser => 'OneDrive を開く';

  @override
  String get homeEntryOneDrive => 'OneDrive';

  @override
  String get oneDriveBrowserTitle => 'OneDrive';

  @override
  String get oneDriveEmptyFolder => 'このフォルダーは空です';

  @override
  String get oneDrivePlayAll => 'フォルダー内のすべてを再生';

  @override
  String get oneDrivePreparing => '準備中…';

  @override
  String oneDriveError(String message) {
    return 'OneDrive エラー：$message';
  }

  @override
  String get oneDriveUp => '上へ';

  @override
  String get oneDriveCloudLibraryTitle => 'OneDrive · クラウドライブラリ';

  @override
  String get oneDriveCloudLibrarySubtitle =>
      '追加したフォルダーを再帰的にスキャンしてリスト化。タップでオンデマンドダウンロード。再生済みはキャッシュを利用します。';

  @override
  String get oneDriveCloudLibraryEmpty =>
      'まだありません。\nOneDrive でフォルダーを選んでから「再スキャン」してください。';

  @override
  String get oneDriveIndexRootsLabel => 'インデックス対象フォルダー';

  @override
  String get oneDriveRescanIndex => '再スキャン';

  @override
  String get oneDriveBrowseFolders => 'フォルダーを選ぶ';

  @override
  String get oneDrivePickFolderForIndex =>
      'フォルダーの「+」、またはフォルダー内で「このフォルダーを使う」を押します。';

  @override
  String get oneDriveUseCurrentFolder => 'このフォルダーを使う';

  @override
  String get oneDriveAddFolderTooltip => 'クラウドライブラリに追加';

  @override
  String get oneDriveIndexingEllipsis => 'スキャン中…';

  @override
  String oneDriveLastIndexed(String time) {
    return '最終スキャン: $time';
  }

  @override
  String get oneDrivePlayAllTracks => 'すべて再生';

  @override
  String oneDriveTracksCount(int count) {
    return '$count 曲';
  }

  @override
  String get oneDriveCloudSearchHint => 'ファイル名やパスを検索…';

  @override
  String get oneDriveNoIndexRoots => 'フォルダーが未設定です。先に「フォルダーを選ぶ」から設定してください。';

  @override
  String get languageSettingsTitle => '言語';

  @override
  String get languageSettingsDescription =>
      '表示言語を選びます。「システムに従う」は、翻訳がある場合に端末の言語に合わせます。';

  @override
  String get langFollowSystem => 'システムに従う';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langSimplifiedChinese => '簡体中国語';

  @override
  String get langTraditionalChinese => '繁体中国語';

  @override
  String get themeSettingsTitle => 'テーマ設定';

  @override
  String get globalTheme => 'アプリのテーマ';

  @override
  String get globalThemeDesc => 'ライト、ダーク、またはシステムに従います。端末に保存されます。';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get sectionThemeType => 'テーマの種類';

  @override
  String get themeTypeSolid => 'プリセット色';

  @override
  String get themeTypeCustom => 'カスタム色';

  @override
  String get themeTypeImage => '背景画像';

  @override
  String get sectionPresetColors => 'プリセット色';

  @override
  String get sectionCustomColor => 'カスタム色';

  @override
  String get sectionBackgroundImage => '背景画像';

  @override
  String get primaryColor => '主色';

  @override
  String get secondaryColor => '補色';

  @override
  String get actionSelect => '選択';

  @override
  String get fogBackground => '背景のぼかし・暗さ';

  @override
  String get fogBackgroundDesc => '文字やアイコンを読みやすくするため、背景をぼかして暗くします。既定 45%。';

  @override
  String get fogWeak => '弱';

  @override
  String get fogStrong => '強';

  @override
  String get actionPickImage => '画像を選ぶ';

  @override
  String get actionRemove => '削除';

  @override
  String cannotSaveBackground(String error) {
    return '背景画像を保存できません。やり直すか別の画像を試してください：$error';
  }

  @override
  String get colorDialogTitlePrimary => '主色';

  @override
  String get colorDialogTitleSecondary => '補色';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionRetry => '再試行';

  @override
  String startupFailed(String error) {
    return '起動に失敗しました：$error';
  }

  @override
  String get welcomeTagline => '聴き始めの、その一歩。';

  @override
  String get welcomeEnter => 'はじめる';

  @override
  String get welcomeEnterWait => 'はじめる（読み込みが終わるまで待つ）';

  @override
  String get welcomeHintWhenReady => '読み込みが完了しました。すぐホームへ入れます。';

  @override
  String get welcomeHintWhenNotReady => '起動が完了すると自動的にホームが開きます。';

  @override
  String get welcomePreparing => '起動の準備を完了しています…';

  @override
  String get welcomeCountdownLabel => '起動時間';

  @override
  String get welcomeCountdownSubDoneReady => 'ホームの準備ができました — 入室できます';

  @override
  String get welcomeStartupSubLoading => 'ホーム画面のデータを読み込んでいます — 準備できたら自動で開きます';

  @override
  String get secondsUnit => '秒';

  @override
  String get welcomeNotReadyMessage => '少々お待ちください。まだ読み込み中です。';

  @override
  String welcomeLoadError(String error) {
    return '問題が発生しました。ストレージへのアクセスを確認するか、しばらくしてから再試行してください。\n\n$error';
  }

  @override
  String get welcomeFakeUserSettings => 'ユーザー設定を読み込み中';

  @override
  String get welcomeFakeLibrary => 'ライブラリを読み込み中';

  @override
  String get welcomeFakePlaylists => 'プレイリストを読み込み中';

  @override
  String get welcomeFakeOther => 'その他のデータを読み込み中';

  @override
  String get welcomeFakeFinishing => '初期化を完了しています';

  @override
  String get homeGreetingLateNight => '夜更かし中？';

  @override
  String get homeGreetingMorning => 'おはよう';

  @override
  String get homeGreetingAfternoon => 'こんにちは';

  @override
  String get homeGreetingEvening => 'こんばんは';

  @override
  String get homeMenuTooltip => 'メニュー';

  @override
  String get homeSearchTooltip => '検索';

  @override
  String get homeQuickEntryEmpty => 'ショートカットはありません。「管理」からライブラリやプレイリストを表示できます。';

  @override
  String get homeEntryLibrary => 'ライブラリ';

  @override
  String get homeEntryMyPlaylists => 'マイプレイリスト';

  @override
  String get homeEntryRecent => '最近再生';

  @override
  String get homeEntryDiscover => '見つける';

  @override
  String get homeEntryCloudLibrary => 'クラウド曲庫';

  @override
  String get homeSectionQuickEntry => 'ショートカット';

  @override
  String get homeActionManage => '管理';

  @override
  String get homeSectionMyPlaylists => 'マイプレイリスト';

  @override
  String get homeActionMore => 'さらに';

  @override
  String get homeLoadingLibrary => 'ライブラリを読み込み中…';

  @override
  String get homeRecentEmpty => '最近の再生はありません。曲庫やプレイリストで再生すると表示されます。';

  @override
  String get homeSectionMostPlayed => 'よく聴く';

  @override
  String get homeSectionRecentPlays => '最近の再生';

  @override
  String get homeActionAll => 'すべて';

  @override
  String get homeMostPlayedPathMismatch =>
      '再生回数の記録はありますが、曲庫のパスと一致しません。移動した場合はフォルダを再スキャンし、数回再生してください。';

  @override
  String get homeMostPlayedEmpty => 'まだ再生回数の統計はありません。曲を再生するとよく聴く一覧が作られます。';

  @override
  String homePlayCount(int c) {
    return '$c 回再生';
  }

  @override
  String homePlayCountWithBase(String base, int c) {
    return '$base · $c 回再生';
  }

  @override
  String homeGreetingLine(String greeting) {
    return '$greeting。今日は何を聴きますか？';
  }

  @override
  String get homeGreetingSub => '下の続きから、またはプレイリストから';

  @override
  String get homeSearchHint => '曲・アーティスト・プレイリストを検索';

  @override
  String get homeContinuePlaying => '続きを再生';

  @override
  String get homeUnknownTitle => '不明';

  @override
  String get homeNowPlayingAlbum => '再生中';

  @override
  String get homeNothingPlaying => '何も再生していません';

  @override
  String get homeOpenLibraryToPlay => 'ライブラリで曲を選ぶ';

  @override
  String get homeAllSongsLoading => '読み込み中…';

  @override
  String get homeScanMusicFolder => '音楽フォルダをスキャン';

  @override
  String homeTrackCount(int n) {
    return '$n 曲';
  }

  @override
  String get homeAllSongs => '全曲';

  @override
  String get homeCreatePlaylist => '新規プレイリスト';

  @override
  String get homeCreatePlaylistSub => '好きな曲を集めて';

  @override
  String get homeEmptyPlaylist => '空';

  @override
  String get songsListEmpty => '曲はまだありません';

  @override
  String get tooltipSort => '並べ替え';

  @override
  String get languageRestartNotice => '表示言語をすべてに反映するには、アプリの再起動が必要な場合があります。';

  @override
  String get locateNotInList => 'このリストに再生中の曲はありません';

  @override
  String get locateToCurrent => '再生位置へ';

  @override
  String get locateToCurrentPlaying => '再生中の曲を表示';

  @override
  String get locateToLyricLine => 'いまの行へ';

  @override
  String get tooltipBack => '戻る';

  @override
  String get tooltipAddToPlaylist => 'プレイリストに追加';

  @override
  String get tooltipDone => '完了';

  @override
  String get tooltipMoreActions => '操作';

  @override
  String get tooltipMore => 'その他';

  @override
  String get tooltipLyricStyle => '歌詞の見た目';

  @override
  String get tooltipFolderInfo => 'フォルダ情報';

  @override
  String get tooltipReloadSongs => '再スキャン';

  @override
  String get tooltipEdit => '編集';

  @override
  String get tooltipRemoveFolder => 'フォルダを外す';

  @override
  String get actionDelete => '削除';

  @override
  String get actionSave => '保存';

  @override
  String get actionCreate => '作成';

  @override
  String get actionConfirm => '確認';

  @override
  String get actionGotIt => '了解';

  @override
  String get actionOK => 'OK';

  @override
  String get settingsRowHelpTooltip => '詳細';

  @override
  String get fieldName => '名前';

  @override
  String get fieldNewNameHint => '新しい名前';

  @override
  String get folderAppBarTitle => 'フォルダ';

  @override
  String folderSongsCount(int n) {
    return '$n 曲';
  }

  @override
  String get folderInfoAlias => '表示名：';

  @override
  String get folderInfoPath => 'パス：';

  @override
  String get folderInfoSongCount => '曲数：';

  @override
  String get folderInfoAdded => '追加日時：';

  @override
  String get folderAddLoadingTitle => '曲を読み込み中';

  @override
  String get folderReloading => '再読み込み中';

  @override
  String get folderScanningWait => 'フォルダをスキャンしています…';

  @override
  String folderLoadOk(int n) {
    return '$n 曲を読み込みました';
  }

  @override
  String folderLoadFailed(String error) {
    return '読み込みに失敗しました：$error';
  }

  @override
  String get folderRemoveTitle => 'このフォルダを外しますか？';

  @override
  String folderRemoveMessage(String name) {
    return '「$name」をライブラリから外しますか？（ディスク上のファイルは削除されません）';
  }

  @override
  String get folderDuplicateDialogTitle => 'お知らせ';

  @override
  String folderDuplicateMessage(String path) {
    return '既に追加済みのフォルダです：$path';
  }

  @override
  String folderAddOk(int n) {
    return '$n 曲を追加しました';
  }

  @override
  String get folderAddErrorTitle => 'エラー';

  @override
  String folderAddErrorMessage(String error) {
    return 'フォルダを追加できませんでした：$error';
  }

  @override
  String get folderAddNoSelection => 'フォルダが選択されていません。';

  @override
  String get folderRenameDialogTitle => 'フォルダ名を変更';

  @override
  String get playlistPageTitle => 'プレイリスト';

  @override
  String get playlistNotFound => 'プレイリストがありません';

  @override
  String get playlistNotFoundMessage => '削除された可能性があります。';

  @override
  String get playlistEmptyNoSongs =>
      '再生できる曲がありません。\n（「音楽フォルダ」をスキャンするか、パスが無効かもしれません）';

  @override
  String get playlistDeleteTitle => 'プレイリストを削除';

  @override
  String get playlistDeleteMessage => 'このプレイリストを削除しますか？参照のみ失われ、ファイルは削除されません。';

  @override
  String get playlistDeleteBatchTitle => '複数のプレイリストを削除';

  @override
  String playlistDeleteBatchMessage(int n) {
    return '選択した $n 件のプレイリストを削除しますか？参照のみ失われ、ファイルは削除されません。';
  }

  @override
  String get playlistDeletedOne => 'プレイリストを削除しました';

  @override
  String get importDialogBody =>
      '曲は「完全なファイルパス」で区別されます。同じタイトルでもファイルが異なれば別扱いで、誤ってマージされません。\n\n• マージ取り込み：同じ id のプレイリストは曲をマージ（パスは重複除去）。バックアップにだけあるプレイリストは新規作成されます。\n• すべて置換：先にローカルのプレイリストをすべて消去してからバックアップで復元します（慎重に）。';

  @override
  String playlistCreatedOn(String date) {
    return '作成 $date';
  }

  @override
  String get recentPlaysEmptyTitle => '再生履歴はまだありません';

  @override
  String get quickEntryReorderHint =>
      'ハンドルをドラッグして並べ替え。「ホームに表示」をオフにするとホームから非表示になります。';

  @override
  String get quickEntryShowOnHome => 'ホームに表示';

  @override
  String get playlistSearchHint => '曲、アーティスト、ファイル名で検索…';

  @override
  String get searchNoMatchingSongs => '該当する曲がありません';

  @override
  String get playlistRenameTitle => '名前を変更';

  @override
  String get exportCannot => 'このプレイリストはエクスポートできません';

  @override
  String exportSaved(String path) {
    return 'エクスポートしました：$path';
  }

  @override
  String get exportCancelled => 'エクスポートをキャンセルしました';

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗しました：$error';
  }

  @override
  String get exportDialogTitle => 'プレイリストをエクスポート';

  @override
  String get menuRename => '名前を変更';

  @override
  String get menuExportThis => 'このプレイリストをエクスポート…';

  @override
  String get menuDeletePlaylist => 'プレイリストを削除';

  @override
  String get exportSelectFirst => 'エクスポートするプレイリストを選んでください';

  @override
  String get exportNoneToExport => 'エクスポートできるプレイリストがありません';

  @override
  String get exportAllPlaylists => 'すべてのプレイリストをエクスポート';

  @override
  String get exportSelectedPlaylists => '選択したプレイリストをエクスポート';

  @override
  String get exportSelected => '選択をエクスポート';

  @override
  String get exportAll => 'すべてエクスポート';

  @override
  String get importCannotRead => 'ファイルを読めません（ファイルサイズや権限を確認してください）';

  @override
  String importParseError(String message) {
    return '解析できません：$message';
  }

  @override
  String get importMerge => 'マージで取り込む';

  @override
  String get importReplaceAll => 'すべて置き換え';

  @override
  String get importMerged => 'マージで取り込みました';

  @override
  String get importReplaced => '置き換えて取り込みました';

  @override
  String importFailed(String error) {
    return '取り込みに失敗しました：$error';
  }

  @override
  String playlistsDeletedN(int n) {
    return '$n 件のプレイリストを削除しました';
  }

  @override
  String get fabNewPlaylist => '新規プレイリスト';

  @override
  String get emptyPlaylistsHint =>
      'プレイリストはまだありません。\n再生画面や曲一覧から曲を追加できます。\n\n右上の「⋮」から取り込み／エクスポートや複数選択ができます。';

  @override
  String get sortByName => '名前順';

  @override
  String get sortByPath => 'パス順';

  @override
  String get sortByCreated => '作成日時';

  @override
  String get sortByUpdated => '更新日時';

  @override
  String get sortByAddedToPlaylist => 'プレイリストに追加した順';

  @override
  String get sortByAddedToPlaylistSub => '昇順：古い順 · 降順：新しい順';

  @override
  String get lyricAlignLeft => '左';

  @override
  String get lyricAlignCenter => '中央';

  @override
  String get lyricAlignRight => '右';

  @override
  String get addToPlaylistHint => '新しいプレイリスト名';

  @override
  String addToPlaylistUpdatedN(int n) {
    return '$n 件のプレイリストを更新しました';
  }

  @override
  String get noLyrics => '歌詞がありません';

  @override
  String get songNotFound => '曲がありません';

  @override
  String get pageUnknownTitle => '不明なタイトル';

  @override
  String get queueNoTracks => 'キューに曲がありません';

  @override
  String get playQueueTitle => '再生キュー';

  @override
  String get playbackModeTitle => '再生モード';

  @override
  String get playbackSequential => '順番に再生';

  @override
  String get playbackShuffle => 'シャッフル';

  @override
  String get playbackSingleLoop => '1曲リピート';

  @override
  String get playbackOnce => '1回だけ再生';

  @override
  String get playbackTimer => 'タイマー停止';

  @override
  String get sleepTimerSheetTitle => 'タイマーで停止';

  @override
  String get sleepTimerCancel => 'タイマーを解除';

  @override
  String sleepTimerMinutesN(int n) {
    return '$n 分';
  }

  @override
  String get sleepTimerCustom => '時間を指定';

  @override
  String sleepTimerCurrentN(int n) {
    return '現在 $n 分';
  }

  @override
  String get sleepTimerLabelMinutes => '分';

  @override
  String sleepTimerInvalidRange(int min, int max) {
    return '$min～$max の整数を入力してください';
  }

  @override
  String sleepTimerPlayedMinutes(int minutes) {
    return 'スリープタイマー：$minutes 分再生しました';
  }

  @override
  String get lyricModeEmptyHint => '表示モードを切り替え';

  @override
  String get lyricModeAllLines => '複数行：全行表示（タップで1行）';

  @override
  String lyricModeSingleLineN(int n) {
    return '複数行：$n 行目のみ（タップで切替）';
  }

  @override
  String get sortOptionsTitle => '並べ替え';

  @override
  String addToPlaylistTitle(String name) {
    return 'プレイリストに追加 · $name';
  }

  @override
  String get addToPlaylistMultiHelp => '複数選択可能。外すとそのプレイリストから曲を削除します。';

  @override
  String get addToPlaylistNoPlaylistsYet => 'まだプレイリストがありません。上に名前を入れて作成してください。';

  @override
  String get quickEntrySettingsTitle => 'ショートカット';

  @override
  String get playlistSelectModeSingle => '1件だけ';

  @override
  String get playlistSelectModeMulti => '複数';

  @override
  String get menuImportPlaylists => 'プレイリストを取り込む';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get deselectAll => '選択を解除';

  @override
  String playlistSelectCount(int n, int m) {
    return '選択 $n / $m';
  }

  @override
  String get lyricStyleSyncSubtitle => '再生中画面の歌詞と同じ';

  @override
  String get lyricStyleSectionDisplay => '表示';

  @override
  String get lyricStyleSectionDisplaySub => '原文と複数行の訳文のオン/オフ';

  @override
  String get lyricStyleShowOriginal => '原文を表示';

  @override
  String get lyricStyleShowOriginalSub => '各タイムスタンプの 1 行目';

  @override
  String get lyricStyleShowTranslation => '翻訳・追加行を表示';

  @override
  String get lyricStyleShowTranslationSub => '2 行目以降';

  @override
  String get lyricStyleSectionTypography => '文字サイズと行間';

  @override
  String get lyricStyleSectionTypographySub => 'スライダーで変更、すぐ反映';

  @override
  String get lyricStyleFontOriginal => '原文のサイズ';

  @override
  String get lyricStyleFontTranslation => '訳文のサイズ';

  @override
  String get lyricStyleLineSpacing => '行間';

  @override
  String get lyricStyleSectionLineAlign => '行の配置';

  @override
  String get lyricStyleSectionStateColors => '行の状態の色';

  @override
  String get lyricStyleSectionStateColorsSub => '再生中・既に再生・これから';

  @override
  String get lyricStyleStateNowPlaying => '再生中の行';

  @override
  String get lyricStyleStatePlayed => '過去の行';

  @override
  String get lyricStyleStateUpcoming => 'これからの行';

  @override
  String get lyricStyleColorNowOriginal => '再生中 — 原文';

  @override
  String get lyricStyleColorNowTranslation => '再生中 — 訳文';

  @override
  String get lyricStyleColorPlayedOriginal => '再生済み — 原文';

  @override
  String get lyricStyleColorPlayedTranslation => '再生済み — 訳文';

  @override
  String get lyricStyleColorUpcomingOriginal => '未再生 — 原文';

  @override
  String get lyricStyleColorUpcomingTranslation => '未再生 — 訳文';

  @override
  String get lyricStyleColorPersistNote => '色は端末に保存され、切り替え後も保持されます。';

  @override
  String get lyricColorPickerHint => '色をタップ';

  @override
  String get lyricLabelOriginal => '原文';

  @override
  String get lyricLabelTranslation => '訳文';
}
