import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/playback_mode.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/music_tag_editor_launcher.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/song_metadata_reload_utils.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/onedrive_queue_navigation.dart';
import 'package:yeah_music/utils/playback_mode_l10n.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';
import 'package:yeah_music/utils/lyric_highlight_gradient.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/auto_marquee_single_line_text.dart';
import 'package:yeah_music/widgets/desktop_floating_lyrics_host.dart';
import 'package:yeah_music/widgets/lyric_style_settings_panel.dart';
import 'package:yeah_music/widgets/playing_bars_indicator.dart';
import 'package:yeah_music/widgets/scroll_to_current_locate_layer.dart';
import 'package:yeah_music/widgets/song_inline_tags_editor_sheet.dart';
import 'package:yeah_music/widgets/song_list_cover.dart';
import 'package:yeah_music/widgets/song_list_marquee_when_current_line.dart';
import 'package:yeah_music/widgets/song_metadata_dialog.dart'
    show showAudioMetadataDialog;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show AudioMetadata;

class SongPage extends StatefulWidget {
  int index;
  final int initialPage;

  SongPage({super.key, required this.index, this.initialPage = 0});

  @override
  State<StatefulWidget> createState() {
    return _SongPageState();
  }
}

class _SongPageState extends State<SongPage> with WidgetsBindingObserver {
  List<LyricEntry> _lyrics = [];
  List<GlobalKey> _lyricKeys = [];
  int _currentLyricIndex = -1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  late ScrollController _scrollController;

  /// 分屏页右侧歌词列表独立滚动，与全屏 [ListView] 解耦
  late ScrollController _splitLyricScrollController;

  /// 分屏页歌词行 [GlobalKey]，与 [_lyricKeys] 一一对应、仅供分屏列表 [ensureVisible]
  List<GlobalKey> _lyricKeysSplit = [];

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
  int _currentPage = 0; // 0=封皮，1=全屏歌词，2=分屏(左封皮·右歌词)
  bool _pageStateLoaded = false; // 标记页面状态是否已加载

  /// 播放页保持屏幕常亮（偏好持久化于 Hive）
  bool _keepScreenAwake = false;

  /// 已成功跳转外部音频编辑器（标签 / 歌词）；回到前台后对该路径重新 [FileUtils.loadSongMeta]。
  String? _pendingExternalAudioReloadPath;

  // 手动滚动控制
  bool _isManualScrolling = false;
  Timer? _scrollTimer;
  late final VoidCallback _lyricsUiRevListener;

  @override
  void initState() {
    super.initState();
    _lyricsUiRevListener = () {
      if (!mounted) return;
      unawaited(_reloadLyricsUiFromHiveExternalNotification());
    };
    SettingsService.lyricsUiStorageRevision.addListener(_lyricsUiRevListener);
    _scrollController = ScrollController();
    _settings = LyricSettings(); // 初始化默认设置
    final initialPage = widget.initialPage.clamp(0, 2);
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _splitLyricScrollController = ScrollController();
    _loadSettings();
    _listenToPlayer();
    unawaited(_loadKeepAwakePreference());
    _initPostFrame();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    final pending = _pendingExternalAudioReloadPath;
    if (pending == null || pending.isEmpty) return;
    _pendingExternalAudioReloadPath = null;
    unawaited(_reloadSongMetaAfterResumeFromExternalEditor(pending));
  }

  /// 从第三方编辑器返回后重载；Android 上略延迟以减少与原生合并缓存 / 系统写盘的竞态，并触发媒体扫描。
  Future<void> _reloadSongMetaAfterResumeFromExternalEditor(String path) async {
    if (Platform.isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await MusicTagEditorLauncher.scanAudioFileAfterExternalEdit(path);
    }
    if (!mounted) return;
    await _reloadSongMetaAfterExternalMusicTagEdit(path);
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
      // 从迷你条等仅 push [SongPage] 而无 [navToSongPage] 时补标「全库」；不覆盖最近/歌单/adHoc 会话
      if (!playListProvider.hasPlaybackQueueOverride) {
        final keepNonLibrary =
            playListProvider.playbackSessionIsRecentList ||
            playListProvider.playbackSessionIsMostPlayedList ||
            playListProvider.playbackSessionIsUserPlaylistKind ||
            playListProvider.playbackSessionIsAdHoc;
        if (!keepNonLibrary) {
          playListProvider.setPlaybackListSessionForLibrary();
        }
      }
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
      if (savedPage != null && savedPage >= 0 && savedPage <= 2) {
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
      saved.normalizeLayoutFields();
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
      ..lyricTextAlignIndex = _settings.lyricTextAlignIndex
      ..activeOriginalColor = _settings.activeOriginalColor
      ..activeTranslationColor = _settings.activeTranslationColor
      ..playedOriginalColor = _settings.playedOriginalColor
      ..playedTranslationColor = _settings.playedTranslationColor
      ..upcomingOriginalColor = _settings.upcomingOriginalColor
      ..upcomingTranslationColor = _settings.upcomingTranslationColor
      ..activeLyricUseGradient = _settings.activeLyricUseGradient
      ..activeLyricGradientStart = _settings.activeLyricGradientStart
      ..activeLyricGradientEnd = _settings.activeLyricGradientEnd
      ..activeLyricGradientDirectionIndex =
          _settings.activeLyricGradientDirectionIndex
      ..playedLyricUseGradient = _settings.playedLyricUseGradient
      ..playedLyricGradientStart = _settings.playedLyricGradientStart
      ..playedLyricGradientEnd = _settings.playedLyricGradientEnd
      ..playedLyricGradientDirectionIndex =
          _settings.playedLyricGradientDirectionIndex
      ..upcomingLyricUseGradient = _settings.upcomingLyricUseGradient
      ..upcomingLyricGradientStart = _settings.upcomingLyricGradientStart
      ..upcomingLyricGradientEnd = _settings.upcomingLyricGradientEnd
      ..upcomingLyricGradientDirectionIndex =
          _settings.upcomingLyricGradientDirectionIndex
      ..lyricDisplayMode = _lyricDisplayMode;

    await SettingsService.saveLyricSettings(newSettings);
    // 更新当前设置对象
    _settings = newSettings;
    unawaited(MacosMenuBarLyricsGlue.reloadFromHive());
    unawaited(DesktopFloatingLyricsGlue.reloadFromHive());
  }

  Future<void> _reloadLyricsUiFromHiveExternalNotification() async {
    await _loadKeepAwakePreference();
    await _loadSettings();
    if (!mounted) return;
    unawaited(MacosMenuBarLyricsGlue.reloadFromHive());
    unawaited(DesktopFloatingLyricsGlue.reloadFromHive());
  }

  Future<void> _loadKeepAwakePreference() async {
    final v = await SettingsService.loadSongPageKeepScreenAwake();
    if (!mounted) return;
    setState(() => _keepScreenAwake = v);
    if (v) await WakelockPlus.enable();
  }

  Future<void> _setKeepScreenAwake(
    bool enabled, {
    VoidCallback? alsoNotifySheet,
  }) async {
    await SettingsService.saveSongPageKeepScreenAwake(enabled);
    if (!mounted) return;
    setState(() => _keepScreenAwake = enabled);
    alsoNotifySheet?.call();
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
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
    _pendingExternalAudioReloadPath = null;
    SettingsService.lyricsUiStorageRevision.removeListener(
      _lyricsUiRevListener,
    );
    unawaited(WakelockPlus.disable());
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _scrollController.dispose();
    _splitLyricScrollController.dispose();
    _pageController.dispose();
    _scrollTimer?.cancel();
    // 延迟保存设置，避免在dispose时访问已关闭的box
    Future.microtask(() => _saveSettings());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 与曲库重新加载元信息时内嵌封面大小上限一致。
  static const int _songMetaReloadMaxEmbeddedArtBytes = 512 * 1024;

  /// 外部编辑器或应用内标签编辑改写磁盘文件后，刷新 Hive / UI / 媒体通知。
  /// 亦用于「更多 → 重新加载元信息」：凡引用该路径的 [Song] 实例（目录列表、合并曲库、当前队列）均 [FileUtils.loadSongMeta] 并 [Song.save]。
  Future<void> _reloadSongMetaAfterExternalMusicTagEdit(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;

    await reloadAllSongInstancesAfterFileMetadataChanged(
      context,
      trimmed,
      maxEmbeddedArtBytes: _songMetaReloadMaxEmbeddedArtBytes,
      afterProvidersNotify: () {
        if (!mounted) return;
        setState(() {
          _lyricsHydratedForPath = null;
        });
        final play = Provider.of<PlayListProvider>(context, listen: false);
        final cur = play.currentSong;
        if (cur != null && songPathsEqual(cur.path, trimmed)) {
          _applySongLyrics(cur);
          _updateDuration();
        }
      },
    );
  }

  Future<void> _openInlineTagsEditor(
    BuildContext navigatorContext,
    Song song,
  ) async {
    await showSongInlineTagsEditorSheet(
      navigatorContext: navigatorContext,
      song: song,
      onSavedReload: (p) async {
        await _reloadSongMetaAfterExternalMusicTagEdit(p);
      },
    );
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
          : (scrollLine * _lineScrollUnitEstimate()).clamp(
              0.0,
              double.infinity,
            );

      _scrollController.dispose();
      _scrollController = ScrollController(initialScrollOffset: initialOffset);
      _splitLyricScrollController.dispose();
      _splitLyricScrollController = ScrollController(
        initialScrollOffset: initialOffset,
      );

      setState(() {
        _lyricsBoundSongPath = song.path;
        _lyricsHydratedForPath = song.path;
        _currentPosition = pos;
        _lyrics = parsed;
        _lyricKeys = List<GlobalKey>.generate(
          _lyrics.length,
          (_) => GlobalKey(),
        );
        _lyricKeysSplit = List<GlobalKey>.generate(
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
          _scrollToCurrentLyric(_currentLyricIndex, force: true, instant: true);
        }
      });
    } else {
      _scrollController.dispose();
      _scrollController = ScrollController();
      _splitLyricScrollController.dispose();
      _splitLyricScrollController = ScrollController();
      setState(() {
        _lyricsBoundSongPath = song.path;
        _lyricsHydratedForPath = song.path;
        _lyrics = [];
        _lyricKeys = [];
        _lyricKeysSplit = [];
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

  void _updateCurrentLyric(Duration position, {bool instantScroll = false}) {
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
            _scrollToCurrentLyric(newIndex, instant: instantScroll);
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
    if (_isManualScrolling && !force) return;
    if (index < 0) return;
    if (_currentPage == 0) {
      return;
    }
    if (_currentPage == 2) {
      _scrollSplitToCurrentLyric(index, force: force, instant: instant);
      return;
    }
    if (!_scrollController.hasClients) return;
    if (index >= _lyricKeys.length) return;

    final ctx = _lyricKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: instant ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

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

  /// 分屏右栏歌词表：与 [_scrollToCurrentLyric] 相同策略，独立 [ScrollController] / keys
  void _scrollSplitToCurrentLyric(
    int index, {
    bool force = false,
    bool instant = false,
  }) {
    if (_isManualScrolling && !force) return;
    if (!_splitLyricScrollController.hasClients) return;
    if (index < 0 || index >= _lyricKeysSplit.length) return;

    final ctx = _lyricKeysSplit[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: instant ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    final pos = _splitLyricScrollController.position;
    final maxExtent = pos.maxScrollExtent;
    if (maxExtent <= 0 || _lyrics.length <= 1) {
      if (instant) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollSplitToCurrentLyric(index, force: force, instant: instant);
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
      _splitLyricScrollController.jumpTo(estimatedOffset);
    } else {
      _splitLyricScrollController.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final builtCtx = _lyricKeysSplit[index].currentContext;
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
    if (_currentLyricIndex < 0) return;
    _isManualScrolling = false;
    if (_currentPage == 2) {
      if (_currentLyricIndex < _lyricKeysSplit.length) {
        _scrollSplitToCurrentLyric(
          _currentLyricIndex,
          force: true,
          instant: false,
        );
      }
    } else if (_currentPage == 1) {
      if (_currentLyricIndex < _lyricKeys.length) {
        _scrollToCurrentLyric(_currentLyricIndex, force: true, instant: false);
      }
    }
  }

  // 监听用户手动滚动
  void _onUserScroll() {
    if (mounted) {
      setState(() {
        _isManualScrolling = true;
      });
    } else {
      _isManualScrolling = true;
    }
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
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
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return LyricStyleSettingsPanel(
                      settings: _settings,
                      pageContext: context,
                      keepScreenAwake: _keepScreenAwake,
                      onKeepScreenAwakeChanged: (v) {
                        unawaited(
                          _setKeepScreenAwake(
                            v,
                            alsoNotifySheet: () => setModalState(() {}),
                          ),
                        );
                      },
                      onUpdate: () {
                        setModalState(() {});
                        setState(() {});
                      },
                      onPersist: _saveSettings,
                    );
                  },
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

  /// 多行歌词：当前行按钮图标（-1=全部，0..=仅第 N 行）
  IconData _lyricLineDisplayModeIcon() {
    if (_globalDisplayMode < 0) return Icons.lyrics_rounded;
    switch (_globalDisplayMode) {
      case 0:
        return Icons.filter_1_rounded;
      case 1:
        return Icons.filter_2_rounded;
      case 2:
        return Icons.filter_3_rounded;
      case 3:
        return Icons.filter_4_rounded;
      case 4:
        return Icons.filter_5_rounded;
      case 5:
        return Icons.filter_6_rounded;
      case 6:
        return Icons.filter_7_rounded;
      case 7:
        return Icons.filter_8_rounded;
      case 8:
        return Icons.filter_9_rounded;
      default:
        return Icons.view_column_rounded;
    }
  }

  String _lyricLineDisplayModeTooltip(AppLocalizations l10n) {
    if (_lyrics.isEmpty) {
      return l10n.lyricModeEmptyHint;
    }
    if (_globalDisplayMode < 0) {
      return l10n.lyricModeAllLines;
    }
    return l10n.lyricModeSingleLineN(_globalDisplayMode + 1);
  }

  // 获取播放模式图标（圆角系，与底栏/模式列表一致）
  IconData _getPlaybackModeIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.sequential:
        return Icons.queue_music_rounded;
      case PlaybackMode.shuffle:
        return Icons.shuffle_rounded;
      case PlaybackMode.singleLoop:
        return Icons.repeat_one_rounded;
      case PlaybackMode.playOnce:
        return Icons.play_arrow_rounded;
      case PlaybackMode.timerShutdown:
        return Icons.timer_rounded;
    }
  }

  // 显示播放模式选择弹窗
  void _showPlaybackModeSheet(BuildContext context, PlayListProvider provider) {
    final primary = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context);
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
            child: SafeArea(
              top: false,
              child: Builder(
                builder: (inner) {
                  final innerL10n = AppLocalizations.of(inner);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          l10n.playbackModeTitle,
                          style: Theme.of(inner).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...PlaybackMode.values.map((mode) {
                        final isSelected = provider.playbackMode == mode;
                        return ListTile(
                          leading: Icon(_getPlaybackModeIcon(mode)),
                          title: Text(playbackModeLabel(mode, innerL10n)),
                          trailing: isSelected
                              ? Icon(Icons.check, color: primary)
                              : null,
                          onTap: () {
                            provider.setPlaybackMode(mode);
                            SettingsService.savePlaybackMode(mode);
                            Navigator.pop(sheetContext);
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
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
        final l10n = AppLocalizations.of(ctx);
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
                    Text(
                      l10n.sleepTimerCustom,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ctx.gradFg(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: TextStyle(color: ctx.gradFg()),
                      cursorColor: ctx.gradFg(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.sleepTimerLabelMinutes,
                        labelStyle: TextStyle(color: ctx.gradFgMuted()),
                        hintText:
                            '$_customTimerMinMinutes–$_customTimerMaxMinutes',
                        hintStyle: TextStyle(color: ctx.gradFg(0.38)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ctx.gradBorder(0.22)),
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
                            foregroundColor: ctx.gradFg(0.7),
                          ),
                          child: Text(l10n.actionCancel),
                        ),
                        TextButton(
                          onPressed: () => _submitCustomTimer(ctx, controller),
                          child: Text(l10n.actionOK),
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
      final l10n = AppLocalizations.of(ctx);
      showAppSnackBar(
        ctx,
        l10n.sleepTimerInvalidRange(
          _customTimerMinMinutes,
          _customTimerMaxMinutes,
        ),
        kind: AppSnackKind.error,
      );
      return;
    }
    Navigator.pop(ctx, v);
  }

  Future<void> _showSongMetadataDialog(BuildContext context, Song song) async {
    final l10n = AppLocalizations.of(context);
    final path = song.path.trim();
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMetadataReadFailed,
        kind: AppSnackKind.error,
      );
      return;
    }
    late final AudioMetadata meta;
    try {
      meta = readEmbeddedAudioMetadata(file, getImage: true);
    } catch (e, st) {
      appLog.e('read song metadata failed', error: e, stackTrace: st);
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMetadataReadFailed,
        kind: AppSnackKind.error,
      );
      return;
    }
    late final int sizeBytes;
    try {
      sizeBytes = (await file.stat()).size;
    } catch (_) {
      sizeBytes = 0;
    }

    if (!context.mounted) return;
    await showAudioMetadataDialog(
      context: context,
      song: song,
      meta: meta,
      sizeBytes: sizeBytes,
    );
  }

  Future<void> _shareSongFile(BuildContext context, Song song) async {
    final path = song.path.trim();
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        AppLocalizations.of(context).songPageShareFileNotFound,
        kind: AppSnackKind.error,
      );
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } catch (e, st) {
      appLog.e('share audio file failed', error: e, stackTrace: st);
      if (context.mounted) {
        showAppSnackBar(context, '$e', kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _uploadCurrentToOneDrive(BuildContext context, Song song) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context
          .read<OneDriveDownloadQueueController>()
          .enqueueLibraryUploads([song]);
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.libraryBatchUploadQueued,
        kind: AppSnackKind.success,
        action: SnackBarAction(
          label: l10n.libraryBatchOpenQueue,
          onPressed: () => openOneDriveTransferQueue(
            initialTab: OneDriveTransferQueueTab.upload,
          ),
        ),
      );
    } on StateError catch (e) {
      final msg = '$e';
      if (!context.mounted) return;
      final text = msg.contains('not signed')
          ? l10n.libraryBatchUploadNeedSignIn
          : msg.contains('upload folder unset')
          ? l10n.libraryBatchUploadNeedCloudFolder
          : '$e';
      showAppSnackBar(context, text, kind: AppSnackKind.error);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '$e', kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _openMusicTagEditorExternal(
    BuildContext context,
    Song song,
  ) async {
    await MusicTagEditorLauncher.openMusicTagEditorWithFeedback(
      context,
      song,
      onLaunchedOk: (path) => _pendingExternalAudioReloadPath = path,
    );
  }

  Future<void> _openSyncedLyricEditorExternal(
    BuildContext context,
    Song song,
  ) async {
    final l10n = AppLocalizations.of(context);
    final path = song.path.trim();
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMusicTagEditorFileNotFound,
        kind: AppSnackKind.error,
      );
      return;
    }
    if (!Platform.isAndroid) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMusicTagEditorUnsupportedPlatform,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    try {
      final status = await MusicTagEditorLauncher.openSyncedLyricEditor(path);
      if (!context.mounted) return;
      final String? msg = switch (status) {
        'ok' => null,
        'activity_not_found' => l10n.songPageSyncedLyricEditorNotInstalled,
        'file_not_found' => l10n.songPageMusicTagEditorFileNotFound,
        'cannot_share_path' => l10n.songPageMusicTagEditorCannotSharePath,
        'invalid_args' => l10n.songPageSyncedLyricEditorLaunchFailed,
        null => l10n.songPageSyncedLyricEditorLaunchFailed,
        _ => l10n.songPageSyncedLyricEditorLaunchFailed,
      };
      if (msg != null) {
        showAppSnackBar(context, msg, kind: AppSnackKind.error);
      } else {
        _pendingExternalAudioReloadPath = path;
      }
    } on MissingPluginException {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageSyncedLyricEditorLaunchFailed,
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _confirmDeleteCurrentSong(
    BuildContext context,
    Song song,
  ) async {
    final l10n = AppLocalizations.of(context);
    final displayName = (song.title?.trim().isNotEmpty ?? false)
        ? song.title!.trim()
        : p.basename(song.path);

    final step1 = await showAppConfirmDialog(
      context: context,
      title: l10n.songPageDeleteDiskWarningTitle,
      message: l10n.songPageDeleteDiskWarningBody,
      icon: Icons.warning_amber_rounded,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.songPageDeleteContinue,
    );
    if (step1 != true || !context.mounted) return;

    final step2 = await showAppConfirmDialog(
      context: context,
      title: l10n.songPageDeleteFinalConfirmTitle,
      message: l10n.songPageDeleteFinalConfirmBody(displayName),
      icon: Icons.delete_outline_rounded,
      confirmIsDestructive: true,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
    );
    if (step2 != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final folder = context.read<FolderProvider>();
    final play = context.read<PlayListProvider>();
    final userPl = context.read<UserPlaylistProvider>();
    if (!userPl.initialized) await userPl.init();
    await deleteLibrarySongsAndRefresh(
      folderProvider: folder,
      playListProvider: play,
      userPlaylistProvider: userPl,
      songs: [song],
    );
    if (!mounted) return;
    navigator.maybePop();
  }

  void _showSongMoreSheet(
    BuildContext context,
    PlayListProvider playListProvider,
  ) {
    final song = playListProvider.currentSong;
    if (song == null) return;
    final navigatorContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FrostedGlassBottomSheet(
            child: SafeArea(
              top: false,
              child: Consumer<PlayListProvider>(
                builder: (ctx, provider, _) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            l10n.songPageMoreSheetTitle,
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            provider.isSleepTimerActive
                                ? Icons.timer_off_rounded
                                : Icons.timer_rounded,
                          ),
                          title: Text(l10n.sleepTimerSheetTitle),
                          subtitle: provider.isSleepTimerActive
                              ? Text(
                                  l10n.sleepTimerCurrentN(
                                    provider.timerDuration,
                                  ),
                                )
                              : null,
                          trailing: provider.isSleepTimerActive
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _showTimerSheet(navigatorContext, provider);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline_rounded),
                          title: Text(l10n.songPageMoreQueryMetadata),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _showSongMetadataDialog(navigatorContext, song);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.refresh_rounded),
                          title: Text(l10n.libraryReloadMetadata),
                          onTap: () {
                            final path = song.path;
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              if (!mounted) return;
                              final ctx2 = context;
                              final doneText = AppLocalizations.of(
                                ctx2,
                              ).libraryReloadMetadataDone;
                              await _reloadSongMetaAfterExternalMusicTagEdit(
                                path,
                              );
                              if (!mounted || !ctx2.mounted) return;
                              showAppSnackBar(
                                ctx2,
                                doneText,
                                kind: AppSnackKind.success,
                              );
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: Text(l10n.songPageMoreUploadOneDrive),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _uploadCurrentToOneDrive(navigatorContext, song);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.share_outlined),
                          title: Text(l10n.songPageMoreShare),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _shareSongFile(navigatorContext, song);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit_attributes_outlined),
                          title: Text(l10n.songPageMoreEditMusicTagsInline),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _openInlineTagsEditor(navigatorContext, song);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit_note_outlined),
                          title: Text(l10n.songPageMoreEditMusicTagsExternal),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _openMusicTagEditorExternal(
                                navigatorContext,
                                song,
                              );
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.subtitles_outlined),
                          title: Text(l10n.songPageMoreEditLyricsExternal),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _openSyncedLyricEditorExternal(
                                navigatorContext,
                                song,
                              );
                            });
                          },
                        ),
                        Divider(height: 1, color: ctx.gradBorder(0.2)),
                        ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                          title: Text(
                            l10n.actionDelete,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _confirmDeleteCurrentSong(navigatorContext, song);
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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
        final isCustom =
            provider.isSleepTimerActive &&
            !_presetTimerMinutes.contains(provider.timerDuration);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: FrostedGlassBottomSheet(
            child: SafeArea(
              top: false,
              child: Builder(
                builder: (inner) {
                  final l10n = AppLocalizations.of(inner);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          l10n.sleepTimerSheetTitle,
                          style: Theme.of(inner).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (provider.isSleepTimerActive)
                        ListTile(
                          leading: const Icon(Icons.timer_off),
                          title: Text(l10n.sleepTimerCancel),
                          onTap: () {
                            provider.cancelSleepTimer();
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ..._presetTimerMinutes.map((minutes) {
                        return ListTile(
                          leading: const Icon(Icons.timer),
                          title: Text(l10n.sleepTimerMinutesN(minutes)),
                          trailing:
                              provider.timerDuration == minutes &&
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
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.sleepTimerCustom),
                        subtitle: isCustom
                            ? Text(
                                l10n.sleepTimerCurrentN(provider.timerDuration),
                              )
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
                  );
                },
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
      appLog.e('跳转播放位置失败', error: e);
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

  /// 与第一页相同封面资源；[side] 有值时按第三页分屏区计算出的边长，否则为全屏第一页布局
  Widget _buildCoverArt(Song song, {double? side}) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final img = Image(
      image: ApplicationUtils.getImageCoverProvider(
        song,
        size: 400,
        devicePixelRatio: dpr,
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
    if (side != null) {
      return SizedBox(
        width: side,
        height: side,
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: img),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: AspectRatio(aspectRatio: 1, child: img),
      ),
    );
  }

  /// 与第二页全屏歌词列表行完全一致的单元（显示模式/翻译/高亮/点击 seek）
  Widget _lyricListItem(int index, Duration effectivePos, GlobalKey? lineKey) {
    final line = _lyrics[index];
    final ts = line.timestamp;
    final played = ts != null && ts <= effectivePos;
    final active = line.isActive;
    final lineSpecificMode = _lyricDisplayMode[index];
    final displayMode = lineSpecificMode ?? _globalDisplayMode;
    final linesToShow = <String>[];

    if (displayMode == -1) {
      if (_settings.showOriginal && line.lines.isNotEmpty) {
        linesToShow.add(line.lines[0]);
      }
      if (_settings.showTranslations && line.lines.length > 1) {
        linesToShow.addAll(line.lines.sublist(1));
      }
    } else if (displayMode < line.lines.length) {
      linesToShow.add(line.lines[displayMode]);
    } else {
      if (_settings.showOriginal && line.lines.isNotEmpty) {
        linesToShow.add(line.lines[0]);
      }
      if (_settings.showTranslations && line.lines.length > 1) {
        linesToShow.addAll(line.lines.sublist(1));
      }
    }

    if (linesToShow.isEmpty) {
      return SizedBox(key: lineKey, height: 0.01);
    }
    final isShowingAll = displayMode == -1;
    final isShowingSingleLine =
        displayMode >= 0 && displayMode < line.lines.length;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: _settings.lyricLineSpacing / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: ts == null ? null : () => _seekTo(ts),
        child: Container(
          key: lineKey,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            // 占满行宽，否则 [Text.textAlign] 在窄于父级的宽度上无效
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < linesToShow.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i > 0 ? 4 : 0),
                  child: Builder(
                    builder: (context) {
                      final originalIndex = isShowingAll ? i : displayMode;
                      final isOriginalLine = originalIndex == 0;
                      final shouldHighlight =
                          active &&
                          ((isShowingAll) ||
                              (isShowingSingleLine &&
                                  originalIndex == displayMode));
                      final activeColor = Color(
                        isOriginalLine
                            ? _settings.activeOriginalColor
                            : _settings.activeTranslationColor,
                      );
                      final playedColor = Color(
                        isOriginalLine
                            ? _settings.playedOriginalColor
                            : _settings.playedTranslationColor,
                      );
                      final upcomingColor = Color(
                        isOriginalLine
                            ? _settings.upcomingOriginalColor
                            : _settings.upcomingTranslationColor,
                      );
                      final rowKind = shouldHighlight
                          ? LyricRowVisualKind.active
                          : (played
                                ? LyricRowVisualKind.played
                                : LyricRowVisualKind.upcoming);
                      final rowGradient = lyricRowGradientOrNull(
                        _settings,
                        rowKind,
                      );
                      final useRowGradient = rowGradient != null;
                      final solidColor = shouldHighlight
                          ? activeColor
                          : (played ? playedColor : upcomingColor);
                      final displayColor = useRowGradient
                          ? Colors.white
                          : solidColor;
                      return SizedBox(
                        width: double.infinity,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: TextStyle(
                            fontSize: shouldHighlight && isOriginalLine
                                ? _settings.originalFontSize + 2
                                : (isOriginalLine
                                      ? _settings.originalFontSize
                                      : _settings.translationFontSize),
                            fontWeight: shouldHighlight
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: displayColor,
                            height: 1.35,
                            letterSpacing: 0.2,
                          ),
                          child: useRowGradient
                              ? ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      rowGradient.createShader(
                                        Rect.fromLTWH(
                                          0,
                                          0,
                                          bounds.width,
                                          bounds.height,
                                        ),
                                      ),
                                  child: Text(
                                    linesToShow[i],
                                    textAlign: _settings.lyricTextAlign,
                                  ),
                                )
                              : Text(
                                  linesToShow[i],
                                  textAlign: _settings.lyricTextAlign,
                                ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 与第二页全屏歌词 [Stack] 行为一致；[pageIndexForFab] 为当前全屏/分屏页下标 1 或 2
  Widget _buildLyricsScrollStack(
    Duration effectivePos, {
    required ScrollController controller,
    required List<GlobalKey> keys,
    required EdgeInsets listPadding,
    required int pageIndexForFab,
  }) {
    final l10n = AppLocalizations.of(context);
    return ScrollToCurrentLocateLayer(
      onManualScroll: _onUserScroll,
      isManual: _isManualScrolling,
      canLocate: _currentLyricIndex >= 0 && _currentPage == pageIndexForFab,
      onLocate: _scrollToCurrentPlayingLyric,
      tooltip: l10n.locateToLyricLine,
      child: ScrollConfiguration(
        // 不显示歌词列表滚动条（自动跟唱与手动滚动均不显示，避免桌面端条常显/闪动）
        behavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.builder(
          controller: controller,
          physics: const ClampingScrollPhysics(),
          padding: listPadding,
          itemCount: _lyrics.length,
          itemBuilder: (context, index) {
            final key = keys.length == _lyrics.length ? keys[index] : null;
            return _lyricListItem(index, effectivePos, key);
          },
        ),
      ),
    );
  }

  /// 第三页：左为 [_buildCoverArt] 的第三页边长、右为与第二页相同的 [_buildLyricsScrollStack]
  Widget _buildSplitScreenPage(Song song, Duration effectivePos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l10n = AppLocalizations.of(context);
        const outerH = 16.0;
        const outerHRight = 12.0;
        final innerW = (constraints.maxWidth - outerH - outerHRight).clamp(
          0.0,
          4000.0,
        );
        const flexL = 8;
        const flexR = 11;
        final leftColW = innerW * flexL / (flexL + flexR) - 6;
        const edgePad = 4.0;
        final wAvail = (leftColW - edgePad * 2).clamp(0.0, 2000.0);
        final hAvail = (constraints.maxHeight - edgePad * 2).clamp(0.0, 2000.0);
        var coverSide = wAvail < hAvail ? wAvail : hAvail;
        coverSide *= 0.99;
        if (coverSide > wAvail) {
          coverSide = wAvail;
        }
        coverSide = coverSide.clamp(80.0, 720.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(outerH, 4, outerHRight, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: Align(
                  alignment: const Alignment(0.32, 0.0),
                  child: _buildCoverArt(song, side: coverSide),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // const SizedBox(height: 6),
                      Expanded(
                        child: _lyrics.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.noLyrics,
                                  style: TextStyle(color: context.gradFg(0.45)),
                                ),
                              )
                            : _buildLyricsScrollStack(
                                effectivePos,
                                controller: _splitLyricScrollController,
                                keys: _lyricKeysSplit,
                                listPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                pageIndexForFab: 2,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayListProvider, ThemeConfigProvider>(
      builder: (context, playListProvider, themeConfig, childWidget) {
        final l10n = AppLocalizations.of(context);
        if (playListProvider.playList.isEmpty) {
          return themeConfig.buildThemedBackground(
            context: context,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text(
                  l10n.songNotFound,
                  style: TextStyle(color: context.gradFgMuted()),
                ),
              ),
            ),
          );
        }

        final song =
            playListProvider.currentSong ?? playListProvider.playList.first;
        final skipDisabled =
            playListProvider.playbackMode == PlaybackMode.playOnce;
        // 使用StreamBuilder来监听播放状态，确保按钮状态正确
        final effectivePos = _effectivePosition();
        final compactChrome =
            MediaQuery.orientationOf(context) == Orientation.landscape;

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
          context: context,
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: Column(
                children: [
                  // 顶部栏：与主页一致，浅色字叠在全局背景上
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: compactChrome ? 6 : 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          color: context.gradFg(),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AutoMarqueeSingleLineText(
                                text: song.title ?? l10n.pageUnknownTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: context.gradFg(),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              if (song.artist != null &&
                                  song.artist!.isNotEmpty)
                                AutoMarqueeSingleLineText(
                                  text: song.artist!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.gradFg(0.65),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.list, size: 24),
                          color: context.gradFg(),
                          onPressed: () {
                            _showPlayListSheet(context, playListProvider);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 封皮 / 全屏歌词 / 分屏；底部分段指示
                  Expanded(
                    child: Column(
                      children: [
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
                              // 正常顺序：0=封皮，1=全屏歌词，2=分屏(左封皮·右歌词)
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                                _savePageState(); // 保存页面状态
                                if (index == 1 && _lyrics.isNotEmpty) {
                                  // 从封面切到歌词时瞬时对齐，避免先看到顶再滚到当前行
                                  _isManualScrolling = false;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted) return;
                                    _updateCurrentLyric(
                                      _effectivePosition(),
                                      instantScroll: true,
                                    );
                                  });
                                }
                                if (index == 2 && _lyrics.isNotEmpty) {
                                  _isManualScrolling = false;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted) return;
                                    _updateCurrentLyric(
                                      _effectivePosition(),
                                      instantScroll: true,
                                    );
                                  });
                                }
                              },
                              children: [
                                // 封皮页面（第0页）：横屏可用高度小，需按宽高中较小边限制，避免 AspectRatio 溢出
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const outerPad = 32.0;
                                    const maxSide = 400.0;
                                    final innerW =
                                        constraints.maxWidth - outerPad * 2;
                                    final innerH =
                                        constraints.maxHeight - outerPad * 2;
                                    final side = math
                                        .min(math.min(innerW, innerH), maxSide)
                                        .clamp(1.0, maxSide);
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(outerPad),
                                        child: _buildCoverArt(song, side: side),
                                      ),
                                    );
                                  },
                                ),
                                // 歌词页面（第1页）：与 [_buildLyricsScrollStack] 分屏复用
                                _lyrics.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.music_note,
                                              size: 64,
                                              color: context.gradFg(0.45),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              l10n.noLyrics,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: context.gradFg(0.55),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _buildLyricsScrollStack(
                                        effectivePos,
                                        controller: _scrollController,
                                        keys: _lyricKeys,
                                        listPadding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 20,
                                        ),
                                        pageIndexForFab: 1,
                                      ),
                                _buildSplitScreenPage(song, effectivePos),
                              ],
                            ),
                          ),
                        ),
                        _SongPageIndicator(currentIndex: _currentPage),
                      ],
                    ),
                  ),

                  // 横屏时剩余高度小，底部固定区总高度易超过 [Column] 可用空间；整体 scaleDown + 紧缩竖向边距
                  LayoutBuilder(
                    builder: (context, chromeConstraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: chromeConstraints.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: compactChrome ? 2 : 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          LyricsUtils.formatDuration(
                                            effectivePos,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.gradFg(0.55),
                                          ),
                                        ),
                                        Text(
                                          LyricsUtils.formatDuration(
                                            _totalDuration,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.gradFg(0.55),
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
                                                      _totalDuration
                                                          .inMilliseconds)
                                                  .clamp(0.0, 1.0)
                                            : 0.0,
                                        min: 0.0,
                                        max: 1.0,
                                        activeColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        inactiveColor: context.gradFg(0.25),
                                        onChangeStart: (_) {
                                          _isSeeking = true;
                                          _seekPreview = effectivePos;
                                          setState(() {});
                                        },
                                        onChanged: (value) {
                                          if (_totalDuration.inMilliseconds >
                                              0) {
                                            final newPosition = Duration(
                                              milliseconds:
                                                  (value *
                                                          _totalDuration
                                                              .inMilliseconds)
                                                      .toInt(),
                                            );
                                            _seekPreview = newPosition;
                                            _updateCurrentLyric(_seekPreview);
                                            setState(() {});
                                          }
                                        },
                                        onChangeEnd: (value) async {
                                          if (_totalDuration.inMilliseconds >
                                              0) {
                                            final newPosition = Duration(
                                              milliseconds:
                                                  ((value.clamp(0.0, 1.0)) *
                                                          _totalDuration
                                                              .inMilliseconds)
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: compactChrome ? 4 : 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous),
                                      color: context.gradFg(),
                                      iconSize: 32,
                                      onPressed: skipDisabled
                                          ? null
                                          : () async {
                                              await playListProvider.playPrev();
                                              _initLyrics();
                                              _updateDuration();
                                            },
                                    ),
                                    const SizedBox(width: 24),
                                    StreamBuilder<bool>(
                                      stream: MusicService.playingStream,
                                      initialData: MusicService.isPlaying,
                                      builder: (context, snapshot) {
                                        final isPlayingNow =
                                            snapshot.data ?? false;
                                        return GestureDetector(
                                          onTap: () async {
                                            if (isPlayingNow) {
                                              MusicService().pause();
                                            } else {
                                              if (MusicService.duration !=
                                                      null &&
                                                  _currentPosition
                                                          .inMilliseconds >
                                                      0) {
                                                MusicService().seek(
                                                  _currentPosition,
                                                );
                                                MusicService().resume();
                                              } else {
                                                final ok = await MusicService()
                                                    .playCurrentFromPlaylist(
                                                      queue: playListProvider
                                                          .playList,
                                                      currentIndex:
                                                          playListProvider
                                                              .currentIndex,
                                                      useAndroidConcatQueue:
                                                          playListProvider
                                                              .playbackMode !=
                                                          PlaybackMode.playOnce,
                                                    );
                                                if (!context.mounted) return;
                                                if (!ok) {
                                                  reportPlaybackFailureToUser(
                                                    context,
                                                  );
                                                  return;
                                                }
                                                await playListProvider
                                                    .recordRecentForCurrent();
                                              }
                                            }
                                          },
                                          child: Container(
                                            width: 64,
                                            height: 64,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: context.gradFg(0.12),
                                              border: Border.all(
                                                color: context.gradFg(0.38),
                                                width: 1.25,
                                              ),
                                            ),
                                            child: Icon(
                                              isPlayingNow
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 34,
                                              color: context.gradFg(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next),
                                      color: context.gradFg(),
                                      iconSize: 32,
                                      onPressed: skipDisabled
                                          ? null
                                          : () async {
                                              await playListProvider.playNext();
                                              _initLyrics();
                                              _updateDuration();
                                            },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  12,
                                  compactChrome ? 4 : 8,
                                  12,
                                  compactChrome ? 2 : 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _SongToolIcon(
                                      icon: Icons.translate_rounded,
                                      onPressed: _showLyricStyleSheet,
                                      tooltip: l10n.tooltipLyricStyle,
                                    ),
                                    _SongToolIcon(
                                      icon: _lyricLineDisplayModeIcon(),
                                      iconColor: _globalDisplayMode < 0
                                          ? null
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      onPressed: _toggleDisplayMode,
                                      tooltip: _lyricLineDisplayModeTooltip(
                                        l10n,
                                      ),
                                    ),
                                    Consumer<PlayListProvider>(
                                      builder: (context, provider, _) {
                                        final t = AppLocalizations.of(context);
                                        return _SongToolIcon(
                                          icon: _getPlaybackModeIcon(
                                            provider.playbackMode,
                                          ),
                                          onPressed: () {
                                            _showPlaybackModeSheet(
                                              context,
                                              provider,
                                            );
                                          },
                                          tooltip: playbackModeLabel(
                                            provider.playbackMode,
                                            t,
                                          ),
                                        );
                                      },
                                    ),
                                    _SongToolIcon(
                                      icon: Icons.library_add_rounded,
                                      onPressed: () {
                                        final song =
                                            playListProvider.currentSong;
                                        if (song == null) return;
                                        showAddToUserPlaylistsSheet(
                                          context,
                                          song,
                                        );
                                      },
                                      tooltip: l10n.tooltipAddToPlaylist,
                                    ),
                                    _SongToolIcon(
                                      icon: Icons.more_horiz_rounded,
                                      onPressed: () {
                                        _showSongMoreSheet(
                                          context,
                                          playListProvider,
                                        );
                                      },
                                      tooltip: l10n.tooltipMore,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).padding.bottom,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 播放页中间区域三页：封面 / 全屏歌词 / 分屏
class _SongPageIndicator extends StatelessWidget {
  const _SongPageIndicator({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final idx = currentIndex.clamp(0, 2);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final sel = i == idx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: sel ? 22 : 6,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: sel ? context.gradFg(0.88) : context.gradFg(0.28),
            ),
          );
        }),
      ),
    );
  }
}

/// 播放页底栏图标：无容器背景，仅悬停/按压/聚焦时高亮
class _SongToolIcon extends StatelessWidget {
  const _SongToolIcon({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;

  static const double _kIcon = 25;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, size: _kIcon),
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            iconColor: WidgetStatePropertyAll(iconColor ?? context.gradFg()),
            iconSize: const WidgetStatePropertyAll(_kIcon),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStateProperty.resolveWith((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.hovered)) {
                return context.gradFg(0.10);
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.focused)) {
                return context.gradFg(0.16);
              }
              return null;
            }),
            shape: const WidgetStatePropertyAll(CircleBorder()),
            visualDensity: VisualDensity.comfortable,
          ),
        ),
      ),
    );
  }
}

/// 插播区与下方主队列之间的柔和过渡（无硬分割「栅栏」）。
class _PendingMainBlend extends StatelessWidget {
  const _PendingMainBlend();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 12,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.13),
                  primary.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 播放队列底部表单：定位当前曲目、高亮当前行、动态播放指示器
class _PlaybackQueueSheet extends StatefulWidget {
  const _PlaybackQueueSheet({required this.provider, required this.onPick});

  final PlayListProvider provider;
  final Future<void> Function(int index) onPick;

  @override
  State<_PlaybackQueueSheet> createState() => _PlaybackQueueSheetState();
}

class _PlaybackQueueSheetState extends State<_PlaybackQueueSheet> {
  static const double _kQueueRowH = 72;
  static const double _kQueueSepH = 1;
  static const double _kQueueItemExtent = _kQueueRowH + _kQueueSepH;

  /// 与 [CustomScrollView] 顶部标题 [SliverToBoxAdapter] 视觉高度对齐（用于滚动定位）。
  static const double _kPlayQueueTitleBlock = 46;
  static const double _kPendingSectionTitleBlock = 30;

  /// 与 [_PendingMainBlend] 纵向占位一致（padding 2+6 + 渐变条 12）。
  static const double _kBlendBelowPending = 20;

  late final ScrollController _queueScroll;
  late int _lastHeardDisplayIndex;
  int? _playerMediaIndex;
  StreamSubscription<int?>? _playerQueueIndexSub;

  /// 与 [PlayListPage] 一致：全库顺序播放时队列 UI 按排序偏好展示；随机模式下仍为底层合并顺序以免误导。
  ({List<Song> display, bool sortAlignedUi}) _queueRowsModel(
    PlayListProvider provider,
  ) {
    final raw = provider.playList;
    final prefs = loadSongSortPreferencesSync();
    final align =
        provider.playbackSessionIsLibrary &&
        !provider.hasPlaybackQueueOverride &&
        provider.playbackMode != PlaybackMode.shuffle;
    if (!align || raw.isEmpty) {
      return (display: raw, sortAlignedUi: false);
    }
    return (
      display: sortSongsCopy(raw, prefs.type, prefs.ascending),
      sortAlignedUi: true,
    );
  }

  int _displayIdxForPlaybackIdx(
    int playbackIdx,
    List<Song> raw,
    List<Song> display,
    bool aligned,
  ) {
    if (!aligned) {
      return playbackIdx.clamp(0, raw.isEmpty ? 0 : raw.length - 1);
    }
    if (playbackIdx < 0 || playbackIdx >= raw.length) return 0;
    final song = raw[playbackIdx];
    final d = display.indexWhere((s) => s.path == song.path);
    return d >= 0 ? d : playbackIdx.clamp(0, display.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _playerMediaIndex = MusicService.currentIndex;
    final provider = widget.provider;
    final rows = _queueRowsModel(provider);
    final raw = provider.playList;
    final display = rows.display;
    final aligned = rows.sortAlignedUi;
    final pb = _displayCurrentIndex(provider);
    _lastHeardDisplayIndex = _displayIdxForPlaybackIdx(
      pb,
      raw,
      display,
      aligned,
    );
    _queueScroll = ScrollController();
    widget.provider.addListener(_onProviderChanged);
    _playerQueueIndexSub = MusicService.currentMediaIndexStream.listen((
      int? i,
    ) {
      if (!mounted) return;
      final before = _displayCurrentIndex(
        widget.provider,
        playerIdxOverride: _playerMediaIndex,
      );
      setState(() => _playerMediaIndex = i);
      if (!MusicService.androidCarQueueActive) return;
      final after = _displayCurrentIndex(widget.provider, playerIdxOverride: i);
      if (after != before) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _refineQueueScroll(animated: true),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refineQueueScroll(animated: false);
    });
  }

  @override
  void dispose() {
    _playerQueueIndexSub?.cancel();
    widget.provider.removeListener(_onProviderChanged);
    _queueScroll.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final p = widget.provider;
    final rows = _queueRowsModel(p);
    final raw = p.playList;
    final display = rows.display;
    final aligned = rows.sortAlignedUi;
    final idx = _displayIdxForPlaybackIdx(
      _displayCurrentIndex(p),
      raw,
      display,
      aligned,
    );
    final indexMoved = idx != _lastHeardDisplayIndex;
    _lastHeardDisplayIndex = idx;
    setState(() {});
    if (indexMoved) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refineQueueScroll(animated: true),
      );
    }
  }

  double _leadingPixelsBeforeMainQueue(PlayListProvider provider) {
    var y = _kPlayQueueTitleBlock;
    final pend = provider.pendingPlayAfterCurrentSongs.length;
    if (pend > 0) {
      y +=
          _kPendingSectionTitleBlock +
          pend * _kQueueItemExtent +
          _kBlendBelowPending;
    }
    return y;
  }

  /// Android 车载整队列时以播放器当前段索引为准，否则以 [PlayListProvider.currentIndex] 为准。
  int _displayCurrentIndex(PlayListProvider p, {int? playerIdxOverride}) {
    final listLen = p.playList.length;
    if (listLen <= 0) return 0;
    final playerIdx = playerIdxOverride ?? _playerMediaIndex;
    if (MusicService.androidCarQueueActive) {
      if (playerIdx != null && playerIdx >= 0 && playerIdx < listLen) {
        return playerIdx;
      }
    }
    return p.currentIndex.clamp(0, listLen - 1);
  }

  void _refineQueueScroll({required bool animated}) {
    if (!mounted) return;
    if (!_queueScroll.hasClients) return;
    final provider = widget.provider;
    final rows = _queueRowsModel(provider);
    final display = rows.display;
    if (display.isEmpty) return;
    final raw = provider.playList;
    final aligned = rows.sortAlignedUi;
    final i = _displayIdxForPlaybackIdx(
      _displayCurrentIndex(provider),
      raw,
      display,
      aligned,
    ).clamp(0, display.length - 1);
    final pos = _queueScroll.position;
    final viewH = pos.viewportDimension;

    // 合并为单一滚动列表后：若仍按当前曲在主队列中的偏移滚动，会把上方的插播整段滚出视口。
    // 有待播插播时固定在顶部，便于始终能看到插播区（当前曲请手动向下滚动查看）。
    final pendingQueued = provider.pendingPlayAfterCurrentSongs;
    final double target;
    if (pendingQueued.isNotEmpty) {
      target = 0;
    } else {
      final leading = _leadingPixelsBeforeMainQueue(provider);
      final rowTop = leading + i * _kQueueItemExtent;
      target = (rowTop - viewH * 0.22).clamp(0.0, pos.maxScrollExtent);
    }
    if (animated) {
      _queueScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _queueScroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = widget.provider;
    final rawList = provider.playList;
    final rows = _queueRowsModel(provider);
    final displayList = rows.display;
    final sortAlignedUi = rows.sortAlignedUi;
    final primary = Theme.of(context).colorScheme.primary;
    final fg = context.gradFg();
    final fgSoft = context.gradFg(0.55);
    final fgSub = context.gradFgMuted();
    final divColor = context.gradBorder(0.12);

    if (displayList.isEmpty) {
      return Center(
        child: Text(l10n.queueNoTracks, style: TextStyle(color: fgSoft)),
      );
    }

    final curPlayback = _displayCurrentIndex(provider);
    final curDisplay = _displayIdxForPlaybackIdx(
      curPlayback,
      rawList,
      displayList,
      sortAlignedUi,
    );

    final pendingPlayNext = provider.pendingPlayAfterCurrentSongs;

    return CustomScrollView(
      controller: _queueScroll,
      cacheExtent: 280,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              l10n.playQueueTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
        if (pendingPlayNext.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.queuePendingPlayAfterCurrentSection,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fgSoft,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverFixedExtentList(
              itemExtent: _kQueueItemExtent,
              delegate: SliverChildBuilderDelegate((context, pi) {
                final s = pendingPlayNext[pi];
                final sepSoft = context.gradBorder(0.04);
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      height: _kQueueRowH,
                      child: Material(
                        color: primary.withValues(alpha: 0.09),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SongListCover(
                                song: s,
                                size: 48,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title ?? l10n.pageUnknownTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: primary.withValues(alpha: 0.95),
                                      ),
                                    ),
                                    Text(
                                      s.artist ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: fgSub,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(height: _kQueueSepH, color: sepSoft),
                  ],
                );
              }, childCount: pendingPlayNext.length),
            ),
          ),
          const SliverToBoxAdapter(child: _PendingMainBlend()),
        ],
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 12),
          sliver: SliverFixedExtentList(
            itemExtent: _kQueueItemExtent,
            delegate: SliverChildBuilderDelegate((context, index) {
              final s = displayList[index];
              final isCurrent = index == curDisplay;
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    key: ValueKey<String>('q_${index}_${s.path}'),
                    height: _kQueueRowH,
                    child: Material(
                      color: isCurrent
                          ? primary.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final pb = sortAlignedUi
                              ? rawList.indexWhere((x) => x.path == s.path)
                              : index;
                          if (pb >= 0) widget.onPick(pb);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SongListCover(
                                song: s,
                                size: 48,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SongListMarqueeWhenCurrentLine(
                                      text: s.title ?? l10n.pageUnknownTitle,
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isCurrent ? primary : fg,
                                      ),
                                      isCurrentTrack: isCurrent,
                                    ),
                                    SongListMarqueeWhenCurrentLine(
                                      text: s.artist ?? '',
                                      style: TextStyle(
                                        color: isCurrent
                                            ? primary.withValues(alpha: 0.8)
                                            : fgSub,
                                        fontSize: 13,
                                      ),
                                      isCurrentTrack: isCurrent,
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                ListRowPlayingIndicator(color: primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(height: _kQueueSepH, color: divColor),
                ],
              );
            }, childCount: displayList.length),
          ),
        ),
      ],
    );
  }
}
