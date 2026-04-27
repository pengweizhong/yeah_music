import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';
import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/folder.dart';
import '../utils/song_list_sort.dart';
import '../widgets/add_to_user_playlists_sheet.dart';
import '../widgets/scroll_aware_list_frame.dart';
import '../widgets/song_list_cover.dart';
import '../widgets/song_sort_bottom_sheet.dart';

var log = Logger(printer: SimplePrinter());

@immutable
class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key, this.openSearchOnOpen = false});

  /// 为 true 时在进入页后自动打开搜索（如主页「发现/搜索」）
  final bool openSearchOnOpen;

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> {
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
  void initState() {
    super.initState();

    // 加载排序配置
    _loadSortSettings();

    // 使用postFrameCallback避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final folderProvider = context.read<FolderProvider>();
      final playListProvider = context.read<PlayListProvider>();
      if (!playListProvider.initialized) {
        log.d("初始化全部歌单列表");
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
        showSearch(
          context: context,
          delegate: SongSearchDelegate(sorted, playListProvider),
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
        log.d("加载排序设置: $_sortType, 正序: $_isAscending");
      }
    } catch (e) {
      log.e("加载排序设置失败: $e");
    }
  }

  Future<void> _saveSortSettings() async {
    try {
      await saveSongSortPreferences(_sortType, _isAscending);
      log.d("保存排序设置: $_sortType, 正序: $_isAscending");
    } catch (e) {
      log.e("保存排序设置失败: $e");
    }
  }

  @override
  void dispose() {
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
        });
        _saveSortSettings();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayListProvider, List<Song>>(
      selector: (_, p) => p.playList,
      shouldRebuild: (a, b) => !identical(a, b) || a.length != b.length,
      builder: (context, playList, _) {
        final playListProvider = context.read<PlayListProvider>();
        _filteredSongs = _sortedForPlayList(playList);
        final pathToIndex = <String, int>{
          for (var i = 0; i < playList.length; i++) playList[i].path: i,
        };
        return Consumer<ThemeConfigProvider>(
          builder: (context, themeConfig, child) {
            return themeConfig.buildThemedBackground(
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: const Text(
                    "歌曲列表",
                    style: TextStyle(color: Colors.white),
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
                          ),
                        );
                      },
                      tooltip: '搜索',
                    ),
                    // 排序按钮
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: _showSortOptions,
                      tooltip: '排序',
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
                                    '暂无歌曲',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                      : ScrollAwareListFrame(
                          child: ListView.builder(
                            // 略增大预建范围，快滑时减少「出屏再入屏才解码」的顿挫
                            cacheExtent: 480,
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _filteredSongs.length,
                            itemBuilder: (context, index) {
                                final song = _filteredSongs[index];
                                final originalIndex =
                                    pathToIndex[song.path] ?? 0;
                                return ListTile(
                                  key: ValueKey<String>(song.path),
                                  leading: SongListCover(
                                    song: song,
                                    size: 48,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  title: Text(
                                    song.title ?? "未知音乐",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    showSecondTitle(song),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.playlist_add,
                                      color: Colors.white70,
                                    ),
                                    tooltip: '加入歌单',
                                    onPressed: () =>
                                        showAddToUserPlaylistsSheet(
                                          context,
                                          song,
                                        ),
                                  ),
                                  onTap: () => navToSongPage(
                                    originalIndex,
                                    playListProvider,
                                  ),
                                );
                              },
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

  void addPlayList(List<Song> playList, FolderProvider folderProvider) {
    //所有的文件夹
    List<Folder> folders = folderProvider.folders;
    for (var value in folders) {
      log.d("添加了目录：${value.name}，共${value.songList?.length}首歌曲");
      if (value.songList == null || value.songList!.isEmpty) {
        continue;
      }
      playList.addAll(value.songList as Iterable<Song>);
    }
  }

  void navToSongPage(int index, PlayListProvider playListProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPage(index: index)),
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

  SongSearchDelegate(
    this.allSongs,
    this.playListProvider, {
    this.playbackContextQueue,
  }) : super(
         searchFieldStyle: const TextStyle(
           color: Colors.white,
           fontSize: 20,
           fontWeight: FontWeight.w400,
         ),
       );

  @override
  String get searchFieldLabel => '搜索歌曲、艺术家或文件名...';

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

    final pl = playListProvider.playList;
    final pathToMainIndex = <String, int>{
      for (var i = 0; i < pl.length; i++) pl[i].path: i,
    };

    if (results.isEmpty) {
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
              '未找到匹配的歌曲',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ScrollAwareListFrame(
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final song = results[index];
          return ListTile(
            leading: SongListCover(
              song: song,
              size: 48,
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              song.title ?? "未知音乐",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              song.artist ?? song.album ?? '',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.playlist_add, color: Colors.white70),
              tooltip: '加入歌单',
              onPressed: () => showAddToUserPlaylistsSheet(context, song),
            ),
            onTap: () async {
              close(context, song);
              if (playbackContextQueue != null) {
                final q = playbackContextQueue!;
                final idx = q.indexWhere((s) => s.path == song.path);
                if (idx < 0) return;
                await playListProvider.setPlaybackQueueAndPlay(q, idx);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SongPage(index: idx)),
                );
              } else {
                final originalIndex = pathToMainIndex[song.path] ?? -1;
                if (originalIndex < 0) return;
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongPage(index: originalIndex),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
