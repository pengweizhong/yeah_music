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
import 'package:yeah_music/utils/song_path_utils.dart';

/// 将当前歌词行写入系统媒体项副标题（锁屏 / 部分车机），依赖 [JustAudioBackground]。
class AndroidCarLyricsSync {
  AndroidCarLyricsSync._();

  static PlayListProvider? _playlist;
  static Timer? _timer;
  static ExternalLyricLineFormatter? _formatter;
  static StreamSubscription<int?>? _indexSubscription;
  static Timer? _pushDebounce;

  static void attach(PlayListProvider playlist) {
    if (kIsWeb || !Platform.isAndroid) return;
    _playlist = playlist;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      unawaited(_tick());
    });
    _indexSubscription?.cancel();
    _pushDebounce?.cancel();
    _indexSubscription =
        MusicService.currentMediaIndexStream.listen((int? i) {
      if (i == null || i < 0) return;
      _schedulePushForIndex(i);
    });
    final initial = MusicService.currentIndex;
    if (initial != null && initial >= 0) {
      _schedulePushForIndex(initial);
    }
  }

  static Future<void> republishCurrentTrackMediaItem() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final p = _playlist;
    if (p == null) return;
    final s = p.currentSong;
    if (s == null) return;
    await MusicService.pushAndroidNotificationForSong(s);
  }

  static void detach() {
    _timer?.cancel();
    _timer = null;
    _pushDebounce?.cancel();
    _pushDebounce = null;
    _indexSubscription?.cancel();
    _indexSubscription = null;
    _playlist = null;
    _formatter = null;
  }

  /// 切歌后防抖推送完整 [MediaItem]（封面/歌词），避免队列初建时元数据未载。
  static void _schedulePushForIndex(int index) {
    if (_playlist == null) return;
    final list = _playlist!.playList;
    if (index < 0 || index >= list.length) return;
    _pushDebounce?.cancel();
    _pushDebounce = Timer(const Duration(milliseconds: 220), () {
      unawaited(_pushForPlayerIndex(index));
    });
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
  }

  static Future<void> _tick() async {
    if (_playlist == null) return;
    if (!MusicService.isPlaying) return;
    if (!await SettingsService.loadAndroidCarLyricsSyncLyrics()) return;

    final raw = await SettingsService.loadLyricSettings();
    final style = raw ?? LyricSettings();
    style.normalizeLayoutFields();
    _formatter ??= ExternalLyricLineFormatter(lyricStyle: style);
    _formatter!.lyricStyle = style;

    final ci = MusicService.currentIndex;
    final list = _playlist!.playList;
    if (list.isEmpty) return;
    final idx = (ci != null && ci >= 0 && ci < list.length)
        ? ci
        : _playlist!.currentIndex.clamp(0, list.length - 1);
    final song = list[idx];

    final line = _formatter!.formatLine(
      song: song,
      position: MusicService.lastPosition,
      l10n: null,
    );
    if (line.isEmpty) return;

    final item = AudioService.currentMediaItem;
    if (item == null) return;
    if (!mediaItemIdMatchesSongPath(item.id, song.path)) return;
    if (item.displaySubtitle == line &&
        item.displayDescription == line &&
        item.extras?[MusicService.androidComposerMetadataKey] == line) {
      return;
    }

    // 无封面时仅改副标题会把 Android 会话 artBitmap 置空；先补推完整 MediaItem。
    if (item.artUri == null) {
      unawaited(MusicService.pushAndroidNotificationForSong(song));
      return;
    }

    try {
      final merged = Map<String, dynamic>.from(item.extras ?? {});
      merged[MusicService.androidComposerMetadataKey] = line;
      final next = item.copyWith(
        displaySubtitle: line,
        displayDescription: line,
        extras: merged,
      );
      if (next.artUri == null) return;
      await JustAudioBackground.updateNotificationMediaItem(next);
    } catch (_) {}
  }
}
