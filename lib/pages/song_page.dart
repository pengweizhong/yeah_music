import 'dart:async';
import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';

var log = Logger(printer: SimplePrinter());

class SongPage extends StatefulWidget {
  int index;
  final int initialPage;

  SongPage({super.key, required this.index, this.initialPage = 0});

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
  late ScrollController _scrollController;

  /// 与当前已加载歌词对应的曲目路径（build 中用于检测切歌，需与 [ _lyricsHydratedForPath ] 同步）
  String? _lyricsBoundSongPath;

  /// 已完成歌词数据与滚动对齐的曲路径；用于避免首帧无歌词、以及 initState 的 postFrame 重复 [_initLyrics]
  String? _lyricsHydratedForPath;

  // 歌词显示配置（从设置加载）
  late LyricSettings _settings;

  // 多语言切换显示模式：-1=全部显示，0=只显示第1行，1=只显示第2行，...
  Map<int, int> _lyricDisplayMode = {}; // key: lyric index, value: display mode

  // 拖动进度条时的预览
  bool _isSeeking = false;
  bool _isJumpingPosition = false;
  int _seekRequestId = 0;
  Duration? _lastSeekTarget;
  DateTime? _ignoreStalePositionUntil;
  Duration _seekPreview = Duration.zero;

  late final PageController _pageController;
  int _currentPage = 0; // 0=封皮，1=歌词
  bool _pageStateLoaded = false; // 标记页面状态是否已加载

  // 手动滚动控制
  bool _isManualScrolling = false;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _settings = LyricSettings(); // 初始化默认设置
    final initialPage = widget.initialPage.clamp(0, 1);
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _loadSettings();
    _listenToPlayer();
    _initPostFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在首帧 build 前尽量解析好歌词，避免先闪「暂无/黑底」再出现列表
    _tryEagerHydrateLyrics();
  }

  void _tryEagerHydrateLyrics() {
    if (!mounted) return;
    final p = Provider.of<PlayListProvider>(context, listen: false);
    if (p.playList.isEmpty) return;
    final idx = widget.index.clamp(0, p.playList.length - 1);
    final song = p.playList[idx];
    if (_lyricsHydratedForPath == song.path) return;
    _applySongLyrics(song);
  }

  void _initPostFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 用路由传入的 index 初始化当前播放索引
      final playListProvider = Provider.of<PlayListProvider>(
        context,
        listen: false,
      );
      if (playListProvider.playList.isNotEmpty) {
        final targetIndex = widget.index;
        final currentIndex = playListProvider.currentIndex;
        final currentSong = playListProvider.currentSong;
        final targetSong =
            playListProvider.playList[targetIndex.clamp(
              0,
              playListProvider.playList.length - 1,
            )];

        // 如果点击的是同一首歌曲，只设置索引，不播放
        if (currentIndex == targetIndex ||
            (currentSong != null && currentSong.path == targetSong.path)) {
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
        if (savedPage == _currentPage) return;
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
    final playListProvider = Provider.of<PlayListProvider>(
      context,
      listen: false,
    );
    playListProvider.setPlaybackMode(mode);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _scrollTimer?.cancel();
    _scrollTimer?.cancel();
    // 延迟保存设置，避免在dispose时访问已关闭的box
    Future.microtask(() => _saveSettings());
    super.dispose();
  }

  /// 用于 [ScrollController.initialScrollOffset]，使首帧即接近当前行，避免先整屏从顶再跳
  double _lineScrollUnitEstimate() {
    final o = _settings.originalFontSize;
    final t = _settings.translationFontSize;
    final sp = _settings.lyricLineSpacing;
    return o * 1.35 + t * 1.35 + sp + 28;
  }

  void _initLyrics() {
    final playListProvider = Provider.of<PlayListProvider>(
      context,
      listen: false,
    );
    final currentSong = playListProvider.currentSong;
    if (currentSong == null) return;
    if (_lyricsHydratedForPath == currentSong.path) return;
    _applySongLyrics(currentSong);
  }

  void _applySongLyrics(Song song) {
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      final pos = MusicService.lastPosition;
      final parsed = LyricsUtils.parseLyrics(song.lyrics!);
      final lineIndex = LyricsUtils.findCurrentLyricIndex(parsed, pos);
      final scrollLine = lineIndex >= 0 ? lineIndex : 0;
      final initialOffset = parsed.length <= 1
          ? 0.0
          : (scrollLine * _lineScrollUnitEstimate()).clamp(0.0, double.infinity);

      _scrollController.dispose();
      _scrollController = ScrollController(initialScrollOffset: initialOffset);

      setState(() {
        _lyricsBoundSongPath = song.path;
        _lyricsHydratedForPath = song.path;
        _currentPosition = pos;
        _lyrics = parsed;
        _lyricKeys = List<GlobalKey>.generate(
          _lyrics.length,
          (_) => GlobalKey(),
        );
        for (var line in _lyrics) {
          line.isActive = false;
        }
        if (lineIndex >= 0 && lineIndex < _lyrics.length) {
          _lyrics[lineIndex].isActive = true;
          _currentLyricIndex = lineIndex;
        } else {
          _currentLyricIndex = -1;
        }
      });
      // 再一帧瞬时微调行高误差/未建全的 item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _lyrics.isEmpty) return;
        if (_currentLyricIndex >= 0) {
          _scrollToCurrentLyric(
            _currentLyricIndex,
            force: true,
            instant: true,
          );
        }
      });
    } else {
      _scrollController.dispose();
      _scrollController = ScrollController();
      setState(() {
        _lyricsBoundSongPath = song.path;
        _lyricsHydratedForPath = song.path;
        _lyrics = [];
        _lyricKeys = [];
        _currentLyricIndex = -1;
      });
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
        if (!_isSeeking && !_isJumpingPosition) {
          final target = _lastSeekTarget;
          final ignoreUntil = _ignoreStalePositionUntil;
          if (target != null &&
              ignoreUntil != null &&
              DateTime.now().isBefore(ignoreUntil) &&
              (position - target).abs() > const Duration(seconds: 2)) {
            return;
          }
          if (ignoreUntil != null && !DateTime.now().isBefore(ignoreUntil)) {
            _lastSeekTarget = null;
            _ignoreStalePositionUntil = null;
          }
          _currentPosition = position;
          _updateCurrentLyric(position, instantScroll: false);
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
            _updateCurrentLyric(_currentPosition, instantScroll: true);
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
    // 自动切歌由 PlayListProvider 全局订阅 completion，避免离开本页后无法连播
  }

  void _updateCurrentLyric(
    Duration position, {
    bool instantScroll = false,
  }) {
    final newIndex = LyricsUtils.findCurrentLyricIndex(_lyrics, position);
    // 即使索引相同，也要更新激活状态，确保UI同步
    if (newIndex >= 0 && newIndex < _lyrics.length) {
      // 重置所有行的激活状态
      for (var line in _lyrics) {
        line.isActive = false;
      }
      // 设置当前行为激活状态
      _lyrics[newIndex].isActive = true;

      // 如果索引变化，更新并滚动；初次瞬时对齐时索引从 -1 变到当前，也用 instant
      if (newIndex != _currentLyricIndex || instantScroll) {
        _currentLyricIndex = newIndex;
        // 滚动到当前歌词行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLyric(
              newIndex,
              instant: instantScroll,
            );
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

  void _scrollToCurrentLyric(
    int index, {
    bool force = false,
    bool instant = false,
  }) {
    // 如果正在手动滚动且不是强制滚动，则不自动滚动
    if (_isManualScrolling && !force) return;
    if (!_scrollController.hasClients) return;

    if (index < 0 || index >= _lyricKeys.length) return;
    final ctx = _lyricKeys[index].currentContext;
    if (ctx != null) {
      // 目标行已经构建时，直接精确居中。
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: instant ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    // ListView.builder 只构建可见区域附近的歌词。跳转距离较远时，目标行还没有 context，
    // 需要先用索引比例滚到目标附近，等待目标行构建后再精确定位。
    final pos = _scrollController.position;
    final maxExtent = pos.maxScrollExtent;
    if (maxExtent <= 0 || _lyrics.length <= 1) {
      if (instant) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLyric(index, force: force, instant: instant);
          }
        });
      }
      return;
    }

    final estimatedOffset = (maxExtent * (index / (_lyrics.length - 1))).clamp(
      pos.minScrollExtent,
      maxExtent,
    );
    if (instant) {
      _scrollController.jumpTo(estimatedOffset);
    } else {
      _scrollController.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final builtCtx = _lyricKeys[index].currentContext;
      if (builtCtx != null) {
        Scrollable.ensureVisible(
          builtCtx,
          alignment: 0.5,
          duration: instant ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
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

  void _showPlayListSheet(
    BuildContext context,
    PlayListProvider playListProvider,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final h = MediaQuery.sizeOf(sheetContext).height * 0.56;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: FrostedGlassBottomSheet(
            child: SafeArea(
              child: SizedBox(
                height: h,
                child: _PlaybackQueueSheet(
                  provider: playListProvider,
                  onPick: (index) async {
                    Navigator.pop(sheetContext);
                    await playListProvider.playAt(index);
                    _initLyrics();
                    _updateDuration();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLyricStyleSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FrostedGlassBottomSheet(
            child: Theme(
              data: frostedBottomSheetContentTheme(sheetContext),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
                  ),
                  child: StatefulBuilder(
                    builder: (context, setModalState) {
              Widget switchRow(
                String title,
                bool value,
                ValueChanged<bool> onChanged,
              ) {
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

              Widget sliderRow(
                String title,
                double value,
                double min,
                double max,
                ValueChanged<double> onChanged,
              ) {
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

              Future<void> pickColor(
                String title,
                Color currentColor,
                ValueChanged<Color> onChanged,
              ) async {
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
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      child: Theme(
                        data: frostedDialogContentTheme(dialogContext),
                        child: FrostedGlassDialog(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
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
                                            color: currentColor == color
                                                ? Theme.of(dialogContext)
                                                    .colorScheme
                                                    .primary
                                                : Colors.white30,
                                            width: currentColor == color
                                                ? 3
                                                : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              Widget colorRow(
                String title,
                Color color,
                ValueChanged<Color> onChanged,
              ) {
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
                      child: Text(
                        '歌词显示设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    switchRow('显示原文（每个时间戳第 1 行）', _settings.showOriginal, (v) {
                      _settings.showOriginal = v;
                      _saveSettings();
                    }),
                    switchRow(
                      '显示翻译/附加行（第 2..n 行）',
                      _settings.showTranslations,
                      (v) {
                        _settings.showTranslations = v;
                        _saveSettings();
                      },
                    ),
                    sliderRow('原文字号', _settings.originalFontSize, 14, 28, (v) {
                      _settings.originalFontSize = v;
                      _saveSettings();
                    }),
                    sliderRow('翻译字号', _settings.translationFontSize, 10, 22, (
                      v,
                    ) {
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
                      child: Text(
                        '颜色设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '当前播放行',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    colorRow('原文颜色', Color(_settings.activeOriginalColor), (v) {
                      _settings.activeOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow('翻译颜色', Color(_settings.activeTranslationColor), (
                      v,
                    ) {
                      _settings.activeTranslationColor = v.value;
                      _saveSettings();
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '已播放行',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    colorRow('原文颜色', Color(_settings.playedOriginalColor), (v) {
                      _settings.playedOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow('翻译颜色', Color(_settings.playedTranslationColor), (
                      v,
                    ) {
                      _settings.playedTranslationColor = v.value;
                      _saveSettings();
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '未播放行',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    colorRow('原文颜色', Color(_settings.upcomingOriginalColor), (
                      v,
                    ) {
                      _settings.upcomingOriginalColor = v.value;
                      _saveSettings();
                    }),
                    colorRow(
                      '翻译颜色',
                      Color(_settings.upcomingTranslationColor),
                      (v) {
                        _settings.upcomingTranslationColor = v.value;
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              );
                    },
                  ),
                ),
              ),
            ),
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
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FrostedGlassBottomSheet(
            child: Theme(
              data: frostedBottomSheetContentTheme(sheetContext),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        '播放模式',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ...PlaybackMode.values.map((mode) {
                      final isSelected = provider.playbackMode == mode;
                      return ListTile(
                        leading: Icon(
                          _getPlaybackModeIcon(mode),
                          color: Colors.white,
                        ),
                        title: Text(mode.displayName),
                        trailing: isSelected
                            ? Icon(Icons.check, color: primary)
                            : null,
                        onTap: () {
                          provider.setPlaybackMode(mode);
                          SettingsService.savePlaybackMode(mode);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _presetTimerMinutes = [15, 30, 45, 60, 90, 120];
  static const int _customTimerMinMinutes = 1;
  static const int _customTimerMaxMinutes = 600;

  /// 自定义定时分钟数（返回 null 表示取消）
  Future<int?> _promptCustomTimerMinutes(
    BuildContext dialogContext,
    int initialMinutes,
  ) {
    final controller = TextEditingController(
      text: initialMinutes > 0 ? '$initialMinutes' : '',
    );
    return showDialog<int>(
      context: dialogContext,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Theme(
            data: frostedDialogContentTheme(ctx),
            child: FrostedGlassDialog(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '自定义时间',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '分钟',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        hintText:
                            '$_customTimerMinMinutes–$_customTimerMaxMinutes',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.primary),
                        ),
                      ),
                      autofocus: true,
                      onSubmitted: (_) => _submitCustomTimer(ctx, controller),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => _submitCustomTimer(ctx, controller),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _submitCustomTimer(BuildContext ctx, TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    if (v == null || v < _customTimerMinMinutes || v > _customTimerMaxMinutes) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '请输入 $_customTimerMinMinutes–$_customTimerMaxMinutes 之间的整数',
          ),
        ),
      );
      return;
    }
    Navigator.pop(ctx, v);
  }

  // 显示定时关闭弹窗
  void _showTimerSheet(BuildContext context, PlayListProvider provider) {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isCustom = provider.isSleepTimerActive &&
            !_presetTimerMinutes.contains(provider.timerDuration);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FrostedGlassBottomSheet(
            child: Theme(
              data: frostedBottomSheetContentTheme(sheetContext),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        '定时关闭',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (provider.isSleepTimerActive)
                      ListTile(
                        leading: const Icon(Icons.timer_off, color: Colors.white),
                        title: const Text('取消定时关闭'),
                        onTap: () {
                          provider.cancelSleepTimer();
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ..._presetTimerMinutes.map((minutes) {
                      return ListTile(
                        leading: const Icon(Icons.timer, color: Colors.white),
                        title: Text('$minutes 分钟'),
                        trailing: provider.timerDuration == minutes &&
                                provider.isSleepTimerActive
                            ? Icon(Icons.check, color: primary)
                            : null,
                        onTap: () {
                          _startSleepTimer(minutes, provider);
                          Navigator.pop(sheetContext);
                        },
                      );
                    }),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, color: Colors.white),
                      title: const Text('自定义时间'),
                      subtitle: isCustom
                          ? Text('当前 ${provider.timerDuration} 分钟')
                          : null,
                      trailing: isCustom
                          ? Icon(Icons.check, color: primary)
                          : null,
                      onTap: () async {
                        final minutes = await _promptCustomTimerMinutes(
                          sheetContext,
                          provider.timerDuration,
                        );
                        if (!mounted || minutes == null) return;
                        _startSleepTimer(minutes, provider);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 定时关闭由 [PlayListProvider] 持有，避免离开播放页后 [Timer] 被 dispose 取消
  void _startSleepTimer(int minutes, PlayListProvider provider) {
    provider.startSleepTimer(minutes);
  }

  Duration _effectivePosition() => _isSeeking ? _seekPreview : _currentPosition;

  Future<void> _seekTo(Duration target) async {
    if (_totalDuration.inMilliseconds > 0 && target > _totalDuration) {
      target = _totalDuration;
    }
    if (target < Duration.zero) {
      target = Duration.zero;
    }

    final requestId = ++_seekRequestId;

    _scrollTimer?.cancel();
    _isSeeking = false;
    _isJumpingPosition = true;
    _isManualScrolling = false;
    _currentPosition = target;
    _seekPreview = target;
    _lastSeekTarget = target;
    _ignoreStalePositionUntil = DateTime.now().add(
      const Duration(milliseconds: 1200),
    );
    _updateCurrentLyric(target);
    if (mounted) setState(() {});

    try {
      await MusicService().pause();
      await MusicService().seek(target);
      if (!mounted || requestId != _seekRequestId) return;

      _currentPosition = target;
      _seekPreview = target;
      _lastSeekTarget = target;
      _ignoreStalePositionUntil = DateTime.now().add(
        const Duration(milliseconds: 1200),
      );
      _updateCurrentLyric(target);
      _isJumpingPosition = false;
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            requestId == _seekRequestId &&
            _currentLyricIndex >= 0 &&
            _currentLyricIndex < _lyricKeys.length) {
          _scrollToCurrentLyric(_currentLyricIndex, force: true);
        }
      });

      MusicService().play();
    } catch (e) {
      log.e("跳转播放位置失败：$e");
    } finally {
      if (mounted && requestId == _seekRequestId) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted || requestId != _seekRequestId) return;
          _isJumpingPosition = false;
          setState(() {});
        });
      } else if (requestId == _seekRequestId) {
        _isJumpingPosition = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayListProvider, ThemeConfigProvider>(
      builder: (context, playListProvider, themeConfig, childWidget) {
        if (playListProvider.playList.isEmpty) {
          return themeConfig.buildThemedBackground(
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text(
                  '歌曲不存在',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        final song =
            playListProvider.currentSong ?? playListProvider.playList.first;
        // 使用StreamBuilder来监听播放状态，确保按钮状态正确
        final effectivePos = _effectivePosition();

        final sp = song.path;
        if (sp != _lyricsBoundSongPath) {
          _lyricsBoundSongPath = sp;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initLyrics();
              _updateDuration();
            }
          });
        }

        return themeConfig.buildThemedBackground(
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: Column(
                children: [
                  // 顶部栏：与主页一致，浅色字叠在全局背景上
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title ?? '未知标题',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
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
                                    color: Colors.white.withValues(alpha: 0.65),
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
                          color: Colors.white,
                          onPressed: () {
                            _showPlayListSheet(context, playListProvider);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 封皮 / 歌词区：透明，透出 [buildThemedBackground] 与主页相同
                  Expanded(
                    child: ScrollConfiguration(
                    // 支持鼠标滑动
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      // 启用页面滑动
                      scrollDirection: Axis.horizontal,
                      // 水平滑动
                      allowImplicitScrolling: false,
                      reverse: false,
                      // 正常顺序：0=封皮，1=歌词
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                        _savePageState(); // 保存页面状态
                        if (index == 1 && _lyrics.isNotEmpty) {
                          // 从封面切到歌词时瞬时对齐，避免先看到顶再滚到当前行
                          _isManualScrolling = false;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _updateCurrentLyric(
                              _effectivePosition(),
                              instantScroll: true,
                            );
                          });
                        }
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
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Image(
                                    image:
                                        ApplicationUtils.getImageCoverProvider(
                                          song,
                                          size: 400,
                                        ),
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
                                    Icon(
                                      Icons.music_note,
                                      size: 64,
                                      color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无歌词',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification
                                          is UserScrollNotification) {
                                        _onUserScroll();
                                      }
                                      return false;
                                    },
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      physics: const ClampingScrollPhysics(),
                                      // 使用ClampingScrollPhysics，允许PageView处理水平滑动
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                      itemCount: _lyrics.length,
                                      itemBuilder: (context, index) {
                                        final line = _lyrics[index];
                                        final ts = line.timestamp;
                                        final played =
                                            ts != null && ts <= effectivePos;
                                        final active = line.isActive;

                                        // 根据显示模式决定显示哪些行（使用全局模式或该行的特定模式）
                                        final lineSpecificMode =
                                            _lyricDisplayMode[index];
                                        final displayMode =
                                            lineSpecificMode ??
                                            _globalDisplayMode; // 优先使用行特定模式，否则使用全局模式
                                        final linesToShow = <String>[];

                                        if (displayMode == -1) {
                                          // 全部显示
                                          if (_settings.showOriginal &&
                                              line.lines.isNotEmpty) {
                                            linesToShow.add(line.lines[0]);
                                          }
                                          if (_settings.showTranslations &&
                                              line.lines.length > 1) {
                                            linesToShow.addAll(
                                              line.lines.sublist(1),
                                            );
                                          }
                                        } else if (displayMode <
                                            line.lines.length) {
                                          // 只显示指定行
                                          linesToShow.add(
                                            line.lines[displayMode],
                                          );
                                        } else {
                                          // 容错：如果模式超出范围，显示全部
                                          if (_settings.showOriginal &&
                                              line.lines.isNotEmpty) {
                                            linesToShow.add(line.lines[0]);
                                          }
                                          if (_settings.showTranslations &&
                                              line.lines.length > 1) {
                                            linesToShow.addAll(
                                              line.lines.sublist(1),
                                            );
                                          }
                                        }

                                        final isShowingAll = displayMode == -1;
                                        final isShowingSingleLine =
                                            displayMode >= 0 &&
                                            displayMode < line.lines.length;

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical:
                                                _settings.lyricLineSpacing / 2,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: ts == null
                                                ? null
                                                : () => _seekTo(ts),
                                            child: Container(
                                              key:
                                                  _lyricKeys.length ==
                                                      _lyrics.length
                                                  ? _lyricKeys[index]
                                                  : null,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 8,
                                                  ),
                                              child: Column(
                                                children: [
                                                  for (
                                                    int i = 0;
                                                    i < linesToShow.length;
                                                    i++
                                                  )
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: i > 0 ? 4 : 0,
                                                      ),
                                                      child: Builder(
                                                        builder: (context) {
                                                          // 确定当前显示的行在原始lines中的索引
                                                          final originalIndex =
                                                              isShowingAll
                                                              ? i
                                                              : displayMode;
                                                          final isOriginalLine =
                                                              originalIndex ==
                                                              0;

                                                          // 如果显示全部且是当前行，所有行都高亮
                                                          final shouldHighlight =
                                                              active &&
                                                              ((isShowingAll) ||
                                                                  (isShowingSingleLine &&
                                                                      originalIndex ==
                                                                          displayMode));

                                                          final activeColor = Color(
                                                            isOriginalLine
                                                                ? _settings
                                                                      .activeOriginalColor
                                                                : _settings
                                                                      .activeTranslationColor,
                                                          );
                                                          final playedColor = Color(
                                                            isOriginalLine
                                                                ? _settings
                                                                      .playedOriginalColor
                                                                : _settings
                                                                      .playedTranslationColor,
                                                          );
                                                          final upcomingColor = Color(
                                                            isOriginalLine
                                                                ? _settings
                                                                      .upcomingOriginalColor
                                                                : _settings
                                                                      .upcomingTranslationColor,
                                                          );
                                                          return AnimatedDefaultTextStyle(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      160,
                                                                ),
                                                            style: TextStyle(
                                                              fontSize:
                                                                  shouldHighlight &&
                                                                      isOriginalLine
                                                                  ? _settings
                                                                            .originalFontSize +
                                                                        2
                                                                  : (isOriginalLine
                                                                        ? _settings
                                                                              .originalFontSize
                                                                        : _settings
                                                                              .translationFontSize),
                                                              fontWeight:
                                                                  shouldHighlight
                                                                  ? FontWeight
                                                                        .w600
                                                                  : FontWeight
                                                                        .w400,
                                                              color:
                                                                  shouldHighlight
                                                                  ? activeColor
                                                                  : (played
                                                                        ? playedColor
                                                                        : upcomingColor),
                                                              height: 1.35,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                            child: Text(
                                                              linesToShow[i],
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
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
                                  if (_isManualScrolling &&
                                      _currentLyricIndex >= 0)
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: FloatingActionButton(
                                        mini: true,
                                        onPressed: _scrollToCurrentPlayingLyric,
                                        child: const Icon(
                                          Icons.my_location,
                                          size: 20,
                                        ),
                                        tooltip: '定位到当前歌词',
                                      ),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                // 播放进度条
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LyricsUtils.formatDuration(effectivePos),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          Text(
                            LyricsUtils.formatDuration(_totalDuration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _totalDuration.inMilliseconds > 0
                              ? (effectivePos.inMilliseconds /
                                        _totalDuration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                              : 0.0,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Colors.white.withValues(alpha: 0.25),
                          onChangeStart: (_) {
                            _isSeeking = true;
                            _seekPreview = effectivePos;
                            setState(() {});
                          },
                          onChanged: (value) {
                            if (_totalDuration.inMilliseconds > 0) {
                              final newPosition = Duration(
                                milliseconds:
                                    (value * _totalDuration.inMilliseconds)
                                        .toInt(),
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
                                milliseconds:
                                    ((value.clamp(0.0, 1.0)) *
                                            _totalDuration.inMilliseconds)
                                        .toInt(),
                              );
                              await _seekTo(newPosition);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 上一曲
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        color: Colors.white,
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
                            onTap: () async {
                              if (isPlayingNow) {
                                MusicService().pause();
                              } else {
                                // 如果当前没有播放，检查是否需要从当前位置继续
                                final currentSong =
                                    playListProvider.currentSong ?? song;
                                if (MusicService.duration != null &&
                                    _currentPosition.inMilliseconds > 0) {
                                  // 从当前位置继续播放
                                  MusicService().seek(_currentPosition);
                                  MusicService().resume();
                                } else {
                                  // 播放新歌曲（不经过 [playAt] 时需补记最近播放）
                                  await MusicService().playSong(currentSong);
                                  if (!context.mounted) return;
                                  await playListProvider.recordRecentForCurrent();
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlayingNow ? Icons.pause : Icons.play_arrow,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      // 下一曲
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate),
                        color: Colors.white,
                        onPressed: _showLyricStyleSheet,
                        tooltip: '歌词样式',
                      ),
                      // 显示模式切换按钮（替代长按）
                      IconButton(
                        icon: const Icon(Icons.view_agenda),
                        color: Colors.white,
                        onPressed: _toggleDisplayMode,
                        tooltip: '切换显示模式',
                      ),
                      // 播放模式按钮
                      Consumer<PlayListProvider>(
                        builder: (context, provider, _) {
                          return IconButton(
                            icon: Icon(
                              _getPlaybackModeIcon(provider.playbackMode),
                            ),
                            color: Colors.white,
                            onPressed: () {
                              _showPlaybackModeSheet(context, provider);
                            },
                            tooltip: provider.playbackMode.displayName,
                          );
                        },
                      ),
                      // 定时关闭按钮
                      IconButton(
                        icon: Icon(
                          playListProvider.isSleepTimerActive
                              ? Icons.timer_off
                              : Icons.timer,
                        ),
                        color: playListProvider.isSleepTimerActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        onPressed: () {
                          _showTimerSheet(context, playListProvider);
                        },
                        tooltip: playListProvider.isSleepTimerActive
                            ? '取消定时关闭'
                            : '定时关闭',
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        color: Colors.white,
                        onPressed: () {
                          final song = playListProvider.currentSong;
                          if (song == null) return;
                          showAddToUserPlaylistsSheet(context, song);
                        },
                        tooltip: '加入歌单',
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_play),
                        color: Colors.white,
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
        ),
        );
      },
    );
  }
}

/// 播放队列底部表单：定位当前曲目、高亮当前行、动态播放指示器
class _PlaybackQueueSheet extends StatefulWidget {
  const _PlaybackQueueSheet({
    required this.provider,
    required this.onPick,
  });

  final PlayListProvider provider;
  final Future<void> Function(int index) onPick;

  @override
  State<_PlaybackQueueSheet> createState() => _PlaybackQueueSheetState();
}

class _PlaybackQueueSheetState extends State<_PlaybackQueueSheet> {
  final GlobalKey _playingRowKey = GlobalKey();
  late int _lastHeardIndex;

  @override
  void initState() {
    super.initState();
    _lastHeardIndex = widget.provider.currentIndex;
    widget.provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCurrentIntoView(animated: false));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCurrentIntoView(animated: false));
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final idx = widget.provider.currentIndex;
    final indexMoved = idx != _lastHeardIndex;
    _lastHeardIndex = idx;
    setState(() {});
    if (indexMoved) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCurrentIntoView(animated: true));
    }
  }

  void _scrollCurrentIntoView({required bool animated}) {
    final ctx = _playingRowKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.22,
      duration: animated ? const Duration(milliseconds: 320) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final list = provider.playList;
    final primary = Theme.of(context).colorScheme.primary;

    if (list.isEmpty) {
      return Center(
        child: Text(
          '暂无曲目',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            '播放队列',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: list.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            itemBuilder: (context, index) {
              final s = list[index];
              final isCurrent = index == provider.currentIndex;
              return ListTile(
                key: isCurrent ? _playingRowKey : ValueKey<String>('${index}_${s.path}'),
                selected: isCurrent,
                selectedColor: primary,
                selectedTileColor: primary.withValues(alpha: 0.16),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
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
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: isCurrent ? primary : Colors.white,
                  ),
                ),
                subtitle: Text(
                  s.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? primary.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                trailing: isCurrent
                    ? _PlayingBarsIndicator(color: primary)
                    : null,
                onTap: () => widget.onPick(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 随节拍起伏的条形播放指示器
class _PlayingBarsIndicator extends StatefulWidget {
  const _PlayingBarsIndicator({required this.color});

  final Color color;

  @override
  State<_PlayingBarsIndicator> createState() => _PlayingBarsIndicatorState();
}

class _PlayingBarsIndicatorState extends State<_PlayingBarsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        const barCount = 4;
        return SizedBox(
          width: 22,
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final wave = sin(t + i * 0.85);
              final h = 4.0 + 12.0 * ((wave + 1) / 2);
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
