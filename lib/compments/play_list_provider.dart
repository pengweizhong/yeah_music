import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/models/constants.dart';

import '../models/folder.dart';
import 'folder_provider.dart';

var log = Logger(printer: SimplePrinter());

class PlayListProvider extends ChangeNotifier {
  //key是用户选择的根目录
  LinkedHashMap<String, List<Song>> folderPlaylistMap = LinkedHashMap();

  bool _initialized = false;

  bool get initialized => _initialized;

  /// 当前播放索引（以 playList 为基准）
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// 播放模式
  PlaybackMode _playbackMode = PlaybackMode.sequential;

  PlaybackMode get playbackMode => _playbackMode;

  /// 定时关闭时长（分钟）
  int _timerDuration = 30;

  int get timerDuration => _timerDuration;

  /// 随机播放时的已播放列表
  List<int> _shuffledPlayedIndices = [];

  /// 随机播放时的当前随机列表
  List<int>? _shuffledIndices;

  /// 缓存的播放列表（仅曲库合并结果）
  List<Song>? _cachedPlayList;

  /// 临时播放队列（例如用户歌单），非空时 [playList] 使用该列表而非曲库合并
  List<Song>? _playbackQueueOverride;

  bool get hasPlaybackQueueOverride => _playbackQueueOverride != null;

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
  Future<void> setPlaybackQueueAndPlay(List<Song> songs, int index) async {
    if (songs.isEmpty) return;
    _playbackQueueOverride = List<Song>.from(songs);
    _currentIndex = index.clamp(0, songs.length - 1);
    _shuffledIndices = null;
    _shuffledPlayedIndices = [];
    notifyListeners();
    await MusicService().playSong(_playbackQueueOverride![_currentIndex]);
  }

  /// 恢复为曲库合并队列；可选按当前播放曲目的路径在全库中定位索引。
  void clearPlaybackQueueOverride({bool relocateCurrentSong = true}) {
    if (_playbackQueueOverride == null) return;
    final path = relocateCurrentSong ? currentSong?.path : null;
    _playbackQueueOverride = null;
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
    notifyListeners();
  }

  /// 加载上次播放的歌曲索引
  Future<void> _loadLastPlayedIndex() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final savedIndex = box.get('last_played_index', defaultValue: 0) as int?;
      if (savedIndex != null && savedIndex >= 0) {
        _currentIndex = savedIndex;
        log.d("加载上次播放的歌曲索引: $_currentIndex");
      }
    } catch (e) {
      log.e("加载上次播放索引失败: $e");
    }
  }

  /// 保存当前播放的歌曲索引
  Future<void> _saveCurrentIndex() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put('last_played_index', _currentIndex);
      log.d("保存当前播放索引: $_currentIndex");
    } catch (e) {
      log.e("保存播放索引失败: $e");
    }
  }

  /// 异步添加播放列表
  Future<void> _addPlayListAsync(FolderProvider folderProvider) async {
    //所有的文件夹
    List<Folder> folders = folderProvider.folders;
    
    for (var value in folders) {
      log.d("添加了目录：${value.name}，共${value.songList?.length}首歌曲");
      putFolder(value);
      
      // 每添加一个文件夹后，让出控制权，避免阻塞UI
      await Future.delayed(Duration.zero);
    }
  }

  void _addPlayList(FolderProvider folderProvider) {
    //所有的文件夹
    List<Folder> folders = folderProvider.folders;
    for (var value in folders) {
      log.d("添加了目录：${value.name}，共${value.songList?.length}首歌曲");
      // if (value.songList == null || value.songList!.isEmpty) {
      //   continue;
      // }
      putFolder(value);
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

  /// 播放指定索引
  Future<void> playAt(int index) async {
    final list = playList;
    if (list.isEmpty) return;
    _currentIndex = index.clamp(0, list.length - 1);
    notifyListeners();
    await MusicService().playSong(list[_currentIndex]);
    if (_playbackQueueOverride == null) {
      await _saveCurrentIndex();
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
    
    notifyListeners();
  }

  /// 设置定时关闭时长
  void setTimerDuration(int minutes) {
    _timerDuration = minutes;
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
