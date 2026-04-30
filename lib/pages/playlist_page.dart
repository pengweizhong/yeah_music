import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import '../compments/onedrive_controller.dart';
import '../compments/play_list_provider.dart';
import '../models/playback_session_surface.dart';
import '../navigation/app_route_observer.dart';
import '../utils/scroll_list_to_current_song.dart';
import '../utils/song_display_lines.dart';
import '../utils/song_list_sort.dart';
import '../utils/song_path_utils.dart';
import '../widgets/add_to_user_playlists_sheet.dart';
import '../widgets/app_prompts.dart';
import '../widgets/compact_song_list_row.dart';
import '../widgets/library_song_more_actions_sheet.dart';
import '../widgets/scroll_aware_list_frame.dart';
import '../widgets/song_playlist_page_shell.dart';
import '../widgets/song_sort_bottom_sheet.dart';

class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  State<PlayListPage> createState() => _PlayListProviderState();
}

class _PlayListProviderState extends State<PlayListPage> with RouteAware {
  final ScrollController _listScrollController = ScrollController();
  bool _routeObserverSubscribed = false;
  bool _batchSelect = false;
  final Set<String> _selectedNormPaths = {};
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
  void didPush() {
    // 每次进入本页清空对齐记忆，确保滚到当前播放（或不在曲库列表时按策略滚顶）
    _lastAutoScrollPathNorm = null;
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
      itemExtent: kSongPlaylistRowExtent,
      playList: pl,
      scrollToTopWhenCurrentMissingFromList: true,
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
        await playListProvider.init(
          folderProvider,
          oneDrive: context.read<OneDriveController>(),
        );
      }
      if (!context.mounted) return;
      if (playListProvider.hasPlaybackQueueOverride) {
        playListProvider.clearPlaybackQueueOverride();
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

  void _exitBatchSelect() {
    setState(() {
      _batchSelect = false;
      _selectedNormPaths.clear();
    });
  }

  void _toggleBatchPath(String path) {
    final k = normSongPath(path);
    setState(() {
      if (_selectedNormPaths.contains(k)) {
        _selectedNormPaths.remove(k);
      } else {
        _selectedNormPaths.add(k);
      }
    });
  }

  void _selectAllFiltered(List<Song> visible) {
    setState(() {
      for (final s in visible) {
        _selectedNormPaths.add(normSongPath(s.path));
      }
    });
  }

  List<Song> _selectedSongsInListOrder(List<Song> visibleOrdered) {
    final out = <Song>[];
    for (final s in visibleOrdered) {
      if (_selectedNormPaths.contains(normSongPath(s.path))) {
        out.add(s);
      }
    }
    return out;
  }

  Future<void> _confirmBatchDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(_filteredSongs);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return;
    }
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.libraryBatchDeleteConfirmTitle,
      message: l10n.libraryBatchDeleteConfirmMessage,
      icon: Icons.delete_outline_rounded,
      confirmIsDestructive: true,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
    );
    if (ok != true || !context.mounted) return;
    final folder = context.read<FolderProvider>();
    final playList = context.read<PlayListProvider>();
    final userPl = context.read<UserPlaylistProvider>();
    if (!userPl.initialized) await userPl.init();
    try {
      await deleteLibrarySongsAndRefresh(
        folderProvider: folder,
        playListProvider: playList,
        userPlaylistProvider: userPl,
        songs: selected,
      );
      if (context.mounted) {
        _exitBatchSelect();
        showAppSnackBar(
          context,
          l10n.librarySongsDeletedN(selected.length),
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      appLog.e('batch delete failed', error: e);
      if (context.mounted) {
        showAppSnackBar(context, '$e', kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _batchAddToPlaylists(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(_filteredSongs);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return;
    }
    final ok = await showAddManyToUserPlaylistsSheet(context, selected);
    if (ok && context.mounted) {
      _exitBatchSelect();
    }
  }


  Future<void> _batchUploadOneDrive(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveDownloadQueueController>();
    final selected = _selectedSongsInListOrder(_filteredSongs);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return;
    }
    try {
      await od.enqueueLibraryUploads(selected);
      if (!context.mounted) return;
      _exitBatchSelect();
      showAppSnackBar(
        context,
        l10n.libraryBatchUploadQueued,
        kind: AppSnackKind.success,
        action: SnackBarAction(
          label: l10n.libraryBatchOpenQueue,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OneDriveDownloadQueuePage(
                  initialTab: OneDriveTransferQueueTab.upload,
                ),
              ),
            );
          },
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

  Widget _libraryBatchActionBar(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _selectAllFiltered(_filteredSongs),
                child: Text(l10n.libraryBatchSelectAll),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_selectedNormPaths.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: l10n.libraryBatchUploadOneDrive,
                icon: const Icon(Icons.cloud_upload_outlined),
                onPressed: () => _batchUploadOneDrive(context),
              ),
              IconButton(
                tooltip: l10n.libraryBatchAddToPlaylist,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _batchAddToPlaylists(context),
              ),
              IconButton(
                tooltip: l10n.libraryBatchDelete,
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () => _confirmBatchDelete(context),
              ),
            ],
          ),
        ),
      ),
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
              itemExtent: kSongPlaylistRowExtent,
              playList: playListProvider,
              scrollToTopWhenCurrentMissingFromList: true,
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
        final l10n = AppLocalizations.of(context);
        return PopScope(
          canPop: !_batchSelect,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _batchSelect) {
              _exitBatchSelect();
            }
          },
          child: SongPlaylistThemedScaffold(
          appBar: AppBar(
            leading: _batchSelect
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitBatchSelect,
                  )
                : null,
            title: Text(
              _batchSelect
                  ? '${_selectedNormPaths.length}'
                  : l10n.menuSongList,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_batchSelect)
                TextButton(
                  onPressed: _exitBatchSelect,
                  child: Text(
                    l10n.libraryBatchDone,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: SongSearchDelegate(
                        _filteredSongs,
                        playListProvider,
                        searchFieldLabelText: l10n.playlistSearchHint,
                        onSongMore: showLibrarySongMoreActionsSheet,
                      ),
                    );
                  },
                  tooltip: l10n.homeSearchTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                  tooltip: l10n.tooltipSort,
                ),
              ],
            ],
          ),
          body: SongPlaylistBodyUnderlapColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _filteredSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.songsListEmpty,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SongPlaylistSongListView(
                          scrollController: _listScrollController,
                          songs: _filteredSongs,
                          listBottomInsetExtra: _batchSelect ? 64 : 0,
                          itemBuilder: (context, song, index, isRowCurrent) {
                            final originalIndex =
                                pathToIndex[song.path] ?? 0;
                            return CompactSongListRow(
                              key: ValueKey<String>(
                                'lib_row_${index}_${normSongPath(song.path)}',
                              ),
                              song: song,
                              title: song.title ?? l10n.pageUnknownTitle,
                              subtitle: songListSecondaryLine(song),
                              isCurrent: isRowCurrent,
                              showAddToPlaylist: false,
                              onMoreMenuTap: () =>
                                  showLibrarySongMoreActionsSheet(context, song),
                              selectionMode: _batchSelect,
                              isSelected: _selectedNormPaths
                                  .contains(normSongPath(song.path)),
                              onSelectionTap: () =>
                                  _toggleBatchPath(song.path),
                              onLongPress: () {
                                setState(() {
                                  _batchSelect = true;
                                  _selectedNormPaths.add(normSongPath(song.path));
                                });
                              },
                              onTap: () async {
                                if (_batchSelect) {
                                  _toggleBatchPath(song.path);
                                  return;
                                }
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
                                    listSession:
                                        PlaybackSessionSurface.library,
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
                if (_batchSelect) _libraryBatchActionBar(context, l10n),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

/// 搜索代理；[playbackContextQueue] 非空时，选中歌曲将按该队列播放（如用户歌单页）
class SongSearchDelegate extends SearchDelegate<Song?> {
  final List<Song> allSongs;
  final PlayListProvider playListProvider;
  final List<Song>? playbackContextQueue;

  /// 当 [playbackContextQueue] 为用户歌单时传入，用于 [PlaybackSessionSurface.userPlaylist]
  final String? userPlaylistIdForContext;

  /// 与 [playbackContextQueue] 同时使用时指定会话（如 [PlaybackSessionSurface.recentList]）。
  /// 为 null 时仍按「用户歌单 / 临时队列」推断。
  final PlaybackSessionSurface? playbackQueueSession;

  /// [playbackContextQueue] 播放时传给 [PlayListProvider.setPlaybackQueueAndPlay]。
  final bool playbackQueueRecordRecent;

  /// [playbackContextQueue] 播放时是否累计播放次数。
  final bool playbackQueueBumpPlayCount;

  /// 曲库页：行尾「更多」菜单（重命名、加入歌单、查询/重载元数据）。
  final void Function(BuildContext context, Song song)? onSongMore;

  SongSearchDelegate(
    this.allSongs,
    this.playListProvider, {
    this.playbackContextQueue,
    this.userPlaylistIdForContext,
    this.playbackQueueSession,
    this.playbackQueueRecordRecent = true,
    this.playbackQueueBumpPlayCount = true,
    required this.searchFieldLabelText,
    this.onSongMore,
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
            itemExtent: kSongPlaylistRowExtent,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final song = results[index];
              final isRowCurrent = current != null &&
                  songPathsEqual(song.path, current.path);
              return CompactSongListRow(
                key: ValueKey<String>(
                  'search_${index}_${normSongPath(song.path)}',
                ),
                song: song,
                title: song.title ?? l10n.pageUnknownTitle,
                subtitle: songListSecondaryLine(song),
                isCurrent: isRowCurrent,
                showAddToPlaylist: onSongMore == null,
                onMoreMenuTap: onSongMore == null
                    ? null
                    : () => onSongMore!(context, song),
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
                    final surface = playbackQueueSession ??
                        (userPlaylistIdForContext != null
                            ? PlaybackSessionSurface.userPlaylist
                            : PlaybackSessionSurface.adHoc);
                    await p.setPlaybackQueueAndPlay(
                      q,
                      idx,
                      recordRecent: playbackQueueRecordRecent,
                      bumpPlayCount: playbackQueueBumpPlayCount,
                      session: surface,
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

/// 在当前 Navigator 上打开曲库搜索，不压入 [PlayListPage]（供主页搜索入口：关闭搜索后仍停留在主页）。
Future<void> showLibrarySearch(BuildContext context) async {
  final folderProvider = context.read<FolderProvider>();
  final playListProvider = context.read<PlayListProvider>();
  if (!playListProvider.initialized) {
    await playListProvider.init(
      folderProvider,
      oneDrive: context.read<OneDriveController>(),
    );
  }
  if (!context.mounted) return;
  if (playListProvider.hasPlaybackQueueOverride) {
    playListProvider.clearPlaybackQueueOverride();
  }
  final prefs = await loadSongSortPreferences();
  if (!context.mounted) return;
  final sorted = sortSongsCopy(
    playListProvider.playList,
    prefs.type,
    prefs.ascending,
  );
  final l10n = AppLocalizations.of(context);
  showSearch(
    context: context,
    delegate: SongSearchDelegate(
      sorted,
      playListProvider,
      searchFieldLabelText: l10n.playlistSearchHint,
      onSongMore: showLibrarySongMoreActionsSheet,
    ),
  );
}
