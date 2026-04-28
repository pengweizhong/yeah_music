import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/compments/bookmark_service.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';

class MusicService {
  static final _player = AudioPlayer();
  static bool isPlaying = false;

  /// Android 且开启车载歌词时，使用与 [PlayListProvider.playList] 对齐的拼接队列。
  static bool androidCarQueueActive = false;

  static Future<void> _playChain = Future.value();

  /// 按当前播放列表与索引开始播放（Android 车载开则用整队列；否则仅当前曲）。
  Future<void> playCurrentFromPlaylist({
    required List<Song> queue,
    required int currentIndex,
  }) async {
    if (queue.isEmpty) return;
    final i = currentIndex.clamp(0, queue.length - 1);
    final useCarQueue =
        Platform.isAndroid && await SettingsService.loadAndroidCarLyricsEnabled();
    if (useCarQueue) {
      final f = _playChain
          .catchError((Object? e) {
            appLog.d('playQueue 前序(可忽略): $e');
          })
          .then((_) => _playQueueBody(queue, i));
      _playChain = f;
      return f;
    }
    return playSong(queue[i]);
  }

  Future<void> playQueue(List<Song> queue, int index) async {
    final f = _playChain
        .catchError((Object? e) {
          appLog.d('playQueue 前序(可忽略): $e');
        })
        .then((_) => _playQueueBody(queue, index));
    _playChain = f;
    return f;
  }

  Future<void> playSong(Song song) {
    final f = _playChain
        .catchError((Object? e) {
          appLog.d('playSong 前序(可忽略): $e');
        })
        .then((_) => _playSongBody(song));
    _playChain = f;
    return f;
  }

  Future<void> _playSongBody(Song song) async {
    androidCarQueueActive = false;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _player.stop();
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 64));
        }
        final tag = await _tagForSong(song);
        await _player.setAudioSource(_buildAudioSource(song, tag: tag));
        await _player.seek(Duration.zero);
        play();
        return;
      } catch (e) {
        final msg = e.toString();
        if (attempt == 0 && msg.contains('interrupted')) {
          appLog.d('换源被中断，重试一次: $e');
          continue;
        }
        if (attempt < 2 &&
            Platform.isMacOS &&
            (msg.contains('257') ||
                msg.contains('permission') ||
                msg.contains('Permission'))) {
          appLog.d('macOS: 尝试恢复安全作用域书签后重试播放');
          try {
            await BookmarkService.restoreAllBookmarks();
          } catch (_) {}
          continue;
        }
        appLog.e('设置音频并播放失败', error: e);
        return;
      }
    }
  }

  Future<void> _playQueueBody(List<Song> queue, int index) async {
    androidCarQueueActive = false;
    if (queue.isEmpty) return;
    final idx = index.clamp(0, queue.length - 1);
    final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
    final lyricStyle = await SettingsService.loadLyricSettings();
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _player.stop();
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 64));
        }
        final children = <AudioSource>[];
        for (final s in queue) {
          final tag = await _mediaItemForSong(
            s,
            showCover: showCover,
            lyricStyle: lyricStyle,
          );
          children.add(_buildAudioSource(s, tag: tag));
        }
        await _player.setAudioSources(
          children,
          initialIndex: idx,
          initialPosition: Duration.zero,
        );
        androidCarQueueActive = true;
        play();
        return;
      } catch (e) {
        final msg = e.toString();
        if (attempt == 0 && msg.contains('interrupted')) {
          appLog.d('队列换源被中断，重试一次: $e');
          continue;
        }
        appLog.e('设置队列音频并播放失败', error: e);
        return;
      }
    }
  }

  Future<Object?> _tagForSong(Song song) async {
    if (Platform.isAndroid) {
      final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
      final lyricStyle = await SettingsService.loadLyricSettings();
      return _mediaItemForSong(
        song,
        showCover: showCover,
        lyricStyle: lyricStyle,
      );
    }
    return song;
  }

  Future<MediaItem> _mediaItemForSong(
    Song song, {
    required bool showCover,
    LyricSettings? lyricStyle,
  }) async {
    final title = (song.title?.trim().isNotEmpty ?? false)
        ? song.title!.trim()
        : p.basename(song.path);
    final artist = song.artist?.trim().isNotEmpty == true
        ? song.artist!.trim()
        : '';
    Uri? artUri;
    if (showCover) {
      final bytes = song.imageBytes;
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final dir = await getTemporaryDirectory();
          final f = File(
            '${dir.path}/yeah_music_art_${song.path.hashCode}.jpg',
          );
          if (!await f.exists()) {
            await f.writeAsBytes(bytes, flush: true);
          }
          artUri = Uri.file(f.path);
        } catch (_) {}
      }
    }
    final style = lyricStyle ?? LyricSettings();
    style.normalizeLayoutFields();
    String? initialSubtitle;
    final rawLyrics = song.lyrics;
    if (rawLyrics != null &&
        rawLyrics.trim().isNotEmpty &&
        await SettingsService.loadAndroidCarLyricsSyncLyrics()) {
      try {
        initialSubtitle = ExternalLyricLineFormatter(
          lyricStyle: style,
        ).formatLine(
          song: song,
          position: Duration.zero,
          l10n: null,
        );
      } catch (_) {}
    }
    return MediaItem(
      id: song.path,
      title: title,
      artist: artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      displaySubtitle: initialSubtitle,
    );
  }

  AudioSource _buildAudioSource(Song song, {required Object? tag}) {
    final uri = Uri.file(song.path);
    final pathLower = song.path.toLowerCase();
    if (pathLower.endsWith('.mp3')) {
      return ProgressiveAudioSource(
        uri,
        tag: tag,
        options: const ProgressiveAudioSourceOptions(
          androidExtractorOptions: AndroidExtractorOptions(
            constantBitrateSeekingEnabled: true,
            constantBitrateSeekingAlwaysEnabled: true,
            mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking,
          ),
          darwinAssetOptions: DarwinAssetOptions(
            preferPreciseDurationAndTiming: true,
          ),
        ),
      );
    }

    return ProgressiveAudioSource(
      uri,
      tag: tag,
      options: const ProgressiveAudioSourceOptions(
        darwinAssetOptions: DarwinAssetOptions(
          preferPreciseDurationAndTiming: true,
        ),
      ),
    );
  }

  void playNext() {
    // playSong((currentIndex! + 1) % playlist.length);
  }

  void playPrev() {
    // playSong((currentIndex! - 1) % playlist.length);
  }

  void play() {
    _player.play();
    isPlaying = _player.playing;
  }

  Future<void> pause() async {
    await _player.pause();
    isPlaying = false;
  }

  void resume() {
    _player.play();
    isPlaying = _player.playing;
  }

  static bool get canUseResumeToPlay {
    switch (_player.processingState) {
      case ProcessingState.ready:
      case ProcessingState.buffering:
      case ProcessingState.loading:
        return true;
      case ProcessingState.idle:
      case ProcessingState.completed:
        return false;
    }
  }

  Future<void> setLoopMode(LoopMode mode) async => _player.setLoopMode(mode);

  Future<void> dispose() async {
    return _player.dispose();
  }

  Future<void> seek(Duration duration, {int? index}) async {
    return _player.seek(duration, index: index);
  }

  Future<void> stop() async {
    isPlaying = false;
    androidCarQueueActive = false;
    return _player.stop();
  }

  static Stream<bool> get playingStream {
    return _player.playingStream.map((playing) {
      isPlaying = playing;
      return playing;
    });
  }

  static Duration _positionCache = Duration.zero;

  static Duration get lastPosition => _positionCache;

  static Stream<Duration> get positionStream {
    return _player.positionStream.map((d) {
      _positionCache = d;
      return d;
    });
  }

  static Stream<int?> get currentMediaIndexStream => _player.currentIndexStream;

  static Stream<Duration?> get durationStream => _player.durationStream;

  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static Duration? get duration => _player.duration;

  static int? get currentIndex => _player.currentIndex;
}
