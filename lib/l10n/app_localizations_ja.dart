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
  String get menuStatistics => '統計';

  @override
  String get menuSettings => '設定';

  @override
  String get statisticsTitle => '統計';

  @override
  String get statisticsSubtitle => 'ライブラリ・再生・プレイリストの概要';

  @override
  String get statisticsReloadTooltip => '更新';

  @override
  String get statisticsReloadStarted => '再生統計を更新しています…';

  @override
  String get statisticsReloadDone => '再生統計を更新しました';

  @override
  String get statisticsReloadFailed => '再生統計を更新できませんでした';

  @override
  String get statisticsSectionLibrary => 'ライブラリ';

  @override
  String get statisticsSectionPlayback => '再生';

  @override
  String get statisticsSectionPlaylists => 'プレイリスト';

  @override
  String get statisticsSectionOneDrive => 'OneDrive';

  @override
  String get statisticsTracksLabel => '曲数';

  @override
  String get statisticsFoldersLabel => 'メディアフォルダ';

  @override
  String get statisticsDurationLabel => '推定総再生時間';

  @override
  String get statisticsDurationHint => 'メタデータに長さがある曲のみ合計';

  @override
  String get statisticsFormatsLabel => 'フォーマット';

  @override
  String get statisticsFormatsOther => 'その他';

  @override
  String statisticsFormatsMore(int count) {
    return 'ほか $count 種類';
  }

  @override
  String get statisticsQualityLabel => '音質の分布';

  @override
  String get statisticsQualityHint =>
      'ライブラリの音質バッジと同じ推定（形式・ビットレート・サンプルレートが取得できる場合）';

  @override
  String get statisticsQualityUnknown => '不明';

  @override
  String get statisticsHistoricalListeningLabel => '再生時間の累計';

  @override
  String get statisticsHistoricalListeningHint =>
      '再生中のみ経過時間を累計します（一時停止・停止は含みません）。再生速度には連動しません。このバージョンから保存します。強制終了すると未書き込みの数秒が失われることがあります（約8秒ごとに記録）。';

  @override
  String get statisticsPlaybackTotalLabel => '再生開始の累計';

  @override
  String get statisticsPlaybackTotalSubtitle => '再生開始ごとに 1 と数えた保存済みの回数です。';

  @override
  String get statisticsPlaybackDistinctLabel => '再生履歴のある曲';

  @override
  String get statisticsRecentEntriesLabel => '最近再生リスト件数';

  @override
  String statisticsRecentEntriesSubtitle(int max) {
    return 'ローカルに最大 $max 件まで保存';
  }

  @override
  String get statisticsPlaylistsCountLabel => 'マイプレイリスト数';

  @override
  String get statisticsPlaylistRefsLabel => 'プレイリスト内エントリ';

  @override
  String get statisticsPlaylistRefsSubtitle => '各リストのパス数の合計（重複カウントあり）';

  @override
  String get statisticsOneDriveIndexedLabel => 'クラウド索引トラック';

  @override
  String get statisticsOneDriveCachedLabel => 'キャッシュ／ダウンロード済み';

  @override
  String get statisticsOneDriveUnavailable => 'クラウド統計はサインイン後に表示';

  @override
  String get statisticsNotInitialized => 'ライブラリを初期化しています…';

  @override
  String statisticsDurationHM(int hours, int minutes) {
    return '$hours 時間 $minutes 分';
  }

  @override
  String statisticsDurationMOnly(int minutes) {
    return '$minutes 分';
  }

  @override
  String get statisticsDurationUnknown => '算出できません';

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
  String get settingsHomeGreetingTitle => 'ホームのあいさつ';

  @override
  String get settingsHomeGreetingListSubtitle => '自作の一文が既定文と順に表示されます';

  @override
  String get settingsHomeGreetingHelp =>
      'ホームのあいさつカード2行目には、組み込みのローカライズ済みの既定文が必ず含まれます。下の各行は任意の追加文です（件数の上限なし）。保存後は既定文とあわせて表示され、順番かランダムかを下で選べます。';

  @override
  String get settingsHomeGreetingLineHint => 'あいさつの文章';

  @override
  String get settingsHomeGreetingRotationTitle => '切り替え';

  @override
  String get settingsHomeGreetingRotationSequential => '順番';

  @override
  String get settingsHomeGreetingRotationRandom => 'ランダム';

  @override
  String get settingsHomeGreetingEmptyHint => 'まだありません。下のボタンで追加してください。';

  @override
  String get settingsHomeGreetingAddLine => '行を追加';

  @override
  String get settingsHomeGreetingSave => '保存';

  @override
  String get settingsHomeGreetingSaved => '保存しました';

  @override
  String get settingsAboutDialogAuthor => '作者';

  @override
  String get settingsAboutDialogRepo => 'リポジトリ';

  @override
  String get settingsAboutDialogLicense => 'ライセンス';

  @override
  String get settingsAboutDialogCopyright => '著作権';

  @override
  String get settingsAboutDialogClose => '閉じる';

  @override
  String settingsAboutDialogVersionLabel(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutDialogBuildLabel(String buildNumber) {
    return 'ビルド $buildNumber';
  }

  @override
  String get settingsAboutDialogVersionTapHint => 'タップして更新を確認';

  @override
  String get settingsAboutUpdateChecking => '更新を確認しています…';

  @override
  String get settingsAboutUpdateAlreadyLatest => '最新バージョンです';

  @override
  String get settingsAboutUpdateAvailableTitle => 'アップデートがあります';

  @override
  String settingsAboutUpdateAvailableBody(String latest, String current) {
    return '最新は v$latest です。お使いのバージョンは v$current です。';
  }

  @override
  String get settingsAboutUpdateOpenReleases => 'リリースページを開く';

  @override
  String get settingsAboutUpdateCheckFailed => '更新を確認できませんでした';

  @override
  String get settingsAboutUpdateNoRelease => 'このリポジトリには GitHub のリリースがありません';

  @override
  String get settingsSponsorTitle => '支援・スポンサー';

  @override
  String get settingsSponsorSubtitle => '無料アプリ · Star と任意のチップ';

  @override
  String get settingsSponsorSectionFreeTitle => 'Yeah Music は完全無料';

  @override
  String get settingsSponsorSectionFreeBody =>
      'Yeah Music は無料で利用でき、「有料で機能解放」のような仕組みはありません。非公式の「購入」をうたう第三者への支払いは避けてください。開発は趣味時間での運用です。以下は任意の支援であり、機能には一切影響しません。';

  @override
  String get settingsSponsorSectionStarTitle => 'GitHub で Star';

  @override
  String get settingsSponsorSectionStarHint =>
      'Star は無料で、リポジトリの発見やリリース情報の把握に役立ちます。';

  @override
  String get settingsSponsorRepoYeahMusicTitle => 'Yeah Music';

  @override
  String get settingsSponsorRepoYeahMusicSubtitle => 'このプレーヤーのソースコード';

  @override
  String get settingsSponsorRepoDynamicSql2Title => 'dynamic-sql2';

  @override
  String get settingsSponsorRepoDynamicSql2Subtitle =>
      '動的 SQL / Java DSL の OSS';

  @override
  String get settingsSponsorEasterEggTriggerLine => 'お支払い／チップの方法';

  @override
  String get settingsSponsorEasterEggDialogTitle => '残念';

  @override
  String get settingsSponsorEasterEggDialogBody =>
      'お金？ お断りです。このプロジェクトは趣味と愛で回しています。';

  @override
  String get settingsSponsorExternalHint =>
      'ブラウザなど外部で開きます。信頼できるページだけで操作してください。チップで機能が解放されることはありません。';

  @override
  String get settingsSponsorCopyLink => 'リンクをコピー';

  @override
  String get settingsSponsorLinkCopied => 'コピーしました';

  @override
  String get settingsSponsorLaunchFailed => 'リンクを開けませんでした';

  @override
  String get settingsSysinfoSectionDevice => '端末情報';

  @override
  String get settingsSysinfoSectionStorage => 'ストレージ';

  @override
  String get settingsSysinfoPlatformLabel => '実行プラットフォーム';

  @override
  String get settingsSysinfoTotalSpace => '合計容量';

  @override
  String get settingsSysinfoUsedSpace => '使用済み';

  @override
  String get settingsSysinfoFreeSpace => '空き容量';

  @override
  String get settingsSysinfoStorageUnavailable => 'ストレージ情報を取得できません。';

  @override
  String get settingsSysinfoDeviceModel => 'モデル';

  @override
  String get settingsSysinfoManufacturer => '製造元';

  @override
  String get settingsSysinfoOsVersion => 'OS バージョン';

  @override
  String get settingsSysinfoSdkVersion => 'SDK バージョン';

  @override
  String get settingsSysinfoDeviceName => '端末名';

  @override
  String get settingsSysinfoHostName => 'コンピューター名';

  @override
  String get settingsSysinfoKernelVersion => 'カーネル';

  @override
  String get settingsSysinfoDistroLabel => 'バージョン';

  @override
  String get settingsSysinfoBuildNumber => 'ビルド';

  @override
  String get settingsSysinfoError => 'エラー';

  @override
  String get settingsSysinfoFetchFailed => '端末情報を取得できませんでした。';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSubtitle => 'UI の表示言語';

  @override
  String get settingsLanguageDesc => 'メニューや画面の言語を選びます。曲情報はファイルのタグに従います。';

  @override
  String get settingsOneDrive => 'OneDrive';

  @override
  String get settingsOneDriveSubtitle => 'Microsoft アカウント・フォルダ・ダウンロード先';

  @override
  String get settingsOneDriveDesc =>
      'Microsoft でサインイン（リリース版ではクライアント ID の入力は不要）。音楽の参照ルート、クラウドのアプリ用フォルダ、ローカルの保存先を設定できます。再生を始めるとき、保存先フォルダーが存在すればそこへ、なければアプリデータ内の既定キャッシュに保存します。';

  @override
  String get settingsPlaybackShortcutsTitle => 'キーボードショートカット';

  @override
  String get settingsPlaybackShortcutsSubtitle => '再生・一時停止・前の曲・次の曲';

  @override
  String get settingsPlaybackShortcutsPlayPause => '再生 / 一時停止';

  @override
  String get settingsPlaybackShortcutsPrevious => '前の曲';

  @override
  String get settingsPlaybackShortcutsNext => '次の曲';

  @override
  String get settingsPlaybackShortcutsChange => '変更…';

  @override
  String get settingsPlaybackShortcutsDisable => 'オフ';

  @override
  String get settingsPlaybackShortcutsEnable => 'オン';

  @override
  String get settingsPlaybackShortcutsDisabledLabel => 'オフ';

  @override
  String get settingsPlaybackShortcutsPressKey => '新しいショートカット';

  @override
  String get settingsPlaybackShortcutsPressKeyHint =>
      '使うキーの組み合わせを押してください。Esc でキャンセル。';

  @override
  String get settingsPlaybackShortcutsUnavailableBody =>
      'キーボードショートカットは Windows / macOS / Linux のデスクトップ版でのみ変更できます。';

  @override
  String get settingsWireRemoteTitle => 'ヘッドセット操作';

  @override
  String get settingsWireRemoteSubtitle =>
      '有線の連打と Bluetooth の次へ／戻るキー（アプリが手前のとき）';

  @override
  String get settingsWireRemoteSubtitleOtherPlatforms =>
      'カスタム割り当ては Android アプリが手前のときのみ有効です。';

  @override
  String get settingsWireRemoteUnavailableTitle => 'この環境では編集できません';

  @override
  String get settingsWireRemoteUnavailableBody =>
      'ヘッドセットの割り当ては Android でアプリが手前のときのみ（有線の連打と Bluetooth のメディアキー）。デスクトップはキーボードショートカット、iOS は OS の既定動作です。';

  @override
  String get settingsWireRemoteUseCustom => 'カスタム割り当て';

  @override
  String get settingsWireRemoteUseCustomSubtitle =>
      'オフのときはヘッドセットは OS の既定の動作になります。';

  @override
  String get wireRemoteSingleTitle => 'シングルクリック';

  @override
  String get wireRemoteDoubleTitle => 'ダブルクリック';

  @override
  String get wireRemoteTripleTitle => 'トリプルクリック';

  @override
  String get wireRemoteMediaNextTitle => '「次へ」メディアキー（Bluetooth など）';

  @override
  String get wireRemoteMediaPreviousTitle => '「戻る」メディアキー（Bluetooth など）';

  @override
  String get wireRemoteActionPlayPause => '再生 / 一時停止';

  @override
  String get wireRemoteActionNext => '次の曲';

  @override
  String get wireRemoteActionPrevious => '前の曲';

  @override
  String get wireRemoteActionNone => 'なし';

  @override
  String get wireRemotePickActionTitle => '動作を選ぶ';

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
  String get oneDriveSectionAccount => 'アカウント';

  @override
  String get oneDriveSectionPaths => 'フォルダとストレージ';

  @override
  String get oneDriveSectionSync => 'クラウド同期';

  @override
  String get oneDriveSyncMasterTitle => 'OneDrive に同期';

  @override
  String get oneDriveSyncMasterSubtitle =>
      '同期する項目を選びます。アップロードのたびにクラウドのアプリ用フォルダー配下へ「機種名 / yyyyMMddTHHmmss」を作成します。';

  @override
  String get oneDriveSyncItemUserPlaylists => 'マイプレイリスト';

  @override
  String get oneDriveSyncItemUserPlaylistsSubtitle =>
      'カバー画像・配色・リストと曲順（機種ごとのフォルダーに保存）。';

  @override
  String get oneDriveSyncItemHomeGreeting => 'ホームの挨拶（先頭カード）';

  @override
  String get oneDriveSyncItemHomeGreetingSubtitle => '設定 → ホームの挨拶と同じデータです。';

  @override
  String get oneDriveSyncItemQuickEntry => 'ホームのショートカット';

  @override
  String get oneDriveSyncItemQuickEntrySubtitle => '並び順と表示のオン／オフ。';

  @override
  String get oneDriveSyncItemPlaybackListsStats => '最近／再生回数と再生統計';

  @override
  String get oneDriveSyncItemPlaybackListsStatsSubtitle =>
      '最近再生リスト・再生回数・累計試聴時間（ホームと統計ページの Hive）。';

  @override
  String get oneDriveSyncItemLyricsUi => '歌詞と再生画面';

  @override
  String get oneDriveSyncItemLyricsUiSubtitle =>
      '歌詞スタイル、デスクトップ／車載歌詞、画面スリープ抑制など。';

  @override
  String get oneDriveSyncItemSongRecognition => '楽曲認識と履歴';

  @override
  String get oneDriveSyncItemSongRecognitionSubtitle =>
      '利用サービス、AudD / ACRCloud のトークン、端末側の認識履歴。';

  @override
  String get oneDriveSyncItemTheme => '背景テーマ';

  @override
  String get oneDriveSyncItemThemeSubtitle =>
      'グラデーション、プリセット／カスタム色と背景画像（UI 言語は含みません）。';

  @override
  String get oneDriveSyncFrequencyLabel => '同期の間隔';

  @override
  String get oneDriveSyncFreqManual => '手動のみ';

  @override
  String get oneDriveSyncFreq1h => '1 時間ごと';

  @override
  String get oneDriveSyncFreq6h => '6 時間ごと';

  @override
  String get oneDriveSyncFreq12h => '12 時間ごと';

  @override
  String get oneDriveSyncFreq24h => '24 時間ごと';

  @override
  String get oneDriveSyncNow => '今すぐ同期';

  @override
  String get oneDriveSyncNowDescription =>
      'チェックした項目をすぐアップロードします。クラウドのアプリ用フォルダー下に「機種名 / yyyyMMddTHHmmss」を作成します。';

  @override
  String get oneDriveSyncNowNeedLogin => '先に Microsoft にサインインしてください。';

  @override
  String get oneDriveSyncNowNeedCloudFolder =>
      '上の「クラウドのアプリ用フォルダ」を選ぶと、バックアップ先が分かります。';

  @override
  String get oneDriveSyncNowFinished => 'クラウドのアプリ用フォルダー内の同期ディレクトリへアップロードしました。';

  @override
  String oneDriveSyncNowFailed(String message) {
    return 'バックアップに失敗しました：$message';
  }

  @override
  String get oneDriveRestoreFromCloud => 'クラウドから復元';

  @override
  String get oneDriveRestoreSubtitle =>
      'バックアップの種類（旧レイアウトまたは機種別フォルダー）を選び、復元する内容にチェックします。';

  @override
  String get oneDriveRestoreSheetTitle => 'バックアップを選ぶ';

  @override
  String get oneDriveRestoreGroupThisDevice => 'このデバイス';

  @override
  String get oneDriveRestoreGroupOtherDevices => 'ほかのデバイス';

  @override
  String get oneDriveRestoreGroupLegacyFlat => '旧レイアウト';

  @override
  String get oneDriveRestoreContentSectionTitle => '復元する内容';

  @override
  String get oneDriveRestoreLoadMore => 'さらに表示';

  @override
  String oneDriveRestoreListShowing(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get oneDriveRestoreTabUnknownDevice => '不明なデバイス';

  @override
  String get oneDriveRestoreEmpty => 'バックアップがまだありません。先に「今すぐ同期」でアップロードしてください。';

  @override
  String get oneDriveRestorePlaylistCheckbox => 'プレイリスト';

  @override
  String get oneDriveRestoreLegacySettingsCheckbox => '旧形式の設定ファイル一式';

  @override
  String get oneDriveRestoreSliceHomeGreeting => 'ホームの挨拶';

  @override
  String get oneDriveRestoreSliceQuickEntry => 'ホームのショートカット';

  @override
  String get oneDriveRestoreSlicePlaybackLists => '最近再生と統計（Hive）';

  @override
  String get oneDriveRestoreSliceLyricsUi => '歌詞と画面スリープ抑制';

  @override
  String get oneDriveRestoreSliceSongRecognition => '楽曲認識と履歴';

  @override
  String get oneDriveRestoreSliceTheme => '背景テーマ';

  @override
  String get oneDriveRestorePlaylistModeMerge => 'ローカルとマージ（同じ id は曲を結合）';

  @override
  String get oneDriveRestorePlaylistModeReplace => 'ローカルを置き換え（いったん消してから取り込み）';

  @override
  String get oneDriveRestoreAction => '復元';

  @override
  String get oneDriveRestoreNeedPickContent => '復元する項目を少なくとも 1 つ選んでください。';

  @override
  String get oneDriveRestoreMissingPlaylistsFile =>
      'このバックアップにプレイリストファイルがありません。';

  @override
  String get oneDriveRestoreMissingSettingsFile => 'このバックアップに旧形式の設定ファイルがありません。';

  @override
  String oneDriveBackupSnapshotDeviceSession(
    String deviceName,
    String sessionStamp,
  ) {
    return '$deviceName · $sessionStamp';
  }

  @override
  String get oneDriveSyncNowNeedMasterOn => '先に上の「OneDrive に同期」をオンにしてください。';

  @override
  String get oneDriveSyncNowNothingSelected => '同期する項目を少なくとも 1 つオンにしてください。';

  @override
  String get oneDriveRestoreFinished => '復元が完了しました。';

  @override
  String oneDriveRestoreFailed(String message) {
    return '復元に失敗しました：$message';
  }

  @override
  String get oneDriveRestoreLoadingList => 'バックアップ一覧を読み込み中…';

  @override
  String get oneDriveSyncNowInProgress => '同期中…';

  @override
  String get oneDriveRestoreInProgress => '復元中…';

  @override
  String get oneDriveCloudAppDataTitle => 'クラウドのアプリ用フォルダ';

  @override
  String get oneDriveCloudAppDataSubtitle => '設定バックアップ・プレイリスト・同期などに予定。';

  @override
  String get oneDriveCloudAppFolderUnset => '未設定';

  @override
  String get oneDriveLocalDownloadTitle => 'ローカルのダウンロード先';

  @override
  String get oneDriveLocalDownloadSubtitle =>
      'クラウドから再生するとき、このフォルダーが存在すればそこへ保存します。未設定またはパスが無いときは下の既定ストレージを使います。';

  @override
  String get oneDriveLocalDownloadUnset => '未設定（後で既定の場所を使います）';

  @override
  String get oneDriveChooseCloudFolder => 'OneDrive で選ぶ';

  @override
  String get oneDriveChooseLocalFolder => 'フォルダを選ぶ…';

  @override
  String get oneDrivePickFolderForAppData => 'アプリデータと今後のバックアップ用フォルダを選びます。';

  @override
  String get oneDrivePickFolderForMusicUpload =>
      'この端末からアップロードするときの保存先フォルダーを選びます。';

  @override
  String get oneDriveMusicUploadFolderTitle => '音楽アップロード先フォルダー';

  @override
  String get oneDriveMusicUploadFolderSubtitle =>
      'ローカルライブラリから OneDrive へ上げるときの既定の親フォルダー。未設定のときは上のアプリ用フォルダーを使います。';

  @override
  String get oneDriveMusicUploadFolderFallback => 'アプリ用フォルダーと同じ';

  @override
  String get oneDriveAppMissingClientConfig =>
      'この版ではまだ Microsoft サインインが使えません。ストア版に更新するか、最新版を入れ直してみてください。';

  @override
  String get oneDriveNeedSignInForPicker =>
      '先にサインインしてから OneDrive のフォルダを選んでください。';

  @override
  String get oneDriveClear => 'クリア';

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
  String get oneDriveSignInFailed => 'サインインできませんでした。通信を確認して再度お試しください。';

  @override
  String get oneDriveCacheNote =>
      '既定はアプリデータ内の onedrive_cache です。上で選んだフォルダーが存在し、かつフォルダーのときだけそこへ書き込みます。';

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
  String get oneDriveDownloadQueueTitle => 'OneDrive ダウンロード';

  @override
  String get oneDriveTransferQueueTitle => 'OneDrive 転送';

  @override
  String get oneDriveTransferTabDownload => 'ダウンロード';

  @override
  String get oneDriveTransferTabUpload => 'アップロード';

  @override
  String get oneDriveDownloadPause => '一時停止';

  @override
  String get oneDriveDownloadResume => '再開';

  @override
  String get oneDriveDownloadStopAll => 'すべて停止';

  @override
  String get oneDriveDownloadContinueAll => 'すべて再開';

  @override
  String get oneDriveDownloadAutoPlayWhenDone => 'キュー完了後に自動再生';

  @override
  String get oneDriveDownloadPlayDownloaded => 'ダウンロード済みを再生';

  @override
  String get oneDriveDownloadStatusPending => '待機';

  @override
  String get oneDriveDownloadStatusDownloading => 'ダウンロード中';

  @override
  String get oneDriveDownloadStatusDone => '完了';

  @override
  String get oneDriveDownloadStatusFailed => '失敗';

  @override
  String get oneDriveDownloadStatusCancelled => 'キャンセル';

  @override
  String get oneDriveDownloadCloseJustPanel => 'パネルを閉じる（ダウンロードは続行）';

  @override
  String get oneDriveDownloadQueueEmpty =>
      'まだありません。\nクラウドライブラリまたはブラウザで「すべて再生」を使うとここに表示されます。パネルを閉じてもダウンロードは続きます。';

  @override
  String get oneDriveUploadQueueEmpty =>
      'アップロードはまだありません。\nローカルライブラリの一括バーから「OneDrive にアップロード」で追加できます。';

  @override
  String get oneDriveTransferQueueEmpty => 'キューに項目はありません。';

  @override
  String get oneDriveDownloadQueuePageHint =>
      '一時停止・再開・停止はここで。パネルを閉じてもバックグラウンドのダウンロードは止まりません。';

  @override
  String get oneDriveUploadQueuePageHint =>
      '端末からのアップロードはここに表示されます。上のボタンで一時停止・再開・停止できます。履歴を消すとダウンロード履歴も消えます。';

  @override
  String get oneDriveDownloadQueueSubtitle => 'アップロード・ダウンロードと再生';

  @override
  String get oneDriveDownloadQueueTooltip => 'ダウンロードキュー';

  @override
  String get oneDriveBrowserRefreshTooltip =>
      'このフォルダを更新（一覧キャッシュを消去してクラウドから再取得）';

  @override
  String oneDriveEnqueueAddedSingle(String name) {
    return '「$name」をキューに追加しました。';
  }

  @override
  String oneDriveEnqueueAddedMany(int count) {
    return '$count 曲をキューに追加しました。';
  }

  @override
  String get oneDriveDownloadViewQueue => 'キューを開く';

  @override
  String get oneDriveDownloadClearHistory => '履歴を消去';

  @override
  String get oneDriveTransferClearDownloadsList => 'ダウンロード一覧をクリア';

  @override
  String get oneDriveTransferClearUploadsList => 'アップロード一覧をクリア';

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
      '追加したフォルダーを再帰的にスキャンしてリスト化。タップでオンデマンド取得（カスタム保存先があるときはそこへ、なければ既定キャッシュ）。取得済みはオフライン再生可能。';

  @override
  String get oneDriveCloudLibraryEmpty =>
      'まだありません。\nOneDrive でフォルダーを選んでから「再スキャン」してください。';

  @override
  String get oneDriveCachedPlaylistTitle => 'OneDrive · キャッシュ';

  @override
  String get oneDriveCachedPlaylistEmpty =>
      'OneDrive からダウンロードされた曲がありません。クラウド曲庫から再生すると、アプリのキャッシュまたは設定したダウンロード先に保存されます。';

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
  String get oneDrivePickMultipleFoldersHint =>
      'チェックボックスでフォルダーを選びます。矢印で開いてさらに選べます。';

  @override
  String get oneDriveIncludeOpenFolderInSelection => '開いているフォルダーを含める';

  @override
  String oneDriveAddSelectedFoldersAction(int count) {
    return '追加（$count）';
  }

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
  String get oneDriveLastIndexedNever => '最終スキャン: —';

  @override
  String get oneDriveIndexFoldersRecursiveHint =>
      'スキャンはサブフォルダーを含みます。追加したフォルダー配下の音声ファイルがすべて一覧に含まれます。';

  @override
  String get oneDriveRemoveIndexFolderTitle => 'インデックスから外しますか？';

  @override
  String oneDriveRemoveIndexFolderMessage(String name) {
    return '「$name」をインデックスから外しますか？このフォルダーとその下のトラックは一覧から消えます。あとから追加し直せます。';
  }

  @override
  String get oneDriveRemoveIndexFolderAction => '外す';

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
  String get themeGradientRgbSectionTitle => 'グラデーション背景';

  @override
  String get themeGradientRgbSectionSubtitle =>
      'プレイリストカバーと同じ RGB スライダーで、両端の色と向きを調整できます。';

  @override
  String get themeGradientRgbFineTune => '色と向きを編集…';

  @override
  String get themeGradientRgbDialogTitle => '背景のグラデーション';

  @override
  String get actionSelect => '選択';

  @override
  String get fogBackground => '背景のぼかし・暗さ';

  @override
  String get fogBackgroundDesc =>
      '読みやすさのため壁紙をぼかして暗くします。弱めでもベースの減光と上下のわずかなビネットは維持します。模様やコントラストが強い写真は強めがおすすめ。既定は 45%。';

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
  String get themeWallpaperSavedRestartHint =>
      '壁紙を保存しました。画面が変わらない場合は、アプリを完全に終了してから開き直してください。';

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
  String get homePullLoftTitle => 'この端末から再読み込み';

  @override
  String get homePullReleaseHint => '離すと保存済み設定を読み込みます';

  @override
  String get homePullEmptyTease => 'ここには何もありません。引き続けてもムダですよ。';

  @override
  String get homePullStepThemeWallpaper => 'テーマ（色・グラデーション・壁紙）';

  @override
  String get homePullStepBrightnessMode => '外観（ライト／ダーク）';

  @override
  String get homePullStepLanguage => '表示言語';

  @override
  String get homePullStepPlaylistsCarousel => 'プレイリストとホーム横スクロール順';

  @override
  String get homePullStepShortcuts => 'ホームのショートカット';

  @override
  String get homePullStepRecentTopPlayed => '最近再生と再生回数';

  @override
  String get homePullStepLyricsDisplay => '歌詞表示（保存データを再読み込み）';

  @override
  String get homePullStepPlaybackPrefs => '再生モード（シャッフル／リピートなど）';

  @override
  String get homePullRefreshDone => '端末の保存済み設定を再読み込みしました。';

  @override
  String homePullRefreshFailed(String error) {
    return '端末からの再読み込みに失敗しました：$error';
  }

  @override
  String get homeMenuTooltip => 'メニュー';

  @override
  String get homeSearchTooltip => '検索';

  @override
  String get homeQuickEntryEmpty =>
      'ショートカットはありません。「管理」からライブラリ・プレイリスト・OneDrive キャッシュなどを表示できます。';

  @override
  String get homeEntryLibrary => 'ライブラリ';

  @override
  String get homeEntryMyPlaylists => 'マイプレイリスト';

  @override
  String get homeEntryRecent => '最近再生';

  @override
  String get homeEntryMostPlayed => 'よく聴く';

  @override
  String get homeEntryDiscover => '見つける';

  @override
  String get homeEntryCloudLibrary => 'クラウド曲庫';

  @override
  String get homeEntryOneDriveCachePlaylist => 'キャッシュのプレイリスト';

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
  String get mostPlayedSwitchSortAscending => '再生回数の昇順に切り替え（少ない順）';

  @override
  String get mostPlayedSwitchSortDescending => '再生回数の降順に切り替え（多い順）';

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
  String get playbackFailedSnackMessage =>
      'この曲を再生できません。ファイルがない、読み取れない、または非対応形式の可能性があります。';

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
  String get menuPlayNextAfterCurrent => '現在の曲の次に再生';

  @override
  String get libraryPlayNextAfterCurrentQueued => '現在の曲が終わったあとにこの曲を再生します。';

  @override
  String get libraryPlayNextAfterCurrentNotInQueue => 'この曲は現在の再生キューにありません。';

  @override
  String get tooltipDone => '完了';

  @override
  String get tooltipMoreActions => '操作';

  @override
  String get tooltipMore => 'その他';

  @override
  String get tooltipLyricStyle => '歌詞の見た目';

  @override
  String get songPageMoreSheetTitle => 'その他の操作';

  @override
  String get songPageMoreQueryMetadata => 'メタデータを表示';

  @override
  String get songPageMoreUploadOneDrive => 'OneDrive にアップロード';

  @override
  String get songPageMoreShare => '共有';

  @override
  String get songPageMoreEditMusicTagsExternal => '外部アプリでタグを編集…';

  @override
  String get songPageMoreEditMusicTagsInline => '埋め込みタグを編集…';

  @override
  String get songPageInlineTagsUnstableTitle => '確認';

  @override
  String get songPageInlineTagsUnstableBody =>
      'この機能はまだ十分に安定しておらず、書き込みでファイルのメタデータが壊れることがあります。続行する前に曲をコピーや複製でバックアップすることをおすすめします。';

  @override
  String get songPageInlineTagsUnstableContinue => '続行する';

  @override
  String get songPageInlineTagsUnstableCancel => 'キャンセル';

  @override
  String get songPageInlineTagsEditorTitle => '埋め込みタグを編集';

  @override
  String get songPageInlineTagsFieldTitle => 'タイトル';

  @override
  String get songPageInlineTagsFieldArtist => 'アーティスト';

  @override
  String get songPageInlineTagsFieldAlbum => 'アルバム';

  @override
  String get songPageInlineTagsCoverSection => '埋め込みカバー';

  @override
  String get songPageInlineTagsCoverReplace => '画像を選んでトリミング…';

  @override
  String get songPageInlineTagsCoverRemove => 'カバーを削除';

  @override
  String get songPageInlineTagsCoverInvalid => 'JPEG または PNG を選んでください。';

  @override
  String get songPageInlineTagsFieldYear => '年';

  @override
  String get songPageInlineTagsFieldTrackNumber => 'トラック番号';

  @override
  String get songPageInlineTagsFieldTrackTotal => '総トラック数';

  @override
  String get songPageInlineTagsFieldDiscNumber => 'ディスク番号';

  @override
  String get songPageInlineTagsFieldDiscTotal => '総ディスク数';

  @override
  String get songPageInlineTagsFieldLyrics => '歌詞';

  @override
  String get songPageInlineTagsSave => '保存';

  @override
  String get songPageInlineTagsSaved => 'ファイルに保存しました';

  @override
  String songPageInlineTagsSaveFailed(Object error) {
    return 'タグを保存できませんでした：$error';
  }

  @override
  String get songPageStorageManageAllFilesHint =>
      '共有ストレージ内の音声を編集・削除するには「すべてのファイルへのアクセス」が必要です。設定で許可してから再度お試しください。';

  @override
  String get audioQualityTierLq => 'エコノミー';

  @override
  String get audioQualityTierStd => '標準';

  @override
  String get audioQualityTierHq => '高音質';

  @override
  String get audioQualityTierSq => 'ロスレス（CD相当）';

  @override
  String get audioQualityTierHr => 'ハイレゾ';

  @override
  String get audioQualityTierDsd => 'DSD・最上位';

  @override
  String get songPageMoreEditLyricsExternal => 'SyncedLyricEditor で編集…';

  @override
  String get songPageSyncedLyricEditorNotInstalled =>
      'SyncedLyric Editor が未インストールのため開けません。';

  @override
  String get songPageSyncedLyricEditorLaunchFailed =>
      'SyncedLyric Editor を開けませんでした。';

  @override
  String get songPageMusicTagEditorUnsupportedPlatform =>
      '外部でのタグ編集は Android のみ対応です。';

  @override
  String get songPageMusicTagEditorFileNotFound => '音声ファイルが見つかりません。';

  @override
  String get songPageMusicTagEditorNotInstalled =>
      'Music Tag Editor が未インストールのため開けません。';

  @override
  String get songPageMusicTagEditorCannotSharePath => 'この場所から他アプリで開けません。';

  @override
  String get songPageMusicTagEditorLaunchFailed =>
      'Music Tag Editor を開けませんでした。';

  @override
  String get songPageMetadataDialogTitle => 'オーディオのメタデータ';

  @override
  String get songPageMetadataReadFailed => 'メタデータを読み取れませんでした。';

  @override
  String get songPageShareFileNotFound => 'ディスク上にファイルが見つかりません。';

  @override
  String get songPageDeleteDiskWarningTitle => 'ディスクから削除しますか？';

  @override
  String get songPageDeleteDiskWarningBody =>
      '端末ストレージから音声ファイルを完全に削除します。取り消せません。プレイリストと再生履歴からも削除されます。';

  @override
  String get songPageDeleteContinue => '削除へ進む';

  @override
  String get songPageDeleteFinalConfirmTitle => '削除の確認';

  @override
  String songPageDeleteFinalConfirmBody(Object fileName) {
    return '「$fileName」を削除しますか？';
  }

  @override
  String get songPageMetaFieldTitle => 'タイトル';

  @override
  String get songPageMetaFieldArtist => 'アーティスト';

  @override
  String get songPageMetaFieldAlbum => 'アルバム';

  @override
  String get songPageMetaFieldDuration => '長さ';

  @override
  String get songPageMetaFieldBitrate => 'ビットレート';

  @override
  String get songPageMetaFieldSampleRate => 'サンプルレート';

  @override
  String get songPageMetaFieldYear => '年';

  @override
  String get songPageMetaFieldTrack => 'トラック';

  @override
  String get songPageMetaFieldDisc => 'ディスク';

  @override
  String get songPageMetaFieldPath => 'パス';

  @override
  String get songPageMetaFieldSize => 'ファイルサイズ';

  @override
  String get songPageMetaFieldGenre => 'ジャンル';

  @override
  String get songPageMetaFieldPerformers => '参加アーティスト';

  @override
  String get songPageMetaFieldLanguage => '言語';

  @override
  String get songPageMetaFieldEmbeddedLyrics => '埋め込み歌詞';

  @override
  String get songPageMetaFieldFormat => '形式';

  @override
  String get songPageMetaSectionTags => 'タグ';

  @override
  String get songPageMetaSectionAudio => '音声';

  @override
  String get songPageMetaSectionFile => 'ファイル';

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
  String get playlistCoverStyleTitle => 'カバー色';

  @override
  String get playlistCoverStyleSubtitle =>
      'ホームのカードと一覧のサムネイルに使います。「プリセット順」では並びに沿って自動配色します。グラデーションは開始・終了の2色を自由に設定できます。';

  @override
  String get playlistCoverUseDefaultPalette => 'プリセットを順に使う';

  @override
  String get playlistCoverSolidSection => '単色';

  @override
  String get playlistCoverGradientSection => 'グラデーション';

  @override
  String get playlistCoverCustomGradientTitle => 'カスタムグラデーション';

  @override
  String get playlistCoverGradientStartColor => '開始色';

  @override
  String get playlistCoverGradientEndColor => '終了色';

  @override
  String get playlistCoverGradientSwapColors => '色を入れ替え';

  @override
  String get playlistCoverGradientDirectionTitle => 'グラデーションの向き';

  @override
  String get playlistCoverGradientDirHorizontalLR => '左から右';

  @override
  String get playlistCoverGradientDirHorizontalRL => '右から左';

  @override
  String get playlistCoverGradientDirVerticalTB => '上から下';

  @override
  String get playlistCoverGradientDirVerticalBT => '下から上';

  @override
  String get playlistCoverGradientDirDiagonalTLBR => '対角（左上→右下）';

  @override
  String get playlistCoverGradientDirDiagonalTRBL => '対角（右上→左下）';

  @override
  String get playlistCoverGradientDirDiagonalBRTL => '対角（右下→左上）';

  @override
  String get playlistCoverGradientDirDiagonalBLTR => '対角（左下→右上）';

  @override
  String get playlistCoverRgbTitle => 'RGB を指定';

  @override
  String get playlistCoverRgbRed => '赤';

  @override
  String get playlistCoverRgbGreen => '緑';

  @override
  String get playlistCoverRgbBlue => '青';

  @override
  String get playlistCoverRgbPreview => 'プレビュー';

  @override
  String get playlistCoverPreviewLabel => '現在の見え方';

  @override
  String get playlistCoverMenuItem => 'カバー色…';

  @override
  String get playlistCoverPictureSection => '画像';

  @override
  String get playlistCoverPickImage => '画像を選ぶ…';

  @override
  String get playlistCoverRemoveImage => '画像を削除';

  @override
  String get imageCropTitle => '画像をトリミング';

  @override
  String get imageCropFailure => 'トリミングできませんでした。';

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
  String librarySongsDeletedN(int n) {
    return '$n 曲を削除しました';
  }

  @override
  String get fabNewPlaylist => '新規プレイリスト';

  @override
  String get emptyPlaylistsHint =>
      'プレイリストはまだありません。\n再生画面や曲一覧から曲を追加できます。\n\n右上の「⋮」から取り込みや複数選択ができます。';

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
  String get queuePendingPlayAfterCurrentSection => '次に再生（予約）';

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
  String get songPageKeepScreenAwake => '再生画面で画面オンのまま';

  @override
  String get lyricStyleKeepScreenAwakeSub => '再生画面で歌詞を読む間はスリープしません';

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
  String get lyricStyleActiveGradientTitle => '再生中行のグラデーション';

  @override
  String get lyricStyleStateGradientSub =>
      'オンにすると、この二色グラデーションが上の原文・訳文の単色より優先されます。オフのときは単色のみ。方向と RGB はプレイリストカバー編集と共通です。';

  @override
  String get lyricStyleActiveGradientTune => 'グラデーションを編集';

  @override
  String get lyricStyleActiveGradientDialogTitle => '再生中行のグラデーション';

  @override
  String get lyricStylePlayedGradientTitle => '過去の行のグラデーション';

  @override
  String get lyricStyleUpcomingGradientTitle => 'これからの行のグラデーション';

  @override
  String get lyricStylePlayedGradientDialogTitle => '過去の行のグラデーション';

  @override
  String get lyricStyleUpcomingGradientDialogTitle => 'これからの行のグラデーション';

  @override
  String get lyricColorPickerHint => '色をタップ';

  @override
  String get lyricLabelOriginal => '原文';

  @override
  String get lyricLabelTranslation => '訳文';

  @override
  String get libraryBatchSelect => '選択';

  @override
  String get libraryBatchDone => '完了';

  @override
  String get libraryBatchSelectAll => 'すべて';

  @override
  String get libraryBatchDelete => '削除';

  @override
  String get libraryBatchRename => '名前変更';

  @override
  String get libraryBatchUploadOneDrive => 'OneDrive にアップロード';

  @override
  String get libraryBatchDeleteConfirmTitle => '選択した曲を削除しますか？';

  @override
  String get libraryBatchDeleteConfirmMessage =>
      '端末からファイルが削除され、プレイリストなどの参照が更新されます。取り消せません。';

  @override
  String get libraryBatchNoneSelected => '曲を選択してください';

  @override
  String get libraryBatchRenameTitle => '一括リネーム';

  @override
  String get libraryBatchRenameHint => 'パターン（%n は連番。例: Track %n）';

  @override
  String get libraryBatchRenameStart => '開始番号';

  @override
  String get libraryRenameSingleTitle => '1 曲だけ名前変更';

  @override
  String get libraryRenameSingleHint => '拡張子なしのファイル名だけを入力してください。';

  @override
  String get libraryRenameSingleFieldLabel => '名前';

  @override
  String get libraryRenameSingleDone => '名前を変更しました';

  @override
  String get libraryCloneSong => '曲を複製';

  @override
  String get libraryCloneSongTitle => '新しいファイルとして複製';

  @override
  String get libraryCloneSongHint =>
      'コピーの名前を入力してください（拡張子は元と同じです）。同じフォルダに保存されます。';

  @override
  String get libraryCloneSongDefaultSuffix => ' のコピー';

  @override
  String get libraryCloneSongDone => '複製しました';

  @override
  String get libraryCloneSongFailed => '複製できませんでした';

  @override
  String get libraryCloneSongProgressTitle => '曲を複製しています';

  @override
  String get libraryCloneSongProgressMessage => 'ファイルをコピーしてライブラリを更新しています…';

  @override
  String get libraryBatchUploadNeedSignIn => '設定から OneDrive にサインインしてください';

  @override
  String get libraryBatchUploadNeedCloudFolder =>
      '設定で OneDrive のアプリ用フォルダーを選んでください';

  @override
  String get libraryBatchUploadNeedParentFolder =>
      '設定で音楽アップロード用フォルダーまたはアプリ用フォルダーを選んでください。';

  @override
  String get libraryBatchUploadQueued => '転送キューに追加しました';

  @override
  String get libraryBatchOpenQueue => 'キューを開く';

  @override
  String get libraryBatchAddToPlaylist => 'プレイリストに追加';

  @override
  String libraryBatchAddToPlaylistSheetTitle(int count) {
    return '$count 曲をユーザープレイリストに追加';
  }

  @override
  String get libraryBatchAddToPlaylistSheetHelp =>
      'チェック済みは、選択したすべての曲がすでに含まれているプレイリストです。確定すると選択した各曲に対して反映されます。';

  @override
  String get libraryBatchAddToPlaylistDone => 'プレイリストを更新しました';

  @override
  String get libraryReloadMetadata => '埋め込みメタデータを再読み込み';

  @override
  String get libraryReloadMetadataDone => 'ファイルからメタデータを再読み込みしました';

  @override
  String get oneDriveUploadStatusUploading => 'アップロード中';

  @override
  String get oneDriveTaskDirectionUpload => 'アップロード';

  @override
  String get homeEntrySongRecognizer => '楽曲認識';

  @override
  String get songRecognizerTitle => '楽曲認識';

  @override
  String get songRecognizerModeInApp => 'アプリ内';

  @override
  String get songRecognizerModeAmbient => '環境モード';

  @override
  String get songRecognizerModeInAppHelp =>
      'この画面のまま、再生中の音源に近づけ、約 10 秒録音すると精度が上がります。';

  @override
  String get songRecognizerModeAmbientHelp =>
      'オンにすると約 20 秒ごとに自動で録音・認識します。スピーカーや他アプリの音に近づけてください。バックグラウンドでは端末によりマイクが止まることがあります。';

  @override
  String get songRecognizerStart => '聴き取り開始';

  @override
  String get songRecognizerSnackbarStarted => '認識を開始…';

  @override
  String get songRecognizerSnackbarCancelled => '認識をキャンセルしました';

  @override
  String get songRecognizerStopAmbient => '環境モード停止';

  @override
  String get songRecognizerListening => '録音中…';

  @override
  String get songRecognizerRecognizing => '認識中…';

  @override
  String get songRecognizerHistory => '履歴';

  @override
  String get songRecognizerHistoryEmpty => 'まだありません';

  @override
  String get songRecognizerHistoryFilterAll => 'すべて';

  @override
  String get songRecognizerHistoryFilterMatched => '一致のみ';

  @override
  String get songRecognizerHistoryFilterArchived => 'お気に入り';

  @override
  String get songRecognizerHistoryEmptyMatched => '一致した曲の履歴はまだありません。';

  @override
  String get songRecognizerHistoryEmptyArchived => 'お気に入りはまだありません。';

  @override
  String get songRecognizerDeleteHistoryEntryTitle => '履歴を削除';

  @override
  String get songRecognizerDeleteHistoryEntryMessage => 'この認識履歴を削除しますか？';

  @override
  String get songRecognizerSwipeArchive => 'お気に入り';

  @override
  String get songRecognizerSwipeRestore => '解除';

  @override
  String get songRecognizerSwipeDelete => '削除';

  @override
  String get songRecognizerEntryArchived => 'お気に入りに追加しました';

  @override
  String get songRecognizerEntryRestoredFromArchive => 'お気に入りから外しました';

  @override
  String get songRecognizerCopyEntry => 'コピー';

  @override
  String get songRecognizerEntryCopied => 'クリップボードにコピーしました';

  @override
  String get songRecognizerCopyLabelTime => '日時：';

  @override
  String get songRecognizerCopyLabelMode => '取得モード：';

  @override
  String get songRecognizerCopyLabelService => 'サービス：';

  @override
  String get songRecognizerCopyLabelSong => '曲名：';

  @override
  String get songRecognizerCopyLabelArtist => 'アーティスト：';

  @override
  String get songRecognizerCopyLabelAlbum => 'アルバム：';

  @override
  String get songRecognizerCopyLabelReleased => '発売日：';

  @override
  String get songRecognizerCopyLabelAppleMusic => 'Apple Music：';

  @override
  String get songRecognizerCopyLabelSpotify => 'Spotify：';

  @override
  String get songRecognizerCopyLabelNoMatch => '結果：';

  @override
  String get songRecognizerCopyLabelError => 'エラー：';

  @override
  String get songRecognizerClearHistory => '履歴を消去';

  @override
  String get songRecognizerClearHistoryConfirm => 'すべての履歴を削除しますか？';

  @override
  String get songRecognizerNoMatch => '一致する楽曲がありません。ノイズを減らして再試行してください。';

  @override
  String get songRecognizerOpenAppleMusic => 'Apple Music';

  @override
  String get songRecognizerOpenSpotify => 'Spotify';

  @override
  String get songRecognizerApiKey => 'AudD API トークン';

  @override
  String get songRecognizerApiKeyHelp =>
      'audd.io でトークンを作成して貼り付けてください。空欄は試用トークン（厳しい制限）です。';

  @override
  String get songRecognizerSave => '保存';

  @override
  String get songRecognizerMicDenied => 'マイクの許可が必要です';

  @override
  String get songRecognizerWebUnsupported => 'このブラウザでは楽曲認識に未対応です。';

  @override
  String get songRecognizerAccuracyTip =>
      'ヒント: 10〜12 秒、静かな環境でスピーカーに近づけると精度が上がります。';

  @override
  String get songRecognizerDuplicateSkipped => '直前と同じ結果のため省略しました';

  @override
  String get songRecognizerError => '認識に失敗しました';

  @override
  String get songRecognizerAmbientActive => '環境モード稼働中';

  @override
  String get songRecognizerTokenMenu => 'API トークン';

  @override
  String get songRecognizerCredentialsMenu => '認証情報';

  @override
  String get songRecognizerProviderLabel => '認識サービス';

  @override
  String get songRecognizerProviderAudd => 'AudD';

  @override
  String get songRecognizerProviderAcrcloud => 'ACRCloud';

  @override
  String get songRecognizerModeLabel => '取得モード';

  @override
  String get songRecognizerAcrTitle => 'ACRCloud プロジェクト';

  @override
  String get songRecognizerAcrHelp =>
      'コンソールの Host（例: identify-eu-west-1.acrcloud.com、https やパスは含めない）、Access Key、Access Secret を入力してください。';

  @override
  String get songRecognizerAcrHost => 'Host';

  @override
  String get songRecognizerAcrHostHint => 'identify-….acrcloud.com';

  @override
  String get songRecognizerAcrAccessKey => 'Access Key';

  @override
  String get songRecognizerAcrSecret => 'Secret Key';

  @override
  String get songRecognizerAcrIncomplete =>
      '下の Host、Access Key、Secret Key を入力して保存してから認識してください。';

  @override
  String get songRecognizerSectionApiConfig => 'API 設定';

  @override
  String get songRecognizerConfigHint =>
      '楽曲認識の画面で使うプロバイダーを選びます。この画面で各キーを入力して保存してください（端末内のみ）。';

  @override
  String get songRecognizerConfigSaved => '保存しました';

  @override
  String get songRecognizerAuddCardSubtitle => 'audd.io のトークン。空欄は制限付きテスト用。';

  @override
  String get songRecognizerAcrCardTitle => 'ACRCloud';

  @override
  String get songRecognizerAcrCardSubtitle =>
      'コンソールの Host、Access Key、Secret Key（音楽認識プロジェクト）。';

  @override
  String get songRecognizerOpenApiConfigSubtitle =>
      'AudD トークンと ACRCloud の Host / キー';

  @override
  String get songRecognizerMatchConfirmTitle => '認識結果';

  @override
  String get songRecognizerMatchConfirmArtistLabel => 'アーティスト';

  @override
  String get songRecognizerMatchConfirmAlbumLabel => 'アルバム';

  @override
  String get songRecognizerMatchConfirmReleaseLabel => '発売日';

  @override
  String get songRecognizerMatchConfirmYes => 'この曲です';

  @override
  String get songRecognizerMatchConfirmNo => '違う、もう一度';
}
