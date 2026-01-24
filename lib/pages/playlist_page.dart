import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/utils/hive_utils.dart';
import 'package:yeah_music/models/constants.dart';

import '../compments/folder_provider.dart';
import '../compments/play_list_provider.dart';
import '../models/folder.dart';
import '../utils/application_utils.dart';

var log = Logger(printer: SimplePrinter());

enum SortType {
  name,
  createTime,
  modifyTime,
}

@immutable
class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> {
  // 排序相关
  SortType _sortType = SortType.name;
  bool _isAscending = true;
  
  // 过滤和排序后的歌曲列表
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    
    // 加载排序配置
    _loadSortSettings();
    
    // 使用postFrameCallback避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folderProvider = context.read<FolderProvider>();
      final playListProvider = context.read<PlayListProvider>();
      if (!playListProvider.initialized) {
        log.d("初始化全部歌单列表");
        playListProvider.init(folderProvider);
      }
    });
  }

  /// 加载排序设置
  Future<void> _loadSortSettings() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      final savedSortType = box.get('sort_type', defaultValue: 0) as int?;
      final savedIsAscending = box.get('sort_ascending', defaultValue: true) as bool?;
      
      if (mounted) {
        setState(() {
          _sortType = SortType.values[savedSortType ?? 0];
          _isAscending = savedIsAscending ?? true;
        });
        log.d("加载排序设置: $_sortType, 正序: $_isAscending");
      }
    } catch (e) {
      log.e("加载排序设置失败: $e");
    }
  }

  /// 保存排序设置
  Future<void> _saveSortSettings() async {
    try {
      final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
      await box.put('sort_type', _sortType.index);
      await box.put('sort_ascending', _isAscending);
      log.d("保存排序设置: $_sortType, 正序: $_isAscending");
    } catch (e) {
      log.e("保存排序设置失败: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 过滤和排序歌曲
  List<Song> _getFilteredAndSortedSongs(List<Song> songs) {
    // 排序
    List<Song> filtered = List.from(songs);
    
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortType) {
        case SortType.name:
          result = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case SortType.createTime:
          // 如果没有创建时间，使用修改时间
          final aTime = a.createDateTime ?? a.updateDateTime ?? DateTime(1970);
          final bTime = b.createDateTime ?? b.updateDateTime ?? DateTime(1970);
          result = aTime.compareTo(bTime);
          break;
        case SortType.modifyTime:
          final aTime = a.updateDateTime ?? DateTime(1970);
          final bTime = b.updateDateTime ?? DateTime(1970);
          result = aTime.compareTo(bTime);
          break;
      }
      return _isAscending ? result : -result;
    });

    return filtered;
  }

  // 显示排序选项
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('排序方式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('按名称'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sortType == SortType.name)
                      Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                    if (_sortType == SortType.name)
                      const SizedBox(width: 8),
                    if (_sortType == SortType.name)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (_sortType == SortType.name) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortType = SortType.name;
                      _isAscending = true;
                    }
                  });
                  _saveSortSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('按创建时间'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sortType == SortType.createTime)
                      Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                    if (_sortType == SortType.createTime)
                      const SizedBox(width: 8),
                    if (_sortType == SortType.createTime)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (_sortType == SortType.createTime) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortType = SortType.createTime;
                      _isAscending = true;
                    }
                  });
                  _saveSortSettings();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('按更新时间'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sortType == SortType.modifyTime)
                      Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                    if (_sortType == SortType.modifyTime)
                      const SizedBox(width: 8),
                    if (_sortType == SortType.modifyTime)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (_sortType == SortType.modifyTime) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortType = SortType.modifyTime;
                      _isAscending = true;
                    }
                  });
                  _saveSortSettings();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
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
                      delegate: SongSearchDelegate(_filteredSongs, playListProvider),
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
                            // 找到原始列表中的索引
                            final originalIndex = playListProvider.playList.indexOf(song);
                            
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

// 搜索代理
class SongSearchDelegate extends SearchDelegate<Song?> {
  final List<Song> allSongs;
  final PlayListProvider playListProvider;

  SongSearchDelegate(this.allSongs, this.playListProvider);

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
      final fileName = (song.path?.split('/').last ?? '').toLowerCase();
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
        final originalIndex = playListProvider.playList.indexOf(song);
        
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
          onTap: () {
            close(context, song);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SongPage(index: originalIndex)),
            );
          },
        );
      },
    );
  }
}
