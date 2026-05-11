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
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/services/playback_sound_effect_service.dart';

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
  static AndroidLoudnessEnhancer? _androidLoudnessEnhancer;
  static AndroidEqualizer? _androidEqualizer;

  static final AudioPlayer _player = _createAudioPlayer();

  static AudioPlayer _createAudioPlayer() {
    if (Platform.isAndroid) {
      _androidLoudnessEnhancer = AndroidLoudnessEnhancer();
      _androidEqualizer = AndroidEqualizer();
      return AudioPlayer(
        /// 硬件 offload 走解码旁路时，系统均衡器往往不生效；显式关闭以保证 EQ 可听。
        androidAudioOffloadPreferences: const AndroidAudioOffloadPreferences(
          audioOffloadMode: AndroidAudioOffloadMode.disabled,
        ),
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            _androidLoudnessEnhancer!,
            _androidEqualizer!,
          ],
        ),
      );
    }
    return AudioPlayer();
  }

  static StreamSubscription<int?>? _androidSoundPresetSessionSub;
  static Timer? _androidSoundPresetSessionDebounce;

  /// ExoPlayer 在 [androidAudioSessionId] 变化时会重建原生 Equalizer；须再次套用 Hive 中的预设。
  static void attachAndroidSoundPresetSessionListener() {
    if (!Platform.isAndroid) return;
    if (_androidSoundPresetSessionSub != null) return;
    _androidSoundPresetSessionSub =
        _player.androidAudioSessionIdStream.listen((_) {
      _androidSoundPresetSessionDebounce?.cancel();
      _androidSoundPresetSessionDebounce =
          Timer(const Duration(milliseconds: 160), () {
        unawaited(reapplyStoredAndroidSoundPreset());
      });
    });
  }

  /// Android 硬件均衡器（与 [_player] pipeline 绑定）；非 Android 为 null。
  static AndroidEqualizer? get androidEqualizer => _androidEqualizer;

  /// Android 响度增强（与 [_player] pipeline 绑定）；非 Android 为 null。
  static AndroidLoudnessEnhancer? get androidLoudnessEnhancer =>
      _androidLoudnessEnhancer;

  static bool isPlaying = false;

  /// 暂停 / 切歌前线性淡出总时长（与宿主通知栏 handler 一致）。
  static const Duration _kFadeOutDuration = Duration(milliseconds: 800);
  static const int _kFadeOutSteps = 40;
  static int _volumeFadeGeneration = 0;

  /// 取消进行中的淡出（新一次 [play]/[resume]/换源 时调用）。
  static void abortVolumeFade() {
    _volumeFadeGeneration++;
  }

  /// 正在播放时把 [AudioPlayer] 音量在 [_kFadeOutDuration] 内线性收到 0；与 [abortVolumeFade] 代数配合可打断。
  static Future<void> fadeOutVolumeWhilePlaying() async {
    if (!_player.playing) return;
    final gen = ++_volumeFadeGeneration;
    double start;
    try {
      start = _player.volume.clamp(0.0, 1.0);
    } catch (_) {
      start = 1.0;
    }
    if (start <= 0) return;
    final stepMs = (_kFadeOutDuration.inMilliseconds / _kFadeOutSteps)
        .floor()
        .clamp(1, 1000);
    for (var i = 1; i <= _kFadeOutSteps; i++) {
      if (gen != _volumeFadeGeneration) return;
      final v = start * (1.0 - i / _kFadeOutSteps);
      try {
        await _player.setVolume(v);
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: stepMs));
    }
    if (gen != _volumeFadeGeneration) return;
    try {
      await _player.setVolume(0.0);
    } catch (_) {}
  }

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

  /// 最近一次成功构建 Android 整队列时的 [queue] 引用；与本次调用 [identical] 时用 [seek] 切索引，避免整轨重建卡顿。
  static List<Song>? _lastAndroidQueueRef;

  /// 串行化换源；链上任务的返回值由各 API（如 [playSong]）自行向外透出。
  static Future _playChain = Future.value();

  static StreamSubscription<bool>? _listeningPlayingSub;
  static Timer? _listeningPeriodicFlushTimer;
  static DateTime? _listeningWallAnchor;

  /// 订阅播放器 [playing] 状态，按墙上时钟累计真实收听时长并写入 Hive（暂停、停止不计）。
  /// 应在 Hive 初始化成功后调用一次。
  static void attachListeningTimeTracker() {
    if (_listeningPlayingSub != null) return;
    _listeningPlayingSub = _player.playingStream.listen(
      _onPlayingChangedForListeningTracker,
    );
  }

  static void _onPlayingChangedForListeningTracker(bool playing) {
    if (playing) {
      _listeningWallAnchor = DateTime.now();
      _listeningPeriodicFlushTimer?.cancel();
      _listeningPeriodicFlushTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) {
          if (!_player.playing) return;
          _flushListeningWallClock(periodic: true);
        },
      );
    } else {
      _listeningPeriodicFlushTimer?.cancel();
      _listeningPeriodicFlushTimer = null;
      _flushListeningWallClock(periodic: false);
    }
  }

  static void _flushListeningWallClock({required bool periodic}) {
    final anchor = _listeningWallAnchor;
    if (anchor == null) return;
    final now = DateTime.now();
    var ms = now.difference(anchor).inMilliseconds;
    if (periodic) {
      _listeningWallAnchor = now;
    } else {
      _listeningWallAnchor = null;
    }
    if (ms <= 0) return;
    if (ms > 600000) ms = 600000;
    unawaited(RecentPlayService.addListenedMilliseconds(ms));
  }

  /// 将当前播放段的已历时写入 Hive（锚点顺延）。统计刷新或进入统计页时可调用以使累计更接近实时。
  static void flushListeningWallClockIntoHive() {
    if (!_player.playing || _listeningWallAnchor == null) return;
    _flushListeningWallClock(periodic: true);
  }

  static void _invalidateAndroidQueueReuse() {
    _lastAndroidQueueRef = null;
  }

  /// 在换源或切轨后按设置重新应用 Android 音效预设。
  static Future<void> reapplyStoredAndroidSoundPreset() async {
    if (!Platform.isAndroid) return;
    final eq = _androidEqualizer;
    final loud = _androidLoudnessEnhancer;
    if (eq == null || loud == null) return;
    try {
      final preset = await SettingsService.loadPlaybackSoundPreset();
      await PlaybackSoundEffectService.applyPreset(
        preset,
        equalizer: eq,
        loudness: loud,
      );
    } catch (e) {
      appLog.d('reapplyStoredAndroidSoundPreset: $e');
    }
  }

  /// 按当前播放列表与索引开始播放。
  ///
  /// 返回 `true` 表示已成功 [setAudioSource] 并已触发 [AudioPlayer.play]
  /// （不包含解码器等异步阶段的后续报错）。
  ///
  /// Android 且列表多于一首时默认构建 [ConcatenatingAudioSource]，使通知/车机上的上一首、下一首与
  /// 真实曲目对应。
  ///
  /// 「仅播放一次」等业务场景须传 [useAndroidConcatQueue] 为 false：否则会由系统在曲目末尾自动连播
  /// 下一首，应用层无法在原生 concatenating 队列之前拦截。
  Future<bool> playCurrentFromPlaylist({
    required List<Song> queue,
    required int currentIndex,
    bool useAndroidConcatQueue = true,
  }) async {
    abortVolumeFade();
    if (queue.isEmpty) return false;
    final i = currentIndex.clamp(0, queue.length - 1);
    final useFullPlayerQueue =
        useAndroidConcatQueue && Platform.isAndroid && queue.length > 1;
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

  Future<bool> playQueue(List<Song> queue, int index) async {
    if (queue.isEmpty) return false;
    final f = _playChain
        .catchError((Object? e) {
          appLog.d('playQueue 前序(可忽略): $e');
        })
        .then((_) => _playQueueBody(queue, index));
    _playChain = f;
    return f;
  }

  Future<bool> playSong(Song song) {
    final f = _playChain
        .catchError((Object? e) {
          appLog.d('playSong 前序(可忽略): $e');
        })
        .then((_) => _playSongBody(song));
    _playChain = f;
    return f;
  }

  Future<bool> _playSongBody(Song song) async {
    androidCarQueueActive = false;
    _invalidateAndroidQueueReuse();
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (Platform.isLinux &&
            _player.processingState == ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
        await _player.stop();
        await _player.setVolume(1.0);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        final tag = await _tagForSong(song);
        await _player.setAudioSource(_buildAudioSource(song, tag: tag));
        await _player.seek(Duration.zero);
        // 勿 await play()：部分机型/后端上该 Future 长期不结束会卡死整条 _playChain 与 UI 触发的 playAt。
        _player.play();
        isPlaying = _player.playing;
        await Future<void>.delayed(const Duration(milliseconds: 24));
        if (Platform.isAndroid) {
          final g = ++_androidMediaSessionSyncGeneration;
          unawaited(
            pushAndroidNotificationForSong(song, abortIfStaleGeneration: g),
          );
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 48), () {
              return reapplyStoredAndroidSoundPreset();
            }),
          );
        }
        return true;
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
        return false;
      }
    }
    return false;
  }

  Future<bool> _playQueueBody(List<Song> queue, int index) async {
    if (queue.isEmpty) return false;
    final idx = index.clamp(0, queue.length - 1);

    // 同一 [queue] 实例（曲库缓存列表或同一用户歌单覆盖队列）内切歌：只 seek，避免全量 MediaItem + setAudioSources。
    if (Platform.isAndroid &&
        queue.length > 1 &&
        androidCarQueueActive &&
        identical(queue, _lastAndroidQueueRef)) {
      try {
        final seq = _player.sequence;
        if (seq.isEmpty || seq.length != queue.length) {
          throw StateError('sequence length mismatch');
        }
        final tag = seq[idx].tag;
        final expectedPath = queue[idx].path;
        final actualPath = tag is MediaItem
            ? filePathFromMediaItemId(tag.id)
            : (tag is Song ? tag.path : null);
        if (actualPath == null ||
            normSongPath(actualPath) != normSongPath(expectedPath)) {
          throw StateError('sequence path mismatch at current index');
        }
        await _player.setVolume(1.0);
        await _player.seek(Duration.zero, index: idx);
        _player.play();
        isPlaying = _player.playing;
        androidCarQueueActive = true;
        _lastAndroidQueueRef = queue;
        if (Platform.isAndroid) {
          final g = ++_androidMediaSessionSyncGeneration;
          final s = queue[idx];
          unawaited(
            pushAndroidNotificationForSong(s, abortIfStaleGeneration: g),
          );
          unawaited(reapplyStoredAndroidSoundPreset());
        }
        return true;
      } catch (e) {
        appLog.d('Android 队列内快速切曲不可用，整轨重建: $e');
        _invalidateAndroidQueueReuse();
      }
    }

    androidCarQueueActive = false;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (Platform.isLinux &&
            _player.processingState == ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
        await _player.stop();
        await _player.setVolume(1.0);
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
        final lyricStyle = await SettingsService.loadLyricSettings();
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
        _lastAndroidQueueRef = queue;
        _player.play();
        isPlaying = _player.playing;
        await Future<void>.delayed(const Duration(milliseconds: 24));
        if (Platform.isAndroid) {
          final g = ++_androidMediaSessionSyncGeneration;
          final s = queue[idx];
          unawaited(
            pushAndroidNotificationForSong(s, abortIfStaleGeneration: g),
          );
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 48), () {
              return reapplyStoredAndroidSoundPreset();
            }),
          );
        }
        return true;
      } catch (e) {
        final msg = e.toString();
        if (attempt == 0 && msg.contains('interrupted')) {
          appLog.d('队列换源被中断，重试一次: $e');
          continue;
        }
        appLog.e('设置队列音频并播放失败', error: e);
        _invalidateAndroidQueueReuse();
        return false;
      }
    }
    return false;
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
        ).formatLine(song: song, position: subtitlePosition, l10n: null);
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
            maxEmbeddedArtBytes:
                SongLibraryMetadataHydrator.maxEmbeddedArtBytes,
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

  Future<void> play() async {
    abortVolumeFade();
    try {
      await _player.setVolume(1.0);
    } catch (_) {}
    _player.play();
    isPlaying = _player.playing;
  }

  Future<void> pause({bool fadeOut = true}) async {
    try {
      if (fadeOut && _player.playing) {
        await fadeOutVolumeWhilePlaying();
      }
      await _player.pause();
    } finally {
      isPlaying = false;
      try {
        await _player.setVolume(1.0);
      } catch (_) {}
    }
  }

  Future<void> resume() async {
    abortVolumeFade();
    try {
      await _player.setVolume(1.0);
    } catch (_) {}
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
    abortVolumeFade();
    try {
      await _player.setVolume(1.0);
    } catch (_) {}
    _listeningPeriodicFlushTimer?.cancel();
    _listeningPeriodicFlushTimer = null;
    if (_listeningWallAnchor != null) {
      _flushListeningWallClock(periodic: false);
    }
    await _listeningPlayingSub?.cancel();
    _listeningPlayingSub = null;
    _androidSoundPresetSessionDebounce?.cancel();
    _androidSoundPresetSessionDebounce = null;
    await _androidSoundPresetSessionSub?.cancel();
    _androidSoundPresetSessionSub = null;
    return _player.dispose();
  }

  Future<void> seek(Duration duration, {int? index}) async {
    return _player.seek(duration, index: index);
  }

  Future<void> stop() async {
    abortVolumeFade();
    try {
      isPlaying = false;
      androidCarQueueActive = false;
      _invalidateAndroidQueueReuse();
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

  static Stream<PlayerException> get errorStream => _player.errorStream;

  static Duration? get duration => _player.duration;

  static int? get currentIndex => _player.currentIndex;

  /// 当前正在解码的这一轨对应的本地路径（与 [currentIndex] 在 [AudioPlayer.sequence] 中的 tag 一致）。
  /// 用于合并曲库顺序变化后把 [PlayListProvider] 的索引按「在播文件」对齐，避免出现声音与迷你条/首页卡片不一致。
  static String? tryCurrentPlayingPath() {
    try {
      final idx = _player.currentIndex;
      if (idx == null || idx < 0) return null;
      final seq = _player.sequence;
      if (seq.isEmpty || idx >= seq.length) return null;
      final tag = seq[idx].tag;
      if (tag is Song) return tag.path;
      if (tag is MediaItem) {
        final p = filePathFromMediaItemId(tag.id);
        return p.trim().isEmpty ? null : p;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
