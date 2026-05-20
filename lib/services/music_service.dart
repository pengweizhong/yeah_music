import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/compments/bookmark_service.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_sound_preset.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/android_car_lyrics_sync.dart';
import 'package:yeah_music/services/android_media_session_lyrics_channel.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';
import 'package:yeah_music/utils/app_ephemeral_storage.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/services/playback_sound_effect_service.dart';

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

  /// 为 true 时表示正在进行「音量 0 → 解码就绪 → 套 EQ → 渐开」；此间推迟 session 触发的 [reapplyStoredAndroidSoundPreset]，避免与渐开叠用再次开关 EQ 造成偶发炸音。
  static bool _androidGradualUnmuteInFlight = false;

  static void _onAndroidSessionSoundPresetDebounceFire() {
    _androidSoundPresetSessionDebounce = null;
    if (_androidGradualUnmuteInFlight) {
      _androidSoundPresetSessionDebounce = Timer(
        const Duration(milliseconds: 180),
        _onAndroidSessionSoundPresetDebounceFire,
      );
      return;
    }
    unawaited(reapplyStoredAndroidSoundPreset());
  }

  /// ExoPlayer 在 [androidAudioSessionId] 变化时会重建原生 Equalizer；须再次套用 Hive 中的预设。
  static void attachAndroidSoundPresetSessionListener() {
    if (!Platform.isAndroid) return;
    if (_androidSoundPresetSessionSub != null) return;
    _androidSoundPresetSessionSub =
        _player.androidAudioSessionIdStream.listen((_) {
      _androidSoundPresetSessionDebounce?.cancel();
      _androidSoundPresetSessionDebounce =
          Timer(const Duration(milliseconds: 320), () {
        _onAndroidSessionSoundPresetDebounceFire();
      });
    });
  }

  /// 取消待执行的 session 音效重应用，避免与 [stop]/换源 内即将进行的 [reapplyStoredAndroidSoundPreset] 叠用。
  static void cancelPendingAndroidSoundPresetSessionReapply() {
    _androidSoundPresetSessionDebounce?.cancel();
    _androidSoundPresetSessionDebounce = null;
  }

  /// 与 [abortVolumeFade] 独立：新一次换源后渐开音量任务代数，防止旧任务把音量拉回 1。
  static int _androidPostSourceUnmuteGen = 0;

  /// 非「原声」渐开结束后略低于 1.0，给 EQ/响度叠加热门母带留余量，减轻削顶爆音（与常见「延迟启用 EQ + 防 clipping」建议一致）。
  static const double _kAndroidPostEqMasterHeadroom = 0.97;

  /// 换源前将硬件 EQ/响度关到旁路，避免新解码首包仍走「上一曲的曲线」与滤波器状态叠出爆音。
  static Future<void> _resetAndroidHardwareEffectsToBypass() async {
    if (!Platform.isAndroid) return;
    final eq = _androidEqualizer;
    final loud = _androidLoudnessEnhancer;
    if (eq == null || loud == null) return;
    try {
      await PlaybackSoundEffectService.applyHardAndroidBypassForSourceChange(
        equalizer: eq,
        loudness: loud,
      );
    } catch (e) {
      appLog.d('_resetAndroidHardwareEffectsToBypass: $e');
    }
  }

  /// Android：非「原声」时先 [play] 且音量为 0，待 [ProcessingState.ready] 后再经静音预热、套 EQ、再渐开音量
  /// （对齐「延迟启用音效 / ready 后再开 Equalizer / 播放后数百毫秒再 apply」等常见做法）。
  ///
  /// [skipPresetReapply]：同一条原生拼接队列内仅 [seek] 换索引时 EQ 曲线已正确，只做静音等待 + 渐开音量，
  /// 避免再次整轨关开 EQ；全量 [setAudioSource] 换源须为 false。
  static Future<void> _androidGradualUnmuteAfterSourceStart(
    int gen, {
    bool skipPresetReapply = false,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final preset = await SettingsService.loadPlaybackSoundPreset();
      if (gen != _androidPostSourceUnmuteGen) return;
      if (preset == PlaybackSoundPreset.standard) {
        try {
          await _player.setVolume(1.0);
        } catch (_) {}
        return;
      }

      cancelPendingAndroidSoundPresetSessionReapply();
      _androidGradualUnmuteInFlight = true;
      try {
        try {
          /// 仅在 ready 时认为解码器可安全挂 EQ；completed 多为切尾态，避免误当「可开音效」。
          await _player.playerStateStream
              .firstWhere(
                (ps) =>
                    ps.playing &&
                    ps.processingState == ProcessingState.ready,
              )
              .timeout(const Duration(milliseconds: 2200));
        } catch (_) {}

        if (gen != _androidPostSourceUnmuteGen) return;

        /// 仍保持音量为 0：在 ready 之后再给一段静音预热，减少首包与滤波器初始化叠出爆音（约 300～500ms 量级，按路径拆分）。
        await Future<void>.delayed(
          Duration(
            milliseconds: skipPresetReapply ? 340 : 220,
          ),
        );
        if (gen != _androidPostSourceUnmuteGen) return;

        if (!skipPresetReapply) {
          /// 静音下解码已走稳后再写 EQ；频段分步爬升减轻与曲目起始瞬态叠出的爆音。
          await reapplyStoredAndroidSoundPreset(smoothGainRamp: true);
        }
        if (gen != _androidPostSourceUnmuteGen) return;
        await Future<void>.delayed(
          Duration(milliseconds: skipPresetReapply ? 90 : 200),
        );
        if (gen != _androidPostSourceUnmuteGen) return;

        if (!_player.playing) {
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
          return;
        }

        const steps = 28;
        const stepMs = 12;
        final head = _kAndroidPostEqMasterHeadroom;
        for (var i = 1; i <= steps; i++) {
          if (gen != _androidPostSourceUnmuteGen) return;
          try {
            await _player.setVolume(
              (head * i / steps).clamp(0.0, 1.0),
            );
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: stepMs));
        }
        if (gen != _androidPostSourceUnmuteGen) return;
        try {
          await _player.setVolume(head);
        } catch (_) {}
      } finally {
        _androidGradualUnmuteInFlight = false;
      }
    } catch (e, st) {
      appLog.d('Android 渐开音量失败(忽略): $e', error: e, stackTrace: st);
      if (gen == _androidPostSourceUnmuteGen) {
        try {
          await _player.setVolume(1.0);
        } catch (_) {}
      }
    }
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

  /// 通知栏副标题（与 [packages/audio_service] Java 侧常量一致）。
  ///
  /// ColorOS 等第二行常读 [METADATA_KEY_ARTIST] 而非 [DISPLAY_SUBTITLE]，
  /// 歌词开启时 Java 会把本字段同步写入 ARTIST。
  static const String androidNotifySubtitleExtraKey = 'yeah.notify.subtitle';

  static const String androidNotifySongTitleExtraKey = 'yeah.notify.songTitle';

  static const String androidNotifyArtistExtraKey = 'yeah.notify.artist';

  static Map<String, dynamic> _androidNotifyExtras({
    required Song song,
    Map<String, dynamic>? base,
  }) {
    final artist = song.artist?.trim() ?? '';
    final title = songNotificationBaseTitle(song);
    final subtitle = androidNotificationSubtitleForSong(song);
    return <String, dynamic>{
      ...?base,
      androidNotifySongTitleExtraKey: title,
      androidNotifyArtistExtraKey: artist,
      androidNotifySubtitleExtraKey: subtitle,
    };
  }

  static Map<String, dynamic>? _androidLyricExtras(String? line) {
    if (line == null || line.isEmpty) return null;
    return {androidComposerMetadataKey: line};
  }

  /// 通知栏 / 媒体会话默认主标题（曲名）。
  static String songNotificationBaseTitle(Song song) {
    return (song.title?.trim().isNotEmpty ?? false)
        ? song.title!.trim()
        : p.basename(song.path);
  }

  static const String androidNotificationTitleSeparator = ' - ';

  /// 歌名 - 歌手（通知栏开歌词同步时副标题用）。
  static String androidNotificationTitleArtistLine({
    required String title,
    required String artist,
  }) {
    final t = title.trim();
    final a = artist.trim();
    if (a.isEmpty) return t;
    if (t.isEmpty) return a;
    return '$t$androidNotificationTitleSeparator$a';
  }

  /// 通知栏第二行：歌名 - 歌手。
  static String androidNotificationSubtitleForSong(Song song) {
    final artist = song.artist?.trim() ?? '';
    return androidNotificationTitleArtistLine(
      title: songNotificationBaseTitle(song),
      artist: artist,
    );
  }

  static String? _lastAndroidNotifyLyricLineShown;

  static void resetAndroidNotificationLyricDedupe() {
    _lastAndroidNotifyLyricLineShown = null;
  }

  /// 子开关关闭时：通知主标题为曲名（仍走歌词模式 UI / 通道）。
  static void pushAndroidNotificationSongTitle(Song song) {
    if (!Platform.isAndroid) return;
    if (!AndroidCarLyricsSync.isFeatureEnabled) return;
    final line = songNotificationBaseTitle(song);
    if (line.isEmpty) return;
    if (line == _lastAndroidNotifyLyricLineShown) return;
    _lastAndroidNotifyLyricLineShown = line;
    final subtitle = androidNotificationSubtitleForSong(song);
    JustAudioBackground.patchNotificationLyricDisplay(
      songPath: song.path,
      displayTitle: line,
      displaySubtitle: subtitle,
    );
    AndroidMediaSessionLyricsChannel.updateDisplay(
      displayTitle: line,
      displaySubtitle: subtitle,
    );
    _logAndroidNotifyArt('songTitle ${p.basename(song.path)}');
  }

  static void pushAndroidNotificationLyricLine(
    Song song, {
    required String lyricLine,
  }) {
    if (!Platform.isAndroid) return;
    if (!AndroidCarLyricsSync.isFeatureEnabled ||
        !AndroidCarLyricsSync.isSyncLyricsEnabled) {
      return;
    }
    final isGap = AndroidCarLyricsSync.isNotificationLyricGapLine(lyricLine);
    final line = isGap ? lyricLine : lyricLine.trim();
    if (line.isEmpty) return;
    if (line == _lastAndroidNotifyLyricLineShown) return;
    _lastAndroidNotifyLyricLineShown = line;
    final subtitle = androidNotificationSubtitleForSong(song);
    JustAudioBackground.patchNotificationLyricDisplay(
      songPath: song.path,
      displayTitle: line,
      displaySubtitle: subtitle,
      composerMetadataKey:
          isGap ? null : androidComposerMetadataKey,
      composerLine: isGap ? null : line,
    );
    AndroidMediaSessionLyricsChannel.updateDisplay(
      displayTitle: line,
      displaySubtitle: subtitle,
    );
    _logAndroidNotifyArt(
      'lyricLine ${line.length > 28 ? '${line.substring(0, 28)}…' : line}',
    );
  }

  static String androidNotificationPrimaryLine({
    required Song song,
    required Duration position,
    required LyricSettings style,
  }) {
    final base = songNotificationBaseTitle(song);
    final raw = song.lyrics?.trim();
    if (raw == null || raw.isEmpty) return base;
    try {
      final snap = ExternalLyricLineFormatter(lyricStyle: style).resolveAt(
        song: song,
        position: position,
        l10n: null,
      );
      if (!snap.hasEmbeddedLyrics || snap.lyricIndex < 0) return base;
      if (snap.displayLine.isEmpty) return base;
      return snap.displayLine;
    } catch (_) {
      return base;
    }
  }

  /// 新一次 [setAudioSource]/队列换源成功并 [play] 时递增；仅带「本次播放代数」的
  /// [pushAndroidNotificationForSong] 在结束时若已过期则丢弃，避免切歌后旧 hydrate 覆盖新会话。
  static int _androidMediaSessionSyncGeneration = 0;

  /// 每次 [pushAndroidNotificationForSong] 递增；仅最新一次允许 [updateMediaItem]。
  static int _androidNotifyPushSerial = 0;

  /// 短时内已成功推送的曲目 + 封面指纹，合并车载/歌词触发的重复 push。
  static String? _androidNotifyLastOkPath;
  static int _androidNotifyLastOkArtFp = -1;
  static DateTime? _androidNotifyLastOkAt;

  /// 列表/播放页 hydrate 封面后，若仍为在播曲目则补推通知栏（与 UI 封面补全同步）。
  static void attachAndroidNotificationCoverSync() {
    if (!Platform.isAndroid) return;
    SongLibraryMetadataHydrator.onCoverFingerprintChanged = (song) {
      unawaited(pushAndroidNotificationCoverIfStillCurrent(song));
    };
  }

  /// 封面已在内存中补全且仍为当前解码曲目时，补推 [MediaItem.artUri]（不受切歌代数作废）。
  static Future<void> pushAndroidNotificationCoverIfStillCurrent(Song song) async {
    if (!Platform.isAndroid) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    final playing = tryCurrentPlayingPath();
    if (playing == null || !songPathsEqual(playing, song.path)) return;
    if (song.imageBytes == null || song.imageBytes!.isEmpty) {
      _logAndroidNotifyArt(
        'coverIfStillCurrent skip (no bytes) ${_artDiag(song)}',
      );
      return;
    }
    final syncLyrics = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    final artFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    if (syncLyrics &&
        _androidNotifyLastOkPath != null &&
        songPathsEqual(_androidNotifyLastOkPath!, song.path) &&
        _androidNotifyLastOkArtFp == artFp) {
      _logAndroidNotifyArt(
        'coverIfStillCurrent skip (lyrics sync, art unchanged) ${_artDiag(song)}',
      );
      return;
    }
    _logAndroidNotifyArt('coverIfStillCurrent repush ${_artDiag(song)}');
    await pushAndroidNotificationForSong(song);
  }

  /// 快速连点「下一曲」时：若 [abortIfStaleGeneration] 已过期但 [songPath] 仍是正在播放的路径，
  /// 仍应推送（典型为封面 hydrate 较慢）；否则丢弃，避免旧曲 metadata 盖住新曲。
  static bool _shouldApplyAndroidMediaPush({
    required String songPath,
    int? abortIfStaleGeneration,
  }) {
    final playing = tryCurrentPlayingPath();
    if (playing != null && songPathsEqual(playing, songPath)) {
      return true;
    }
    if (abortIfStaleGeneration == null) return true;
    return abortIfStaleGeneration == _androidMediaSessionSyncGeneration;
  }

  static void _logAndroidNotifyArt(String message) {
    if (!Platform.isAndroid) return;
    appLog.i('[AndroidNotifyArt] $message');
  }

  static String _artDiag(Song song) {
    final b = song.imageBytes;
    return 'path=${p.basename(song.path)} bytes=${b?.length ?? 0}';
  }

  static String _mediaItemArtDiag(MediaItem item) =>
      'id=${p.basename(item.id)} artUri=${item.artUri != null}';

  /// Android 多曲且「通知与车载歌词」开启时 [playCurrentFromPlaylist] 会构建整段队列；否则为 false。
  static bool androidCarQueueActive = false;

  /// 换源前与设置页开关对齐原生「是否展示媒体通知 / 系统媒体卡片」。
  static Future<void> syncAndroidCarNotificationGate() async {
    if (!Platform.isAndroid) return;
    await AndroidMediaSessionLyricsChannel.setCarNotificationEnabled(
      await SettingsService.loadAndroidCarLyricsEnabled(),
    );
  }

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
  static Future<void> reapplyStoredAndroidSoundPreset({
    bool smoothGainRamp = false,
  }) async {
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
        smoothGainRamp: smoothGainRamp,
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
    final carLyricsOn = Platform.isAndroid
        ? await SettingsService.loadAndroidCarLyricsEnabled()
        : false;
    final useFullPlayerQueue = useAndroidConcatQueue &&
        Platform.isAndroid &&
        carLyricsOn &&
        queue.length > 1;
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
    if (Platform.isAndroid) {
      await syncAndroidCarNotificationGate();
    }
    androidCarQueueActive = false;
    _invalidateAndroidQueueReuse();
    abortVolumeFade();
    for (var attempt = 0; attempt < 3; attempt++) {
      int? unmuteGen;
      try {
        if (Platform.isAndroid) {
          _androidPostSourceUnmuteGen++;
          unmuteGen = _androidPostSourceUnmuteGen;
        }
        if (Platform.isLinux &&
            _player.processingState == ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
        cancelPendingAndroidSoundPresetSessionReapply();
        await _player.stop();
        if (Platform.isAndroid) {
          try {
            await _player.setVolume(0.0);
          } catch (_) {}
        } else {
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
        }
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        final tag = await _tagForSong(song);
        final androidPreset = Platform.isAndroid
            ? await SettingsService.loadPlaybackSoundPreset()
            : null;
        await _player.setAudioSource(_buildAudioSource(song, tag: tag));
        await _player.seek(Duration.zero);
        if (Platform.isAndroid) {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        /// 须在 [setAudioSource] 之后：否则 [AndroidEqualizer.parameters] 未就绪，软/原声路径会挂起整条 [_playChain] 导致无法点歌。
        if (Platform.isAndroid &&
            androidPreset != null &&
            androidPreset != PlaybackSoundPreset.standard) {
          await _resetAndroidHardwareEffectsToBypass();
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        // 「原声」仍在静音下先关效果器；非原声则推迟到 [_androidGradualUnmuteAfterSourceStart] 内解码就绪后再套 EQ。
        if (Platform.isAndroid &&
            androidPreset == PlaybackSoundPreset.standard) {
          await reapplyStoredAndroidSoundPreset();
        }
        // 勿 await play()：部分机型/后端上该 Future 长期不结束会卡死整条 _playChain 与 UI 触发的 playAt。
        _player.play();
        isPlaying = _player.playing;
        if (Platform.isAndroid && unmuteGen != null) {
          unawaited(_androidGradualUnmuteAfterSourceStart(unmuteGen));
        }
        await Future<void>.delayed(const Duration(milliseconds: 24));
        if (Platform.isAndroid &&
            await SettingsService.loadAndroidCarLyricsEnabled()) {
          final g = ++_androidMediaSessionSyncGeneration;
          unawaited(
            pushAndroidNotificationForSong(song, abortIfStaleGeneration: g),
          );
        }
        return true;
      } catch (e) {
        if (Platform.isAndroid) {
          _androidPostSourceUnmuteGen++;
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
        }
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
        abortVolumeFade();
        cancelPendingAndroidSoundPresetSessionReapply();
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
        final androidPreset = await SettingsService.loadPlaybackSoundPreset();
        if (androidPreset != PlaybackSoundPreset.standard) {
          _androidPostSourceUnmuteGen++;
          final unmuteGen = _androidPostSourceUnmuteGen;
          try {
            await _player.setVolume(0.0);
          } catch (_) {}
          await _player.seek(Duration.zero, index: idx);
          _player.play();
          isPlaying = _player.playing;
          unawaited(
            _androidGradualUnmuteAfterSourceStart(
              unmuteGen,
              skipPresetReapply: true,
            ),
          );
        } else {
          await _player.setVolume(1.0);
          await _player.seek(Duration.zero, index: idx);
          _player.play();
          isPlaying = _player.playing;
        }
        androidCarQueueActive = true;
        _lastAndroidQueueRef = queue;
        if (Platform.isAndroid &&
            await SettingsService.loadAndroidCarLyricsEnabled()) {
          final g = ++_androidMediaSessionSyncGeneration;
          final s = queue[idx];
          try {
            await SongLibraryMetadataHydrator.hydrateIfNeeded(s);
          } catch (_) {}
          unawaited(
            pushAndroidNotificationForSong(s, abortIfStaleGeneration: g),
          );
        }
        return true;
      } catch (e) {
        appLog.d('Android 队列内快速切曲不可用，整轨重建: $e');
        _invalidateAndroidQueueReuse();
      }
    }

    if (Platform.isAndroid) {
      await syncAndroidCarNotificationGate();
    }
    androidCarQueueActive = false;
    abortVolumeFade();
    for (var attempt = 0; attempt < 3; attempt++) {
      int? unmuteGen;
      try {
        if (Platform.isAndroid) {
          _androidPostSourceUnmuteGen++;
          unmuteGen = _androidPostSourceUnmuteGen;
        }
        if (Platform.isLinux &&
            _player.processingState == ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
        cancelPendingAndroidSoundPresetSessionReapply();
        await _player.stop();
        if (Platform.isAndroid) {
          try {
            await _player.setVolume(0.0);
          } catch (_) {}
        } else {
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
        }
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
        final lyricStyle = await SettingsService.loadLyricSettings();
        final androidPreset = Platform.isAndroid
            ? await SettingsService.loadPlaybackSoundPreset()
            : null;
        final children = <AudioSource>[];
        for (var i = 0; i < queue.length; i++) {
          final s = queue[i];
          if (i == idx) {
            try {
              await SongLibraryMetadataHydrator.hydrateIfNeeded(s);
            } catch (e) {
              _logAndroidNotifyArt('queueBuild hydrate current failed: $e');
            }
          }
          final tag = await buildMediaItemForSong(
            s,
            showCover: showCover,
            lyricStyle: lyricStyle,
            subtitlePosition: Duration.zero,
          );
          if (i == idx) {
            _logAndroidNotifyArt(
              'queueBuild current ${_artDiag(s)} → ${_mediaItemArtDiag(tag)}',
            );
          }
          children.add(_buildAudioSource(s, tag: tag));
        }
        await _player.setAudioSources(
          children,
          initialIndex: idx,
          initialPosition: Duration.zero,
        );
        androidCarQueueActive = true;
        _lastAndroidQueueRef = queue;
        if (Platform.isAndroid) {
          await Future<void>.delayed(const Duration(milliseconds: 28));
        }
        if (Platform.isAndroid &&
            androidPreset != null &&
            androidPreset != PlaybackSoundPreset.standard) {
          await _resetAndroidHardwareEffectsToBypass();
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        if (Platform.isAndroid &&
            androidPreset == PlaybackSoundPreset.standard) {
          await reapplyStoredAndroidSoundPreset();
        }
        _player.play();
        isPlaying = _player.playing;
        if (Platform.isAndroid && unmuteGen != null) {
          unawaited(_androidGradualUnmuteAfterSourceStart(unmuteGen));
        }
        await Future<void>.delayed(const Duration(milliseconds: 24));
        if (Platform.isAndroid &&
            await SettingsService.loadAndroidCarLyricsEnabled()) {
          final g = ++_androidMediaSessionSyncGeneration;
          final s = queue[idx];
          unawaited(
            pushAndroidNotificationForSong(s, abortIfStaleGeneration: g),
          );
        }
        return true;
      } catch (e) {
        if (Platform.isAndroid) {
          _androidPostSourceUnmuteGen++;
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
        }
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

  /// Android 已 [JustAudioBackground.init] 时 [AudioSource.tag] 必须为 [MediaItem]；
  /// 通知栏/车载推送由 [loadAndroidCarLyricsEnabled] 单独门禁。
  Future<MediaItem> _mediaItemTagForSong(Song song) async {
    final carEnabled = await SettingsService.loadAndroidCarLyricsEnabled();
    final showCover =
        carEnabled && await SettingsService.loadAndroidCarLyricsShowCover();
    final lyricStyle = await SettingsService.loadLyricSettings();
    final syncLyrics = carEnabled &&
        await SettingsService.loadAndroidCarLyricsSyncLyrics();
    return buildMediaItemForSong(
      song,
      showCover: showCover,
      lyricStyle: lyricStyle,
      subtitlePosition: Duration.zero,
      deferLyricDisplayToChannel: syncLyrics,
    );
  }

  Future<Object?> _tagForSong(Song song) async {
    if (Platform.isAndroid) {
      return _mediaItemTagForSong(song);
    }
    return song;
  }

  /// 构建 [MediaItem]（`just_audio_background` 的 AudioSource tag）。
  static Future<MediaItem> buildMediaItemForSong(
    Song song, {
    required bool showCover,
    LyricSettings? lyricStyle,
    Duration subtitlePosition = Duration.zero,
    /// 为 true 时不写入 [displayTitle]/歌词 extras，由 [pushAndroidNotificationLyricLine] 直推。
    bool deferLyricDisplayToChannel = false,
  }) async {
    final baseTitle = songNotificationBaseTitle(song);
    final artist = song.artist?.trim().isNotEmpty == true
        ? song.artist!.trim()
        : '';
    Uri? artUri;
    if (showCover) {
      final bytes = song.imageBytes;
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final f = await AppEphemeralStorage.writeNotificationArtFile(
            songPath: song.path,
            bytes: bytes,
          );
          artUri = Uri.file(f.path);
        } catch (_) {}
      }
    }
    final style = lyricStyle ?? LyricSettings();
    style.normalizeLayoutFields();
    // 开启同步歌词行且 defer 时，主标题由 [pushAndroidNotificationLyricLine] 跟进度直推。
    final useLyricChannel = deferLyricDisplayToChannel;
    final lyricLine = useLyricChannel
        ? androidNotificationPrimaryLine(
            song: song,
            position: subtitlePosition,
            style: style,
          )
        : null;
    final lyricsInTitle =
        useLyricChannel && lyricLine != null && lyricLine != baseTitle;
    final displayTitle = useLyricChannel ? null : baseTitle;
    final displaySubtitle =
        useLyricChannel ? null : androidNotificationSubtitleForSong(song);
    final lyricExtras = _androidLyricExtras(lyricsInTitle ? lyricLine : null);
    Map<String, dynamic>? artBase;
    if (artUri != null && artUri.scheme == 'file') {
      artBase = <String, dynamic>{
        if (lyricExtras != null) ...lyricExtras,
        'artCacheFile': artUri.toFilePath(),
      };
    } else {
      artBase = lyricExtras;
    }
    final extras = _androidNotifyExtras(song: song, base: artBase);
    return MediaItem(
      id: song.path,
      title: baseTitle,
      artist: artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      displayTitle: displayTitle,
      displaySubtitle: displaySubtitle,
      extras: extras,
    );
  }

  /// 在切歌或补载元数据后，把当前曲目的封面/标题/歌词行推送到系统媒体会话（更新通知）。
  ///
  /// [abortIfStaleGeneration]：与 [_androidMediaSessionSyncGeneration] 配套，仅在「随本次换源发起的
  /// 单次补推」上使用；歌词 tick、[AndroidCarLyricsSync] 等不传，始终落库。
  static Future<void> pushAndroidNotificationForSong(
    Song song, {
    int? abortIfStaleGeneration,
    bool forceNotificationPush = false,
  }) async {
    if (!Platform.isAndroid) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    final targetPath = song.path;
    if (targetPath.trim().isEmpty) return;
    final syncLyrics = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    final artFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    if (!forceNotificationPush &&
        syncLyrics &&
        _androidNotifyLastOkPath != null &&
        songPathsEqual(_androidNotifyLastOkPath!, targetPath) &&
        _androidNotifyLastOkArtFp == artFp &&
        (song.imageBytes?.isNotEmpty ?? false)) {
      _logAndroidNotifyArt(
        'push skip (lyrics sync, same path+art) ${_artDiag(song)}',
      );
      return;
    }
    final now = DateTime.now();
    if (_androidNotifyLastOkPath != null &&
        songPathsEqual(_androidNotifyLastOkPath!, targetPath) &&
        _androidNotifyLastOkArtFp == artFp &&
        _androidNotifyLastOkAt != null &&
        now.difference(_androidNotifyLastOkAt!) <
            const Duration(milliseconds: 450)) {
      _logAndroidNotifyArt(
        'push coalesced (recent OK) ${_artDiag(song)}',
      );
      return;
    }
    final sw = Stopwatch()..start();
    final gen = abortIfStaleGeneration;
    final ticket = ++_androidNotifyPushSerial;
    _logAndroidNotifyArt(
      'push start #$ticket gen=$gen ${_artDiag(song)} '
      'playing=${p.basename(tryCurrentPlayingPath() ?? "")}',
    );
    try {
      try {
        final hydrated = await SongLibraryMetadataHydrator.hydrateIfNeeded(song);
        _logAndroidNotifyArt(
          'after hydrate ${sw.elapsedMilliseconds}ms changed=$hydrated ${_artDiag(song)}',
        );
      } catch (e) {
        _logAndroidNotifyArt('hydrate failed: $e');
      }
      final showCover = await SettingsService.loadAndroidCarLyricsShowCover();
      if (showCover && (song.imageBytes == null || song.imageBytes!.isEmpty)) {
        try {
          await FileUtils.loadSongMeta(
            song,
            loadEmbeddedAlbumArt: true,
            storeLyricsWithTrack: syncLyrics,
            maxEmbeddedArtBytes:
                SongLibraryMetadataHydrator.maxEmbeddedArtBytes,
          );
          ApplicationUtils.evictSongCoverProvidersForPath(song.path);
          scheduleEmbeddedSongMetadataPersist(song);
          _logAndroidNotifyArt(
            'after loadSongMeta art ${sw.elapsedMilliseconds}ms ${_artDiag(song)}',
          );
        } catch (e) {
          _logAndroidNotifyArt('loadSongMeta art failed: $e');
        }
      } else if (syncLyrics &&
          (song.lyrics == null || song.lyrics!.trim().isEmpty)) {
        try {
          await FileUtils.loadSongMeta(
            song,
            loadEmbeddedAlbumArt: false,
            storeLyricsWithTrack: syncLyrics,
          );
          scheduleEmbeddedSongMetadataPersist(song);
        } catch (_) {}
      }
      if (!showCover) {
        _logAndroidNotifyArt('showCover=false, skip artUri');
      }
      final playing = tryCurrentPlayingPath();
      final stillCurrent =
          playing != null && songPathsEqual(playing, targetPath);
      final genOk = _shouldApplyAndroidMediaPush(
        songPath: targetPath,
        abortIfStaleGeneration: abortIfStaleGeneration,
      );
      if (!genOk) {
        _logAndroidNotifyArt(
          'ABORT before build gen=$gen curGen=$_androidMediaSessionSyncGeneration '
          'stillCurrent=$stillCurrent ${sw.elapsedMilliseconds}ms',
        );
        return;
      }
      final lyricStyle = await SettingsService.loadLyricSettings();
      final item = await buildMediaItemForSong(
        song,
        showCover: showCover,
        lyricStyle: lyricStyle,
        subtitlePosition: playerPosition,
        deferLyricDisplayToChannel: syncLyrics,
      );
      if (!_shouldApplyAndroidMediaPush(
        songPath: targetPath,
        abortIfStaleGeneration: abortIfStaleGeneration,
      )) {
        _logAndroidNotifyArt(
          'ABORT before updateMediaItem ${sw.elapsedMilliseconds}ms '
          '${_mediaItemArtDiag(item)}',
        );
        return;
      }
      if (ticket != _androidNotifyPushSerial) {
        _logAndroidNotifyArt(
          'DROP stale ticket #$ticket (latest #$_androidNotifyPushSerial) '
          '${sw.elapsedMilliseconds}ms',
        );
        return;
      }
      await JustAudioBackground.updateNotificationMediaItem(item);
      _androidNotifyLastOkPath = targetPath;
      _androidNotifyLastOkArtFp = artFp;
      _androidNotifyLastOkAt = DateTime.now();
      _logAndroidNotifyArt(
        'notificationMediaItem OK #$ticket ${sw.elapsedMilliseconds}ms '
        '${_mediaItemArtDiag(item)}',
      );
    } catch (e, st) {
      _logAndroidNotifyArt('push FAILED ${sw.elapsedMilliseconds}ms: $e');
      appLog.d('pushAndroidNotificationForSong', error: e, stackTrace: st);
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
    if (Platform.isAndroid) {
      _androidPostSourceUnmuteGen++;
      _androidGradualUnmuteInFlight = false;
    }
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
    cancelPendingAndroidSoundPresetSessionReapply();
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

  /// 解码器当前进度（略早于 [positionStream] 事件，便于在歌词行边界即时判定）。
  static Duration get playerPosition => _player.position;

  static Stream<Duration>? _androidLyricPositionStream;

  /// 供 Android 通知歌词同步：最高约 16ms 采样，与播放页 [positionStream] 同源于 just_audio，
  /// 但不受默认 maxPeriod 200ms 限制。
  static Stream<Duration> get androidLyricPositionStream {
    return _androidLyricPositionStream ??= _player
        .createPositionStream(
          steps: 4000,
          minPeriod: const Duration(milliseconds: 16),
          maxPeriod: const Duration(milliseconds: 16),
        )
        .map((d) {
          _positionCache = d;
          return d;
        });
  }

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
