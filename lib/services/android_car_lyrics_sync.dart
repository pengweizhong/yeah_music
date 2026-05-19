import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';

/// Android 通知栏歌词：与播放页相同，在 [MusicService.androidLyricPositionStream]
/// 每次进度更新时用 [LyricsUtils.findCurrentLyricIndex] 判定行；行索引一变即推送（无定时器、不排队阻塞）。
class AndroidCarLyricsSync {
  AndroidCarLyricsSync._();

  static PlayListProvider? _playlist;
  static ExternalLyricLineFormatter? _formatter;
  static LyricSettings _lyricStyle = LyricSettings();
  static StreamSubscription<int?>? _indexSubscription;
  static StreamSubscription<Duration>? _positionSubscription;
  static StreamSubscription<bool>? _playingSubscription;
  static bool _syncLyricsEnabled = false;

  /// 已同步到通知的「曲目 + 歌词行索引」（与播放页 [_currentLyricIndex] 对齐）。
  static String? _publishedLineKey;
  static String? _hydrateInFlightPath;
  static int _publishGeneration = 0;

  static Future<void> refreshSyncEnabled() async {
    _syncLyricsEnabled = await SettingsService.loadAndroidCarLyricsSyncLyrics();
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

  static void attach(PlayListProvider playlist) {
    if (kIsWeb || !Platform.isAndroid) return;
    _playlist = playlist;
    _publishedLineKey = null;
    _hydrateInFlightPath = null;
    unawaited(() async {
      await refreshSyncEnabled();
      await _reloadLyricStyle();
    }());
    _indexSubscription?.cancel();
    _playingSubscription?.cancel();
    _playingSubscription = MusicService.playingStream.listen((playing) {
      if (playing && _syncLyricsEnabled) {
        _onPositionPulse();
      }
    });
    _indexSubscription =
        MusicService.currentMediaIndexStream.listen((int? i) {
      if (i == null || i < 0) return;
      _publishedLineKey = null;
      _hydrateInFlightPath = null;
      _formatter?.invalidate();
      unawaited(_pushForPlayerIndex(i));
    });
    final initial = MusicService.currentIndex;
    if (initial != null && initial >= 0) {
      unawaited(_pushForPlayerIndex(initial));
    }
  }

  static Future<void> republishCurrentTrackMediaItem() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await refreshSyncEnabled();
    await _reloadLyricStyle();
    final p = _playlist;
    if (p == null) return;
    final s = p.currentSong;
    if (s == null) return;
    _publishedLineKey = null;
    await MusicService.pushAndroidNotificationForSong(s);
    if (_syncLyricsEnabled) {
      _onPositionPulse();
    }
  }

  static void detach() {
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
    _publishGeneration = 0;
  }

  static String _lineKey(String songPath, int lyricIndex) =>
      '$songPath|$lyricIndex';

  /// 同步：仅用当前解码进度计算行索引，与播放页一致。
  static void _onPositionPulse() {
    if (_playlist == null || !_syncLyricsEnabled) return;

    final position = MusicService.playerPosition;
    _formatter ??= ExternalLyricLineFormatter(lyricStyle: _lyricStyle);

    final p = _playlist!;
    final ci = MusicService.currentIndex;
    final list = p.playList;
    if (list.isEmpty) return;
    final idx = (ci != null && ci >= 0 && ci < list.length)
        ? ci
        : p.currentIndex.clamp(0, list.length - 1);
    final song = list[idx];

    if (song.lyrics == null || song.lyrics!.trim().isEmpty) {
      if (_hydrateInFlightPath != song.path) {
        _hydrateInFlightPath = song.path;
        unawaited(
          SongLibraryMetadataHydrator.hydrateIfNeeded(song).then((changed) {
            if (changed) {
              _formatter?.invalidate();
              _publishedLineKey = null;
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

    final gen = ++_publishGeneration;
    unawaited(_publishLine(gen: gen, song: song, snap: snap, lineKey: key));
  }

  static Future<void> _publishLine({
    required int gen,
    required Song song,
    required ExternalLyricLineAtPosition snap,
    required String lineKey,
  }) async {
    if (gen != _publishGeneration) return;

    final baseTitle = MusicService.songNotificationBaseTitle(song);
    final primary = snap.hasEmbeddedLyrics && snap.lyricIndex >= 0
        ? snap.displayLine
        : baseTitle;
    final lyricsInTitle = primary != baseTitle;

    final item = AudioService.currentMediaItem;
    if (item == null) return;
    if (!mediaItemIdMatchesSongPath(item.id, song.path)) return;
    if (gen != _publishGeneration) return;

    if (item.artUri == null) {
      unawaited(MusicService.pushAndroidNotificationForSong(song));
      return;
    }

    try {
      final merged = Map<String, dynamic>.from(item.extras ?? {});
      if (lyricsInTitle) {
        merged[MusicService.androidComposerMetadataKey] = primary;
      } else {
        merged.remove(MusicService.androidComposerMetadataKey);
      }
      final artist = song.artist?.trim() ?? '';
      final next = item.copyWith(
        title: primary,
        artist: artist.isNotEmpty ? artist : item.artist,
        displaySubtitle: lyricsInTitle ? baseTitle : null,
        displayDescription: lyricsInTitle && artist.isNotEmpty ? artist : null,
        extras: merged,
      );
      if (next.artUri == null) return;
      await JustAudioBackground.updateNotificationMediaItem(next);
      if (gen == _publishGeneration) {
        _publishedLineKey = lineKey;
      }
    } catch (_) {}
  }

  static Future<void> _pushForPlayerIndex(int index) async {
    final p = _playlist;
    if (p == null) return;
    final list = p.playList;
    if (list.isEmpty) return;
    final playing = MusicService.tryCurrentPlayingPath();
    Song? song;
    if (playing != null) {
      for (final s in list) {
        if (songPathsEqual(s.path, playing)) {
          song = s;
          break;
        }
      }
    }
    song ??= list[index.clamp(0, list.length - 1)];
    await MusicService.pushAndroidNotificationForSong(song);
    if (_syncLyricsEnabled) {
      _publishedLineKey = null;
      _onPositionPulse();
    }
  }
}
