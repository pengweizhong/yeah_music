import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';
import 'folder_provider.dart';


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

  /// 缓存的播放列表（仅曲库合并结果）
  List<Song>? _cachedPlayList;

  /// 临时播放队列（例如用户歌单），非空时 [playList] 使用该列表而非曲库合并
  List<Song>? _playbackQueueOverride;

  /// 当前一次「临时队列」会话内，是否写入最近列表 / 是否增加播放次数（由 [setPlaybackQueueAndPlay] 设定，曲库直播为默认都记）
  bool _statsRecordRecent = true;
  bool _statsBumpPlayCount = true;

  bool get hasPlaybackQueueOverride => _playbackQueueOverride != null;

  /// 当前一次播放会话在 UI 上「属于」哪个列表，用于从 [SongPage] 返回时是否在该表滚到当前曲
  PlaybackSessionSurface _playbackSessionSurface = PlaybackSessionSurface.library;
  String? _playbackSessionUserPlaylistId;

  /// 是否为「从全库/全部歌曲」发起的会話（在 [PlayListPage] 滚屏）
  bool get playbackSessionIsLibrary =>
      _playbackSessionSurface == PlaybackSessionSurface.library;

  /// 是否为「从最近播放相关列表」发起（在 [RecentPlaysPage] 滚屏）
  bool get playbackSessionIsRecentList =>
      _playbackSessionSurface == PlaybackSessionSurface.recentList;

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

  /// 本地已扫描目录的合并曲库（不受 [_playbackQueueOverride] 影响）
  List<Song> get libraryMergedSongs {
    return folderPlaylistMap.values.expand((l) => l).toList();
  }

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
  List<Song> resolveRecentSongsFromPaths(
    List<String> paths, {
    int? maxSongs,
  }) {
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

  /// 把所有文件夹里的歌曲合并成一个大列表（使用缓存优化性能），
  /// 若已设置 [_playbackQueueOverride] 则返回覆盖队列。
  List<Song> get playList {
    if (_playbackQueueOverride != null) return _playbackQueueOverride!;
    if (_cachedPlayList == null) {
      _cachedPlayList = folderPlaylistMap.values.expand((list) => list).toList();
    }
    return _cachedPlayList!;
  }

  /// 清除播放列表缓存
  void _clearPlayListCache() {
    _cachedPlayList = null;
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
    if (songs.isEmpty) return;
    if (session == PlaybackSessionSurface.userPlaylist) {
      assert(
        userPlaylistId != null && userPlaylistId.isNotEmpty,
        'userPlaylist 会话需提供 userPlaylistId',
      );
    }
    _applyPlaybackSession(
      session,
      userPlaylistId: userPlaylistId,
    );
    _statsRecordRecent = recordRecent;
    _statsBumpPlayCount = bumpPlayCount;
    _playbackQueueOverride = List<Song>.from(songs);
    _currentIndex = index.clamp(0, songs.length - 1);
    _shuffledIndices = null;
    _shuffledPlayedIndices = [];
    notifyListeners();
    final song = _playbackQueueOverride![_currentIndex];
    await MusicService().playSong(song);
    await RecentPlayService.recordPath(
      song.path,
      updateRecentList: recordRecent,
      bumpPlayCount: bumpPlayCount,
    );
    notifyListeners();
  }

  /// 恢复为曲库合并队列；可选按当前播放曲目的路径在全库中定位索引。
  void clearPlaybackQueueOverride({bool relocateCurrentSong = true}) {
    if (_playbackQueueOverride == null) return;
    final path = relocateCurrentSong ? currentSong?.path : null;
    _playbackQueueOverride = null;
    _statsRecordRecent = true;
    _statsBumpPlayCount = true;
    _clearPlayListCache();
    final lib = folderPlaylistMap.values.expand((l) => l).toList();
    _cachedPlayList = lib;
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
  }

  Song? get currentSong {
    final list = playList;
    if (list.isEmpty) return null;
    final idx = _currentIndex.clamp(0, list.length - 1);
    return list[idx];
  }

  /// 从 FolderProvider 加载歌曲（优化版本，支持大量歌曲）
  Future<void> init(FolderProvider folderProvider) async {
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
    _initialized = true;
    
    // 加载上次播放的歌曲索引
    await _loadLastPlayedIndex();
    
    // 保障 currentIndex 合法
    final list = playList;
    if (list.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= list.length) {
      _currentIndex = 0;
    }
    _attachPlaybackCompletionListener();
    notifyListeners();
  }

  /// 播放结束切下一首 / 单曲循环；挂在 Provider 上，避免仅 SongPage 订阅时在退出页面后失效
  void _attachPlaybackCompletionListener() {
    _playerCompletionSubscription?.cancel();
    _playerCompletionSubscription = MusicService.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed) return;
      // 同一次 completion 的同步回调里立刻换源会触发 just_audio Loading interrupted，延后到本事件后执行
      Future.microtask(() {
        if (_playbackMode == PlaybackMode.singleLoop) {
          MusicService().seek(Duration.zero);
          MusicService().play();
          return;
        }
        if (_playbackMode == PlaybackMode.playOnce) {
          return;
        }
        playNext();
      });
    });
  }

  @override
  void dispose() {
    _sleepShutdownTimer?.cancel();
    _playerCompletionSubscription?.cancel();
    super.dispose();
  }

  /// 加载上次播放的歌曲索引
  Future<void> _loadLastPlayedIndex() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final savedIndex = box.get('last_played_index', defaultValue: 0) as int?;
      if (savedIndex != null && savedIndex >= 0) {
        _currentIndex = savedIndex;
        appLog.d('已恢复播放位置: 索引 $_currentIndex');
      }
    } catch (e) {
      appLog.e('加载上次播放索引失败', error: e);
    }
  }

  /// 保存当前播放的歌曲索引
  Future<void> _saveCurrentIndex() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put('last_played_index', _currentIndex);
    } catch (e) {
      appLog.e('保存播放索引失败', error: e);
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
    _clearPlayListCache(); // 清除缓存
  }

  ///新增
  void flushAddPlaylist(Folder folder) {
    List<Song>? addSongs = folder.songList;
    // if (addSongs == null || addSongs.isEmpty) {
    //   return;
    // }
    putFolder(folder);
    _clearPlayListCache(); // 清除缓存
    // for (var value in addSongs) {
    //   if (!playList.contains(value)) {
    //     playList.add(value);
    //   }
    // }
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
    _clearPlayListCache(); // 清除缓存
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
    _clearPlayListCache(); // 清除缓存
    if (_playbackQueueOverride == null) {
      final list = folderPlaylistMap.values.expand((l) => l).toList();
      if (list.isEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= list.length) {
        _currentIndex = 0;
      }
    }
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

  /// 将当前曲目写入最近播放并通知（用于直调 [MusicService.playSong] 而未经过 [playAt] 的场景）
  Future<void> recordRecentForCurrent() async {
    final s = currentSong;
    if (s == null) return;
    await RecentPlayService.recordPath(s.path);
    notifyListeners();
  }

  /// 播放指定索引；[listSession] 非空时（例如从「最近播放」切到全库索引后 [playAt]）会更新会话面。
  Future<void> playAt(int index, {PlaybackSessionSurface? listSession}) async {
    final list = playList;
    if (list.isEmpty) return;
    if (listSession != null) {
      assert(
        listSession != PlaybackSessionSurface.userPlaylist,
        '歌单会话请使用 setPlaybackQueueAndPlay',
      );
      _applyPlaybackSession(
        listSession,
      );
    }
    _currentIndex = index.clamp(0, list.length - 1);
    notifyListeners();
    final playing = list[_currentIndex];
    await MusicService().playSong(playing);
    await RecentPlayService.recordPath(
      playing.path,
      updateRecentList: _statsRecordRecent,
      bumpPlayCount: _statsBumpPlayCount,
    );
    if (_playbackQueueOverride == null) {
      await _saveCurrentIndex();
    }
    notifyListeners();
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
      if (ctx != null) {
        final l10n = AppLocalizations.of(ctx);
        sm?.showSnackBar(
          SnackBar(
            content: Text(l10n.sleepTimerPlayedMinutes(minutes)),
          ),
        );
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

  /// 下一首
  Future<void> playNext() async {
    final list = playList;
    if (list.isEmpty) return;

    int next;
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        next = (_currentIndex + 1) % list.length;
        break;
      case PlaybackMode.shuffle:
        next = _getNextShuffledIndex(list.length);
        break;
      case PlaybackMode.singleLoop:
        next = _currentIndex; // 单曲循环，播放同一首
        break;
      case PlaybackMode.playOnce:
        // 仅播放一次，不自动播放下一首
        return;
      case PlaybackMode.timerShutdown:
        next = (_currentIndex + 1) % list.length;
        break;
    }
    await playAt(next);
  }

  /// 上一首
  Future<void> playPrev() async {
    final list = playList;
    if (list.isEmpty) return;

    int prev;
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        prev = (_currentIndex - 1 + list.length) % list.length;
        break;
      case PlaybackMode.shuffle:
        // 随机模式下，上一首也是随机的
        prev = _getPrevShuffledIndex(list.length);
        break;
      case PlaybackMode.singleLoop:
        prev = _currentIndex; // 单曲循环
        break;
      case PlaybackMode.playOnce:
        prev = (_currentIndex - 1 + list.length) % list.length;
        break;
      case PlaybackMode.timerShutdown:
        prev = (_currentIndex - 1 + list.length) % list.length;
        break;
    }
    await playAt(prev);
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
}
