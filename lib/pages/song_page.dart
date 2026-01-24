import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';

var log = Logger(printer: SimplePrinter());

class SongPage extends StatefulWidget {
  int index;

  SongPage({super.key, required this.index});

  @override
  State<StatefulWidget> createState() {
    return _SongPageState();
  }
}

class _SongPageState extends State<SongPage> {
  List<LyricEntry> _lyrics = [];
  List<GlobalKey> _lyricKeys = [];
  int _currentLyricIndex = -1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  final ScrollController _scrollController = ScrollController();

  // 歌词显示配置（从设置加载）
  late LyricSettings _settings;

  // 多语言切换显示模式：-1=全部显示，0=只显示第1行，1=只显示第2行，...
  Map<int, int> _lyricDisplayMode = {}; // key: lyric index, value: display mode

  // 拖动进度条时的预览
  bool _isSeeking = false;
  Duration _seekPreview = Duration.zero;

  // 滑动视图：0=封皮，1=歌词（反转顺序，左滑显示封面，右滑显示歌词）
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0; // 0=封皮，1=歌词
  bool _pageStateLoaded = false; // 标记页面状态是否已加载

  // 定时关闭相关
  Timer? _shutdownTimer;
  bool _isTimerActive = false;

  // 手动滚动控制
  bool _isManualScrolling = false;
  Timer? _scrollTimer;


  @override
  void initState() {
    super.initState();
    _settings = LyricSettings(); // 初始化默认设置
    _loadSettings();
    _listenToPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 用路由传入的 index 初始化当前播放索引
      final playListProvider = Provider.of<PlayListProvider>(context, listen: false);
      if (playListProvider.playList.isNotEmpty) {
        final targetIndex = widget.index;
        final currentIndex = playListProvider.currentIndex;
        final currentSong = playListProvider.currentSong;
        final targetSong = playListProvider.playList[targetIndex.clamp(0, playListProvider.playList.length - 1)];
        
        // 如果点击的是同一首歌曲，只设置索引，不播放
        if (currentIndex == targetIndex || (currentSong != null && currentSong.path == targetSong.path)) {
          playListProvider.setCurrentIndex(targetIndex);
        } else {
          // 不同歌曲，播放选择的歌曲
          await playListProvider.playAt(targetIndex);
        }
      }
      _initLyrics();
      _updateDuration();
      _loadPlaybackMode();
      // 加载上次的页面状态（封皮或歌词）
      _loadPageState();
    });
  }

  /// 加载页面状态（封皮或歌词）
  Future<void> _loadPageState() async {
    if (_pageStateLoaded) return; // 避免重复加载
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final savedPage = box.get('last_song_page', defaultValue: 0) as int?;
      if (savedPage != null && savedPage >= 0 && savedPage <= 1) {
        _pageStateLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(savedPage);
            setState(() {
              _currentPage = savedPage;
            });
          }
        });
      } else {
        _pageStateLoaded = true;
      }
    } catch (e) {
      _pageStateLoaded = true;
      // 忽略错误，使用默认值
    }
  }

  /// 保存页面状态
  Future<void> _savePageState() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put('last_song_page', _currentPage);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final saved = await SettingsService.loadLyricSettings();
    if (saved != null) {
      setState(() {
        _settings = saved;
        _lyricDisplayMode = saved.lyricDisplayMode;
        // 恢复全局显示模式（取第一个有设置的值，或默认为-1）
        if (_lyricDisplayMode.isNotEmpty) {
          _globalDisplayMode = _lyricDisplayMode.values.first;
        } else {
          _globalDisplayMode = -1;
        }
      });
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // 创建新的设置对象，避免HiveObject重复存储错误
    final newSettings = LyricSettings()
      ..showOriginal = _settings.showOriginal
      ..showTranslations = _settings.showTranslations
      ..originalFontSize = _settings.originalFontSize
      ..translationFontSize = _settings.translationFontSize
      ..lyricLineSpacing = _settings.lyricLineSpacing
      ..activeOriginalColor = _settings.activeOriginalColor
      ..activeTranslationColor = _settings.activeTranslationColor
      ..playedOriginalColor = _settings.playedOriginalColor
      ..playedTranslationColor = _settings.playedTranslationColor
      ..upcomingOriginalColor = _settings.upcomingOriginalColor
      ..upcomingTranslationColor = _settings.upcomingTranslationColor
      ..lyricDisplayMode = _lyricDisplayMode;
    
    await SettingsService.saveLyricSettings(newSettings);
    // 更新当前设置对象
    _settings = newSettings;
  }

  /// 加载播放模式
  Future<void> _loadPlaybackMode() async {
    final mode = await SettingsService.loadPlaybackMode();
    final playListProvider = Provider.of<PlayListProvider>(context, listen: false);
    playListProvider.setPlaybackMode(mode);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _shutdownTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollTimer?.cancel();
    // 延迟保存设置，避免在dispose时访问已关闭的box
    Future.microtask(() => _saveSettings());
    super.dispose();
  }

  void _initLyrics() {
    final playListProvider = Provider.of<PlayListProvider>(context, listen: false);
    final currentSong = playListProvider.currentSong;
    if (currentSong != null) {
      final song = currentSong;
      if (song.lyrics != null && song.lyrics!.isNotEmpty) {
        setState(() {
          _lyrics = LyricsUtils.parseLyrics(song.lyrics);
          _currentLyricIndex = -1;
          // 重置所有行的激活状态
          for (var line in _lyrics) {
            line.isActive = false;
          }
          _lyricKeys = List<GlobalKey>.generate(_lyrics.length, (_) => GlobalKey());
          // 重置滚动位置
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      } else {
        setState(() {
          _lyrics = [];
          _lyricKeys = [];
          _currentLyricIndex = -1;
        });
      }
    }
  }

  void _updateDuration() {
    final duration = MusicService.duration;
    if (duration != null && duration != _totalDuration) {
      setState(() {
        _totalDuration = duration;
      });
    }
  }

  void _listenToPlayer() {
    // 监听播放位置
    _positionSubscription = MusicService.positionStream.listen((position) {
      if (mounted) {
        if (!_isSeeking) {
          _currentPosition = position;
          _updateCurrentLyric(position);
          setState(() {});
        }
      }
    });

    // 监听播放状态
    _playingSubscription = MusicService.playingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {});
        if (isPlaying) {
          _updateDuration();
          // 首次播放时，确保歌词与滚动立即对齐
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCurrentLyric(_currentPosition);
          });
        }
      }
    });

    // 监听总时长（首次播放/刚 setAudioSource 时更可靠）
    _durationSubscription = MusicService.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null && d != _totalDuration) {
        setState(() {
          _totalDuration = d;
        });
      }
    });

    // 监听播放完成，自动播放下一首
    _playerStateSubscription = MusicService.playerStateStream.listen((state) {
      if (!mounted) return;
      // 当播放完成时（processingState == completed）
      if (state.processingState == ProcessingState.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final playListProvider = Provider.of<PlayListProvider>(context, listen: false);
          // 根据播放模式决定是否自动播放下一首
          if (playListProvider.playbackMode == PlaybackMode.singleLoop) {
            // 单曲循环：重新播放当前歌曲（使用播放器的seek回到开头）
            MusicService().seek(Duration.zero);
            MusicService().play();
          } else if (playListProvider.playbackMode != PlaybackMode.playOnce) {
            // 顺序播放、随机播放、定时关闭：播放下一首
            playListProvider.playNext().then((_) {
              if (mounted) {
                _initLyrics();
                _updateDuration();
              }
            });
          }
          // playOnce 模式不自动播放下一首
        });
      }
    });
  }

  void _updateCurrentLyric(Duration position) {
    final newIndex = LyricsUtils.findCurrentLyricIndex(_lyrics, position);
    // 即使索引相同，也要更新激活状态，确保UI同步
    if (newIndex >= 0 && newIndex < _lyrics.length) {
      // 重置所有行的激活状态
      for (var line in _lyrics) {
        line.isActive = false;
      }
      // 设置当前行为激活状态
      _lyrics[newIndex].isActive = true;
      
      // 如果索引变化，更新并滚动
      if (newIndex != _currentLyricIndex) {
        _currentLyricIndex = newIndex;
        // 滚动到当前歌词行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLyric(newIndex);
          }
        });
      }
    } else if (newIndex < 0) {
      // 如果找不到对应的歌词，重置所有激活状态
      for (var line in _lyrics) {
        line.isActive = false;
      }
      _currentLyricIndex = -1;
    }
  }

  void _scrollToCurrentLyric(int index, {bool force = false}) {
    // 如果正在手动滚动且不是强制滚动，则不自动滚动
    if (_isManualScrolling && !force) return;
    
    if (index < 0 || index >= _lyricKeys.length) return;
    final ctx = _lyricKeys[index].currentContext;
    if (ctx == null) return;

    // 用 ensureVisible，避免“固定高度估算”导致多行歌词滚动不准
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // 定位到当前播放行
  void _scrollToCurrentPlayingLyric() {
    if (_currentLyricIndex >= 0 && _currentLyricIndex < _lyricKeys.length) {
      _isManualScrolling = false; // 重置手动滚动标志
      _scrollToCurrentLyric(_currentLyricIndex, force: true);
    }
  }

  // 监听用户手动滚动
  void _onUserScroll() {
    _isManualScrolling = true;
    // 取消之前的定时器
    _scrollTimer?.cancel();
    // 5秒后恢复自动滚动
    _scrollTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
      }
    });
  }

  void _showPlayListSheet(BuildContext context, PlayListProvider playListProvider) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        final list = playListProvider.playList;
        return SafeArea(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade800),
            itemBuilder: (context, index) {
              final s = list[index];
              final isCurrent = index == playListProvider.currentIndex;
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image(
                      fit: BoxFit.cover,
                      image: ApplicationUtils.getImageCoverProvider(s),
                    ),
                  ),
                ),
                title: Text(
                  s.title ?? '未知标题',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  s.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: isCurrent ? const Icon(Icons.equalizer) : null,
                onTap: () async {
                  Navigator.pop(context);
                  await playListProvider.playAt(index);
                  _initLyrics();
                  _updateDuration();
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showLyricStyleSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Widget switchRow(String title, bool value, ValueChanged<bool> onChanged) {
                return SwitchListTile(
                  title: Text(title),
                  value: value,
                  onChanged: (v) {
                    onChanged(v);
                    setModalState(() {});
                    setState(() {});
                  },
                );
              }

              Widget sliderRow(String title, double value, double min, double max, ValueChanged<double> onChanged) {
                return ListTile(
                  title: Text(title),
                  subtitle: Slider(
                    value: value,
                    min: min,
                    max: max,
                    onChanged: (v) {
                      onChanged(v);
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                  trailing: Text(value.toStringAsFixed(0)),
                );
              }

              Future<void> pickColor(String title, Color currentColor, ValueChanged<Color> onChanged) async {
                // 简单的颜色选择器
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    final colors = [
                      Colors.white,
                      const Color(0xFFD0D0D0),
                      const Color(0xFFB0B0B0),
                      const Color(0xFF909090),
                      const Color(0xFF7A7A7A),
                      const Color(0xFF6A6A6A),
                      Colors.blue.shade300,
                      Colors.green.shade300,
                      Colors.orange.shade300,
                      Colors.purple.shade300,
                    ];
                    return AlertDialog(
                      title: Text(title),
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              onChanged(color);
                              Navigator.pop(dialogContext);
                              setModalState(() {});
                              setState(() {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: currentColor == color ? Colors.blue : Colors.grey,
                                  width: currentColor == color ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              }

              Widget colorRow(String title, Color color, ValueChanged<Color> onChanged) {
                return ListTile(
                  title: Text(title),
                  trailing: GestureDetector(
                    onTap: () => pickColor(title, color, onChanged),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('歌词显示设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    switchRow('显示原文（每个时间戳第 1 行）', _settings.showOriginal, (v) {
                      _settings.showOriginal = v;
                      _saveSettings();
                    }),
                    switchRow('显示翻译/附加行（第 2..n 行）', _settings.showTranslations, (v) {
                      _settings.showTranslations = v;
                      _saveSettings();
                    }),
                    sliderRow('原文字号', _settings.originalFontSize, 14, 28, (v) {
                      _settings.originalFontSize = v;
                      _saveSettings();
                    }),
                    sliderRow('翻译字号', _settings.translationFontSize, 10, 22, (v) {
                      _settings.translationFontSize = v;
                      _saveSettings();
                    }),
                    sliderRow('歌词行间距', _settings.lyricLineSpacing, 4, 32, (v) {
                      _settings.lyricLineSpacing = v;
                      _saveSettings();
                    }),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('颜色设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('当前播放行', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    colorRow('原文颜色', Color(_settings.activeOriginalColor), (v) {
                      _settings.activeOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow('翻译颜色', Color(_settings.activeTranslationColor), (v) {
                      _settings.activeTranslationColor = v.value;
                      _saveSettings();
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('已播放行', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    colorRow('原文颜色', Color(_settings.playedOriginalColor), (v) {
                      _settings.playedOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow('翻译颜色', Color(_settings.playedTranslationColor), (v) {
                      _settings.playedTranslationColor = v.value;
                      _saveSettings();
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('未播放行', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    colorRow('原文颜色', Color(_settings.upcomingOriginalColor), (v) {
                      _settings.upcomingOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow('翻译颜色', Color(_settings.upcomingTranslationColor), (v) {
                      _settings.upcomingTranslationColor = v.value;
                      _saveSettings();
                    }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 全局显示模式：-1=全部显示，0=只显示第1行，1=只显示第2行，...
  int _globalDisplayMode = -1;

  // 切换显示模式 - 按照最多行的歌词为基数，统一切换所有歌词
  void _toggleDisplayMode() {
    if (_lyrics.isEmpty) return;
    
    setState(() {
      // 找到行数最多的歌词
      int maxLines = 0;
      for (var lyric in _lyrics) {
        if (lyric.lines.length > maxLines) {
          maxLines = lyric.lines.length;
        }
      }
      
      if (maxLines <= 1) return; // 没有多行歌词
      
      // 循环切换全局显示模式
      if (_globalDisplayMode == -1) {
        // 当前是全部显示，切换到只显示第1行
        _globalDisplayMode = 0;
      } else if (_globalDisplayMode >= maxLines - 1) {
        // 当前是最后一行，切换回全部显示
        _globalDisplayMode = -1;
      } else {
        // 切换到下一行
        _globalDisplayMode = _globalDisplayMode + 1;
      }
      
      // 将所有歌词的显示模式设置为全局模式
      for (int i = 0; i < _lyrics.length; i++) {
        if (_lyrics[i].lines.length > 1) {
          _lyricDisplayMode[i] = _globalDisplayMode;
        }
      }
      
      _saveSettings();
    });
  }

  // 获取播放模式图标
  IconData _getPlaybackModeIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.sequential:
        return Icons.playlist_play;
      case PlaybackMode.shuffle:
        return Icons.shuffle;
      case PlaybackMode.singleLoop:
        return Icons.repeat_one;
      case PlaybackMode.playOnce:
        return Icons.play_arrow;
      case PlaybackMode.timerShutdown:
        return Icons.timer;
    }
  }

  // 显示播放模式选择弹窗
  void _showPlaybackModeSheet(BuildContext context, PlayListProvider provider) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('播放模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: PlaybackMode.values.map((mode) {
                    final isSelected = provider.playbackMode == mode;
                    return ListTile(
                      leading: Icon(_getPlaybackModeIcon(mode)),
                      title: Text(mode.displayName),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        provider.setPlaybackMode(mode);
                        SettingsService.savePlaybackMode(mode);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示定时关闭弹窗
  void _showTimerSheet(BuildContext context, PlayListProvider provider) {
    final durations = [15, 30, 45, 60, 90, 120];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('定时关闭', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_isTimerActive)
                      ListTile(
                        leading: const Icon(Icons.timer_off),
                        title: const Text('取消定时关闭'),
                        onTap: () {
                          _cancelTimer();
                          Navigator.pop(context);
                        },
                      ),
                    ...durations.map((minutes) {
                      return ListTile(
                        leading: const Icon(Icons.timer),
                        title: Text('$minutes 分钟'),
                        trailing: provider.timerDuration == minutes && _isTimerActive
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          _startTimer(minutes, provider);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 启动定时关闭
  void _startTimer(int minutes, PlayListProvider provider) {
    _cancelTimer();
    provider.setTimerDuration(minutes);
    SettingsService.saveTimerDuration(minutes);
    _isTimerActive = true;
    _shutdownTimer = Timer(Duration(minutes: minutes), () {
      MusicService().pause();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定时关闭：已播放 $minutes 分钟')),
        );
      }
      _isTimerActive = false;
      setState(() {});
    });
    setState(() {});
  }

  // 取消定时关闭
  void _cancelTimer() {
    _shutdownTimer?.cancel();
    _shutdownTimer = null;
    _isTimerActive = false;
    setState(() {});
  }

  Duration _effectivePosition() => _isSeeking ? _seekPreview : _currentPosition;

  Future<void> _seekTo(Duration target) async {
    try {
      // 确保有总时长，如果没有则先更新
      if (_totalDuration.inMilliseconds == 0) {
        _updateDuration();
        // 等待一下让时长更新
        await Future.delayed(const Duration(milliseconds: 200));
        // 再次检查
        if (_totalDuration.inMilliseconds == 0) {
          _isSeeking = false;
          if (mounted) setState(() {});
          return;
        }
      }
      
      // 如果当前没有播放，先播放再seek
      final wasPlaying = MusicService.isPlaying;
      if (!wasPlaying) {
        await MusicService().play();
      }
      
      // 先更新位置，再seek，确保同步
      _currentPosition = target;
      await MusicService().seek(target);
      _isSeeking = false;
      
      // 立即更新歌词高亮和滚动
      _updateCurrentLyric(target);
      
      // 确保UI更新
      if (mounted) {
        setState(() {});
        // 延迟一下再滚动，确保歌词索引已更新
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && _currentLyricIndex >= 0 && _currentLyricIndex < _lyricKeys.length) {
          // 强制滚动到当前歌词位置
          _isManualScrolling = false;
          _scrollToCurrentLyric(_currentLyricIndex, force: true);
        }
      }
    } catch (e) {
      log.e("跳转播放位置失败：$e");
      _isSeeking = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayListProvider>(
      builder: (context, playListProvider, childWidget) {
        if (playListProvider.playList.isEmpty) {
          return const Scaffold(body: Center(child: Text('歌曲不存在')));
        }

        final song = playListProvider.currentSong ?? playListProvider.playList.first;
        // 使用StreamBuilder来监听播放状态，确保按钮状态正确
        final effectivePos = _effectivePosition();

        // 如果歌曲切换，重新加载歌词
        if (_lyrics.isEmpty && song.lyrics != null && song.lyrics!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initLyrics();
          });
        }

        return SafeArea(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Column(
              children: [
                // 顶部栏：返回按钮和歌曲信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title ?? '未知标题',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (song.artist != null && song.artist!.isNotEmpty)
                              Text(
                                song.artist!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.list, size: 24),
                        onPressed: () {
                          _showPlayListSheet(context, playListProvider);
                        },
                      ),
                    ],
                  ),
                ),

                // 歌词/封皮显示区域（支持左右滑动：左滑显示封面，右滑显示歌词）
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const PageScrollPhysics(), // 启用页面滑动
                    scrollDirection: Axis.horizontal, // 水平滑动
                    allowImplicitScrolling: false,
                    reverse: false, // 正常顺序：0=封皮，1=歌词
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _savePageState(); // 保存页面状态
                    },
                    children: [
                      // 封皮页面（第0页）
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image(
                                  image: ApplicationUtils.getImageCoverProvider(song, size: 400),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 歌词页面（第1页）
                      _lyrics.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.music_note, size: 64, color: Colors.grey.shade600),
                                  const SizedBox(height: 16),
                                  Text('暂无歌词', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is UserScrollNotification) {
                                      _onUserScroll();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics: const ClampingScrollPhysics(), // 使用ClampingScrollPhysics，允许PageView处理水平滑动
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: _lyrics.length,
                              itemBuilder: (context, index) {
                            final line = _lyrics[index];
                            final ts = line.timestamp;
                            final played = ts != null && ts <= effectivePos;
                            final active = line.isActive;

                            TextStyle styleFor({required bool isOriginal}) {
                              final baseSize = isOriginal ? _settings.originalFontSize : _settings.translationFontSize;
                              final activeColor = Color(isOriginal ? _settings.activeOriginalColor : _settings.activeTranslationColor);
                              final playedColor = Color(isOriginal ? _settings.playedOriginalColor : _settings.playedTranslationColor);
                              final upcomingColor = Color(isOriginal ? _settings.upcomingOriginalColor : _settings.upcomingTranslationColor);
                              final color = active
                                  ? activeColor
                                  : (played ? playedColor : upcomingColor);
                              return TextStyle(
                                fontSize: active && isOriginal ? baseSize + 2 : baseSize,
                                fontWeight: active && isOriginal ? FontWeight.w600 : FontWeight.w400,
                                color: color,
                                height: 1.35,
                                letterSpacing: 0.2,
                              );
                            }

                            // 根据显示模式决定显示哪些行（使用全局模式或该行的特定模式）
                            final lineSpecificMode = _lyricDisplayMode[index];
                            final displayMode = lineSpecificMode ?? _globalDisplayMode; // 优先使用行特定模式，否则使用全局模式
                            final linesToShow = <String>[];
                            
                            if (displayMode == -1) {
                              // 全部显示
                              if (_settings.showOriginal && line.lines.isNotEmpty) {
                                linesToShow.add(line.lines[0]);
                              }
                              if (_settings.showTranslations && line.lines.length > 1) {
                                linesToShow.addAll(line.lines.sublist(1));
                              }
                            } else if (displayMode < line.lines.length) {
                              // 只显示指定行
                              linesToShow.add(line.lines[displayMode]);
                            } else {
                              // 容错：如果模式超出范围，显示全部
                              if (_settings.showOriginal && line.lines.isNotEmpty) {
                                linesToShow.add(line.lines[0]);
                              }
                              if (_settings.showTranslations && line.lines.length > 1) {
                                linesToShow.addAll(line.lines.sublist(1));
                              }
                            }

                            final original = line.lines.isNotEmpty ? line.lines.first : '';
                            final isShowingAll = displayMode == -1;
                            final isShowingSingleLine = displayMode >= 0 && displayMode < line.lines.length;

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: _settings.lyricLineSpacing / 2),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: ts == null ? null : () async {
                            await _seekTo(ts);
                            // 确保进度条和歌词同步更新
                            if (mounted) {
                              setState(() {
                                _currentPosition = ts;
                              });
                              _updateCurrentLyric(ts);
                            }
                          },
                                child: Container(
                                  key: _lyricKeys.length == _lyrics.length ? _lyricKeys[index] : null,
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < linesToShow.length; i++)
                                        Padding(
                                          padding: EdgeInsets.only(top: i > 0 ? 4 : 0),
                                          child: Builder(
                                            builder: (context) {
                                              // 确定当前显示的行在原始lines中的索引
                                              final originalIndex = isShowingAll 
                                                  ? i 
                                                  : displayMode;
                                              final isOriginalLine = originalIndex == 0;
                                              
                                              // 如果显示全部且是当前行，所有行都高亮
                                              final shouldHighlight = active && (
                                                (isShowingAll) || 
                                                (isShowingSingleLine && originalIndex == displayMode)
                                              );
                                              
                                              final activeColor = Color(isOriginalLine ? _settings.activeOriginalColor : _settings.activeTranslationColor);
                                              final playedColor = Color(isOriginalLine ? _settings.playedOriginalColor : _settings.playedTranslationColor);
                                              final upcomingColor = Color(isOriginalLine ? _settings.upcomingOriginalColor : _settings.upcomingTranslationColor);
                                              return AnimatedDefaultTextStyle(
                                                duration: const Duration(milliseconds: 160),
                                                style: TextStyle(
                                                  fontSize: shouldHighlight && isOriginalLine
                                                      ? _settings.originalFontSize + 2
                                                      : (isOriginalLine ? _settings.originalFontSize : _settings.translationFontSize),
                                                  fontWeight: shouldHighlight ? FontWeight.w600 : FontWeight.w400,
                                                  color: shouldHighlight
                                                      ? activeColor
                                                      : (played ? playedColor : upcomingColor),
                                                  height: 1.35,
                                                  letterSpacing: 0.2,
                                                ),
                                                child: Text(
                                                  linesToShow[i],
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      // 移除长按提示
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                                ),
                                // 定位按钮
                                if (_isManualScrolling && _currentLyricIndex >= 0)
                                  Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: FloatingActionButton(
                                      mini: true,
                                      onPressed: _scrollToCurrentPlayingLyric,
                                      child: const Icon(Icons.my_location, size: 20),
                                      tooltip: '定位到当前歌词',
                                    ),
                                  ),
                              ],
                            ),
                    ],
                  ),
                ),

                // 播放进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LyricsUtils.formatDuration(effectivePos),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          Text(
                            LyricsUtils.formatDuration(_totalDuration),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(
                          context,
                        ).copyWith(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), trackHeight: 2),
                        child: Slider(
                          value: _totalDuration.inMilliseconds > 0
                              ? (effectivePos.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Colors.grey.shade700,
                          onChangeStart: (_) {
                            _isSeeking = true;
                            _seekPreview = effectivePos;
                            setState(() {});
                          },
                          onChanged: (value) {
                            if (_totalDuration.inMilliseconds > 0) {
                              final newPosition = Duration(
                                milliseconds: (value * _totalDuration.inMilliseconds).toInt(),
                              );
                              _seekPreview = newPosition;
                              // 拖动时即时更新“预览高亮/已播放颜色”
                              _updateCurrentLyric(_seekPreview);
                              setState(() {});
                            }
                          },
                          onChangeEnd: (value) async {
                            if (_totalDuration.inMilliseconds > 0) {
                              final newPosition = Duration(
                                milliseconds: ((value.clamp(0.0, 1.0)) * _totalDuration.inMilliseconds).toInt(),
                              );
                              await _seekTo(newPosition);
                              // 确保歌词位置同步更新并强制滚动
                              if (mounted) {
                                _currentPosition = newPosition;
                                _updateCurrentLyric(newPosition);
                                _isManualScrolling = false;
                                if (_currentLyricIndex >= 0 && _currentLyricIndex < _lyricKeys.length) {
                                  _scrollToCurrentLyric(_currentLyricIndex, force: true);
                                }
                                setState(() {});
                              }
                            } else {
                              _isSeeking = false;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 播放控制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 上一曲
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 32,
                        onPressed: () async {
                          await playListProvider.playPrev();
                          _initLyrics();
                          _updateDuration();
                        },
                      ),
                      const SizedBox(width: 24),
                      // 播放/暂停 - 使用StreamBuilder确保状态正确
                      StreamBuilder<bool>(
                        stream: MusicService.playingStream,
                        initialData: MusicService.isPlaying,
                        builder: (context, snapshot) {
                          final isPlayingNow = snapshot.data ?? false;
                          return GestureDetector(
                            onTap: () {
                              if (isPlayingNow) {
                                MusicService().pause();
                              } else {
                                // 如果当前没有播放，检查是否需要从当前位置继续
                                final currentSong = playListProvider.currentSong ?? song;
                                if (MusicService.duration != null && _currentPosition.inMilliseconds > 0) {
                                  // 从当前位置继续播放
                                  MusicService().seek(_currentPosition);
                                  MusicService().resume();
                                } else {
                                  // 播放新歌曲
                                  MusicService().playSong(currentSong);
                                }
                              }
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(isPlayingNow ? Icons.pause : Icons.play_arrow, size: 36, color: Colors.white),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      // 下一曲
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32,
                        onPressed: () async {
                          await playListProvider.playNext();
                          _initLyrics();
                          _updateDuration();
                        },
                      ),
                    ],
                  ),
                ),

                // 底部功能按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate),
                        onPressed: _showLyricStyleSheet,
                        tooltip: '歌词样式',
                      ),
                      // 显示模式切换按钮（替代长按）
                      IconButton(
                        icon: const Icon(Icons.view_agenda),
                        onPressed: _toggleDisplayMode,
                        tooltip: '切换显示模式',
                      ),
                      // 播放模式按钮
                      Consumer<PlayListProvider>(
                        builder: (context, provider, _) {
                          return IconButton(
                            icon: Icon(_getPlaybackModeIcon(provider.playbackMode)),
                            onPressed: () {
                              _showPlaybackModeSheet(context, provider);
                            },
                            tooltip: provider.playbackMode.displayName,
                          );
                        },
                      ),
                      // 定时关闭按钮
                      IconButton(
                        icon: Icon(_isTimerActive ? Icons.timer_off : Icons.timer),
                        color: _isTimerActive ? Theme.of(context).colorScheme.primary : null,
                        onPressed: () {
                          _showTimerSheet(context, playListProvider);
                        },
                        tooltip: _isTimerActive ? '取消定时关闭' : '定时关闭',
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_play),
                        onPressed: () {
                          _showPlayListSheet(context, playListProvider);
                        },
                        tooltip: '播放列表',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}
