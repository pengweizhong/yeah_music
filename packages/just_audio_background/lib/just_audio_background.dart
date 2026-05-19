import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

export 'package:audio_service/audio_service.dart' show MediaItem;

late SwitchAudioHandler _audioHandler;
late JustAudioPlatform _platform;

/// Yeah Music：控制是否向系统会话同步歌词（通知「词」按钮）。
Future<void> Function()? _yeahAndroidLyricsSyncToggleHandler;

/// Yeah Music：后台/锁屏媒体键点击处理；返回 true 表示已消费，不再走默认 play/pause/next/previous。
Future<bool> Function(String kind)? _yeahAndroidMediaButtonClickHandler;

/// 为 true 时 [setMediaItem] 不覆盖队列里已 patch 的当前歌词行。
bool _yeahAndroidLyricsSyncEnabled = false;

/// Yeah Music：暂停 / 通知栏切歌前 800ms 线性淡出（由宿主注入 [MusicService.fadeOutVolumeWhilePlaying]）。
Future<void> Function()? _yeahFadeOutVolumeHandler;

/// 通知自定义动作名，须与 [MediaControl.custom] 的 [name] 一致。
const String kYeahToggleSystemLyricsAction = 'yeah_toggle_system_lyrics';

/// Provides the [init] method to initialise just_audio for background playback.
class JustAudioBackground {
  /// Initialise just_audio for background playback. This should be called from
  /// your app's `main` method. e.g.:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   await JustAudioBackground.init(
  ///     androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
  ///     androidNotificationChannelName: 'Audio playback',
  ///     androidNotificationOngoing: true,
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Each parameter controls a behaviour in audio_service. Consult
  /// audio_service's `AudioServiceConfig` API documentation for more
  /// information.
  static Future<void> init({
    bool androidResumeOnClick = true,
    String? androidNotificationChannelId,
    String androidNotificationChannelName = 'Notifications',
    String? androidNotificationChannelDescription,
    Color? notificationColor,
    String androidNotificationIcon = 'mipmap/ic_launcher',
    bool androidShowNotificationBadge = false,
    bool androidNotificationClickStartsActivity = true,
    bool androidNotificationOngoing = false,
    bool androidStopForegroundOnPause = true,
    int? artDownscaleWidth,
    int? artDownscaleHeight,
    Duration fastForwardInterval = const Duration(seconds: 10),
    Duration rewindInterval = const Duration(seconds: 10),
    bool preloadArtwork = false,
    Map<String, dynamic>? androidBrowsableRootExtras,
    Future<void> Function()? onAndroidLyricsSyncToggle,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _JustAudioBackgroundPlugin.setup(
      androidResumeOnClick: androidResumeOnClick,
      androidNotificationChannelId: androidNotificationChannelId,
      androidNotificationChannelName: androidNotificationChannelName,
      androidNotificationChannelDescription:
          androidNotificationChannelDescription,
      notificationColor: notificationColor,
      androidNotificationIcon: androidNotificationIcon,
      androidShowNotificationBadge: androidShowNotificationBadge,
      androidNotificationClickStartsActivity:
          androidNotificationClickStartsActivity,
      androidNotificationOngoing: androidNotificationOngoing,
      androidStopForegroundOnPause: androidStopForegroundOnPause,
      artDownscaleWidth: artDownscaleWidth,
      artDownscaleHeight: artDownscaleHeight,
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
      preloadArtwork: preloadArtwork,
      androidBrowsableRootExtras: androidBrowsableRootExtras,
      onAndroidLyricsSyncToggle: onAndroidLyricsSyncToggle,
    );
  }

  /// 注册 Android 后台/锁屏媒体键点击处理。
  ///
  /// [kind] 为 `media`、`next` 或 `previous`。
  static void setAndroidMediaButtonClickHandler(
    Future<bool> Function(String kind)? handler,
  ) {
    _yeahAndroidMediaButtonClickHandler = handler;
  }

  /// 注入「当前正在播放时」线性淡出逻辑，供通知栏暂停 / 上一首 / 下一首与宿主一致。
  static void setFadeOutVolumeHandler(Future<void> Function()? handler) {
    _yeahFadeOutVolumeHandler = handler;
  }

  /// 通知栏歌词由 [updateNotificationDisplayText] 直推时，避免 [setMediaItem] 用旧行覆盖当前行。
  static void setAndroidLyricsSyncEnabled(bool enabled) {
    _yeahAndroidLyricsSyncEnabled = enabled;
  }

  /// 更新系统媒体会话 / 通知栏 [MediaItem]（含封面）。
  ///
  /// 必须使用本方法，**不要**调用 [AudioService.updateMediaItem]：后者走
  /// `audio_service` 内未接入 just_audio 的 `_compatibilitySwitcher`，
  /// 不会触发 [_PlayerAudioHandler] 的 [mediaItem] 流，通知栏封面/标题不刷新。
  static Future<void> updateNotificationMediaItem(MediaItem item) async {
    await _audioHandler.updateMediaItem(item);
  }

  /// 歌词换行：只改 [queue]，不 [mediaItem.add]（避免 setMediaItem 覆盖 [DISPLAY_TITLE]）。
  static void patchNotificationLyricDisplay({
    required String songPath,
    required String displayTitle,
    required String displaySubtitle,
    String? composerMetadataKey,
    String? composerLine,
  }) {
    _playerAudioHandler.patchNotificationLyricDisplay(
      songPath: songPath,
      displayTitle: displayTitle,
      displaySubtitle: displaySubtitle,
      composerMetadataKey: composerMetadataKey,
      composerLine: composerLine,
    );
  }
}

class _JustAudioBackgroundPlugin extends JustAudioPlatform {
  static Future<void> setup({
    bool androidResumeOnClick = true,
    String? androidNotificationChannelId,
    String androidNotificationChannelName = 'Notifications',
    String? androidNotificationChannelDescription,
    Color? notificationColor,
    String androidNotificationIcon = 'mipmap/ic_launcher',
    bool androidShowNotificationBadge = false,
    bool androidNotificationClickStartsActivity = true,
    bool androidNotificationOngoing = false,
    bool androidStopForegroundOnPause = true,
    int? artDownscaleWidth,
    int? artDownscaleHeight,
    Duration fastForwardInterval = const Duration(seconds: 10),
    Duration rewindInterval = const Duration(seconds: 10),
    bool preloadArtwork = false,
    Map<String, dynamic>? androidBrowsableRootExtras,
    Future<void> Function()? onAndroidLyricsSyncToggle,
  }) async {
    _yeahAndroidLyricsSyncToggleHandler = onAndroidLyricsSyncToggle;
    _platform = JustAudioPlatform.instance;
    JustAudioPlatform.instance = _JustAudioBackgroundPlugin();
    _audioHandler = await AudioService.init(
      builder: () => SwitchAudioHandler(BaseAudioHandler()),
      config: AudioServiceConfig(
        androidResumeOnClick: androidResumeOnClick,
        androidNotificationChannelId: androidNotificationChannelId,
        androidNotificationChannelName: androidNotificationChannelName,
        androidNotificationChannelDescription:
            androidNotificationChannelDescription,
        notificationColor: notificationColor,
        androidNotificationIcon: androidNotificationIcon,
        androidShowNotificationBadge: androidShowNotificationBadge,
        androidNotificationClickStartsActivity:
            androidNotificationClickStartsActivity,
        androidNotificationOngoing: androidNotificationOngoing,
        androidStopForegroundOnPause: androidStopForegroundOnPause,
        artDownscaleWidth: artDownscaleWidth,
        artDownscaleHeight: artDownscaleHeight,
        fastForwardInterval: fastForwardInterval,
        rewindInterval: rewindInterval,
        preloadArtwork: preloadArtwork,
        androidBrowsableRootExtras: androidBrowsableRootExtras,
      ),
    );
  }

  _JustAudioPlayer? _player;
  String? _playerId;

  _JustAudioBackgroundPlugin();

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    if (_playerId != null) {
      throw PlatformException(
        code: "error",
        message: "just_audio_background supports only a single player instance",
      );
    }
    _playerId = request.id;
    _player ??= _JustAudioPlayer(initRequest: request);
    return _player!;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    if (request.id == _playerId) {
      _playerId = null;
      final player = _player;
      _player = null;
      await player?.release();
    }
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    final player = _player;
    _player = null;
    await player?.release();
    return DisposeAllPlayersResponse();
  }
}

final _PlayerAudioHandler _playerAudioHandler = _PlayerAudioHandler();

class _JustAudioPlayer extends AudioPlayerPlatform {
  final InitRequest initRequest;
  final eventController =
      StreamController<PlaybackEventMessage>.broadcast(sync: true);
  final playerDataController =
      StreamController<PlayerDataMessage>.broadcast(sync: true);

  _JustAudioPlayer({required this.initRequest}) : super(initRequest.id) {
    eventController.onCancel = _playerAudioHandler.cancelStreamSubscriptions;
    _playerAudioHandler._initPlayer(initRequest);
    _audioHandler.inner = _playerAudioHandler;
    _audioHandler.customEvent
        .whereType<PlaybackEventMessage>()
        .listen(eventController.add);
    _audioHandler.customEvent
        .whereType<_PlayingEvent>()
        .map((event) => event.playing)
        .distinct()
        .listen((playing) {
      playerDataController.add(PlayerDataMessage(playing: playing));
    });
  }

  PlaybackState get playbackState => _audioHandler.playbackState.nvalue!;

  Future<void> release() async {
    await _audioHandler.stop();
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      playerDataController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) =>
      _playerAudioHandler.customLoad(request);

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    await _audioHandler.play();
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    await _audioHandler.pause();
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) =>
      _playerAudioHandler.customSetVolume(request);

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    await _playerAudioHandler.setSpeed(request.speed);
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    await _playerAudioHandler.customSetPitch(request);
    return SetPitchResponse();
  }

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
      SetSkipSilenceRequest request) async {
    await _playerAudioHandler.customSetSkipSilence(request);
    return SetSkipSilenceResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    await _audioHandler
        .setRepeatMode(AudioServiceRepeatMode.values[request.loopMode.index]);
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
      SetShuffleModeRequest request) async {
    await _audioHandler.setShuffleMode(
        AudioServiceShuffleMode.values[request.shuffleMode.index]);
    return SetShuffleModeResponse();
  }

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
          SetShuffleOrderRequest request) =>
      _playerAudioHandler.customSetShuffleOrder(request);

  @override
  Future<SetWebCrossOriginResponse> setWebCrossOrigin(
      SetWebCrossOriginRequest request) async {
    _playerAudioHandler.customSetWebCrossOrigin(request);
    return SetWebCrossOriginResponse();
  }

  @override
  Future<SetWebSinkIdResponse> setWebSinkId(SetWebSinkIdRequest request) {
    _playerAudioHandler.customSetWebSinkId(request);
    throw SetWebSinkIdResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) =>
      _playerAudioHandler.customPlayerSeek(request);

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
          ConcatenatingInsertAllRequest request) =>
      _playerAudioHandler.customConcatenatingInsertAll(request);

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest request) =>
      _playerAudioHandler.customConcatenatingRemoveRange(request);

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
          ConcatenatingMoveRequest request) =>
      _playerAudioHandler.customConcatenatingMove(request);

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
          SetAndroidAudioAttributesRequest request) =>
      _playerAudioHandler.customSetAndroidAudioAttributes(request);

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      setAutomaticallyWaitsToMinimizeStalling(
              SetAutomaticallyWaitsToMinimizeStallingRequest request) =>
          _playerAudioHandler
              .customSetAutomaticallyWaitsToMinimizeStalling(request);

  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
          AndroidEqualizerBandSetGainRequest request) =>
      _playerAudioHandler.customAndroidEqualizerBandSetGain(request);

  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
          AndroidEqualizerGetParametersRequest request) =>
      _playerAudioHandler.customAndroidEqualizerGetParameters(request);

  @override
  Future<AndroidLoudnessEnhancerSetTargetGainResponse>
      androidLoudnessEnhancerSetTargetGain(
              AndroidLoudnessEnhancerSetTargetGainRequest request) =>
          _playerAudioHandler
              .customAndroidLoudnessEnhancerSetTargetGain(request);

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
          AudioEffectSetEnabledRequest request) =>
      _playerAudioHandler.customAudioEffectSetEnabled(request);

  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
          SetAllowsExternalPlaybackRequest request) =>
      _playerAudioHandler.customSetAllowsExternalPlayback(request);

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      setCanUseNetworkResourcesForLiveStreamingWhilePaused(
              SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest
                  request) =>
          _playerAudioHandler
              .customSetCanUseNetworkResourcesForLiveStreamingWhilePaused(
                  request);

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
          SetPreferredPeakBitRateRequest request) =>
      _playerAudioHandler.customSetPreferredPeakBitRate(request);
}

class _PlayerAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _lock = Lock();
  var _playerCompleter = _ValueCompleter<AudioPlayerPlatform>();
  PlaybackEventMessage _justAudioEvent = PlaybackEventMessage(
    processingState: ProcessingStateMessage.idle,
    updateTime: DateTime.now(),
    updatePosition: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: null,
    icyMetadata: null,
    currentIndex: null,
    androidAudioSessionId: null,
  );
  AudioSourceMessage? _source;
  bool _playing = false;
  double _speed = 1.0;
  _Seeker? _seeker;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;
  List<int> _shuffleIndices = [];
  List<int> _shuffleIndicesInv = [];
  List<int> _effectiveIndices = [];
  List<int> _effectiveIndicesInv = [];

  /// 避免 debounce 在切歌后重复 [mediaItem.add]，用无封面的队列项覆盖 [pushAndroidNotificationForSong] 已写入的封面。
  int? _debounceLastEmittedIndex;
  Duration? _debounceLastEmittedDuration;

  Future<AudioPlayerPlatform> get _player => _playerCompleter.future;
  int? index;
  MediaItem? get currentMediaItem =>
      index != null && index! >= 0 && index! < currentQueue.length
          ? currentQueue[index!]
          : null;

  List<MediaItem> get currentQueue => queue.value;
  StreamSubscription<TrackInfo>? _trackInfoSubscription;

  Future<void> _initPlayer(InitRequest initRequest) =>
      _lock.synchronized(() async {
        final player = await _platform.init(initRequest);
        _playerCompleter.complete(player);
        final playbackEventMessageStream = player.playbackEventMessageStream;
        _trackInfoSubscription = playbackEventMessageStream
            .map((event) {
              index = event.currentIndex ?? _justAudioEvent.currentIndex;
              _justAudioEvent = event;
              customEvent.add(event);
              _broadcastState();
              return event;
            })
            .map((event) => TrackInfo(event.currentIndex, event.duration))
            .distinct()
            .debounceTime(const Duration(milliseconds: 100))
            .map((track) {
              // Platform may send us a null duration on dispose, which we should
              // ignore.
              final currentMediaItem = this.currentMediaItem;
              if (currentMediaItem != null) {
                if (track.duration == null &&
                    currentMediaItem.duration != null) {
                  return TrackInfo(track.index, currentMediaItem.duration);
                }
              }
              return track;
            })
            .distinct()
            .listen((track) {
              if (currentMediaItem != null && index != null) {
                final idx = index!;
                var durationPatched = false;
                if (track.duration != currentMediaItem!.duration &&
                    (idx < queue.nvalue!.length && track.duration != null)) {
                  currentQueue[idx] =
                      currentQueue[idx].copyWith(duration: track.duration);
                  queue.add(currentQueue);
                  durationPatched = true;
                }
                final indexChanged = _debounceLastEmittedIndex != idx;
                final shouldBroadcast = durationPatched ||
                    indexChanged ||
                    _debounceLastEmittedDuration != track.duration;
                if (shouldBroadcast) {
                  _debounceLastEmittedIndex = idx;
                  _debounceLastEmittedDuration = track.duration;
                  var emit = currentMediaItem!;
                  final live = mediaItem.nvalue;
                  final queueHadArt = emit.artUri != null;
                  emit = _yeahMergeNotificationArtwork(emit, live);
                  emit = _yeahMergeNotificationLyricDisplay(emit, live);
                  if (!queueHadArt && emit.artUri != null) {
                    final patched = List<MediaItem>.from(currentQueue);
                    patched[idx] = emit;
                    queue.add(patched);
                    debugPrint(
                      '[AndroidNotifyArt] debounce: patched queue[$idx] art from live',
                    );
                  } else if (!queueHadArt &&
                      emit.artUri == null &&
                      !indexChanged) {
                    debugPrint(
                      '[AndroidNotifyArt] debounce: SKIP null-art duration-only idx=$idx',
                    );
                    return;
                  } else if (durationPatched && !indexChanged) {
                    final lyricsLayout = _yeahNotificationLyricsLayoutActive(emit);
                    if (lyricsLayout || queueHadArt) {
                      debugPrint(
                        '[AndroidNotifyArt] debounce: SKIP duration-only '
                        '(keep lyrics=$lyricsLayout art=$queueHadArt) idx=$idx',
                      );
                      return;
                    }
                  }
                  if (_yeahAndroidLyricsSyncEnabled && !indexChanged) {
                    debugPrint(
                      '[AndroidNotifyArt] debounce: SKIP (lyrics managed) idx=$idx',
                    );
                    return;
                  }
                  mediaItem.add(_yeahEmitForSetMediaItem(emit));
                }
              }
            }, onError: (Object e, [StackTrace? st]) {});
      });

  Future<void> cancelStreamSubscriptions() async {
    final trackInfoSubscription = _trackInfoSubscription;
    if (trackInfoSubscription != null) {
      _trackInfoSubscription = null;
      await trackInfoSubscription.cancel();
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(queue);
    if (mediaItem.nvalue == null &&
        index != null &&
        index! >= 0 &&
        index! < queue.length) {
      mediaItem.add(_yeahEmitForSetMediaItem(queue[index!]));
    }
  }

  /// [QueueHandler.updateMediaItem] 不广播 [mediaItem]，Android [setMediaItem] 因此不刷新。
  /// 同时将 [updated] 写回 [queue] 当前项，避免切轨 debounce 用建队列时的无封面项覆盖封面。
  @override
  Future<void> updateMediaItem(MediaItem updated) async {
    await super.updateMediaItem(updated);
    final idx = index;
    final q = queue.nvalue;
    var emit = updated;
    if (q != null && idx != null && idx >= 0 && idx < q.length) {
      final next = List<MediaItem>.from(q);
      var slot = idx;
      if (next[slot].id != updated.id) {
        final byId = next.indexWhere((m) => m.id == updated.id);
        if (byId >= 0) slot = byId;
      }
      if (next[slot].id == updated.id) {
        emit = _yeahEmitForSetMediaItem(updated);
        next[slot] = emit;
        queue.add(next);
      }
    }
    // QueueHandler.updateMediaItem 不会触发 mediaItem 流；必须 add 才会走
    // audio_service 的 setMediaItem（file:// 封面依赖 extras.artCacheFile）。
    mediaItem.add(emit);
  }

  void patchNotificationLyricDisplay({
    required String songPath,
    required String displayTitle,
    required String displaySubtitle,
    String? composerMetadataKey,
    String? composerLine,
  }) {
    final q = queue.nvalue;
    if (q == null || q.isEmpty) return;
    final next = List<MediaItem>.from(q);
    var patched = false;
    for (var i = 0; i < next.length; i++) {
      if (!_yeahMediaIdMatchesPath(next[i].id, songPath)) continue;
      final extras = Map<String, dynamic>.from(next[i].extras ?? {});
      if (composerMetadataKey != null &&
          composerLine != null &&
          composerLine.isNotEmpty) {
        extras[composerMetadataKey] = composerLine;
      }
      next[i] = next[i].copyWith(
        displayTitle: displayTitle,
        displaySubtitle: displaySubtitle,
        extras: extras,
      );
      patched = true;
    }
    if (patched) queue.add(next);
  }

  static bool _yeahMediaIdMatchesPath(String mediaId, String songPath) {
    String norm(String p) =>
        p.replaceAll(r'\', '/').trim().toLowerCase();
    var fromId = mediaId.trim();
    if (fromId.startsWith('file://')) {
      try {
        fromId = Uri.parse(fromId).toFilePath();
      } catch (_) {}
    }
    return norm(fromId) == norm(songPath);
  }

  /// 队列项尚无 [artUri] 时保留 [mediaItem] 流里已推送的封面，防止 debounce 刷回黑图。
  static MediaItem _yeahMergeNotificationArtwork(
    MediaItem fromQueue,
    MediaItem? live,
  ) {
    if (live == null || live.id != fromQueue.id) return fromQueue;
    if (fromQueue.artUri != null) return fromQueue;
    if (live.artUri == null) return fromQueue;
    return fromQueue.copyWith(artUri: live.artUri);
  }

  /// 歌词模式：队列经 [patchNotificationLyricDisplay] 更新时优先队列；否则保留 live 展示行。
  static MediaItem _yeahMergeNotificationLyricDisplay(
    MediaItem fromQueue,
    MediaItem? live,
  ) {
    if (live == null || live.id != fromQueue.id) return fromQueue;
    if (_yeahAndroidLyricsSyncEnabled &&
        _yeahNotificationLyricsLayoutActive(fromQueue)) {
      return fromQueue;
    }
    if (_yeahNotificationLyricsLayoutActive(fromQueue)) return fromQueue;
    final lTitle = live.displayTitle?.trim();
    if (lTitle == null || lTitle.isEmpty) return fromQueue;
    if (lTitle == fromQueue.title.trim()) return fromQueue;
    return fromQueue.copyWith(
      displayTitle: live.displayTitle,
      displaySubtitle: live.displaySubtitle ?? fromQueue.displaySubtitle,
    );
  }

  static bool _yeahNotificationLyricsLayoutActive(MediaItem item) {
    final sub = item.displaySubtitle?.trim();
    if (sub != null && sub.isNotEmpty) return true;
    final dt = item.displayTitle?.trim();
    if (dt == null || dt.isEmpty) return false;
    return dt != item.title.trim();
  }

  /// 歌词同步时 [setMediaItem] 不写展示行，避免用队列/cache 里的旧歌词刷通知。
  static MediaItem _yeahEmitForSetMediaItem(MediaItem item) {
    if (!_yeahAndroidLyricsSyncEnabled) return item;
    return item.copyWith(
      displayTitle: null,
      displaySubtitle: null,
    );
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == kYeahToggleSystemLyricsAction) {
      final h = _yeahAndroidLyricsSyncToggleHandler;
      if (h != null) {
        try {
          await h();
        } catch (_) {}
      }
      _broadcastStateIfActive();
      return null;
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    final handler = _yeahAndroidMediaButtonClickHandler;
    if (handler != null) {
      final kind = switch (button) {
        MediaButton.media => 'media',
        MediaButton.next => 'next',
        MediaButton.previous => 'previous',
      };
      try {
        if (await handler(kind)) return;
      } catch (_) {}
    }
    await super.click(button);
  }

  Future<LoadResponse> customLoad(LoadRequest request) async {
    _source = request.audioSourceMessage;
    _updateShuffleIndices();
    _updateQueue();
    final response = await (await _player).load(LoadRequest(
      audioSourceMessage: _source!,
      initialPosition: request.initialPosition,
      initialIndex: request.initialIndex,
    ));
    return LoadResponse(duration: response.duration);
  }

  Future<SetVolumeResponse> customSetVolume(SetVolumeRequest request) async =>
      await (await _player).setVolume(request);

  static const Duration _kYeahFadeOutTotal = Duration(milliseconds: 800);
  static const int _kYeahFadeOutSteps = 40;

  Future<void> _yeahFadeOutVolumeIfPlaying() async {
    if (!_playing) return;
    final h = _yeahFadeOutVolumeHandler;
    if (h != null) {
      try {
        await h();
      } catch (_) {}
      return;
    }
    final p = await _player;
    final stepMs = (_kYeahFadeOutTotal.inMilliseconds / _kYeahFadeOutSteps)
        .floor()
        .clamp(1, 1000);
    for (var i = 1; i <= _kYeahFadeOutSteps; i++) {
      if (!_playing) return;
      final v = 1.0 - i / _kYeahFadeOutSteps;
      try {
        await p.setVolume(SetVolumeRequest(volume: v));
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: stepMs));
    }
    try {
      await p.setVolume(SetVolumeRequest(volume: 0.0));
    } catch (_) {}
  }

  Future<SetSpeedResponse> customSetSpeed(SetSpeedRequest request) async =>
      await (await _player).setSpeed(request);

  Future<SetPitchResponse> customSetPitch(SetPitchRequest request) async =>
      await (await _player).setPitch(request);

  Future<SetSkipSilenceResponse> customSetSkipSilence(
          SetSkipSilenceRequest request) async =>
      await (await _player).setSkipSilence(request);

  Future<SeekResponse> customPlayerSeek(SeekRequest request) async =>
      await (await _player).seek(request);

  Future<SetShuffleOrderResponse> customSetShuffleOrder(
      SetShuffleOrderRequest request) async {
    _source = request.audioSourceMessage;
    _updateShuffleIndices();
    _broadcastStateIfActive();
    return await (await _player).setShuffleOrder(SetShuffleOrderRequest(
      audioSourceMessage: _source!,
    ));
  }

  Future<SetWebCrossOriginResponse> customSetWebCrossOrigin(
      SetWebCrossOriginRequest request) async {
    return await (await _player).setWebCrossOrigin(request);
  }

  Future<SetWebSinkIdResponse> customSetWebSinkId(
      SetWebSinkIdRequest request) async {
    return await (await _player).setWebSinkId(request);
  }

  Future<ConcatenatingInsertAllResponse> customConcatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    final cat = _source!.findCat(request.id)!;
    cat.children.insertAll(request.index, request.children);
    cat.shuffleOrder
        .replaceRange(0, cat.shuffleOrder.length, request.shuffleOrder);
    _updateShuffleIndices();
    _broadcastStateIfActive();
    _updateQueue();
    return await (await _player).concatenatingInsertAll(request);
  }

  Future<ConcatenatingRemoveRangeResponse> customConcatenatingRemoveRange(
      ConcatenatingRemoveRangeRequest request) async {
    final cat = _source!.findCat(request.id)!;
    cat.children.removeRange(request.startIndex, request.endIndex);
    cat.shuffleOrder
        .replaceRange(0, cat.shuffleOrder.length, request.shuffleOrder);
    _updateShuffleIndices();
    _broadcastStateIfActive();
    _updateQueue();
    return await (await _player).concatenatingRemoveRange(request);
  }

  Future<ConcatenatingMoveResponse> customConcatenatingMove(
      ConcatenatingMoveRequest request) async {
    final cat = _source!.findCat(request.id)!;
    cat.children
        .insert(request.newIndex, cat.children.removeAt(request.currentIndex));
    cat.shuffleOrder
        .replaceRange(0, cat.shuffleOrder.length, request.shuffleOrder);
    _updateShuffleIndices();
    _broadcastStateIfActive();
    _updateQueue();
    return await (await _player).concatenatingMove(request);
  }

  Future<SetAndroidAudioAttributesResponse> customSetAndroidAudioAttributes(
          SetAndroidAudioAttributesRequest request) async =>
      await (await _player).setAndroidAudioAttributes(request);

  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      customSetAutomaticallyWaitsToMinimizeStalling(
              SetAutomaticallyWaitsToMinimizeStallingRequest request) async =>
          await (await _player)
              .setAutomaticallyWaitsToMinimizeStalling(request);

  Future<AndroidEqualizerBandSetGainResponse> customAndroidEqualizerBandSetGain(
          AndroidEqualizerBandSetGainRequest request) async =>
      await (await _player).androidEqualizerBandSetGain(request);

  Future<AndroidEqualizerGetParametersResponse>
      customAndroidEqualizerGetParameters(
              AndroidEqualizerGetParametersRequest request) async =>
          await (await _player).androidEqualizerGetParameters(request);

  Future<AndroidLoudnessEnhancerSetTargetGainResponse>
      customAndroidLoudnessEnhancerSetTargetGain(
              AndroidLoudnessEnhancerSetTargetGainRequest request) async =>
          await (await _player).androidLoudnessEnhancerSetTargetGain(request);

  Future<AudioEffectSetEnabledResponse> customAudioEffectSetEnabled(
          AudioEffectSetEnabledRequest request) async =>
      await (await _player).audioEffectSetEnabled(request);

  Future<SetAllowsExternalPlaybackResponse> customSetAllowsExternalPlayback(
          SetAllowsExternalPlaybackRequest request) async =>
      await (await _player).setAllowsExternalPlayback(request);

  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      customSetCanUseNetworkResourcesForLiveStreamingWhilePaused(
              SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest
                  request) async =>
          await (await _player)
              .setCanUseNetworkResourcesForLiveStreamingWhilePaused(request);

  Future<SetPreferredPeakBitRateResponse> customSetPreferredPeakBitRate(
          SetPreferredPeakBitRateRequest request) async =>
      await (await _player).setPreferredPeakBitRate(request);

  void _updateQueue() {
    assert(sequence.every((source) => source.tag is MediaItem),
        'Error : When using just_audio_background, you should always set a MediaItem tag on every AudioSource. See AudioSource.uri documentation for more information.');
    queue.add(sequence.map((source) => source.tag as MediaItem).toList());
  }

  void _updateShuffleIndices() {
    _shuffleIndices = _source?.shuffleIndices ?? [];
    _effectiveIndices = _shuffleMode != AudioServiceShuffleMode.none
        ? _shuffleIndices
        : List.generate(sequence.length, (i) => i);
    _shuffleIndicesInv = List.filled(_effectiveIndices.length, 0);
    for (var i = 0; i < _effectiveIndices.length; i++) {
      _shuffleIndicesInv[_effectiveIndices[i]] = i;
    }
    _effectiveIndicesInv = _shuffleMode != AudioServiceShuffleMode.none
        ? _shuffleIndicesInv
        : List.generate(sequence.length, (i) => i);
  }

  List<IndexedAudioSourceMessage> get sequence => _source?.sequence ?? [];
  List<int> get shuffleIndices => _shuffleIndices;
  List<int> get effectiveIndices => _effectiveIndices;
  List<int> get shuffleIndicesInv => _shuffleIndicesInv;
  List<int> get effectiveIndicesInv => _effectiveIndicesInv;
  int? get nextIndex => getRelativeIndex(1);
  int? get previousIndex => getRelativeIndex(-1);
  bool get hasNext => nextIndex != null;
  bool get hasPrevious => previousIndex != null;

  int? getRelativeIndex(int offset) {
    if (currentQueue.isEmpty || index == null) return null;
    if (_repeatMode == AudioServiceRepeatMode.one) return index;
    if (effectiveIndices.isEmpty) return null;
    if (index! >= effectiveIndicesInv.length) return null;
    final invPos = effectiveIndicesInv[index!];
    var newInvPos = invPos + offset;
    if (newInvPos >= effectiveIndices.length || newInvPos < 0) {
      if (_repeatMode == AudioServiceRepeatMode.all) {
        newInvPos %= effectiveIndices.length;
      } else {
        return null;
      }
    }
    final result = effectiveIndices[newInvPos];
    return result;
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    (await _player).seek(SeekRequest(position: Duration.zero, index: index));
  }

  @override
  Future<void> skipToNext() async {
    if (hasNext) {
      await _yeahFadeOutVolumeIfPlaying();
      await skipToQueueItem(nextIndex!);
      try {
        await (await _player).setVolume(SetVolumeRequest(volume: 1.0));
      } catch (_) {}
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (hasPrevious) {
      await _yeahFadeOutVolumeIfPlaying();
      await skipToQueueItem(previousIndex!);
      try {
        await (await _player).setVolume(SetVolumeRequest(volume: 1.0));
      } catch (_) {}
    }
  }

  @override
  Future<void> play() async {
    if (_justAudioEvent.processingState == ProcessingStateMessage.completed) {
      await skipToQueueItem(0);
    }
    if (!_playing) {
      _updatePosition();
      customEvent.add(_PlayingEvent(_playing = true));
      _broadcastState();
      await (await _player).play(PlayRequest());
    }
  }

  @override
  Future<void> pause() async {
    await _yeahFadeOutVolumeIfPlaying();
    _updatePosition();
    customEvent.add(_PlayingEvent(_playing = false));
    _broadcastState();
    await (await _player).pause(PauseRequest());
    try {
      await (await _player).setVolume(SetVolumeRequest(volume: 1.0));
    } catch (_) {}
  }

  void _updatePosition() {
    _justAudioEvent = _justAudioEvent.copyWith(
      updatePosition: currentPosition,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<void> seek(Duration position) async =>
      await (await _player).seek(SeekRequest(position: position));

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await (await _player).setSpeed(SetSpeedRequest(speed: speed));
  }

  @override
  Future<void> fastForward() =>
      _seekRelative(AudioService.config.fastForwardInterval);

  @override
  Future<void> rewind() => _seekRelative(-AudioService.config.rewindInterval);

  @override
  Future<void> seekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> seekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    _broadcastStateIfActive();
    (await _player).setLoopMode(SetLoopModeRequest(
        loopMode: LoopModeMessage
            .values[min(LoopModeMessage.values.length - 1, repeatMode.index)]));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;
    _updateShuffleIndices();
    _broadcastStateIfActive();
    (await _player).setShuffleMode(SetShuffleModeRequest(
        shuffleMode: ShuffleModeMessage.values[
            min(ShuffleModeMessage.values.length - 1, shuffleMode.index)]));
  }

  @override
  Future<void> stop() => _lock.synchronized(() async {
        final player = _playerCompleter.value;
        if (player == null) return;
        _updatePosition();
        customEvent.add(_PlayingEvent(_playing = false));
        _justAudioEvent = _justAudioEvent.copyWith(
          processingState: ProcessingStateMessage.idle,
        );
        _broadcastState();
        _playerCompleter = _ValueCompleter<AudioPlayerPlatform>();
        await _platform.disposePlayer(DisposePlayerRequest(id: player.id));
      });

  Duration get currentPosition {
    if (_playing &&
        _justAudioEvent.processingState == ProcessingStateMessage.ready) {
      return Duration(
          milliseconds: (_justAudioEvent.updatePosition.inMilliseconds +
                  ((DateTime.now().millisecondsSinceEpoch -
                          _justAudioEvent.updateTime.millisecondsSinceEpoch) *
                      _speed))
              .toInt());
    } else {
      return _justAudioEvent.updatePosition;
    }
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = currentPosition + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > currentMediaItem!.duration!) {
      newPosition = currentMediaItem!.duration!;
    }
    // Perform the jump via a seek.
    await (await _player).seek(SeekRequest(position: newPosition));
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = _Seeker(this, Duration(seconds: 10 * direction),
          const Duration(seconds: 1), currentMediaItem!.duration!)
        ..start();
    }
  }

  void _broadcastStateIfActive() {
    if (_justAudioEvent.processingState != ProcessingStateMessage.idle) {
      _broadcastState();
    }
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState() {
    // 词 / 上一首 / 播放暂停 / 下一首 / 停止（停止仅在展开栏；紧凑为前三项非停止）
    final controls = <MediaControl>[
      MediaControl.custom(
        androidIcon: 'drawable/yeah_media_toggle_lyrics',
        label: '词',
        name: kYeahToggleSystemLyricsAction,
      ),
      if (hasPrevious) MediaControl.skipToPrevious,
      if (_playing) MediaControl.pause else MediaControl.play,
      if (hasNext) MediaControl.skipToNext,
      MediaControl.stop,
    ];
    final compact = <int>[];
    for (var i = 0; i < controls.length && compact.length < 3; i++) {
      if (controls[i].action != MediaAction.stop) {
        compact.add(i);
      }
    }
    playbackState.add(playbackState.nvalue!.copyWith(
      controls: controls,
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: compact,
      processingState: _justAudioEvent.errorCode != null
          ? AudioProcessingState.error
          : const {
                ProcessingStateMessage.idle: AudioProcessingState.idle,
                ProcessingStateMessage.loading: AudioProcessingState.loading,
                ProcessingStateMessage.buffering:
                    AudioProcessingState.buffering,
                ProcessingStateMessage.ready: AudioProcessingState.ready,
                ProcessingStateMessage.completed:
                    AudioProcessingState.completed,
              }[_justAudioEvent.processingState] ??
              AudioProcessingState.idle,
      playing: _playing &&
          !{ProcessingStateMessage.idle, ProcessingStateMessage.completed}
              .contains(_justAudioEvent.processingState),
      updatePosition: currentPosition,
      bufferedPosition: _justAudioEvent.bufferedPosition,
      speed: _speed,
      queueIndex: _justAudioEvent.currentIndex,
      errorCode: _justAudioEvent.errorCode,
      errorMessage: _justAudioEvent.errorMessage,
    ));
  }
}

class _Seeker {
  final _PlayerAudioHandler handler;
  final Duration positionInterval;
  final Duration stepInterval;
  final Duration duration;
  bool _running = false;

  _Seeker(
    this.handler,
    this.positionInterval,
    this.stepInterval,
    this.duration,
  );

  Future<void> start() async {
    _running = true;
    while (_running) {
      Duration newPosition = handler.currentPosition + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > duration) newPosition = duration;
      handler.seek(newPosition);
      await Future<dynamic>.delayed(stepInterval);
    }
  }

  void stop() {
    _running = false;
  }
}

extension _PlaybackEventMessageExtension on PlaybackEventMessage {
  PlaybackEventMessage copyWith({
    ProcessingStateMessage? processingState,
    DateTime? updateTime,
    Duration? updatePosition,
    Duration? bufferedPosition,
    Duration? duration,
    IcyMetadataMessage? icyMetadata,
    int? currentIndex,
    int? androidAudioSessionId,
  }) =>
      PlaybackEventMessage(
        processingState: processingState ?? this.processingState,
        updateTime: updateTime ?? this.updateTime,
        updatePosition: updatePosition ?? this.updatePosition,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
        duration: duration ?? this.duration,
        icyMetadata: icyMetadata ?? this.icyMetadata,
        currentIndex: currentIndex ?? this.currentIndex,
        androidAudioSessionId:
            androidAudioSessionId ?? this.androidAudioSessionId,
      );
}

extension AudioSourceExtension on AudioSourceMessage {
  ConcatenatingAudioSourceMessage? findCat(String id) {
    final self = this;
    if (self is ConcatenatingAudioSourceMessage) {
      if (self.id == id) return self;
      return self.children
          .map((child) => child.findCat(id))
          .firstWhere((cat) => cat != null, orElse: () => null);
    } else if (self is LoopingAudioSourceMessage) {
      return self.child.findCat(id);
    } else {
      return null;
    }
  }

  List<IndexedAudioSourceMessage> get sequence {
    final self = this;
    if (self is ConcatenatingAudioSourceMessage) {
      return self.children.expand((child) => child.sequence).toList();
    } else if (self is LoopingAudioSourceMessage) {
      return List.generate(self.count, (i) => self.child.sequence)
          .expand((sequence) => sequence)
          .toList();
    } else {
      return [self as IndexedAudioSourceMessage];
    }
  }

  List<int> get shuffleIndices {
    final self = this;
    if (self is ConcatenatingAudioSourceMessage) {
      var offset = 0;
      final childIndicesList = <List<int>>[];
      for (final child in self.children) {
        final childIndices =
            child.shuffleIndices.map((i) => i + offset).toList();
        childIndicesList.add(childIndices);
        offset += childIndices.length;
      }
      final indices = <int>[];
      for (final index in self.shuffleOrder) {
        indices.addAll(childIndicesList[index]);
      }
      return indices;
    } else if (self is LoopingAudioSourceMessage) {
      // TODO: This should combine indices of the children, like ConcatenatingAudioSource.
      // Also should be fixed in the plugin frontend.
      return List.generate(self.count, (i) => i);
    } else {
      return [0];
    }
  }
}

@immutable
class TrackInfo {
  final int? index;
  final Duration? duration;

  const TrackInfo(this.index, this.duration);

  @override
  bool operator ==(Object other) =>
      other is TrackInfo && index == other.index && duration == other.duration;

  @override
  int get hashCode => Object.hash(index, duration);

  @override
  String toString() => '($index, $duration)';
}

/// Backwards compatible extensions on rxdart's ValueStream
extension _ValueStreamExtension<T> on ValueStream<T> {
  /// Backwards compatible version of valueOrNull.
  T? get nvalue => hasValue ? value : null;
}

class _PlayingEvent {
  final bool playing;

  const _PlayingEvent(this.playing);
}

class _ValueCompleter<T> {
  final _completer = Completer<T>();
  T? value;

  void complete(T value) {
    this.value = value;
    _completer.complete(value);
  }

  Future<T> get future => _completer.future;
}
