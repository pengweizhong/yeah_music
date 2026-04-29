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
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

int _coverContentFingerprint(List<int> bytes) {
  final len = bytes.length;
  if (len == 0) return 0;
  var h = len;
  final n = len < 4096 ? len : 4096;
  for (var i = 0; i < n; i++) {
    h = (h * 31 + bytes[i]) & 0x3fffffff;
  }
  h ^= bytes[len - 1];
  return h;
}

class MusicService {
  static final _player = AudioPlayer();
  static bool isPlaying = false;

  /// [MediaMetadataCompat.METADATA_KEY_COMPOSER]，部分国产系统控制中心/流体云会读此字段作第三行或歌词。
  static const String androidComposerMetadataKey =
      'android.media.metadata.COMPOSER';

  static Map<String, dynamic>? _androidLyricExtras(String? line) {
    if (line == null || line.isEmpty) return null;
    return {androidComposerMetadataKey: line};
  }

  /// 新一次 [setAudioSource]/队列换源成功并 [play] 时递增；仅带「本次播放代数」的
  /// [pushAndroidNotificationForSong] 在结束时若已过期则丢弃，避免切歌后旧 hydrate 覆盖新会话。
  static int _androidMediaSessionSyncGeneration = 0;

  /// Android 多曲时 [playCurrentFromPlaylist] 会构建整段队列（与「车载歌词」开关无关）；单文件模式为 false。
  static bool androidCarQueueActive = false;

  static Future<void> _playChain = Future.value();

  /// 按当前播放列表与索引开始播放。
  ///
  /// Android 且列表多于一首时始终构建 [ConcatenatingAudioSource]，使通知/车机上的上一首、下一首与
  /// 真实曲目对应（否则仅单文件会话，`hasPrevious` 在首曲为 false，紧凑通知易把停播当成「上一首」）。
  /// 封面/内嵌图仍受「显示封面」开关影响，不依赖「启用车载歌词」。
  Future<void> playCurrentFromPlaylist({
    required List<Song> queue,
    required int currentIndex,
  }) async {
    if (queue.isEmpty) return;
    final i = currentIndex.clamp(0, queue.length - 1);
    final useFullPlayerQueue = Platform.isAndroid && queue.length > 1;
    if (useFullPlayerQueue) {
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
        await _player.setVolume(1.0);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 64));
        }
        final tag = await _tagForSong(song);
        await _player.setAudioSource(_buildAudioSource(song, tag: tag));
        await _player.seek(Duration.zero);
        play();
        if (Platform.isAndroid) {
          final g = ++_androidMediaSessionSyncGeneration;
          unawaited(pushAndroidNotificationForSong(song, abortIfStaleGeneration: g));
        }
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
          appLog.d('macOS: 尝试恢复安全作用域书签后重试');
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
        await _player.setVolume(1.0);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 64));
        }
        final children = <AudioSource>[];
        for (final s in queue) {
          final tag = await buildMediaItemForSong(
            s,
            showCover: showCover,
            lyricStyle: lyricStyle,
            subtitlePosition: Duration.zero,
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
        if (Platform.isAndroid) {
          final g = ++_androidMediaSessionSyncGeneration;
          final s = queue[idx];
          unawaited(pushAndroidNotificationForSong(s, abortIfStaleGeneration: g));
        }
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
      return buildMediaItemForSong(
        song,
        showCover: showCover,
        lyricStyle: lyricStyle,
        subtitlePosition: Duration.zero,
      );
    }
    return song;
  }

  /// 构建 [MediaItem]（`just_audio_background` 的 AudioSource tag）。
  static Future<MediaItem> buildMediaItemForSong(
    Song song, {
    required bool showCover,
    LyricSettings? lyricStyle,
    Duration subtitlePosition = Duration.zero,
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
          final fp = _coverContentFingerprint(bytes);
          final uniqueSuffix = Platform.isAndroid
              ? '_${DateTime.now().microsecondsSinceEpoch}'
              : '';
          final name =
              'yeah_nm_art_${song.path.hashCode}_${bytes.length}_$fp$uniqueSuffix.jpg';
          final f = File(p.join(dir.path, name));
          await f.writeAsBytes(bytes, flush: true);
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
          position: subtitlePosition,
          l10n: null,
        );
      } catch (_) {}
    }
    String? displayDescription;
    if (initialSubtitle != null && initialSubtitle.isNotEmpty) {
      displayDescription = initialSubtitle;
    }
    return MediaItem(
      id: song.path,
      title: title,
      artist: artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      displaySubtitle: initialSubtitle,
      displayDescription: displayDescription,
      extras: _androidLyricExtras(initialSubtitle),
    );
  }

  /// 在切歌或补载元数据后，把当前曲目的封面/标题/歌词行推送到系统媒体会话（更新通知）。
  ///
  /// [abortIfStaleGeneration]：与 [_androidMediaSessionSyncGeneration] 配套，仅在「随本次换源发起的
  /// 单次补推」上使用；歌词 tick、[AndroidCarLyricsSync] 等不传，始终落库。
  static Future<void> pushAndroidNotificationForSong(
    Song song, {
    int? abortIfStaleGeneration,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      try {
        await SongLibraryMetadataHydrator.hydrateIfNeeded(song);
      } catch (e) {
        appLog.d('通知用元数据补全失败(忽略): $e');
      }
      final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
      final wantLyrics = await SettingsService.loadAndroidCarLyricsSyncLyrics();
      if (showCover && (song.imageBytes == null || song.imageBytes!.isEmpty)) {
        try {
          await FileUtils.loadSongMeta(
            song,
            loadEmbeddedAlbumArt: true,
            storeLyricsWithTrack: wantLyrics,
            maxEmbeddedArtBytes: SongLibraryMetadataHydrator.maxEmbeddedArtBytes,
          );
          ApplicationUtils.evictSongCoverProvidersForPath(song.path);
          scheduleEmbeddedSongMetadataPersist(song);
        } catch (_) {}
      } else if (wantLyrics &&
          (song.lyrics == null || song.lyrics!.trim().isEmpty)) {
        try {
          await FileUtils.loadSongMeta(
            song,
            loadEmbeddedAlbumArt: false,
            storeLyricsWithTrack: true,
          );
          scheduleEmbeddedSongMetadataPersist(song);
        } catch (_) {}
      }
      if (abortIfStaleGeneration != null &&
          abortIfStaleGeneration != _androidMediaSessionSyncGeneration) {
        return;
      }
      final lyricStyle = await SettingsService.loadLyricSettings();
      final item = await buildMediaItemForSong(
        song,
        showCover: showCover,
        lyricStyle: lyricStyle,
        subtitlePosition: lastPosition,
      );
      if (abortIfStaleGeneration != null &&
          abortIfStaleGeneration != _androidMediaSessionSyncGeneration) {
        return;
      }
      await AudioService.updateMediaItem(item);
    } catch (e) {
      appLog.d('pushAndroidNotificationForSong: $e');
    }
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
    try {
      await _player.pause();
    } finally {
      isPlaying = false;
      try {
        await _player.setVolume(1.0);
      } catch (_) {}
    }
  }

  void resume() {
    _player.play();
    isPlaying = _player.playing;
  }

  static bool get canUseResumeToPlay {
    switch (_player.processingState) {
      case ProcessingState.idle:
      case ProcessingState.completed:
        return false;
      case ProcessingState.ready:
      case ProcessingState.buffering:
      case ProcessingState.loading:
        return true;
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
    try {
      isPlaying = false;
      androidCarQueueActive = false;
      await _player.stop();
    } finally {
      try {
        await _player.setVolume(1.0);
      } catch (_) {}
    }
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
