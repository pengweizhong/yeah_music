import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';
import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/folder.dart';
import '../utils/application_utils.dart';
import '../utils/song_list_sort.dart';
import '../widgets/add_to_user_playlists_sheet.dart';
import '../widgets/song_sort_bottom_sheet.dart';

var log = Logger(printer: SimplePrinter());

@immutable
class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> {
  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  List<Song> _filteredSongs = [];

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
      playListProvider.clearPlaybackQueueOverride();
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
    PlayListProvider playListProvider = context.watch<PlayListProvider>();
    
    // 获取过滤和排序后的歌曲列表
    _filteredSongs = _getFilteredAndSortedSongs(playListProvider.playList);
    
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return Container(
          decoration: themeConfig.getBackgroundDecoration(),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("歌曲列表", style: TextStyle(color: Colors.white)),
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
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                
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
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            Song song = _filteredSongs[index];
                            final originalIndex =
                                playListProvider.playList.indexWhere((s) => s.path == song.path);
                            
                            return ListTile(
                              leading: ClipRRect(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Image(
                                    fit: BoxFit.cover,
                                    image: ApplicationUtils.getImageCoverProvider(song),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title ?? "未知音乐",
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                showSecondTitle(song),
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add, color: Colors.white70),
                                tooltip: '加入歌单',
                                onPressed: () => showAddToUserPlaylistsSheet(context, song),
                              ),
                              onTap: () => navToSongPage(originalIndex, playListProvider),
                            );
                          },
                        ),
                ),
              ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => SongPage(index: index)));
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
  });

  @override
  String get searchFieldLabel => '搜索歌曲、艺术家或文件名...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
    final results = allSongs.where((song) {
      final q = query.toLowerCase();
      final title = (song.title ?? '').toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final fileName = song.path.split('/').last.toLowerCase();
      return title.contains(q) || artist.contains(q) || fileName.contains(q);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的歌曲',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: ClipRRect(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image(
                fit: BoxFit.cover,
                image: ApplicationUtils.getImageCoverProvider(song),
              ),
            ),
          ),
          title: Text(song.title ?? "未知音乐"),
          subtitle: Text(
            song.artist ?? song.album ?? '',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.playlist_add),
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
              final originalIndex =
                  playListProvider.playList.indexWhere((s) => s.path == song.path);
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SongPage(index: originalIndex)),
              );
            }
          },
        );
      },
    );
  }
}
