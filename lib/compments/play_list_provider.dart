import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/services/android_car_lyrics_sync.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';
import 'folder_provider.dart';
import 'onedrive_controller.dart';
import 'user_playlist_provider.dart';

/// Hive：上次播放曲目路径（冷启动优先按路径恢复迷你条，避免仅索引在合并顺序变化后错位）。
const String _kHiveLastPlayedPathKey = 'last_played_path';

/// Hive：上次播放所属列表（用于冷启动恢复用户歌单队列等）。
const String _kHiveLastPlaybackSessionKey = 'last_playback_session_surface';

/// Hive：用户歌单会话时对应歌单 id。
const String _kHiveLastPlaybackUserPlaylistIdKey = 'last_playback_user_playlist_id';

const String _kHiveLastPlaybackRecordRecentKey = 'last_playback_record_recent';
const String _kHiveLastPlaybackBumpPlayCountKey = 'last_playback_bump_play_count';

/// Hive：艺术家 / 专辑等子队列的曲目路径顺序（与 [PlaybackSessionSurface.libraryByArtist] 等配合）。
const String _kHiveLastOverridePathsKey = 'last_playback_override_paths';

List<String> _parseOverridePathListFromHive(dynamic raw) {
  if (raw is! List) return [];
  return raw.map((e) => '$e'.trim()).where((p) => p.isNotEmpty).toList();
}

List<Song> _resolveSongsFromOrderedPaths(List<String> paths, List<Song> merged) {
  final byKey = <String, Song>{};
  for (final s in merged) {
    byKey[_libraryPathKey(s.path)] = s;
  }
  final out = <Song>[];
  for (final path in paths) {
    final s = byKey[_libraryPathKey(path)];
    if (s != null) out.add(s);
  }
  return out;
}

/// 与 Hive、曲库中歌曲路径做匹配时统一（避免 `\`/`/` 或大小写不一致导致无法解析）
String _libraryPathKey(String path) {
  final t = path.trim();
  if (t.isEmpty) return '';
  return p.normalize(t).replaceAll(r'\', '/').toLowerCase();
}

class PlayListProvider extends ChangeNotifier {
  //key是用户选择的根目录
  LinkedHashMap<String, List<Song>> folderPlaylistMap = LinkedHashMap();

  bool _initialized = false;

  StreamSubscription<PlayerState>? _playerCompletionSubscription;
  StreamSubscription<int?>? _playerIndexSubscription;
  StreamSubscription<PlayerException>? _playerErrorSubscription;
  ProcessingState? _lastProcessingStateFromPlayer;
  bool _completionHandlerRunning = false;
  bool _errorSkipHandlerRunning = false;
  DateTime _lastErrorSkipAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// 串行切歌 / 换队列，避免连点下一曲时多次 [playAt] 与 [MusicService] 交错导致打断加载后不播放。
  Future<void> _playbackNavChain = Future<void>.value();

  /// 连点「下一曲」合并为一次 [_applyPlayNextSteps]，避免每一步都完整 await 播放器。
  int _coalescedPlayNextSteps = 0;

  /// 连点「上一曲」合并。
  int _coalescedPlayPrevSteps = 0;

  /// [_playAtImpl] / [_setPlaybackQueueAndPlayImpl] 执行中；此期间忽略「自然过轨」逻辑，避免误耗「下一曲播放」队列。
  int _playbackNavDepth = 0;

  bool get initialized => _initialized;

  /// 当前播放索引（以 playList 为基准）
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// 播放模式
  PlaybackMode _playbackMode = PlaybackMode.sequential;

  PlaybackMode get playbackMode => _playbackMode;

  /// 定时关闭时长（分钟，最近一次选择）
  int _timerDuration = 30;

  int get timerDuration => _timerDuration;

  /// 应用级定时关闭（同一会话内离开播放页仍有效，进程退出后清除）
  Timer? _sleepShutdownTimer;

  bool get isSleepTimerActive => _sleepShutdownTimer != null;

  /// 随机播放时的已播放列表
  List<int> _shuffledPlayedIndices = [];

  /// 随机播放时的当前随机列表
  List<int>? _shuffledIndices;

  /// 「下一曲播放」临时队列（FIFO）：当前曲自然结束后优先播放队列中的曲目；
  /// 队列为空时仍按原有播放模式继续当前列表（不打断原有顺序逻辑）。
  /// 元素为 [_libraryPathKey]。
  final List<String> _playNextAfterCurrentQueue = [];

  /// 首轮插播生效前正在播放的曲目索引；插播全部播完后 [playAt] 回到该曲继续。
  int? _resumePlaylistIndexAfterDeferred;

  /// 文件夹合并 (+ OneDrive 叠加) 缓存；供 [libraryMergedSongs] 与无临时队列时的 [playList] 共用，
  /// 避免此前 [libraryMergedSongs] getter 每次都 [expand]+[toList] 分配新列表导致长列表/UI 卡顿。
  List<Song>? _cachedMergedLibrary;

  /// 每次合并曲库缓存失效并重算索引时自增；供 UI [Selector] 窄依赖，避免绑整棵 [PlayListProvider]。
  int _libraryMergeEpoch = 0;

  int get libraryMergeEpoch => _libraryMergeEpoch;

  /// OneDrive 点播落地扫描结果（与文件夹曲目按路径去重后并入 [libraryMergedSongs] / [playList]）
  List<Song>? _onedriveCachedSongs;

  /// 临时播放队列（例如用户歌单），非空时 [playList] 使用该列表而非曲库合并
  List<Song>? _playbackQueueOverride;

  /// 当前一次「临时队列」会话内，是否写入最近列表 / 是否增加播放次数（由 [setPlaybackQueueAndPlay] 设定，曲库直播为默认都记）
  bool _statsRecordRecent = true;
  bool _statsBumpPlayCount = true;

  bool get hasPlaybackQueueOverride => _playbackQueueOverride != null;

  /// 当前一次播放会话在 UI 上「属于」哪个列表，用于从 [SongPage] 返回时是否在该表滚到当前曲
  PlaybackSessionSurface _playbackSessionSurface =
      PlaybackSessionSurface.library;
  String? _playbackSessionUserPlaylistId;

  /// 是否为「从全库/全部歌曲」发起的会話（在 [PlayListPage] 滚屏）
  bool get playbackSessionIsLibrary =>
      _playbackSessionSurface == PlaybackSessionSurface.library;

  /// 是否为「从最近播放相关列表」发起（在 [RecentPlaysPage] 滚屏）
  bool get playbackSessionIsRecentList =>
      _playbackSessionSurface == PlaybackSessionSurface.recentList;

  /// 是否为「从最多播放列表」发起（在 [MostPlayedPage] 滚屏）
  bool get playbackSessionIsMostPlayedList =>
      _playbackSessionSurface == PlaybackSessionSurface.mostPlayedList;

  /// 是否为「从艺术家下列表」发起（艺术家分组页的曲目列表）
  bool get playbackSessionIsLibraryByArtist =>
      _playbackSessionSurface == PlaybackSessionSurface.libraryByArtist;

  /// 是否为「从专辑下列表」发起（专辑分组页的曲目列表）
  bool get playbackSessionIsLibraryByAlbum =>
      _playbackSessionSurface == PlaybackSessionSurface.libraryByAlbum;

  /// 是否为「从指定用户歌单」发起（在对应 [UserPlaylistDetailPage] 滚屏）
  bool playbackSessionIsUserPlaylist(String playlistId) =>
      _playbackSessionSurface == PlaybackSessionSurface.userPlaylist &&
      _playbackSessionUserPlaylistId == playlistId;

  /// 当前是否为「用户歌单」类会话（不限定 id，供 [SongPage] 判断是否保持）
  bool get playbackSessionIsUserPlaylistKind =>
      _playbackSessionSurface == PlaybackSessionSurface.userPlaylist;

  bool get playbackSessionIsAdHoc =>
      _playbackSessionSurface == PlaybackSessionSurface.adHoc;

  void _applyPlaybackSession(
    PlaybackSessionSurface surface, {
    String? userPlaylistId,
  }) {
    _playbackSessionSurface = surface;
    if (surface == PlaybackSessionSurface.userPlaylist) {
      _playbackSessionUserPlaylistId = userPlaylistId;
    } else {
      _playbackSessionUserPlaylistId = null;
    }
  }

  /// 在仅打开 [SongPage] 而未切队列时（如从全库行进入），将会话标为全库
  void setPlaybackListSessionForLibrary() {
    _applyPlaybackSession(PlaybackSessionSurface.library);
  }

  /// 媒体目录扫描结果与 OneDrive 本地缓存曲目合并（路径去重，文件夹条目优先）。
  List<Song> _computeMergedLibrarySongs() {
    final base = folderPlaylistMap.values.expand((l) => l).toList();
    final extra = _onedriveCachedSongs;
    if (extra == null || extra.isEmpty) return base;
    final seen = <String>{for (final s in base) _libraryPathKey(s.path)};
    final out = List<Song>.from(base);
    for (final s in extra) {
      final k = _libraryPathKey(s.path);
      if (k.isEmpty) continue;
      if (seen.contains(k)) continue;
      seen.add(k);
      out.add(s);
    }
    return out;
  }

  /// 文件夹扫描合并后再并入 OneDrive 缓存目录中的曲目（不受 [_playbackQueueOverride] 影响）
  List<Song> get libraryMergedSongs =>
      _cachedMergedLibrary ??= _computeMergedLibrarySongs();

  /// 在合并曲库中按路径查 [Song]（与当前播放队列是否被歌单覆盖无关）
  Song? songInLibraryByPath(String path) {
    for (final s in libraryMergedSongs) {
      if (s.path == path) return s;
    }
    return null;
  }

  int indexInLibraryByPath(String path) {
    return libraryMergedSongs.indexWhere((s) => s.path == path);
  }

  /// 将 [paths] 顺序解析为曲库 [Song]；严格保持 [paths] 的先后（即最近播放在服务中的顺序），不在此重排
  /// [maxSongs] 为 null 时不截断
  List<Song> resolveRecentSongsFromPaths(List<String> paths, {int? maxSongs}) {
    if (!_initialized) return [];
    if (maxSongs != null && maxSongs <= 0) return [];
    final byKey = <String, Song>{};
    for (final s in libraryMergedSongs) {
      byKey[_libraryPathKey(s.path)] = s;
    }
    final out = <Song>[];
    for (final path in paths) {
      final s = byKey[_libraryPathKey(path)];
      if (s != null) {
        out.add(s);
        if (maxSongs != null && out.length >= maxSongs) break;
      }
    }
    return out;
  }

  /// 将按播放次数排序的 path+count 转为曲库内 [Song]，保持顺序，跳过已不在库内的路径（供「最多播放」等）
  List<({Song song, int playCount})> resolveTopPlayedFromPathCounts(
    List<({String path, int count})> entries, {
    int? maxSongs,
  }) {
    if (!_initialized) return [];
    if (maxSongs != null && maxSongs <= 0) return [];
    final byKey = <String, Song>{};
    for (final s in libraryMergedSongs) {
      byKey[_libraryPathKey(s.path)] = s;
    }
    final out = <({Song song, int playCount})>[];
    for (final e in entries) {
      final s = byKey[_libraryPathKey(e.path)];
      if (s != null) {
        out.add((song: s, playCount: e.count));
        if (maxSongs != null && out.length >= maxSongs) {
          break;
        }
      }
    }
    return out;
  }

  /// [playAt] / [setPlaybackQueueAndPlay] / 合并后的上下曲均经此排队执行。
  Future<void> _enqueuePlaybackNav(Future<void> Function() job) async {
    final f = _playbackNavChain
        .catchError((Object? e) {
          appLog.d('playback nav 前序(可忽略): $e');
        })
        .then((_) async {
          try {
            await job();
          } catch (e, st) {
            appLog.e('playback nav 任务失败', error: e, stackTrace: st);
          }
        });
    _playbackNavChain = f;
    return f;
  }

  /// 把所有文件夹里的歌曲合并成一个大列表（使用缓存优化性能），
  /// 若已设置 [_playbackQueueOverride] 则返回覆盖队列。
  List<Song> get playList {
    if (_playbackQueueOverride != null) return _playbackQueueOverride!;
    return _cachedMergedLibrary ??= _computeMergedLibrarySongs();
  }

  /// 清除播放列表缓存
  void _clearPlayListCache() {
    _cachedMergedLibrary = null;
  }

  /// 合并曲库缓存失效时：按解码器当前在播路径重算 [_currentIndex]，避免列表合并顺序变化后「在播 A、UI 指向 B」。
  void _invalidateMergedLibraryCacheSyncingCurrentIndex() {
    _libraryMergeEpoch++;
    _clearPlayListCache();
    _relocateCurrentIndexToMatchPlayingMedia();
  }

  void _relocateCurrentIndexToMatchPlayingMedia() {
    if (_playbackQueueOverride != null) return;
    final lib = _computeMergedLibrarySongs();
    _cachedMergedLibrary = lib;
    final path = MusicService.tryCurrentPlayingPath();
    if (path != null && path.trim().isNotEmpty) {
      final wanted = _libraryPathKey(path);
      final i = lib.indexWhere((s) => _libraryPathKey(s.path) == wanted);
      if (i >= 0) {
        _currentIndex = i;
        return;
      }
    }
    if (lib.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = _currentIndex.clamp(0, lib.length - 1);
    }
  }

  /// Android 队列索引通知：在「全库合并」会话下优先按正在解码的文件路径对齐，避免与 ExoPlayer 队列顺序暂时不一致时错位。
  void _applyAndroidPlayerIndexToProviderIndex(int playerIdx) {
    if (_playbackQueueOverride != null) {
      final list = playList;
      if (playerIdx < 0 || playerIdx >= list.length) return;
      if (playerIdx != _currentIndex) {
        _currentIndex = playerIdx;
        notifyListeners();
        unawaited(_saveCurrentPlaybackSnapshot());
      }
      return;
    }

    final path = MusicService.tryCurrentPlayingPath();
    if (path != null && path.trim().isNotEmpty) {
      final wanted = _libraryPathKey(path);
      final list = playList;
      final byPath = list.indexWhere((s) => _libraryPathKey(s.path) == wanted);
      if (byPath >= 0) {
        if (byPath != _currentIndex) {
          _currentIndex = byPath;
          notifyListeners();
          unawaited(_saveCurrentPlaybackSnapshot());
        }
        return;
      }
    }

    final list = playList;
    if (playerIdx >= 0 &&
        playerIdx < list.length &&
        playerIdx != _currentIndex) {
      _currentIndex = playerIdx;
      notifyListeners();
      unawaited(_saveCurrentPlaybackSnapshot());
    }
  }

  void _clearDeferredPlayNext() {
    _playNextAfterCurrentQueue.clear();
    _resumePlaylistIndexAfterDeferred = null;
  }

  int _indexInPlayListByPathKey(String pathKey) {
    if (pathKey.isEmpty) return -1;
    final list = playList;
    for (var i = 0; i < list.length; i++) {
      if (_libraryPathKey(list[i].path) == pathKey) return i;
    }
    return -1;
  }

  /// 当前曲播放结束后紧接着播放 [song]（见「更多」菜单）。
  ///
  /// 加入全局 **FIFO** 临时队列；轮到下一曲时若队列非空则先播放队列中的曲目，
  /// 否则仍按当前播放模式（顺序 / 随机 / 单曲循环等）在原列表继续。
  ///
  /// 若 [song] 不在当前 [playList]（含临时歌单队列）中则返回 false。
  bool enqueuePlayAfterCurrent(Song song) {
    final key = _libraryPathKey(song.path);
    if (key.isEmpty) return false;
    if (_indexInPlayListByPathKey(key) < 0) return false;
    _playNextAfterCurrentQueue.add(key);
    notifyListeners();
    return true;
  }

  /// 「下一曲播放」队列当前待播条目（顺序与 FIFO 一致）；仅供 UI。
  List<Song> get pendingPlayAfterCurrentSongs {
    final list = playList;
    final out = <Song>[];
    for (final key in _playNextAfterCurrentQueue) {
      final i = _indexInPlayListByPathKey(key);
      if (i >= 0) out.add(list[i]);
    }
    return List<Song>.unmodifiable(out);
  }

  /// 将播放队列设为 [songs]（顺序与列表一致），并从 [index] 开始播放。
  ///
  /// [recordRecent] / [bumpPlayCount] 控制 [RecentPlayService.recordPath] 行为，并在切歌 [playAt] 时沿用，直至 [clearPlaybackQueueOverride]。
  ///
  /// [session] / [userPlaylistId] 描述本次播放来自哪类列表，用于从播放页返回时只在该表定位。
  Future<void> setPlaybackQueueAndPlay(
    List<Song> songs,
    int index, {
    bool recordRecent = true,
    bool bumpPlayCount = true,
    required PlaybackSessionSurface session,
    String? userPlaylistId,
  }) async {
    return _enqueuePlaybackNav(() async {
      await _setPlaybackQueueAndPlayImpl(
        songs,
        index,
        recordRecent: recordRecent,
        bumpPlayCount: bumpPlayCount,
        session: session,
        userPlaylistId: userPlaylistId,
      );
    });
  }

  Future<void> _setPlaybackQueueAndPlayImpl(
    List<Song> songs,
    int index, {
    required bool recordRecent,
    required bool bumpPlayCount,
    required PlaybackSessionSurface session,
    String? userPlaylistId,
  }) async {
    _playbackNavDepth++;
    try {
      await _setPlaybackQueueAndPlayImplBody(
        songs,
        index,
        recordRecent: recordRecent,
        bumpPlayCount: bumpPlayCount,
        session: session,
        userPlaylistId: userPlaylistId,
      );
    } finally {
      _playbackNavDepth--;
    }
  }

  Future<void> _setPlaybackQueueAndPlayImplBody(
    List<Song> songs,
    int index, {
    required bool recordRecent,
    required bool bumpPlayCount,
    required PlaybackSessionSurface session,
    String? userPlaylistId,
  }) async {
    if (songs.isEmpty) return;
    _clearDeferredPlayNext();
    _coalescedPlayNextSteps = 0;
    _coalescedPlayPrevSteps = 0;
    if (session == PlaybackSessionSurface.userPlaylist) {
      assert(
        userPlaylistId != null && userPlaylistId.isNotEmpty,
        'userPlaylist 会话需提供 userPlaylistId',
      );
    }
    _applyPlaybackSession(session, userPlaylistId: userPlaylistId);
    _statsRecordRecent = recordRecent;
    _statsBumpPlayCount = bumpPlayCount;
    _playbackQueueOverride = List<Song>.from(songs);
    _currentIndex = index.clamp(0, songs.length - 1);
    _shuffledIndices = null;
    _shuffledPlayedIndices = [];
    notifyListeners();
    final song = _playbackQueueOverride![_currentIndex];
    final ok = await MusicService().playCurrentFromPlaylist(
      queue: _playbackQueueOverride!,
      currentIndex: _currentIndex,
      useAndroidConcatQueue: _playbackMode != PlaybackMode.playOnce,
    );
    if (!ok) {
      reportPlaybackFailureToUser();
      return;
    }
    await RecentPlayService.recordPath(
      song.path,
      updateRecentList: recordRecent,
      bumpPlayCount: bumpPlayCount,
    );
    await _saveCurrentPlaybackSnapshot();
    unawaited(_syncAndroidCarMediaSession());
    notifyListeners();
  }

  /// 恢复为曲库合并队列；可选按当前播放曲目的路径在全库中定位索引。
  void clearPlaybackQueueOverride({bool relocateCurrentSong = true}) {
    if (_playbackQueueOverride == null) return;
    final path = relocateCurrentSong ? currentSong?.path : null;
    _playbackQueueOverride = null;
    _clearDeferredPlayNext();
    _coalescedPlayNextSteps = 0;
    _coalescedPlayPrevSteps = 0;
    _statsRecordRecent = true;
    _statsBumpPlayCount = true;
    _applyPlaybackSession(PlaybackSessionSurface.library);
    _clearPlayListCache();
    final lib = _computeMergedLibrarySongs();
    _cachedMergedLibrary = lib;
    if (path != null) {
      final i = lib.indexWhere((s) => s.path == path);
      if (i >= 0) {
        _currentIndex = i;
      } else if (lib.isEmpty) {
        _currentIndex = 0;
      } else {
        _currentIndex = 0;
      }
    } else if (lib.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = _currentIndex.clamp(0, lib.length - 1);
    }
    _shuffledIndices = null;
    _shuffledPlayedIndices = [];
    notifyListeners();
    unawaited(_saveCurrentPlaybackSnapshot());
  }

  Song? get currentSong {
    final list = playList;
    if (list.isEmpty) return null;
    final idx = _currentIndex.clamp(0, list.length - 1);
    return list[idx];
  }

  /// 从 [OneDriveController.loadLocallyCachedOneDriveSongs] 刷新叠加曲目并刷新合并缓存。
  Future<void> refreshOneDriveLibraryOverlay(OneDriveController od) async {
    await _loadOneDriveOverlayFrom(od);
    _invalidateMergedLibraryCacheSyncingCurrentIndex();
    notifyListeners();
  }

  Future<void> _loadOneDriveOverlayFrom(OneDriveController od) async {
    try {
      _onedriveCachedSongs = await od.loadLocallyCachedOneDriveSongs();
    } catch (_) {
      _onedriveCachedSongs = null;
    }
  }

  /// 冷启动即从 Hive 恢复播放模式；勿仅在 SongPage 加载，否则首页/曲库发起播放时仍为默认顺序，
  /// Android 整段队列会在曲末自动连播下一首，表现为「仅播放一次」无效。
  Future<void> _hydratePlaybackModeFromStorage() async {
    try {
      _playbackMode = await SettingsService.loadPlaybackMode();
      _shuffledIndices = null;
      _shuffledPlayedIndices = [];
      if (_playbackMode == PlaybackMode.singleLoop) {
        MusicService().setLoopMode(LoopMode.one);
      } else {
        MusicService().setLoopMode(LoopMode.off);
      }
      await _syncAndroidCarMediaSession();
    } catch (e, st) {
      appLog.e('加载播放模式失败', error: e, stackTrace: st);
    }
  }

  /// 已在 Android concat 会话中时切换到「仅播放一次」，需重建为单曲源，否则会由系统在曲末自动切下一曲。
  Future<void> _rebindAndroidCurrentAsSingleConcatDisabled() async {
    try {
      final list = playList;
      if (list.isEmpty || list.length <= 1) return;
      final idx = _currentIndex.clamp(0, list.length - 1);
      final pos = MusicService.lastPosition;
      final ok = await MusicService().playCurrentFromPlaylist(
        queue: list,
        currentIndex: idx,
        useAndroidConcatQueue: false,
      );
      if (!ok) {
        reportPlaybackFailureToUser();
        return;
      }
      if (pos > Duration.zero) {
        await Future<void>.delayed(const Duration(milliseconds: 48));
        await MusicService().seek(pos);
      }
    } catch (e, st) {
      appLog.e('仅播放一次：重建单曲会话失败', error: e, stackTrace: st);
    }
  }

  /// 从 FolderProvider 加载歌曲（优化版本，支持大量歌曲）。
  /// [oneDrive] 非 null 时会并入 OneDrive 点播落地缓存路径中的音频。
  Future<void> init(
    FolderProvider folderProvider, {
    OneDriveController? oneDrive,
    UserPlaylistProvider? userPlaylists,
  }) async {
    //若本身已经被初始化
    if (_initialized) {
      return;
    }
    // 等待 FolderProvider 初始化
    if (!folderProvider.initialized) {
      await folderProvider.init();
    }
    // 遍历所有文件夹（使用异步方式，避免阻塞UI）
    await _addPlayListAsync(folderProvider);
    if (oneDrive != null) {
      await _loadOneDriveOverlayFrom(oneDrive);
    }
    _initialized = true;

    await _hydratePlaybackModeFromStorage();

    // 进程重启后不保留上一会话的「下一曲播放」插播队列（仅供当次会话）。
    _clearDeferredPlayNext();

    if (userPlaylists != null && !userPlaylists.initialized) {
      await userPlaylists.init();
    }

    // 歌单「失效路径 → 曲库重绑」不在此批量执行；仅在 OneDrive 从云端恢复歌单后由设置页触发，避免冷启动与每次进歌单详情时全量扫描、写 Hive。

    // 加载上次播放
    await _restoreLastPlayedSnapshot(userPlaylists: userPlaylists);

    // 保障 currentIndex 合法
    final list = playList;
    if (list.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= list.length) {
      _currentIndex = 0;
    }
    _attachPlaybackCompletionListener();
    _attachPlayerIndexListener();
    _attachPlaybackErrorListener();
    if (!kIsWeb && Platform.isAndroid) {
      AndroidCarLyricsSync.attach(this);
    }
    notifyListeners();
  }

  /// 与 [just_audio_background] 内队列的 `hasPrevious` / `hasNext` 一致：列表循环时首曲仍有上一首，
  /// 避免紧凑通知省略上一首键后停播被误当成「上一首/退出」。
  Future<void> _syncAndroidCarMediaSession() async {
    if (!Platform.isAndroid) return;
    try {
      if (_playbackMode == PlaybackMode.singleLoop) {
        await AudioService.setRepeatMode(AudioServiceRepeatMode.one);
      } else if (_playbackMode == PlaybackMode.playOnce) {
        await AudioService.setRepeatMode(AudioServiceRepeatMode.none);
      } else {
        await AudioService.setRepeatMode(AudioServiceRepeatMode.all);
      }
    } catch (_) {}
  }

  void _attachPlayerIndexListener() {
    if (!Platform.isAndroid) return;
    _playerIndexSubscription?.cancel();
    var previousPlayerIndex = MusicService.currentIndex;
    _playerIndexSubscription = MusicService.currentMediaIndexStream.listen((i) {
      if (i == null || i < 0) return;
      if (!MusicService.androidCarQueueActive) return;

      final prev = previousPlayerIndex;
      previousPlayerIndex = i;

      if (_playbackNavDepth > 0) {
        _applyAndroidPlayerIndexToProviderIndex(i);
        return;
      }

      final naturalConcatAdvance = _isNaturalConcatAdvanceForDeferred(prev, i);
      if (naturalConcatAdvance) {
        if (_hasDeferredPlayNextQueued()) {
          unawaited(
            _consumeDeferredPlayNextAfterAndroidConcatAdvance(
              fallbackPlayerIndex: i,
            ),
          );
          return;
        }
        final resume = _takeResumeAfterDeferredIfApplicable();
        if (resume != null) {
          unawaited(playAt(resume));
          return;
        }
      }

      _applyAndroidPlayerIndexToProviderIndex(i);
    });
  }

  bool _hasDeferredPlayNextQueued() => _playNextAfterCurrentQueue.isNotEmpty;

  /// Android 整段 Concatenating 队列下，曲目之间往往不发 [ProcessingState.completed]，
  /// 用「playlist 顺序上下一首」判断是否自然过轨（与 ExoPlayer 队列一致）。
  /// 不强制要求 prev 与 [_currentIndex] 相等，避免 Provider 索引偶发漂移时漏触发。
  bool _isNaturalConcatAdvanceForDeferred(
    int? prevPlayerIndex,
    int newPlayerIndex,
  ) {
    if (prevPlayerIndex == null) return false;
    if (_playbackMode == PlaybackMode.singleLoop) return false;
    if (newPlayerIndex == prevPlayerIndex) return false;
    final len = playList.length;
    if (len <= 1) return false;
    final expectedNext = (prevPlayerIndex + 1) % len;
    return newPlayerIndex == expectedNext;
  }

  Future<void> _consumeDeferredPlayNextAfterAndroidConcatAdvance({
    required int fallbackPlayerIndex,
  }) async {
    try {
      if (await _tryConsumeDeferredPlayNext()) {
        return;
      }
      final resume = _takeResumeAfterDeferredIfApplicable();
      if (resume != null) {
        await playAt(resume);
        return;
      }
      _applyAndroidPlayerIndexToProviderIndex(fallbackPlayerIndex);
    } catch (e, st) {
      appLog.e('Android concat 边界消耗「下一曲播放」失败', error: e, stackTrace: st);
      _applyAndroidPlayerIndexToProviderIndex(fallbackPlayerIndex);
    }
  }

  int? _takeResumeAfterDeferredIfApplicable() {
    if (_playNextAfterCurrentQueue.isNotEmpty) return null;
    final r = _resumePlaylistIndexAfterDeferred;
    _resumePlaylistIndexAfterDeferred = null;
    return r;
  }

  /// 消费插播队列头部并真实换源。
  ///
  /// **禁止**在此处调用 [playAt]：它会再通过 [_enqueuePlaybackNav] 挂到 [_playbackNavChain]，
  /// 而 [playNext] 正是在 chain 的 `.then` 里 `await` 本方法 —— 会形成「等待自身」的死锁，
  /// 表现为列表点歌、上一曲/下一曲均无响应。
  Future<bool> _tryConsumeDeferredPlayNext() async {
    while (_playNextAfterCurrentQueue.isNotEmpty) {
      if (_resumePlaylistIndexAfterDeferred == null) {
        final list = playList;
        if (list.isNotEmpty) {
          _resumePlaylistIndexAfterDeferred = _currentIndex.clamp(
            0,
            list.length - 1,
          );
        }
      }
      final key = _playNextAfterCurrentQueue.removeAt(0);
      final idx = _indexInPlayListByPathKey(key);
      if (idx >= 0) {
        _coalescedPlayNextSteps = 0;
        _coalescedPlayPrevSteps = 0;
        await _playAtImpl(idx, clearDeferredResume: false);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 播放结束切下一首 / 单曲循环；挂在 Provider 上，避免仅 SongPage 订阅时在退出页面后失效
  void _attachPlaybackCompletionListener() {
    _playerCompletionSubscription?.cancel();
    _playerCompletionSubscription = MusicService.playerStateStream.listen((
      state,
    ) {
      final now = state.processingState;
      final prev = _lastProcessingStateFromPlayer;
      _lastProcessingStateFromPlayer = now;
      // 仅在「首次进入 completed」时处理一次，避免同一首 completed 重复回调导致重入切歌。
      if (now != ProcessingState.completed ||
          prev == ProcessingState.completed) {
        return;
      }
      if (_completionHandlerRunning) return;
      // 同一次 completion 的同步回调里立刻换源会触发 just_audio Loading interrupted，延后到本事件后执行
      _completionHandlerRunning = true;
      Future.microtask(() async {
        try {
          await _onPlaybackTrackCompleted();
        } finally {
          _completionHandlerRunning = false;
        }
      });
    });
  }

  /// Linux/mpv: 解码异常时自动跳到下一曲，避免整队列卡在坏帧。
  void _attachPlaybackErrorListener() {
    _playerErrorSubscription?.cancel();
    _playerErrorSubscription = MusicService.errorStream.listen((error) {
      if (kIsWeb || !Platform.isLinux) return;
      if (_errorSkipHandlerRunning) return;
      final now = DateTime.now();
      if (now.difference(_lastErrorSkipAt) <
          const Duration(milliseconds: 900)) {
        return;
      }
      if (_playbackNavDepth > 0) return;
      if (playList.isEmpty) return;
      _lastErrorSkipAt = now;
      _errorSkipHandlerRunning = true;
      Future<void>.delayed(const Duration(milliseconds: 120), () async {
        try {
          if (_playbackMode == PlaybackMode.playOnce) {
            await MusicService().pause();
            return;
          }
          if (await _tryConsumeDeferredPlayNext()) return;
          final resume = _takeResumeAfterDeferredIfApplicable();
          if (resume != null) {
            await playAt(resume);
            return;
          }
          await _enqueuePlaybackNav(() async => _applyPlayNextSteps(1));
        } catch (e, st) {
          appLog.e('Linux 解码异常自动跳过失败', error: e, stackTrace: st);
        } finally {
          _errorSkipHandlerRunning = false;
        }
      });
    });
  }

  Future<void> _onPlaybackTrackCompleted() async {
    // Linux (media_kit/mpv): 在 completed 边界立刻换源，偶发触发 ffmpeg flac
    // 帧头/同步码异常。短暂让出事件循环后再切下一首可显著降低该竞态。
    if (!kIsWeb && Platform.isLinux) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      try {
        // 强制结束上一首后端状态，避免自动切歌时解码器仍卡在尾帧。
        await MusicService().stop();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (_playbackMode == PlaybackMode.singleLoop) {
      if (await _tryConsumeDeferredPlayNext()) return;
      final resume = _takeResumeAfterDeferredIfApplicable();
      if (resume != null) {
        await playAt(resume);
        return;
      }
      MusicService().seek(Duration.zero);
      MusicService().play();
      return;
    }

    if (_playbackMode == PlaybackMode.playOnce) {
      if (await _tryConsumeDeferredPlayNext()) return;
      final resume = _takeResumeAfterDeferredIfApplicable();
      if (resume != null) {
        await playAt(resume);
        return;
      }
      await MusicService().pause();
      return;
    }

    if (await _tryConsumeDeferredPlayNext()) return;

    final resume = _takeResumeAfterDeferredIfApplicable();
    if (resume != null) {
      await playAt(resume);
      return;
    }

    final concatAndroid =
        !kIsWeb &&
        Platform.isAndroid &&
        MusicService.androidCarQueueActive &&
        playList.length > 1;
    if (concatAndroid) {
      return;
    }

    await _enqueuePlaybackNav(() async => _applyPlayNextSteps(1));
  }

  @override
  void dispose() {
    _sleepShutdownTimer?.cancel();
    _playerCompletionSubscription?.cancel();
    _playerIndexSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    AndroidCarLyricsSync.detach();
    super.dispose();
  }

  /// 恢复上次播放：优先 [_kHiveLastPlayedPathKey]，其次 legacy `last_played_index`。
  /// 若上次为自建歌单会话且 [userPlaylists] 可用，则恢复 [_playbackQueueOverride] 为该歌单曲目顺序。
  Future<void> _restoreLastPlayedSnapshot({
    UserPlaylistProvider? userPlaylists,
  }) async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);

      PlaybackSessionSurface surface = PlaybackSessionSurface.library;
      final sessionRaw = box.get(_kHiveLastPlaybackSessionKey) as String?;
      if (sessionRaw != null && sessionRaw.trim().isNotEmpty) {
        try {
          surface = PlaybackSessionSurface.values.byName(sessionRaw.trim());
        } catch (_) {}
      }

      _statsRecordRecent =
          box.get(_kHiveLastPlaybackRecordRecentKey, defaultValue: true) as bool? ??
              true;
      _statsBumpPlayCount =
          box.get(_kHiveLastPlaybackBumpPlayCountKey, defaultValue: true) as bool? ??
              true;

      final userPidRaw = box.get(_kHiveLastPlaybackUserPlaylistIdKey) as String?;
      final userPid = userPidRaw?.trim() ?? '';

      final pathRaw = box.get(_kHiveLastPlayedPathKey) as String?;
      final savedIndex = box.get('last_played_index', defaultValue: 0) as int?;

      if (surface == PlaybackSessionSurface.userPlaylist &&
          userPid.isNotEmpty &&
          userPlaylists != null) {
        UserPlaylist? playlist;
        for (final p in userPlaylists.playlists) {
          if (p.id == userPid) {
            playlist = p;
            break;
          }
        }
        if (playlist != null) {
          final resolved = await userPlaylists.songsForPlaylistWithDiskFallback(
            playlist,
            libraryMergedSongs,
          );
          if (resolved.isNotEmpty) {
            _playbackQueueOverride = resolved;
            _applyPlaybackSession(
              PlaybackSessionSurface.userPlaylist,
              userPlaylistId: userPid,
            );
            _applyRestoredIndexFromPathOrLegacyIndex(
              pathRaw,
              savedIndex,
            );
            appLog.d('已恢复用户歌单播放队列 → id=$userPid, ${_currentIndex + 1}/${resolved.length}');
            return;
          }
        }
      }

      _playbackQueueOverride = null;
      if (surface == PlaybackSessionSurface.userPlaylist) {
        _applyPlaybackSession(PlaybackSessionSurface.library);
      } else {
        _applyPlaybackSession(surface);
      }

      if (surface == PlaybackSessionSurface.libraryByArtist ||
          surface == PlaybackSessionSurface.libraryByAlbum) {
        final paths = _parseOverridePathListFromHive(
          box.get(_kHiveLastOverridePathsKey),
        );
        final merged = libraryMergedSongs;
        final resolved = _resolveSongsFromOrderedPaths(paths, merged);
        if (resolved.isNotEmpty) {
          _playbackQueueOverride = resolved;
          _applyPlaybackSession(surface);
          _applyRestoredIndexFromPathOrLegacyIndex(pathRaw, savedIndex);
          appLog.d(
            '已恢复子队列播放（${surface.name}）→ ${resolved.length} 首',
          );
          return;
        }
        surface = PlaybackSessionSurface.library;
        _applyPlaybackSession(PlaybackSessionSurface.library);
      }

      if (surface == PlaybackSessionSurface.library) {
        final merged = libraryMergedSongs;
        if (merged.isNotEmpty) {
          try {
            final prefs = await loadSongSortPreferences();
            _playbackQueueOverride = sortSongsCopy(
              merged,
              prefs.type,
              prefs.ascending,
            );
            appLog.d('已恢复曲库播放队列排序（冷启动）');
          } catch (e, st) {
            appLog.e('恢复曲库播放队列排序失败', error: e, stackTrace: st);
            _playbackQueueOverride = null;
          }
        }
      }

      final list = playList;
      if (list.isEmpty) return;

      _applyRestoredIndexFromPathOrLegacyIndex(pathRaw, savedIndex);
    } catch (e) {
      appLog.e('加载上次播放快照失败', error: e);
    }
  }

  void _applyRestoredIndexFromPathOrLegacyIndex(String? pathRaw, int? savedIndex) {
    final list = playList;
    if (list.isEmpty) return;

    if (pathRaw != null && pathRaw.trim().isNotEmpty) {
      final wanted = _libraryPathKey(pathRaw);
      final i = list.indexWhere((s) => _libraryPathKey(s.path) == wanted);
      if (i >= 0) {
        _currentIndex = i;
        appLog.d('已按路径恢复上次播放 → 索引 $_currentIndex');
        return;
      }
    }

    if (savedIndex != null && savedIndex >= 0) {
      _currentIndex = savedIndex.clamp(0, list.length - 1);
      appLog.d('已恢复播放位置(索引): $_currentIndex');
    }
  }

  /// 写入当前曲目路径与索引（用户歌单等非曲库队列退出后也仍能点亮迷你条）。
  Future<void> _saveCurrentPlaybackSnapshot() async {
    try {
      final list = playList;
      if (list.isEmpty) return;
      final idx = _currentIndex.clamp(0, list.length - 1);
      final path = list[idx].path.trim();
      if (path.isEmpty) return;
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put('last_played_index', idx);
      await box.put(_kHiveLastPlayedPathKey, path);
      await box.put(_kHiveLastPlaybackSessionKey, _playbackSessionSurface.name);
      if (_playbackSessionSurface == PlaybackSessionSurface.userPlaylist &&
          (_playbackSessionUserPlaylistId ?? '').trim().isNotEmpty) {
        await box.put(
          _kHiveLastPlaybackUserPlaylistIdKey,
          _playbackSessionUserPlaylistId!.trim(),
        );
      } else {
        await box.delete(_kHiveLastPlaybackUserPlaylistIdKey);
      }
      await box.put(_kHiveLastPlaybackRecordRecentKey, _statsRecordRecent);
      await box.put(_kHiveLastPlaybackBumpPlayCountKey, _statsBumpPlayCount);
      if (_playbackSessionSurface == PlaybackSessionSurface.libraryByArtist ||
          _playbackSessionSurface == PlaybackSessionSurface.libraryByAlbum) {
        await box.put(
          _kHiveLastOverridePathsKey,
          list.map((s) => s.path).toList(),
        );
      } else {
        await box.delete(_kHiveLastOverridePathsKey);
      }
    } catch (e) {
      appLog.e('保存上次播放快照失败', error: e);
    }
  }

  /// 异步添加播放列表
  Future<void> _addPlayListAsync(FolderProvider folderProvider) async {
    //所有的文件夹
    List<Folder> folders = folderProvider.folders;

    var i = 0;
    for (var value in folders) {
      putFolder(value);
      i++;
      // 让出控制权，避免阻塞主线程上的启动转场；大目录时更频繁Yield
      await Future<void>.delayed(Duration.zero);
      if (i % 3 == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
    }
    if (folders.isNotEmpty) {
      appLog.d('曲库: 已合并 ${folders.length} 个媒体目录');
    }
  }

  void putFolder(Folder folder) {
    folderPlaylistMap.putIfAbsent(folder.path, () => folder.songList ?? []);
    _invalidateMergedLibraryCacheSyncingCurrentIndex();
  }

  ///新增
  void flushAddPlaylist(Folder folder) {
    putFolder(folder);
    notifyListeners();
  }

  ///删除
  void flushRemovePlaylist(Folder folder) {
    // List<Song>? removeSongs = folder.songList;
    // if (removeSongs == null || removeSongs.isEmpty) {
    //   return;
    // }
    // for (var value in removeSongs) {
    //   if (playList.contains(value)) {
    //     playList.remove(value);
    //   }
    // }
    folderPlaylistMap.remove(folder.path);
    _invalidateMergedLibraryCacheSyncingCurrentIndex();
    notifyListeners();
  }

  ///可能新增，也可能删除
  void flushPlaylist(Folder folder) {
    // //不包含就直接新增
    // if (!folderPlaylistMap.containsKey(folder.path)) {
    //   putFolder(folder);
    //   return;
    // }
    // //不存在歌单就无脑删除
    // if (folder.songList == null || folder.songList!.isEmpty) {
    //   folderPlaylistMap.remove(folder.path);
    //   return;
    // }
    // //进行对比更新,新增或者删除
    // List<Song>? cacheList = folderPlaylistMap[folder.path];
    // List<Song>? updateList = folder.songList;
    //感觉应该可以无脑更新   不用这么麻烦
    folderPlaylistMap.remove(folder.path);
    putFolder(folder);
    notifyListeners();
  }

  /// 设置当前播放索引（不自动播放）
  void setCurrentIndex(int index) {
    final list = playList;
    if (list.isEmpty) return;
    final next = index.clamp(0, list.length - 1);
    if (next == _currentIndex) return;
    _currentIndex = next;
    notifyListeners();
  }

  /// 将当前曲目写入最近播放并通知（用于直调 [MusicService.playSong] 而未经过 [playAt] 的场景）。
  /// 沿用 [_statsRecordRecent] / [_statsBumpPlayCount]，与 [setPlaybackQueueAndPlay] 会话一致。
  Future<void> recordRecentForCurrent() async {
    final s = currentSong;
    if (s == null) return;
    await RecentPlayService.recordPath(
      s.path,
      updateRecentList: _statsRecordRecent,
      bumpPlayCount: _statsBumpPlayCount,
    );
    notifyListeners();
  }

  /// 播放指定索引；[listSession] 非空时（例如从「最近播放」切到全库索引后 [playAt]）会更新会话面。
  ///
  /// [preserveDeferredResumeTarget]：为 true 时不丢弃 [_resumePlaylistIndexAfterDeferred]，
  /// 供「下一曲播放」插播链使用。
  Future<void> playAt(
    int index, {
    PlaybackSessionSurface? listSession,
    bool preserveDeferredResumeTarget = false,
  }) async {
    final idx = index;
    final ls = listSession;
    return _enqueuePlaybackNav(() async {
      _coalescedPlayNextSteps = 0;
      _coalescedPlayPrevSteps = 0;
      await _playAtImpl(
        idx,
        listSession: ls,
        clearDeferredResume: !preserveDeferredResumeTarget,
      );
    });
  }

  Future<void> _playAtImpl(
    int index, {
    PlaybackSessionSurface? listSession,
    bool clearDeferredResume = true,
  }) async {
    _playbackNavDepth++;
    try {
      if (clearDeferredResume) {
        _resumePlaylistIndexAfterDeferred = null;
      }
      final list = playList;
      if (list.isEmpty) return;
      if (listSession != null) {
        assert(
          listSession != PlaybackSessionSurface.userPlaylist,
          '歌单会话请使用 setPlaybackQueueAndPlay',
        );
        _applyPlaybackSession(listSession);
      }
      _currentIndex = index.clamp(0, list.length - 1);
      notifyListeners();
      final playing = list[_currentIndex];
      final ok = await MusicService().playCurrentFromPlaylist(
        queue: list,
        currentIndex: _currentIndex,
        useAndroidConcatQueue: _playbackMode != PlaybackMode.playOnce,
      );
      if (!ok) {
        reportPlaybackFailureToUser();
        return;
      }
      await RecentPlayService.recordPath(
        playing.path,
        updateRecentList: _statsRecordRecent,
        bumpPlayCount: _statsBumpPlayCount,
      );
      await _saveCurrentPlaybackSnapshot();
      unawaited(_syncAndroidCarMediaSession());
      notifyListeners();
    } finally {
      _playbackNavDepth--;
    }
  }

  /// 连续「下一曲」合并为一步索引推算后单次 [_playAtImpl]。
  Future<void> _applyPlayNextSteps(int steps) async {
    final list = playList;
    if (list.isEmpty || steps <= 0) return;

    await MusicService.fadeOutVolumeWhilePlaying();

    switch (_playbackMode) {
      case PlaybackMode.playOnce:
        return;
      case PlaybackMode.singleLoop:
        await _playAtImpl(_currentIndex);
        return;
      case PlaybackMode.sequential:
      case PlaybackMode.timerShutdown:
        var idx = _currentIndex;
        for (var i = 0; i < steps; i++) {
          idx = (idx + 1) % list.length;
        }
        await _playAtImpl(idx);
        return;
      case PlaybackMode.shuffle:
        var idx = _currentIndex;
        for (var i = 0; i < steps; i++) {
          idx = _getNextShuffledIndex(list.length);
        }
        await _playAtImpl(idx);
        return;
    }
  }

  /// 连续「上一曲」合并。
  Future<void> _applyPlayPrevSteps(int steps) async {
    final list = playList;
    if (list.isEmpty || steps <= 0) return;

    await MusicService.fadeOutVolumeWhilePlaying();

    switch (_playbackMode) {
      case PlaybackMode.singleLoop:
        await _playAtImpl(_currentIndex);
        return;
      case PlaybackMode.sequential:
      case PlaybackMode.timerShutdown:
      case PlaybackMode.playOnce:
        var idx = _currentIndex;
        for (var i = 0; i < steps; i++) {
          idx = (idx - 1 + list.length) % list.length;
        }
        await _playAtImpl(idx);
        return;
      case PlaybackMode.shuffle:
        var idx = _currentIndex;
        for (var i = 0; i < steps; i++) {
          idx = _getPrevShuffledIndex(list.length);
        }
        await _playAtImpl(idx);
        return;
    }
  }

  /// 设置播放模式
  void setPlaybackMode(PlaybackMode mode) {
    _playbackMode = mode;
    _shuffledIndices = null; // 重置随机列表
    _shuffledPlayedIndices = [];

    // 设置播放器的循环模式
    if (mode == PlaybackMode.singleLoop) {
      MusicService().setLoopMode(LoopMode.one);
    } else {
      MusicService().setLoopMode(LoopMode.off);
    }

    unawaited(() async {
      await _syncAndroidCarMediaSession();
      if (!kIsWeb &&
          Platform.isAndroid &&
          mode == PlaybackMode.playOnce &&
          MusicService.androidCarQueueActive &&
          playList.length > 1) {
        await _rebindAndroidCurrentAsSingleConcatDisabled();
      }
    }());

    notifyListeners();
  }

  /// 设置定时关闭时长（仅更新数值，不启动计时）
  void setTimerDuration(int minutes) {
    _timerDuration = minutes;
    notifyListeners();
  }

  /// 启动应用级定时关闭，到期暂停播放
  void startSleepTimer(int minutes) {
    _sleepShutdownTimer?.cancel();
    _timerDuration = minutes;
    SettingsService.saveTimerDuration(minutes);
    _sleepShutdownTimer = Timer(Duration(minutes: minutes), () {
      _sleepShutdownTimer = null;
      MusicService().pause();
      final sm = appScaffoldMessengerKey.currentState;
      final ctx = sm?.context;
      if (ctx != null && ctx.mounted) {
        final l10n = AppLocalizations.of(ctx);
        showAppSnackBar(ctx, l10n.sleepTimerPlayedMinutes(minutes));
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepShutdownTimer?.cancel();
    _sleepShutdownTimer = null;
    notifyListeners();
  }

  /// 下一首（支持连点合并为一次换源）。
  Future<void> playNext() async {
    final list = playList;
    if (list.isEmpty) return;
    if (_playbackMode == PlaybackMode.playOnce) return;

    _coalescedPlayNextSteps++;
    final f = _playbackNavChain
        .catchError((Object? e) {
          appLog.d('playback nav 前序(可忽略): $e');
        })
        .then((_) async {
          try {
            final steps = _coalescedPlayNextSteps;
            _coalescedPlayNextSteps = 0;
            if (steps <= 0) return;
            var remaining = steps;
            while (remaining > 0 && _playNextAfterCurrentQueue.isNotEmpty) {
              final consumed = await _tryConsumeDeferredPlayNext();
              if (!consumed) break;
              remaining--;
            }
            if (remaining > 0) {
              await _applyPlayNextSteps(remaining);
            }
          } catch (e, st) {
            appLog.e('playNext 合并步骤失败', error: e, stackTrace: st);
          }
        });
    _playbackNavChain = f;
    await f;
  }

  /// 上一首（支持连点合并）。
  Future<void> playPrev() async {
    final list = playList;
    if (list.isEmpty) return;

    _coalescedPlayPrevSteps++;
    final f = _playbackNavChain
        .catchError((Object? e) {
          appLog.d('playback nav 前序(可忽略): $e');
        })
        .then((_) async {
          try {
            final steps = _coalescedPlayPrevSteps;
            _coalescedPlayPrevSteps = 0;
            if (steps <= 0) return;
            await _applyPlayPrevSteps(steps);
          } catch (e, st) {
            appLog.e('playPrev 合并步骤失败', error: e, stackTrace: st);
          }
        });
    _playbackNavChain = f;
    await f;
  }

  /// 获取下一个随机索引
  int _getNextShuffledIndex(int listLength) {
    if (_shuffledIndices == null || _shuffledIndices!.isEmpty) {
      // 生成新的随机列表
      _shuffledIndices = List.generate(listLength, (i) => i)..shuffle();
      _shuffledPlayedIndices = [];
    }

    // 如果所有歌曲都播放过了，重新洗牌
    if (_shuffledPlayedIndices.length >= listLength) {
      _shuffledIndices = List.generate(listLength, (i) => i)..shuffle();
      _shuffledPlayedIndices = [];
    }

    // 找到下一个未播放的索引
    for (final idx in _shuffledIndices!) {
      if (!_shuffledPlayedIndices.contains(idx)) {
        _shuffledPlayedIndices.add(idx);
        return idx;
      }
    }

    // 如果找不到（理论上不会发生），返回第一个
    return 0;
  }

  /// 获取上一个随机索引（简单实现：从已播放列表取最后一个）
  int _getPrevShuffledIndex(int listLength) {
    if (_shuffledPlayedIndices.isEmpty) {
      return (_currentIndex - 1 + listLength) % listLength;
    }
    // 移除当前索引，返回上一个
    if (_shuffledPlayedIndices.length > 1) {
      _shuffledPlayedIndices.removeLast();
      return _shuffledPlayedIndices.last;
    }
    return 0;
  }

  /// 外部编辑器等改写磁盘文件后 [Song] 内存字段已在别处刷新，通知迷你条/列表等刷新。
  void notifySongMetadataChangedRemote() {
    notifyListeners();
  }
}
