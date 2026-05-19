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

/// Android 通知栏歌词：逻辑对齐 [MacosMenuBarLyricsHost]——跟进度流、每 tick 算行，
/// 行索引变化时 **原生直推** [displayTitle]（不经过 [setMediaItem] 单线程池）。
class AndroidCarLyricsSync {
  AndroidCarLyricsSync._();

  static PlayListProvider? _playlist;
  static ExternalLyricLineFormatter? _formatter;
  static LyricSettings _lyricStyle = LyricSettings();
  static StreamSubscription<int?>? _indexSubscription;
  static StreamSubscription<Duration>? _positionSubscription;
  static StreamSubscription<bool>? _playingSubscription;
  static bool _syncLyricsEnabled = false;

  static String? _publishedLineKey;
  static String? _hydrateInFlightPath;
  static int? _lastHandledPlayerIndex;

  static Future<void> refreshSyncEnabled() async {
    _syncLyricsEnabled = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    JustAudioBackground.setAndroidLyricsSyncEnabled(_syncLyricsEnabled);
    await AndroidMediaSessionLyricsChannel.setLyricsDisplayManaged(
      _syncLyricsEnabled,
    );
    _rebindPositionListener();
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
    if (!_syncLyricsEnabled || _playlist == null) return;
    _positionSubscription =
        MusicService.androidLyricPositionStream.listen((_) {
      _onPositionPulse();
    });
  }

  static Future<void> attach(PlayListProvider playlist) async {
    if (kIsWeb || !Platform.isAndroid) return;
    _playlist = playlist;
    _publishedLineKey = null;
    _hydrateInFlightPath = null;
    MusicService.resetAndroidNotificationLyricDedupe();
    await refreshSyncEnabled();
    await _reloadLyricStyle();
    _indexSubscription?.cancel();
    _playingSubscription?.cancel();
    _playingSubscription = MusicService.playingStream.listen((playing) {
      if (playing && _syncLyricsEnabled) {
        _onPositionPulse();
      }
    });
    _lastHandledPlayerIndex = null;
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
    final initial = MusicService.currentIndex;
    if (initial != null && initial >= 0 && initial != _lastHandledPlayerIndex) {
      _lastHandledPlayerIndex = initial;
      unawaited(_pushForPlayerIndex(initial));
    }
  }

  static Future<void> republishCurrentTrackMediaItem() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await refreshSyncEnabled();
    await _reloadLyricStyle();
    final song = _songForPlayback();
    if (song == null) return;
    _publishedLineKey = null;
    MusicService.resetAndroidNotificationLyricDedupe();
    await MusicService.pushAndroidNotificationForSong(
      song,
      forceNotificationPush: true,
    );
    if (_syncLyricsEnabled) {
      _onPositionPulse();
    }
  }

  static void detach() {
    JustAudioBackground.setAndroidLyricsSyncEnabled(false);
    unawaited(AndroidMediaSessionLyricsChannel.setLyricsDisplayManaged(false));
    _indexSubscription?.cancel();
    _indexSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playingSubscription?.cancel();
    _playingSubscription = null;
    _playlist = null;
    _formatter = null;
    _publishedLineKey = null;
    _hydrateInFlightPath = null;
    _lastHandledPlayerIndex = null;
  }

  static String _lineKey(String songPath, int lyricIndex) =>
      '$songPath|$lyricIndex';

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
    if (_playlist == null || !_syncLyricsEnabled) return;

    final song = _songForPlayback();
    if (song == null) return;

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
      return;
    }

    final snap = _formatter!.resolveAt(
      song: song,
      position: position,
      l10n: null,
    );
    final key = _lineKey(song.path, snap.lyricIndex);
    if (key == _publishedLineKey) return;

    final baseTitle = MusicService.songNotificationBaseTitle(song);
    final line = snap.hasEmbeddedLyrics && snap.lyricIndex >= 0
        ? snap.displayLine
        : baseTitle;

    MusicService.pushAndroidNotificationLyricLine(song, lyricLine: line);
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
      if (_syncLyricsEnabled) _onPositionPulse();
      return;
    }
    await MusicService.pushAndroidNotificationForSong(song);
    if (_syncLyricsEnabled) _onPositionPulse();
  }
}
