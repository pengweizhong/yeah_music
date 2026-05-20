import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:yeah_music/services/android_media_session_lyrics_channel.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// Android 通知栏歌词：跟进度流、行变化时原生直推 [displayTitle]。
/// 主开关关闭则不推送；子开关「同步当前歌词行」关时主标题为曲名，开时为实时歌词。
class AndroidCarLyricsSync {
  AndroidCarLyricsSync._();

  static PlayListProvider? _playlist;
  static ExternalLyricLineFormatter? _formatter;
  static LyricSettings _lyricStyle = LyricSettings();
  static StreamSubscription<int?>? _indexSubscription;
  static StreamSubscription<Duration>? _positionSubscription;
  static StreamSubscription<bool>? _playingSubscription;
  static bool _carLyricsEnabled = false;
  static bool _syncLyricsEnabled = false;

  /// 通知与车载歌词主开关。
  static bool get isFeatureEnabled => _carLyricsEnabled;

  /// 同步当前歌词行（须 [isFeatureEnabled]）。
  static bool get isSyncLyricsEnabled => _carLyricsEnabled && _syncLyricsEnabled;

  /// 行与行之间的间隙占位（不换行空格），避免闪曲名或重复上一句歌词。
  static const String notificationLyricGapLine = '\u00A0';

  static bool isNotificationLyricGapLine(String line) =>
      line == notificationLyricGapLine;

  static String? _publishedLineKey;
  static String? _hydrateInFlightPath;
  static int? _lastHandledPlayerIndex;
  static VoidCallback? _lyricsUiRevListener;

  static Future<void> applySettingsFromStorage() async {
    _carLyricsEnabled = await SettingsService.loadAndroidCarLyricsEnabled();
    _syncLyricsEnabled = _carLyricsEnabled
        ? await SettingsService.loadAndroidCarLyricsSyncLyrics()
        : false;
    await AndroidMediaSessionLyricsChannel.setCarNotificationEnabled(
      _carLyricsEnabled,
    );
    JustAudioBackground.setAndroidLyricsSyncEnabled(_syncLyricsEnabled);
    await AndroidMediaSessionLyricsChannel.setLyricsDisplayManaged(
      _syncLyricsEnabled,
    );
    if (_carLyricsEnabled) {
      JustAudioBackground.refreshNotificationPlaybackState();
    } else {
      _publishedLineKey = null;
      MusicService.resetAndroidNotificationLyricDedupe();
    }
    if (_carLyricsEnabled && !_syncLyricsEnabled) {
      _publishedLineKey = null;
      MusicService.resetAndroidNotificationLyricDedupe();
      final song = _songForPlayback();
      if (song != null) {
        MusicService.pushAndroidNotificationSongTitle(song);
      }
    }
    _rebindPositionListener();
    if (!_carLyricsEnabled) {
      _stopPlaybackListeners();
    } else if (_playlist != null) {
      _bindPlaybackListeners();
    }
  }

  static Future<void> refreshSyncEnabled() => applySettingsFromStorage();

  /// 歌词 UI / 显示模式从 Hive 更新后刷新通知栏（与 [MacosMenuBarLyricsGlue.reloadFromHive] 对齐）。
  static Future<void> reloadFromHive() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!_carLyricsEnabled) return;
    await _reloadLyricStyle();
    _formatter?.invalidate();
    _publishedLineKey = null;
    MusicService.resetAndroidNotificationLyricDedupe();
    _onPositionPulse();
  }

  static void _bindLyricsUiRevisionListener() {
    if (_lyricsUiRevListener != null) return;
    _lyricsUiRevListener = () {
      unawaited(reloadFromHive());
    };
    SettingsService.lyricsUiStorageRevision.addListener(_lyricsUiRevListener!);
  }

  static void _unbindLyricsUiRevisionListener() {
    final l = _lyricsUiRevListener;
    if (l == null) return;
    SettingsService.lyricsUiStorageRevision.removeListener(l);
    _lyricsUiRevListener = null;
  }

  static Future<void> attachIfNeeded(PlayListProvider playlist) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    if (_playlist == playlist && _indexSubscription != null) {
      await applySettingsFromStorage();
      return;
    }
    await attach(playlist);
  }

  static Future<void> _reloadLyricStyle() async {
    final raw = await SettingsService.loadLyricSettings();
    _lyricStyle = raw ?? LyricSettings();
    _lyricStyle.normalizeLayoutFields();
    _formatter ??= ExternalLyricLineFormatter(lyricStyle: _lyricStyle);
    _formatter!
      ..lyricStyle = _lyricStyle
      ..invalidate();
  }

  static void _rebindPositionListener() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!_carLyricsEnabled || _playlist == null) return;
    _positionSubscription =
        MusicService.androidLyricPositionStream.listen((_) {
      _onPositionPulse();
    });
  }

  static void _stopPlaybackListeners() {
    _indexSubscription?.cancel();
    _indexSubscription = null;
    _playingSubscription?.cancel();
    _playingSubscription = null;
  }

  static void _bindPlaybackListeners() {
    if (!_carLyricsEnabled || _playlist == null) return;
    _stopPlaybackListeners();
    _playingSubscription = MusicService.playingStream.listen((playing) {
      if (playing && _carLyricsEnabled) {
        _onPositionPulse();
      }
    });
    _indexSubscription =
        MusicService.currentMediaIndexStream.listen((int? i) {
      if (i == null || i < 0) return;
      if (i == _lastHandledPlayerIndex) return;
      _lastHandledPlayerIndex = i;
      _publishedLineKey = null;
      _hydrateInFlightPath = null;
      MusicService.resetAndroidNotificationLyricDedupe();
      _formatter?.invalidate();
      unawaited(_pushForPlayerIndex(i));
    });
  }

  static Future<void> attach(PlayListProvider playlist) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    _playlist = playlist;
    _publishedLineKey = null;
    _hydrateInFlightPath = null;
    MusicService.resetAndroidNotificationLyricDedupe();
    await applySettingsFromStorage();
    await _reloadLyricStyle();
    _bindLyricsUiRevisionListener();
    _lastHandledPlayerIndex = null;
    _bindPlaybackListeners();
    final initial = MusicService.currentIndex;
    if (initial != null && initial >= 0 && initial != _lastHandledPlayerIndex) {
      _lastHandledPlayerIndex = initial;
      unawaited(_pushForPlayerIndex(initial));
    }
  }

  static Future<void> republishCurrentTrackMediaItem() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    await applySettingsFromStorage();
    await _reloadLyricStyle();
    final song = _songForPlayback();
    if (song == null) return;
    _publishedLineKey = null;
    MusicService.resetAndroidNotificationLyricDedupe();
    await MusicService.pushAndroidNotificationForSong(
      song,
      forceNotificationPush: true,
    );
    _onPositionPulse();
  }

  static Future<void> detach() async {
    _unbindLyricsUiRevisionListener();
    _carLyricsEnabled = false;
    _syncLyricsEnabled = false;
    await AndroidMediaSessionLyricsChannel.setCarNotificationEnabled(false);
    JustAudioBackground.setAndroidLyricsSyncEnabled(false);
    unawaited(AndroidMediaSessionLyricsChannel.setLyricsDisplayManaged(false));
    _stopPlaybackListeners();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playlist = null;
    _formatter = null;
    _publishedLineKey = null;
    _hydrateInFlightPath = null;
    _lastHandledPlayerIndex = null;
  }

  static String _lineKey(
    String songPath,
    int lyricIndex,
    String publishKeySuffix,
  ) =>
      '$songPath|$lyricIndex|$publishKeySuffix';

  static String _songTitleKey(String songPath) => '$songPath|title';

  static Song? _songForPlayback() {
    final p = _playlist;
    if (p == null) return null;
    final path = MusicService.tryCurrentPlayingPath();
    if (path != null && path.trim().isNotEmpty) {
      for (final s in p.playList) {
        if (songPathsEqual(s.path, path)) return s;
      }
    }
    return p.currentSong;
  }

  static void _onPositionPulse() {
    if (_playlist == null || !_carLyricsEnabled) return;

    final song = _songForPlayback();
    if (song == null) return;

    final baseTitle = MusicService.songNotificationBaseTitle(song);

    if (!_syncLyricsEnabled) {
      _pushDisplayLine(song, baseTitle, _songTitleKey(song.path));
      return;
    }

    _formatter ??= ExternalLyricLineFormatter(lyricStyle: _lyricStyle);
    final position = MusicService.playerPosition;

    if (song.lyrics == null || song.lyrics!.trim().isEmpty) {
      if (_hydrateInFlightPath != song.path) {
        _hydrateInFlightPath = song.path;
        unawaited(
          SongLibraryMetadataHydrator.hydrateIfNeeded(song).then((changed) {
            if (changed) {
              _formatter?.invalidate();
            }
            if (song.lyrics?.trim().isNotEmpty ?? false) {
              _onPositionPulse();
            }
          }),
        );
      }
      _pushDisplayLine(
        song,
        baseTitle,
        _lineKey(song.path, -1, 'title'),
      );
      return;
    }

    final snap = _formatter!.resolveAt(
      song: song,
      position: position,
      l10n: null,
    );
    final inLyricGap =
        snap.hasEmbeddedLyrics && snap.lyricIndex < 0;
    final key = inLyricGap
        ? _lineKey(song.path, -1, 'gap')
        : _lineKey(
            song.path,
            snap.lyricIndex,
            snap.publishKeySuffix,
          );
    final line = !snap.hasEmbeddedLyrics
        ? baseTitle
        : inLyricGap
            ? notificationLyricGapLine
            : snap.displayLine;
    _pushDisplayLine(song, line, key);
  }

  static void _pushDisplayLine(Song song, String line, String key) {
    if (key == _publishedLineKey) return;
    if (_syncLyricsEnabled) {
      MusicService.pushAndroidNotificationLyricLine(song, lyricLine: line);
    } else {
      MusicService.pushAndroidNotificationSongTitle(song);
    }
    _publishedLineKey = key;
  }

  static Future<void> _pushForPlayerIndex(int index) async {
    final song = _songForPlayback();
    if (song == null) {
      final p = _playlist;
      if (p == null) return;
      final list = p.playList;
      if (list.isEmpty) return;
      final fallback = list[index.clamp(0, list.length - 1)];
      await MusicService.pushAndroidNotificationForSong(fallback);
      _onPositionPulse();
      return;
    }
    await MusicService.pushAndroidNotificationForSong(song);
    _onPositionPulse();
  }
}
