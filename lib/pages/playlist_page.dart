import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/services/music_tag_editor_launcher.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/utils/song_metadata_reload_utils.dart';
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
import '../widgets/compact_song_list_row.dart';
import '../widgets/song_inline_tags_editor_sheet.dart';
import '../widgets/song_metadata_dialog.dart';
import '../widgets/scroll_aware_list_frame.dart';
import '../widgets/song_playlist_page_shell.dart';
import '../widgets/song_sort_bottom_sheet.dart';

const int _kLibraryReloadMetaMaxEmbeddedArtBytes = 512 * 1024;

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
            onSongMore: _showLibrarySongMoreSheet,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.libraryBatchNoneSelected)));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.libraryBatchDeleteConfirmTitle),
        content: Text(l10n.libraryBatchDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playlistDeletedOne)),
        );
      }
    } catch (e) {
      appLog.e('batch delete failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _batchAddToPlaylists(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(_filteredSongs);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.libraryBatchNoneSelected)));
      return;
    }
    final ok = await showAddManyToUserPlaylistsSheet(context, selected);
    if (ok && context.mounted) {
      _exitBatchSelect();
    }
  }

  Future<void> _reloadSongMetadataFromDisk(BuildContext context, Song song) async {
    final l10n = AppLocalizations.of(context);
    final path = song.path.trim();
    if (path.isEmpty) return;
    await reloadAllSongInstancesAfterFileMetadataChanged(
      context,
      path,
      maxEmbeddedArtBytes: _kLibraryReloadMetaMaxEmbeddedArtBytes,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.libraryReloadMetadataDone)),
    );
  }

  void _showLibrarySongMoreSheet(BuildContext context, Song song) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Text(
                        l10n.songPageMoreSheetTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.drive_file_rename_outline, color: Colors.white),
                      title: Text(l10n.menuRename, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _renameSingleSongSheet(context, song);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add, color: Colors.white),
                      title: Text(l10n.tooltipAddToPlaylist, style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await showAddToUserPlaylistsSheet(context, song);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_attributes_outlined, color: Colors.white),
                      title: Text(
                        l10n.songPageMoreEditMusicTagsInline,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await showSongInlineTagsEditorSheet(
                          navigatorContext: context,
                          song: song,
                          onSavedReload: (path) async {
                            await reloadAllSongInstancesAfterFileMetadataChanged(
                              context,
                              path,
                              maxEmbeddedArtBytes: _kLibraryReloadMetaMaxEmbeddedArtBytes,
                            );
                          },
                        );
                      },
                    ),
                    if (Platform.isAndroid)
                      ListTile(
                        leading: const Icon(Icons.edit_note_outlined, color: Colors.white),
                        title: Text(
                          l10n.songPageMoreEditMusicTagsExternal,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await MusicTagEditorLauncher.openMusicTagEditorWithFeedback(
                            context,
                            song,
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: Colors.white),
                      title: Text(l10n.songPageMoreQueryMetadata, style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await tryShowAudioMetadataDialogForSong(context, song);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded, color: Colors.white),
                      title: Text(l10n.libraryReloadMetadata, style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _reloadSongMetadataFromDisk(context, song);
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

  Future<void> _renameSingleSongSheet(BuildContext context, Song song) async {
    if (_batchSelect) return;
    final l10n = AppLocalizations.of(context);
    final base = p.basenameWithoutExtension(song.path);
    final newStem = await showDialog<String?>(
      context: context,
      builder: (ctx) => _SingleSongRenameDialog(
        l10n: l10n,
        initialStem: base,
      ),
    );
    if (newStem == null || !context.mounted) return;
    final folder = context.read<FolderProvider>();
    final playList = context.read<PlayListProvider>();
    final userPl = context.read<UserPlaylistProvider>();
    if (!userPl.initialized) await userPl.init();
    try {
      await renameLibrarySongToStem(
        folderProvider: folder,
        playListProvider: playList,
        userPlaylistProvider: userPl,
        song: song,
        newStem: newStem,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryRenameSingleDone)),
        );
      }
    } catch (e) {
      appLog.e('single rename failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _batchUploadOneDrive(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveDownloadQueueController>();
    final selected = _selectedSongsInListOrder(_filteredSongs);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.libraryBatchNoneSelected)));
      return;
    }
    try {
      await od.enqueueLibraryUploads(selected);
      if (!context.mounted) return;
      _exitBatchSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.libraryBatchUploadQueued),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
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
                        onSongMore: _showLibrarySongMoreSheet,
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
                                  _showLibrarySongMoreSheet(context, song),
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

/// 单首重命名对话框：在 [State] 内创建并 [dispose] [TextEditingController]，避免关闭动画期间误用已释放的 controller。
class _SingleSongRenameDialog extends StatefulWidget {
  const _SingleSongRenameDialog({
    required this.l10n,
    required this.initialStem,
  });

  final AppLocalizations l10n;
  final String initialStem;

  @override
  State<_SingleSongRenameDialog> createState() => _SingleSongRenameDialogState();
}

class _SingleSongRenameDialogState extends State<_SingleSongRenameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialStem);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.libraryRenameSingleTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.l10n.libraryRenameSingleHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.l10n.libraryRenameSingleFieldLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, null),
          child: Text(widget.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<String?>(context, _ctrl.text.trim()),
          child: Text(widget.l10n.actionOK),
        ),
      ],
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

  /// 曲库页：行尾「更多」菜单（重命名、加入歌单、查询/重载元数据）。
  final void Function(BuildContext context, Song song)? onSongMore;

  SongSearchDelegate(
    this.allSongs,
    this.playListProvider, {
    this.playbackContextQueue,
    this.userPlaylistIdForContext,
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
                    await p.setPlaybackQueueAndPlay(
                      q,
                      idx,
                      session: userPlaylistIdForContext != null
                          ? PlaybackSessionSurface.userPlaylist
                          : PlaybackSessionSurface.adHoc,
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
