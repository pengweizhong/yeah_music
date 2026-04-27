import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/menu_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/recent_plays_page.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/widgets/recent_play_list_row.dart';

/// 应用主页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _recentPaths = [];
  bool _recentReady = false;
  PlayListProvider? _play;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrap();
      if (!mounted) return;
      _play = context.read<PlayListProvider>();
      _play!.addListener(_onPlayListChange);
    });
  }

  void _onPlayListChange() {
    _loadRecentPaths();
  }

  @override
  void dispose() {
    _play?.removeListener(_onPlayListChange);
    super.dispose();
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
      await play.init(folder);
    }
    if (!mounted) return;
    await _loadRecentPaths();
  }

  Future<void> _loadRecentPaths() async {
    // 多取一些路径，避免前几条在「临时歌单队列」中无法解析时整区空白
    final p = await RecentPlayService.getPaths(limit: 50);
    if (!mounted) return;
    setState(() {
      _recentPaths = p;
      _recentReady = true;
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  Future<void> _openSongForIndex(int index) async {
    if (!context.mounted) return;
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final saved =
        box.get('last_song_page', defaultValue: 0) as int? ?? 0;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => SongPage(
          index: index,
          initialPage: saved.clamp(0, 1),
        ),
      ),
    );
  }

  void _goLibrary({bool openSearch = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayListPage(openSearchOnOpen: openSearch),
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
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return Container(
          decoration: themeConfig.getBackgroundDecoration(),
          child: Scaffold(
            key: _scaffoldKey,
            extendBodyBehindAppBar: false,
            extendBody: false,
            backgroundColor: Colors.transparent,
            drawer: const MenuPage(),
            appBar: AppBar(
              centerTitle: false,
              title: Text(
                'Yeah Music',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: '菜单',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 26),
                  onPressed: () => _goLibrary(openSearch: true),
                  tooltip: '搜索',
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
                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  onRefresh: _loadRecentPaths,
                  child: _HomeScrollBody(
                    safeBottom: MediaQuery.paddingOf(context).bottom + 8,
                    greeting: _greeting(),
                    play: play,
                    user: user,
                    recentSongs: recentSongs,
                    showRecentList: _recentReady,
                    onOpenLibrary: () => _goLibrary(),
                    onOpenSearch: () => _goLibrary(openSearch: true),
                    onOpenStorage: _goStoragePlaylists,
                    onOpenRecent: _goRecentPlays,
                    onOpenSongIndex: (i) => _openSongForIndex(i),
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

class _HomeScrollBody extends StatelessWidget {
  const _HomeScrollBody({
    required this.safeBottom,
    required this.greeting,
    required this.play,
    required this.user,
    required this.recentSongs,
    required this.showRecentList,
    required this.onOpenLibrary,
    required this.onOpenSearch,
    required this.onOpenStorage,
    required this.onOpenRecent,
    required this.onOpenSongIndex,
    required this.onOpenUserPlaylist,
    required this.songSubtitle,
  });

  final double safeBottom;
  final String greeting;
  final PlayListProvider play;
  final UserPlaylistProvider user;
  final List<Song> recentSongs;
  final bool showRecentList;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenStorage;
  final VoidCallback onOpenRecent;
  final Future<void> Function(int index) onOpenSongIndex;
  final void Function(String playlistId) onOpenUserPlaylist;
  final String Function(Song) songSubtitle;

  static const _hPad = 20.0;
  static const _gapL = 24.0;
  static const _gapM = 16.0;
  static const _gapS = 12.0;

  @override
  Widget build(BuildContext context) {
    final bottomPad = safeBottom + 20.0;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
            child: _GreetingBlock(greeting: greeting),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapM)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _SearchPill(onTap: onOpenSearch),
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
              title: '快捷入口',
              actionLabel: '管理',
              onAction: onOpenStorage,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapS)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: _QuickEntryRow(
              entries: [
                _QuickItem(
                  '本地曲库',
                  Icons.library_music_rounded,
                  const Color(0xFF4FC3F7),
                  onOpenLibrary,
                ),
                _QuickItem(
                  '我的歌单',
                  Icons.playlist_play_rounded,
                  const Color(0xFF81C784),
                  onOpenStorage,
                ),
                _QuickItem(
                  '最近播放',
                  Icons.history_rounded,
                  const Color(0xFFFFB74D),
                  onOpenRecent,
                ),
                _QuickItem(
                  '发现',
                  Icons.explore_rounded,
                  const Color(0xFFE57373),
                  () => onOpenSearch(),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: _hPad, right: 8, top: _gapL + 4),
            child: _SectionTitle(
              title: '我的歌单',
              actionLabel: '更多',
              onAction: onOpenStorage,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _gapS)),
        SliverToBoxAdapter(
          child: _PlaylistCarousels(
            user: user,
            onOpenPlaylist: onOpenUserPlaylist,
            onCreate: onOpenStorage,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: _gapL + 4),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _RecentPlaysHeaderDelegate(
            onOpenRecent: onOpenRecent,
            horizontalPadding: _hPad,
          ),
        ),
        if (!play.initialized)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  '正在加载曲库…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else if (!showRecentList)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white38,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          )
        else if (recentSongs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 0),
              child: Text(
                '暂无最近播放，在曲库或歌单中播放歌曲后会显示',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
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
                  final song = recentSongs[i];
                  final isCurrent = play.currentSong?.path == song.path;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RecentPlayListRow(
                      song: song,
                      subtitle: songSubtitle(song),
                      isCurrent: isCurrent,
                      onTap: () async {
                        final idx = play.indexInLibraryByPath(song.path);
                        if (idx < 0) return;
                        play.clearPlaybackQueueOverride();
                        await play.playAt(idx);
                        if (!context.mounted) return;
                        await onOpenSongIndex(idx);
                      },
                    ),
                  );
                },
                childCount: recentSongs.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
      ],
    );
  }

  Widget _buildContinue(BuildContext context) {
    if (!play.initialized) {
      return const SizedBox.shrink();
    }
    final cur = play.currentSong;
    if (cur == null || play.playList.isEmpty) {
      return _ContinueEmptyCard(onBrowse: onOpenLibrary);
    }
    return const _ContinuePlayLive();
  }
}

/// 让「最近播放」标题在向下滚动时吸附在 [CustomScrollView] 顶部，类似表头冻结
class _RecentPlaysHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RecentPlaysHeaderDelegate({
    required this.onOpenRecent,
    required this.horizontalPadding,
  });

  final VoidCallback onOpenRecent;
  final double horizontalPadding;

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
    // 与「我的歌单」分节相同：仅标题，背景透明，不单独铺色块
    return ColoredBox(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, 8, 0),
          child: _SectionTitle(
            title: '最近播放',
            actionLabel: '全部',
            onAction: onOpenRecent,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RecentPlaysHeaderDelegate oldDelegate) {
    return oldDelegate.onOpenRecent != onOpenRecent ||
        oldDelegate.horizontalPadding != horizontalPadding;
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
        final p = (dur != null && dur.inMilliseconds > 0)
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        return _ContinuePlayCard(
          title: song.title ?? '未知',
          subtitle: _secondary(song),
          progress: p,
          onToggle: () async {
            if (MusicService.isPlaying) {
              await MusicService().pause();
            } else {
              MusicService().resume();
            }
          },
        );
      },
    );
  }

  String _secondary(Song s) {
    if (s.artist == null || s.artist!.isEmpty) {
      return s.album ?? '正在播放';
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBrowse,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 40,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '还没有在播放',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '去本地曲库选一首歌开始',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
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

const _kMixGradients = <List<Color>>[
  [Color(0xFF1A237E), Color(0xFF3949AB)],
  [Color(0xFF004D40), Color(0xFF00695C)],
  [Color(0xFF4A148C), Color(0xFF6A1B9A)],
  [Color(0xFFBF360C), Color(0xFFE64A19)],
];

class _PlaylistCarousels extends StatelessWidget {
  const _PlaylistCarousels({
    required this.user,
    required this.onOpenPlaylist,
    required this.onCreate,
  });
  final UserPlaylistProvider user;
  final void Function(String id) onOpenPlaylist;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (!user.initialized) {
      return const SizedBox(
        height: 168,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white30,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    final list = user.playlists;
    if (list.isEmpty) {
      return SizedBox(
        height: 168,
        child: ListView(
          padding: const EdgeInsets.only(left: 20, right: 8),
          scrollDirection: Axis.horizontal,
          children: [
            _MixCard(
              title: '创建歌单',
              subtitle: '集中收藏你喜欢的歌',
              c1: const Color(0xFF37474F),
              c2: const Color(0xFF455A64),
              onTap: onCreate,
            ),
          ],
        ),
      );
    }
    final take = list.length > 4 ? 4 : list.length;
    return SizedBox(
      height: 168,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 20, right: 8),
        scrollDirection: Axis.horizontal,
        itemCount: take,
        separatorBuilder: (context, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = list[i];
          final g = _kMixGradients[i % _kMixGradients.length];
          final n = p.songPaths.length;
          return _MixCard(
            title: p.name,
            subtitle: n == 0 ? '空歌单' : '$n 首',
            c1: g[0],
            c2: g[1],
            onTap: () => onOpenPlaylist(p.id),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 子组件
// ---------------------------------------------------------------------------

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$greeting，今天想听点什么？',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            '从下面继续上次的歌，或选一张歌单开始',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.45),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '搜索歌曲、歌手、歌单',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
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
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinuePlayCard extends StatelessWidget {
  const _ContinuePlayCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onToggle,
  });
  final String title;
  final String subtitle;
  final double progress;
  final Future<void> Function() onToggle;
  static const _accentStart = Color(0xFF7C4DFF);
  static const _accentEnd = Color(0xFF536DFE);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onToggle(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentStart, _accentEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: _accentStart.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '继续播放',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
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
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 32,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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

class _QuickEntryRow extends StatelessWidget {
  const _QuickEntryRow({required this.entries});
  final List<_QuickItem> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(
            child: _QuickEntryTile(
              item: entries[i],
            ),
          ),
          if (i < entries.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickEntryTile extends StatelessWidget {
  const _QuickEntryTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.tint.withValues(alpha: 0.95),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    required this.c1,
    required this.c2,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 128,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

