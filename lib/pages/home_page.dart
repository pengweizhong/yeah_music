import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/home_initial_data.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/pages/music_recognition_page.dart';
import 'package:yeah_music/pages/menu_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_cached_playlist_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_cloud_playlist_page.dart';
import 'package:yeah_music/pages/setting/onedrive_settings_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/quick_entry_settings_page.dart';
import 'package:yeah_music/pages/most_played_page.dart';
import 'package:yeah_music/pages/recent_plays_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/widgets/wave_progress_bar.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/widgets/recent_play_list_row.dart';

/// 去掉 ScrollBehavior 外包层。
class _HomeBodyScrollBehavior extends MaterialScrollBehavior {
  const _HomeBodyScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// 应用主页
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initial});

  /// 若传入则可跳过首页内对部分数据的冷启动拉取。
  final HomeInitialData? initial;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();
  List<String> _recentPaths = [];
  List<({String path, int count})> _mostPlayedRaw = [];
  bool _recentReady = false;
  PlayListProvider? _play;
  QuickEntryConfig _quickEntry = QuickEntryConfig.defaultConfig();
  /// 首页问候卡片第二行展示文案（内置默认 + 用户自定义轮询）。
  String? _greetingSubLine;
  bool _advanceSubtitleAfterPausedResume = false;
  late final VoidCallback _quickEntryRevListener;

  @override
  void initState() {
    super.initState();
    _quickEntryRevListener = () {
      if (mounted) {
        unawaited(_loadQuickEntryConfig());
      }
    };
    SettingsService.quickEntryStorageRevision.addListener(_quickEntryRevListener);
    WidgetsBinding.instance.addObserver(this);
    final pre = widget.initial;
    if (pre != null) {
      _recentPaths = pre.recentPaths;
      _mostPlayedRaw = pre.mostPlayedRaw;
      _quickEntry = pre.quickEntry;
      _recentReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _play = context.read<PlayListProvider>();
        _play!.addListener(_onPlayListChange);
        // 首页首帧画出后再合并曲库，避免启动门控结束前长时间阻塞在同一动画段内。
        await Future<void>.delayed(const Duration(milliseconds: 52));
        if (!mounted) return;
        await _bootstrapPlayAfterSplash();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_advanceHomeGreetingSubtitle());
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrap();
      if (!mounted) return;
      _play = context.read<PlayListProvider>();
      _play!.addListener(_onPlayListChange);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_advanceHomeGreetingSubtitle());
    });
  }

  void _onPlayListChange() {
    _loadRecentPaths();
  }

  @override
  void dispose() {
    SettingsService.quickEntryStorageRevision.removeListener(_quickEntryRevListener);
    WidgetsBinding.instance.removeObserver(this);
    _play?.removeListener(_onPlayListChange);
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _advanceSubtitleAfterPausedResume = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    if (!_advanceSubtitleAfterPausedResume) return;
    _advanceSubtitleAfterPausedResume = false;
    unawaited(_advanceHomeGreetingSubtitle());
  }

  /// 欢迎页预载后补跑；与无 [initial] 时的 [_bootstrap] 共用合并逻辑。
  Future<void> _bootstrapPlayAfterSplash() async {
    if (!mounted) return;
    final folder = context.read<FolderProvider>();
    final play = context.read<PlayListProvider>();
    if (play.initialized) {
      return;
    }
    try {
      await play.init(
        folder,
        oneDrive: context.read<OneDriveController>(),
      );
    } catch (e, st) {
      appLog.e('曲库合并（PlayListProvider）初始化失败', error: e, stackTrace: st);
      return;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final folder = context.read<FolderProvider>();
    final play = context.read<PlayListProvider>();
    final user = context.read<UserPlaylistProvider>();
    if (!user.initialized) {
      await user.init();
    }
    if (!mounted) return;
    if (!play.initialized) {
      await play.init(
        folder,
        oneDrive: context.read<OneDriveController>(),
      );
    }
    if (!mounted) return;
    await _loadRecentPaths();
    await _loadQuickEntryConfig();
  }

  Future<void> _loadQuickEntryConfig() async {
    final c = await SettingsService.loadQuickEntryConfig();
    if (!mounted) return;
    setState(() {
      _quickEntry = c ?? QuickEntryConfig.defaultConfig();
    });
  }

  void _goQuickEntrySettings() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => QuickEntrySettingsPage(
          initial: QuickEntryConfig(
            order: List<String>.from(_quickEntry.order),
            hidden: Set<String>.from(_quickEntry.hidden),
          ),
        ),
      ),
    ).then((_) => _loadQuickEntryConfig());
  }

  Future<void> _loadRecentPaths() async {
    // 多取一些路径，避免前几条在「临时歌单队列」中无法解析时整区空白
    final p =
        await RecentPlayService.getPaths(limit: RecentPlayService.maxStoredRecentPaths);
    final top = await RecentPlayService.getTopByPlayCount(limit: 40);
    if (!mounted) return;
    setState(() {
      _recentPaths = p;
      _mostPlayedRaw = top;
      _recentReady = true;
    });
  }

  Future<void> _advanceHomeGreetingSubtitle() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final defaultLine = l10n.homeGreetingSub;
    final customs = await SettingsService.loadHomeGreetingCustomSubtitles();
    final randomRotation =
        await SettingsService.loadHomeGreetingRotationRandom();
    final pool = <String>[defaultLine, ...customs];
    final len = pool.length;
    if (len == 0) return;

    if (randomRotation) {
      final idx = len <= 1 ? 0 : math.Random().nextInt(len);
      if (!mounted) return;
      setState(() => _greetingSubLine = pool[idx]);
      return;
    }

    final cursor = await SettingsService.loadHomeGreetingSubCycleCursor();
    final idx = cursor % len;
    final next = (cursor + 1) % len;
    await SettingsService.saveHomeGreetingSubCycleCursor(next);
    if (!mounted) return;
    setState(() => _greetingSubLine = pool[idx]);
  }

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = DateTime.now().hour;
    if (h < 6) return l10n.homeGreetingLateNight;
    if (h < 12) return l10n.homeGreetingMorning;
    if (h < 18) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  void _goLibrary({bool openSearch = false}) {
    if (openSearch) {
      Future<void>(() async {
        if (!mounted) return;
        await showLibrarySearch(context);
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayListPage(),
      ),
    );
  }

  void _goStoragePlaylists() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoragePlayListPage(),
      ),
    );
  }

  void _goRecentPlays() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecentPlaysPage(),
      ),
    );
  }

  void _goMostPlayed() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const MostPlayedPage(),
      ),
    );
  }

  void _goCloudLibrary() {
    final od = context.read<OneDriveController>();
    if (od.signedIn) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const OneDriveCloudPlaylistPage(),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const OneDriveSettingsPage(),
        ),
      );
    }
  }

  void _goOneDrive() {
    final od = context.read<OneDriveController>();
    if (od.signedIn) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const OneDriveBrowserPage(),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const OneDriveSettingsPage(),
        ),
      );
    }
  }

  void _goOneDriveCachedPlaylist() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const OneDriveCachedPlaylistPage(),
      ),
    );
  }

  void _goMusicRecognition() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const MusicRecognitionPage(),
      ),
    );
  }

  void _goUserPlaylist(String playlistId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPlaylistDetailPage(playlistId: playlistId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            key: _scaffoldKey,
            extendBodyBehindAppBar: false,
            extendBody: true,
            backgroundColor: Colors.transparent,
            drawer: MenuPage(),
            appBar: AppBar(
              centerTitle: false,
              title: Text(
                l10n.appTitle,
                style: TextStyle(
                  color: context.gradFg(0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: l10n.homeMenuTooltip,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 26),
                  onPressed: () => _goLibrary(openSearch: true),
                  tooltip: l10n.homeSearchTooltip,
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Consumer2<PlayListProvider, UserPlaylistProvider>(
              builder: (context, play, user, _) {
                final recentSongs = play.resolveRecentSongsFromPaths(
                  _recentPaths,
                  maxSongs: 8,
                );
                final mostPlayedItems = play.resolveTopPlayedFromPathCounts(
                  _mostPlayedRaw,
                  maxSongs: 8,
                );
                final showMini = play.initialized &&
                    play.currentSong != null &&
                    play.playList.isNotEmpty;
                final miniBottom =
                    showMini ? MiniPlayer.barHeight : 0.0;
                return SizedBox.expand(
                  child: _HomeScrollBody(
                        scrollController: _homeScrollController,
                        quickEntry: _quickEntry,
                        safeBottom:
                            MediaQuery.paddingOf(context).bottom +
                                8 +
                                miniBottom,
                        greeting: _greeting(context),
                        greetingSub: _greetingSubLine ??
                            AppLocalizations.of(context).homeGreetingSub,
                        play: play,
                        user: user,
                        recentSongs: recentSongs,
                        mostPlayedItems: mostPlayedItems,
                        mostPlayedRaw: _mostPlayedRaw,
                        showRecentList: _recentReady,
                        onOpenLibrary: () => _goLibrary(),
                        onOpenSearch: () => _goLibrary(openSearch: true),
                        onOpenStorage: _goStoragePlaylists,
                        onOpenRecent: _goRecentPlays,
                        onOpenMostPlayed: _goMostPlayed,
                        onOpenCloudLibrary: _goCloudLibrary,
                        onOpenOneDrive: _goOneDrive,
                        onOpenOneDriveCachedPlaylist:
                            _goOneDriveCachedPlaylist,
                        onOpenMusicRecognition: _goMusicRecognition,
                        onManageQuickEntry: _goQuickEntrySettings,
                        onOpenUserPlaylist: _goUserPlaylist,
                        songSubtitle: _songSecondaryLine,
                      ),
                );
              },
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }

  String _songSecondaryLine(Song s) {
    if (s.artist == null || s.artist!.isEmpty) {
      return s.album ?? '';
    }
    if (s.album == null || s.album!.isEmpty) {
      return s.artist!;
    }
    return '${s.artist} · ${s.album}';
  }
}

// ---------------------------------------------------------------------------
// 滚动主体
// ---------------------------------------------------------------------------

class _HomeScrollBody extends StatefulWidget {
  const _HomeScrollBody({
    required this.scrollController,
    required this.quickEntry,
    required this.safeBottom,
    required this.greeting,
    required this.greetingSub,
    required this.play,
    required this.user,
    required this.recentSongs,
    required this.mostPlayedItems,
    required this.mostPlayedRaw,
    required this.showRecentList,
    required this.onOpenLibrary,
    required this.onOpenSearch,
    required this.onOpenStorage,
    required this.onOpenRecent,
    required this.onOpenMostPlayed,
    required this.onOpenCloudLibrary,
    required this.onOpenOneDrive,
    required this.onOpenOneDriveCachedPlaylist,
    required this.onOpenMusicRecognition,
    required this.onManageQuickEntry,
    required this.onOpenUserPlaylist,
    required this.songSubtitle,
  });

  final ScrollController scrollController;
  final QuickEntryConfig quickEntry;
  final double safeBottom;
  final String greeting;
  final String greetingSub;
  final PlayListProvider play;
  final UserPlaylistProvider user;
  final List<Song> recentSongs;
  final List<({Song song, int playCount})> mostPlayedItems;
  final List<({String path, int count})> mostPlayedRaw;
  final bool showRecentList;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenStorage;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenMostPlayed;
  final VoidCallback onOpenCloudLibrary;
  final VoidCallback onOpenOneDrive;
  final VoidCallback onOpenOneDriveCachedPlaylist;
  final VoidCallback onOpenMusicRecognition;
  final VoidCallback onManageQuickEntry;
  final void Function(String playlistId) onOpenUserPlaylist;
  final String Function(Song) songSubtitle;

  @override
  State<_HomeScrollBody> createState() => _HomeScrollBodyState();
}

class _HomeScrollBodyState extends State<_HomeScrollBody> {
  static const _hPad = 20.0;
  static const _gapL = 24.0;
  static const _gapM = 16.0;
  static const _gapS = 12.0;

  /// [SliverLayoutBuilder] 测得的吸顶分节条在内容中的起点（「最近」一栏）
  double? _recentPlaysSectionStartScroll;
  /// 滚过此 offset 后，吸顶条从「最近」切换为「最多」（= [SliverLayoutBuilder] 在「最多」**流式**分节标题前测得的 `precedingScrollExtent`）
  double? _mostPlayedBarSwitchAt;
  double _lastRecentPrecedingLogged = -1.0;
  double _lastMostPlayedSectionPreceding = -1.0;
  /// 与 [ScrollController] 同步，在短暂无 [hasClients] 的帧中仍用上次 offset 判断吸顶，避免上滑时状态卡在「最多」
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollFrosted);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollFrosted);
    super.dispose();
  }

  void _onScrollFrosted() {
    if (!mounted) return;
    final c = widget.scrollController;
    if (c.hasClients) {
      _lastScrollOffset = c.offset;
    }
    setState(() {});
  }

  void _onRecentSectionLayoutStart(double precedingScrollExtent) {
    if (precedingScrollExtent == _lastRecentPrecedingLogged) {
      return;
    }
    _lastRecentPrecedingLogged = precedingScrollExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_recentPlaysSectionStartScroll == precedingScrollExtent) {
        return;
      }
      setState(() {
        _recentPlaysSectionStartScroll = precedingScrollExtent;
      });
    });
  }

  void _onMostPlayedSectionStartLayout(double precedingToSection) {
    if (precedingToSection == _lastMostPlayedSectionPreceding) {
      return;
    }
    _lastMostPlayedSectionPreceding = precedingToSection;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mostPlayedBarSwitchAt == precedingToSection) {
        return;
      }
      setState(() {
        _mostPlayedBarSwitchAt = precedingToSection;
      });
    });
  }

  Widget _buildQuickEntryRow() {
    final l10n = AppLocalizations.of(context);
    final ids = widget.quickEntry.visibleInOrder;
    if (ids.isEmpty) {
      return Text(
        l10n.homeQuickEntryEmpty,
        style: TextStyle(
          color: context.gradFg(0.45),
          fontSize: 14,
          height: 1.35,
        ),
      );
    }
    final entries = <_QuickItem>[];
    for (final id in ids) {
      switch (id) {
        case QuickEntryConfig.idLibrary:
          entries.add(
            _QuickItem(
              l10n.homeEntryLibrary,
              Icons.library_music_rounded,
              const Color(0xFF4FC3F7),
              widget.onOpenLibrary,
            ),
          );
          break;
        case QuickEntryConfig.idPlaylists:
          entries.add(
            _QuickItem(
              l10n.homeEntryMyPlaylists,
              Icons.playlist_play_rounded,
              const Color(0xFF81C784),
              widget.onOpenStorage,
            ),
          );
          break;
        case QuickEntryConfig.idRecent:
          entries.add(
            _QuickItem(
              l10n.homeEntryRecent,
              Icons.history_rounded,
              const Color(0xFFFFB74D),
              widget.onOpenRecent,
            ),
          );
          break;
        case QuickEntryConfig.idMostPlayed:
          entries.add(
            _QuickItem(
              l10n.homeEntryMostPlayed,
              Icons.equalizer_rounded,
              const Color(0xFFFF8A65),
              widget.onOpenMostPlayed,
            ),
          );
          break;
        case QuickEntryConfig.idDiscover:
          entries.add(
            _QuickItem(
              l10n.homeEntryDiscover,
              Icons.explore_rounded,
              const Color(0xFFE57373),
              widget.onOpenSearch,
            ),
          );
          break;
        case QuickEntryConfig.idCloudLibrary:
          entries.add(
            _QuickItem(
              l10n.homeEntryCloudLibrary,
              Icons.cloud_queue_rounded,
              const Color(0xFF5C9CE6),
              widget.onOpenCloudLibrary,
            ),
          );
          break;
        case QuickEntryConfig.idOneDrive:
          entries.add(
            _QuickItem(
              l10n.homeEntryOneDrive,
              Icons.cloud_rounded,
              const Color(0xFF0078D4),
              widget.onOpenOneDrive,
            ),
          );
          break;
        case QuickEntryConfig.idOneDriveCachePlaylist:
          entries.add(
            _QuickItem(
              l10n.homeEntryOneDriveCachePlaylist,
              Icons.download_done_rounded,
              const Color(0xFF00897B),
              widget.onOpenOneDriveCachedPlaylist,
            ),
          );
          break;
        case QuickEntryConfig.idSongRecognizer:
          entries.add(
            _QuickItem(
              l10n.homeEntrySongRecognizer,
              Icons.mic_rounded,
              const Color(0xFFBA68C8),
              widget.onOpenMusicRecognition,
            ),
          );
          break;
      }
    }
    return _QuickEntryStrip(entries: entries);
  }

  /// 单一吸顶条：显示「最近」时叠在列表上为毛玻璃；切到「最多」后同逻辑以「最多」分节为界
  bool _computePlaybackSectionsFrosted() {
    final o = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : _lastScrollOffset;
    final sr = _recentPlaysSectionStartScroll;
    if (sr == null) {
      return false;
    }
    final sm = _mostPlayedBarSwitchAt;
    if (sm == null) {
      return o + 0.1 >= sr;
    }
    if (o + 0.1 < sm) {
      return o + 0.1 >= sr;
    }
    return o + 0.1 >= sm;
  }

  @override
  void didUpdateWidget(covariant _HomeScrollBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.play.initialized || !widget.showRecentList) {
      if (oldWidget.play.initialized != widget.play.initialized ||
          oldWidget.showRecentList != widget.showRecentList) {
        _mostPlayedBarSwitchAt = null;
        _lastMostPlayedSectionPreceding = -1.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPad = widget.safeBottom + 20.0;
    if (widget.scrollController.hasClients) {
      _lastScrollOffset = widget.scrollController.offset;
    }
    final o = _lastScrollOffset;
    final sm = _mostPlayedBarSwitchAt;
    final showMostInBar = sm != null && o + 0.1 >= sm;
    final useFrostedMerged = _computePlaybackSectionsFrosted();
    return ScrollConfiguration(
      behavior: const _HomeBodyScrollBehavior(),
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
            child: _GreetingBlock(
              greeting: widget.greeting,
              subtitle: widget.greetingSub,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapM)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _SearchPill(onTap: widget.onOpenSearch),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapL)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _buildContinue(context),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapL + 4)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _SectionTitle(
              title: l10n.homeSectionQuickEntry,
              actionLabel: l10n.homeActionManage,
              onAction: widget.onManageQuickEntry,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapS)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _buildQuickEntryRow(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: _hPad, right: 8, top: _gapL + 4),
            child: _SectionTitle(
              title: l10n.homeSectionMyPlaylists,
              actionLabel: l10n.homeActionManage,
              onAction: widget.onOpenStorage,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapS)),
        SliverToBoxAdapter(
          child: _PlaylistCarousels(
            play: widget.play,
            user: widget.user,
            onOpenAllSongs: widget.onOpenLibrary,
            onOpenPlaylist: widget.onOpenUserPlaylist,
            onCreate: widget.onOpenStorage,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: _gapL + 4),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            _onRecentSectionLayoutStart(constraints.precedingScrollExtent);
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _RecentAndMostPinnedHeaderDelegate(
            onOpenRecent: widget.onOpenRecent,
            onOpenMostPlayed: widget.onOpenMostPlayed,
            horizontalPadding: _hPad,
            showMost: showMostInBar,
            useFrosted: useFrostedMerged,
          ),
        ),
        if (!widget.play.initialized)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  l10n.homeLoadingLibrary,
                  style: TextStyle(
                    color: context.gradFg(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else if (!widget.showRecentList)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: context.gradFg(0.38),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          )
        else if (widget.recentSongs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 0),
              child: Text(
                l10n.homeRecentEmpty,
                style: TextStyle(
                  color: context.gradFg(0.45),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_hPad, _gapS - 2, _hPad, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = widget.recentSongs[i];
                  final isCurrent = widget.play.currentSong?.path == song.path;
                  return Padding(
                    key: ValueKey<String>('home_recent_${song.path}'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RecentPlayListRow(
                      song: song,
                      subtitle: widget.songSubtitle(song),
                      isCurrent: isCurrent,
                      onTap: () async {
                        if (isCurrent) {
                          await toggleCurrentRowPlayback(widget.play);
                          return;
                        }
                        await widget.play.setPlaybackQueueAndPlay(
                          List<Song>.from(widget.recentSongs),
                          i,
                          recordRecent: false,
                          bumpPlayCount: true,
                          session: PlaybackSessionSurface.recentList,
                        );
                      },
                    ),
                  );
                },
                childCount: widget.recentSongs.length,
              ),
            ),
          ),
        if (widget.play.initialized && widget.showRecentList) ...[
          SliverToBoxAdapter(child: SizedBox(height: _gapL)),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              _onMostPlayedSectionStartLayout(
                constraints.precedingScrollExtent,
              );
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
              child: _SectionTitle(
                title: l10n.homeSectionMostPlayed,
                actionLabel: l10n.homeActionAll,
                onAction: widget.onOpenMostPlayed,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: _gapS)),
          if (widget.mostPlayedItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
                child: Text(
                  widget.mostPlayedRaw.isNotEmpty
                      ? l10n.homeMostPlayedPathMismatch
                      : l10n.homeMostPlayedEmpty,
                  style: TextStyle(
                    color: context.gradFg(0.45),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = widget.mostPlayedItems[i];
                    final song = item.song;
                    final c = item.playCount;
                    final isCurrent =
                        widget.play.currentSong?.path == song.path;
                    return Padding(
                      key: ValueKey<String>(
                        'home_most_${song.path}_$c',
                      ),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RecentPlayListRow(
                        song: song,
                        subtitle: '',
                        trailingPlayCount: c,
                        isCurrent: isCurrent,
                        onTap: () async {
                          if (isCurrent) {
                            await toggleCurrentRowPlayback(widget.play);
                            return;
                          }
                          final q = widget.mostPlayedItems
                              .map((e) => e.song)
                              .toList();
                          await widget.play.setPlaybackQueueAndPlay(
                            q,
                            i,
                            recordRecent: true,
                            bumpPlayCount: false,
                            session: PlaybackSessionSurface.mostPlayedList,
                          );
                        },
                      ),
                    );
                  },
                  childCount: widget.mostPlayedItems.length,
                ),
              ),
            ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
      ],
      ),
    );
  }

  Widget _buildContinue(BuildContext context) {
    if (!widget.play.initialized) {
      return const SizedBox.shrink();
    }
    final cur = widget.play.currentSong;
    if (cur == null || widget.play.playList.isEmpty) {
      return _ContinueEmptyCard(onBrowse: widget.onOpenLibrary);
    }
    return const _ContinuePlayLive();
  }
}

/// 吸顶分节条：在「最近 / 最多」间切换（同一高度），滚过「最多」列表上沿前吸顶 50 的位置后由 [showMost] 显示「最多播放」，**不再**叠两条吸顶栏。
class _RecentAndMostPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RecentAndMostPinnedHeaderDelegate({
    required this.onOpenRecent,
    required this.onOpenMostPlayed,
    required this.horizontalPadding,
    required this.showMost,
    required this.useFrosted,
  });

  final VoidCallback onOpenRecent;
  final VoidCallback onOpenMostPlayed;
  final double horizontalPadding;
  final bool showMost;
  final bool useFrosted;

  static const double _h = 50;

  @override
  double get minExtent => _h;

  @override
  double get maxExtent => _h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context);
    final child = Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, 8, 0),
        child: showMost
            ? _SectionTitle(
                title: l10n.homeSectionMostPlayed,
                actionLabel: l10n.homeActionAll,
                onAction: onOpenMostPlayed,
              )
            : _SectionTitle(
                title: l10n.homeSectionRecentPlays,
                actionLabel: l10n.homeActionAll,
                onAction: onOpenRecent,
              ),
      ),
    );
    if (useFrosted) {
      return FrostedGlassPanel.pinnedSection(child: child);
    }
    return ColoredBox(
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(
    covariant _RecentAndMostPinnedHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.onOpenRecent != onOpenRecent ||
        oldDelegate.onOpenMostPlayed != onOpenMostPlayed ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.showMost != showMost ||
        oldDelegate.useFrosted != useFrosted;
  }
}

// ---------------------------------------------------------------------------
// 继续播放：实时进度
// ---------------------------------------------------------------------------

class _ContinuePlayLive extends StatelessWidget {
  const _ContinuePlayLive();

  @override
  Widget build(BuildContext context) {
    final play = context.watch<PlayListProvider>();
    final song = play.currentSong;
    if (song == null || play.playList.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<Duration>(
      stream: MusicService.positionStream,
      initialData: MusicService.lastPosition,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        final dur = MusicService.duration;
        final l10n = AppLocalizations.of(context);
        return _ContinuePlayCard(
          song: song,
          title: song.title ?? l10n.homeUnknownTitle,
          subtitle: _secondary(song, l10n),
          position: pos,
          duration: dur,
          onToggle: () async {
            if (MusicService.isPlaying) {
              await MusicService().pause();
            } else if (!MusicService.canUseResumeToPlay) {
              // 冷启动为 idle 或播完后 completed 时 resume 不发声，用当前索引重新 [playSong]
              await play.playAt(play.currentIndex);
            } else {
              MusicService().resume();
            }
          },
        );
      },
    );
  }

  String _secondary(Song s, AppLocalizations l10n) {
    if (s.artist == null || s.artist!.isEmpty) {
      return s.album ?? l10n.homeNowPlayingAlbum;
    }
    if (s.album == null || s.album!.isEmpty) {
      return s.artist!;
    }
    return '${s.artist} · ${s.album}';
  }
}

class _ContinueEmptyCard extends StatelessWidget {
  const _ContinueEmptyCard({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBrowse,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          decoration: BoxDecoration(
            color: context.gradBorder(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.gradBorder(0.1)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 40,
                color: context.gradFg(0.4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeNothingPlaying,
                      style: TextStyle(
                        color: context.gradFg(0.9),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeOpenLibraryToPlay,
                      style: TextStyle(
                        color: context.gradFg(0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.gradFg(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 我的歌单横滑
// ---------------------------------------------------------------------------

/// 首页「我的歌单」混色卡宽度；快捷入口正方形边长上限略小于此值（视觉上仍一眼小于歌单卡）。
const double _kHomePlaylistMixCardWidth = 128;

class _PlaylistCarousels extends StatelessWidget {
  const _PlaylistCarousels({
    required this.play,
    required this.user,
    required this.onOpenAllSongs,
    required this.onOpenPlaylist,
    required this.onCreate,
  });
  final PlayListProvider play;
  final UserPlaylistProvider user;
  final VoidCallback onOpenAllSongs;
  final void Function(String id) onOpenPlaylist;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!user.initialized) {
      return SizedBox(
        height: 168,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: context.gradFg(0.3),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    final allN = play.initialized ? play.libraryMergedSongs.length : 0;
    final allSubtitle = !play.initialized
        ? l10n.homeAllSongsLoading
        : (allN == 0
            ? l10n.homeScanMusicFolder
            : l10n.homeTrackCount(allN));
    final libCover = user.homeLibraryCoverStyle ??
        UserPlaylistCoverStyle.gradient(
          const Color(0xFF1565C0),
          const Color(0xFF0D47A1),
        );
    final libTitle = user.resolvedHomeLibraryTitle(l10n.homeAllSongs);
    final allCard = _MixCard(
      title: libTitle,
      subtitle: allSubtitle,
      decoration: playlistCoverCardDecoration(
        coverStyle: libCover,
        fallbackGradientIndex: 0,
      ),
      onTap: onOpenAllSongs,
    );
    final order = user.resolvedHomeCarouselOrder();
    final list = user.playlists;
    final rowChildren = <Widget>[];

    void pushSpacingIfNeeded() {
      if (rowChildren.isNotEmpty) {
        rowChildren.add(const SizedBox(width: 12));
      }
    }

    var playlistOrdinal = 0;
    for (final key in order) {
      if (key == UserPlaylistProvider.homeCarouselLibrarySentinel) {
        pushSpacingIfNeeded();
        rowChildren.add(allCard);
        continue;
      }
      final p = user.playlistById(key);
      if (p == null) continue;
      pushSpacingIfNeeded();
      final pi = playlistOrdinal++;
      final n = p.songPaths.length;
      rowChildren.add(
        _MixCard(
          title: p.name,
          subtitle:
              n == 0 ? l10n.homeEmptyPlaylist : l10n.homeTrackCount(n),
          decoration: playlistCoverCardDecoration(
            coverStyle: p.coverStyle,
            fallbackGradientIndex: pi,
          ),
          onTap: () => onOpenPlaylist(p.id),
        ),
      );
    }

    if (list.isEmpty) {
      return SizedBox(
        height: 168,
        child: ScrollConfiguration(
          behavior: const _HomeHorizontalScrollBehavior(),
          child: ListView(
            primary: false,
            padding: const EdgeInsets.only(left: 20, right: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            clipBehavior: Clip.hardEdge,
            children: [
              ...rowChildren,
              const SizedBox(width: 12),
              _MixCard(
                title: l10n.homeCreatePlaylist,
                subtitle: l10n.homeCreatePlaylistSub,
                decoration: playlistCoverCardDecoration(
                  coverStyle: UserPlaylistCoverStyle.gradient(
                    const Color(0xFF37474F),
                    const Color(0xFF455A64),
                  ),
                  fallbackGradientIndex: 0,
                ),
                onTap: onCreate,
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: ScrollConfiguration(
        behavior: const _HomeHorizontalScrollBehavior(),
        child: ListView(
          primary: false,
          padding: const EdgeInsets.only(left: 20, right: 8),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          clipBehavior: Clip.hardEdge,
          children: rowChildren,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 子组件
// ---------------------------------------------------------------------------

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.greeting, required this.subtitle});
  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: context.gradBorder(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.gradBorder(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.homeGreetingLine(greeting),
            style: TextStyle(
              color: context.gradFg(0.95),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: context.gradFg(0.45),
              fontSize: 13,
              height: 1.35,
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.gradBorder(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.gradBorder(0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: context.gradFg(0.45),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.homeSearchHint,
                  style: TextStyle(
                    color: context.gradFg(0.45),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: context.gradFg(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.gradFg(0.95),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: context.gradFg(0.45),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContinuePlayCard extends StatefulWidget {
  const _ContinuePlayCard({
    required this.song,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.duration,
    required this.onToggle,
  });

  final Song song;
  final String title;
  final String subtitle;
  final Duration position;
  final Duration? duration;
  final Future<void> Function() onToggle;

  @override
  State<_ContinuePlayCard> createState() => _ContinuePlayCardState();
}

class _ContinuePlayCardState extends State<_ContinuePlayCard> {
  Uint8List? _coverBytes;
  double? _dragFraction;

  @override
  void initState() {
    super.initState();
    _syncBytesFromSong();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateCoverIfNeeded());
  }

  @override
  void didUpdateWidget(_ContinuePlayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      setState(() {
        _coverBytes = null;
        _dragFraction = null;
        _syncBytesFromSong();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateCoverIfNeeded());
    }
  }

  void _syncBytesFromSong() {
    final b = widget.song.imageBytes;
    _coverBytes = (b != null && b.isNotEmpty) ? b : null;
  }

  Future<void> _hydrateCoverIfNeeded() async {
    if (_coverBytes != null && _coverBytes!.isNotEmpty) return;
    await SongLibraryMetadataHydrator.hydrateIfNeeded(widget.song);
    if (!mounted) return;
    final prev = _coverBytes;
    _syncBytesFromSong();
    if (_coverBytes != prev) {
      setState(() {});
    }
  }

  void _onCoverDecodeFailed() {
    if (_coverBytes == null) return;
    setState(() => _coverBytes = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final useCover = _coverBytes != null && _coverBytes!.isNotEmpty;

    final badgeFill =
        useCover ? Colors.white.withValues(alpha: 0.22) : context.gradBorder(0.2);
    final progressBg =
        useCover ? Colors.white.withValues(alpha: 0.28) : context.gradBorder(0.25);

    final fg = context.gradFg();
    final dur = widget.duration;
    final canSeek = dur != null && dur.inMilliseconds > 0;

    double effectiveFraction() {
      final drag = _dragFraction;
      if (drag != null) return drag.clamp(0.0, 1.0);
      if (!canSeek) return 0.0;
      return (widget.position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    }

    final titleBlock = InkWell(
      onTap: () => widget.onToggle(),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.homeContinuePlaying,
                  style: TextStyle(
                    color: context.gradFg(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              StreamBuilder<bool>(
                stream: MusicService.playingStream,
                initialData: MusicService.isPlaying,
                builder: (context, snap) {
                  final playing = snap.data ?? false;
                  return Icon(
                    playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: context.gradFg(0.95),
                    size: 32,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.gradFg(),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.gradFg(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    int playbackMsForWave() {
      final drag = _dragFraction;
      final d = widget.duration;
      if (drag != null && d != null && d.inMilliseconds > 0) {
        return (drag * d.inMilliseconds).round().clamp(0, d.inMilliseconds);
      }
      return widget.position.inMilliseconds;
    }

    final progressWave = WaveProgressBar(
      value: effectiveFraction(),
      playbackMs: playbackMsForWave(),
      trackDurationMs: dur?.inMilliseconds ?? 0,
      rhythmSeed: widget.song.path.hashCode,
      activeColor: fg,
      inactiveBaseColor: progressBg,
      enabled: canSeek,
      height: 28,
      onChanged: canSeek
          ? (v) => setState(() => _dragFraction = v)
          : null,
      onChangeStart: canSeek
          ? () {
              final d = widget.duration;
              if (d == null || d.inMilliseconds <= 0) return;
              setState(() {
                _dragFraction =
                    (widget.position.inMilliseconds / d.inMilliseconds)
                        .clamp(0.0, 1.0);
              });
            }
          : null,
      onChangeEnd: canSeek
          ? (v) async {
              setState(() => _dragFraction = null);
              final d = widget.duration;
              if (d != null && d.inMilliseconds > 0) {
                final ms =
                    (v * d.inMilliseconds).round().clamp(0, d.inMilliseconds);
                await MusicService().seek(Duration(milliseconds: ms));
              }
              if (mounted) setState(() {});
            }
          : null,
    );

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleBlock,
        const SizedBox(height: 16),
        progressWave,
      ],
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: useCover
                ? Colors.white.withValues(alpha: 0.22)
                : context.gradBorder(0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: useCover
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            _coverBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _onCoverDecodeFailed();
                              });
                              return const ColoredBox(color: Colors.transparent);
                            },
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.42),
                                  Colors.black.withValues(alpha: 0.74),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ColoredBox(color: context.gradBorder(0.08)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: cardBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem(this.label, this.icon, this.tint, this.onTap);
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
}

/// 首页横向列表：鼠标拖拽、触控板、触屏均参与滚动（默认 [MaterialScrollBehavior] 在部分平台不含鼠标）。
class _HomeHorizontalScrollBehavior extends MaterialScrollBehavior {
  const _HomeHorizontalScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// 快捷入口：每项为正方形；边长在 [_sideMin]～[_sideMax] 内随窗口平滑变化；排不下时横滑且单屏约 3 个。
class _QuickEntryStrip extends StatelessWidget {
  const _QuickEntryStrip({required this.entries});

  final List<_QuickItem> entries;

  static const double _gap = 10;
  static const double _sideMin = 88;
  static const double _sideMax = _kHomePlaylistMixCardWidth - 4;
  /// 极窄窗口下滚动时的下限，避免算不出布局。
  static const double _sideAbsMin = 48;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final n = entries.length;
        if (n == 0) {
          return const SizedBox.shrink();
        }

        final rawIdeal = (w - (n - 1) * _gap) / n;
        final ideal = rawIdeal.clamp(_sideMin, _sideMax);
        final contentIdeal = n * ideal + (n - 1) * _gap;

        late final double side;
        late final bool scroll;

        if (contentIdeal <= w + 0.5) {
          side = ideal;
          scroll = false;
        } else {
          final cap3 = (w - 2 * _gap) / 3;
          side = math.min(ideal, cap3).clamp(_sideAbsMin, _sideMax);
          final total = n * side + (n - 1) * _gap;
          scroll = total > w + 0.5;
        }

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              SizedBox(
                width: side,
                height: side,
                child: _QuickEntryTile(side: side, item: entries[i]),
              ),
              if (i < n - 1) const SizedBox(width: _gap),
            ],
          ],
        );

        final contentW = n * side + (n - 1) * _gap;

        if (!scroll) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: contentW,
              height: side,
              child: row,
            ),
          );
        }

        return ScrollConfiguration(
          behavior: const _HomeHorizontalScrollBehavior(),
          child: SizedBox(
            height: side,
            width: w,
            child: SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              clipBehavior: Clip.hardEdge,
              child: row,
            ),
          ),
        );
      },
    );
  }
}

class _QuickEntryTile extends StatelessWidget {
  const _QuickEntryTile({required this.side, required this.item});

  final double side;
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    final radius = (side * 0.14).clamp(11.0, 17.0);
    final iconBox = (side * 0.46).clamp(38.0, 62.0);
    final iconGlyph = (iconBox * 0.56).clamp(24.0, 36.0);
    final labelSize = (side * 0.155).clamp(11.0, 14.5);
    final pad = (side * 0.07).clamp(4.0, 10.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.gradBorder(0.16),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: context.gradBorder(0.18),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.85),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: item.tint.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        color: item.tint.withValues(alpha: 0.95),
                        size: iconGlyph,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (side * 0.04).clamp(2.0, 6.0)),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.gradFg(0.9),
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  const _MixCard({
    required this.title,
    required this.subtitle,
    required this.decoration,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  /// 与外层 [ListView] 视口高度一致，避免仅靠文字撑高导致封面/渐变被纵向压扁。
  static const double _cardHeight = 168;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kHomePlaylistMixCardWidth,
      height: _cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: decoration,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.gradFg(),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.gradFg(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

