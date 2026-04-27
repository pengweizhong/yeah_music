import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/playback_session_surface.dart';
import '../navigation/app_route_observer.dart';
import '../utils/scroll_list_to_current_song.dart';
import '../utils/song_list_sort.dart';
import '../utils/song_path_utils.dart';
import '../widgets/compact_song_list_row.dart';
import '../widgets/scroll_aware_list_frame.dart';
import '../widgets/scroll_to_current_locate_layer.dart';
import '../widgets/song_sort_bottom_sheet.dart';

@immutable
class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key, this.openSearchOnOpen = false});

  /// 为 true 时在进入页后自动打开搜索（如主页「发现/搜索」）
  final bool openSearchOnOpen;

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> with RouteAware {
  final ScrollController _listScrollController = ScrollController();
  bool _routeObserverSubscribed = false;
  /// 已按该规范化路径自动滚过屏；仅在一次 [scheduleScrollListToCurrentSong] 的 [onScrollApplied] 中写入。
  String? _lastAutoScrollPathNorm;
  /// 防 build 在首次未挂接时重复排队；在 [onScrollApplied]/[onScrollFailed] 中清除
  bool _autoscrollInFlight = false;

  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  List<Song> _filteredSongs = [];

  List<Song>? _memoSortSourceRef;
  SongListSortType? _memoSortType;
  bool? _memoSortAsc;
  List<Song> _memoSorted = const [];

  /// 在 [playList] 与排序不变时复用结果，避免每次 notify（如切歌）都全量排序
  List<Song> _sortedForPlayList(List<Song> source) {
    if (_memoSortSourceRef != null &&
        identical(_memoSortSourceRef, source) &&
        _memoSortType == _sortType &&
        _memoSortAsc == _isAscending) {
      return _memoSorted;
    }
    _memoSortSourceRef = source;
    _memoSortType = _sortType;
    _memoSortAsc = _isAscending;
    _memoSorted = _getFilteredAndSortedSongs(source);
    return _memoSorted;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        appRouteObserver.subscribe(this, route);
        _routeObserverSubscribed = true;
      }
    }
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    final pl = context.read<PlayListProvider>();
    final list = pl.playList;
    if (list.isEmpty) return;
    // 不依赖 [Selector] 一定重建：用当前排序现算一份，与列表展示一致
    final songs = _sortedForPlayList(list);
    if (songs.isEmpty) return;
    if (_autoscrollInFlight) return;
    _autoscrollInFlight = true;
    scheduleScrollListToCurrentSong(
      context: context,
      controller: _listScrollController,
      songs: songs,
      itemExtent: 80,
      playList: pl,
      onScrollApplied: (p) {
        if (!mounted) return;
        setState(() {
          _lastAutoScrollPathNorm = p;
          _autoscrollInFlight = false;
        });
      },
      onScrollFailed: () {
        if (!mounted) return;
        setState(() => _autoscrollInFlight = false);
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // 加载排序配置
    _loadSortSettings();

    // 使用postFrameCallback避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final folderProvider = context.read<FolderProvider>();
      final playListProvider = context.read<PlayListProvider>();
      if (!playListProvider.initialized) {
        appLog.d('曲库页: 正在初始化 PlayListProvider');
        await playListProvider.init(folderProvider);
      }
      if (!context.mounted) return;
      if (playListProvider.hasPlaybackQueueOverride) {
        playListProvider.clearPlaybackQueueOverride();
      }
      if (!mounted) return;
      if (widget.openSearchOnOpen) {
        if (!context.mounted) return;
        final sorted = _getFilteredAndSortedSongs(playListProvider.playList);
        final l10n = AppLocalizations.of(context);
        showSearch(
          context: context,
          delegate: SongSearchDelegate(
            sorted,
            playListProvider,
            searchFieldLabelText: l10n.playlistSearchHint,
          ),
        );
      }
    });
  }

  Future<void> _loadSortSettings() async {
    try {
      final prefs = await loadSongSortPreferences();
      if (mounted) {
        setState(() {
          _sortType = prefs.type;
          _isAscending = prefs.ascending;
        });
        appLog.d('曲库页: 排序已加载 ($_sortType, asc=$_isAscending)');
      }
    } catch (e) {
      appLog.e('曲库页: 加载排序设置失败', error: e);
    }
  }

  Future<void> _saveSortSettings() async {
    try {
      await saveSongSortPreferences(_sortType, _isAscending);
      appLog.d('曲库页: 已保存排序 ($_sortType, asc=$_isAscending)');
    } catch (e) {
      appLog.e('曲库页: 保存排序设置失败', error: e);
    }
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _listScrollController.dispose();
    super.dispose();
  }

  List<Song> _getFilteredAndSortedSongs(List<Song> songs) {
    return sortSongsCopy(songs, _sortType, _isAscending);
  }

  void _showSortOptions() {
    showSongSortBottomSheet(
      context,
      sortType: _sortType,
      isAscending: _isAscending,
      onApply: (type, ascending) {
        setState(() {
          _sortType = type;
          _isAscending = ascending;
          _lastAutoScrollPathNorm = null;
          _autoscrollInFlight = false;
        });
        _saveSortSettings();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayListProvider>(
      builder: (context, playListProvider, _) {
        final playList = playListProvider.playList;
        _filteredSongs = _sortedForPlayList(playList);
        final current = playListProvider.currentSong;
        if (current == null) {
          _lastAutoScrollPathNorm = null;
          _autoscrollInFlight = false;
        } else if (_filteredSongs.isNotEmpty) {
          final n = normSongPath(current.path);
          if (n != _lastAutoScrollPathNorm && !_autoscrollInFlight) {
            _autoscrollInFlight = true;
            scheduleScrollListToCurrentSong(
              context: context,
              controller: _listScrollController,
              songs: _filteredSongs,
              itemExtent: 80,
              playList: playListProvider,
              onScrollApplied: (p) {
                if (!mounted) return;
                setState(() {
                  _lastAutoScrollPathNorm = p;
                  _autoscrollInFlight = false;
                });
              },
              onScrollFailed: () {
                if (!mounted) return;
                setState(() => _autoscrollInFlight = false);
              },
            );
          }
        }
        final pathToIndex = <String, int>{
          for (var i = 0; i < playList.length; i++) playList[i].path: i,
        };
        return Consumer<ThemeConfigProvider>(
          builder: (context, themeConfig, child) {
            final l10n = AppLocalizations.of(context);
            return themeConfig.buildThemedBackground(
              context: context,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(
                    l10n.menuSongList,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    // 搜索按钮
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: SongSearchDelegate(
                            _filteredSongs,
                            playListProvider,
                            searchFieldLabelText: l10n.playlistSearchHint,
                          ),
                        );
                      },
                      tooltip: l10n.homeSearchTooltip,
                    ),
                    // 排序按钮
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: _showSortOptions,
                      tooltip: l10n.tooltipSort,
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // 顶部间距
                    SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),

                    // 歌曲列表
                    Expanded(
                      child: _filteredSongs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.songsListEmpty,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SongListScrollToCurrentLocate(
                              controller: _listScrollController,
                              songs: _filteredSongs,
                              itemExtent: 80,
                              playList: playListProvider,
                              child: ScrollAwareListFrame(
                                child: ListView.builder(
                                  controller: _listScrollController,
                                  itemExtent: 80,
                                  cacheExtent: 280,
                                  padding: const EdgeInsets.only(bottom: 100),
                                  itemCount: _filteredSongs.length,
                                  itemBuilder: (context, index) {
                                    final song = _filteredSongs[index];
                                    final originalIndex =
                                        pathToIndex[song.path] ?? 0;
                                    final isRowCurrent = current != null &&
                                        songPathsEqual(
                                          song.path,
                                          current.path,
                                        );
                                    return CompactSongListRow(
                                      key: ValueKey<String>(song.path),
                                      song: song,
                                      title: song.title ?? l10n.pageUnknownTitle,
                                      subtitle: showSecondTitle(song),
                                      isCurrent: isRowCurrent,
                                      onTap: () async {
                                        if (isRowCurrent) {
                                          await toggleCurrentRowPlayback(
                                            playListProvider,
                                          );
                                          return;
                                        }
                                        playListProvider
                                            .setPlaybackListSessionForLibrary();
                                        if (playListProvider
                                            .hasPlaybackQueueOverride) {
                                          await playListProvider
                                              .playAt(originalIndex);
                                        } else {
                                          await playListProvider.playAt(
                                            originalIndex,
                                            listSession: PlaybackSessionSurface
                                                .library,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                bottomNavigationBar: const MiniPlayer(),
              ),
            );
          },
        );
      },
    );
  }

  String showSecondTitle(Song song) {
    if (song.artist == null || song.artist!.isEmpty) {
      return song.album ?? "";
    }
    if (song.album == null || song.album!.isEmpty) {
      return song.artist!;
    }
    return "${song.artist} - ${song.album}";
  }
}

/// 搜索代理；[playbackContextQueue] 非空时，选中歌曲将按该队列播放（如用户歌单页）
class SongSearchDelegate extends SearchDelegate<Song?> {
  final List<Song> allSongs;
  final PlayListProvider playListProvider;
  final List<Song>? playbackContextQueue;

  /// 当 [playbackContextQueue] 为用户歌单时传入，用于 [PlaybackSessionSurface.userPlaylist]
  final String? userPlaylistIdForContext;

  SongSearchDelegate(
    this.allSongs,
    this.playListProvider, {
    this.playbackContextQueue,
    this.userPlaylistIdForContext,
    required this.searchFieldLabelText,
  }) : super(
         searchFieldStyle: const TextStyle(
           color: Colors.white,
           fontSize: 20,
           fontWeight: FontWeight.w400,
         ),
       );

  final String searchFieldLabelText;

  @override
  String get searchFieldLabel => searchFieldLabelText;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        toolbarTextStyle: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
      ),
    );
  }

  @override
  Widget? buildFlexibleSpace(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: const SizedBox.expand(),
        );
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: _buildSearchResultsContent(context),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsContent(BuildContext context) {
    final results = allSongs.where((song) {
      final q = query.toLowerCase();
      final title = (song.title ?? '').toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final fileName = song.path.split('/').last.toLowerCase();
      return title.contains(q) || artist.contains(q) || fileName.contains(q);
    }).toList();

    if (results.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoMatchingSongs,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<PlayListProvider>(
      builder: (context, p, _) {
        final mainList = p.playList;
        final pathToMainIndex = <String, int>{
          for (var i = 0; i < mainList.length; i++) mainList[i].path: i,
        };
        final current = p.currentSong;
        final l10n = AppLocalizations.of(context);
        return ScrollAwareListFrame(
          child: ListView.builder(
            itemExtent: 80,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final song = results[index];
              final isRowCurrent = current != null &&
                  songPathsEqual(song.path, current.path);
              return CompactSongListRow(
                key: ValueKey('search_${song.path}'),
                song: song,
                title: song.title ?? l10n.pageUnknownTitle,
                subtitle: song.artist ?? song.album ?? '',
                isCurrent: isRowCurrent,
                onTap: () async {
                  close(context, song);
                  if (isRowCurrent) {
                    await toggleCurrentRowPlayback(p);
                    return;
                  }
                  if (playbackContextQueue != null) {
                    final q = playbackContextQueue!;
                    final idx = q.indexWhere((s) => s.path == song.path);
                    if (idx < 0) return;
                    await p.setPlaybackQueueAndPlay(
                      q,
                      idx,
                      session: PlaybackSessionSurface.userPlaylist,
                      userPlaylistId: userPlaylistIdForContext,
                    );
                    return;
                  }
                  final originalIndex = pathToMainIndex[song.path] ?? -1;
                  if (originalIndex < 0) return;
                  if (!context.mounted) return;
                  p.setPlaybackListSessionForLibrary();
                  await p.playAt(
                    originalIndex,
                    listSession: PlaybackSessionSurface.library,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
