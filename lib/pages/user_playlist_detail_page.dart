import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/library_song_more_actions_sheet.dart';
import 'package:yeah_music/widgets/playlist_cover_style_sheet.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/navigation/app_route_observer.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/utils/user_playlist_backup_io.dart';
import 'package:yeah_music/widgets/song_sort_bottom_sheet.dart';

class UserPlaylistDetailPage extends StatefulWidget {
  const UserPlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<UserPlaylistDetailPage> createState() => _UserPlaylistDetailPageState();
}

class _UserPlaylistDetailPageState extends State<UserPlaylistDetailPage>
    with RouteAware {
  final ScrollController _listScrollController = ScrollController();
  bool _routeObserverSubscribed = false;
  bool _batchSelect = false;
  final Set<String> _selectedNormPaths = {};
  String? _lastAutoScrollPathNorm;
  bool _autoscrollInFlight = false;
  List<Song> _lastOrderedSongs = const [];

  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  /// 与排序 / 歌单 path 组合一致时复用，避免 [Consumer2] 频繁重建时全量 [sortSongsCopy]
  String? _memoOrderKey;
  List<Song>? _memoOrderedSongs;

  /// [UserPlaylist.songPaths] 签名不变时复用同一解析 [Future]（含刷新 overlay + 读盘兜底）
  String? _songsResolveKey;
  Future<List<Song>>? _songsResolveFuture;

  Future<List<Song>> _songsFuture(
    BuildContext context,
    UserPlaylist pl,
    PlayListProvider playList,
    UserPlaylistProvider userPl,
  ) {
    final key = '${pl.id}\x1e${pl.songPaths.join('\x1e')}';
    if (_songsResolveKey == key && _songsResolveFuture != null) {
      return _songsResolveFuture!;
    }
    _songsResolveKey = key;
    _songsResolveFuture = _loadResolvedSongs(context, pl, playList, userPl);
    return _songsResolveFuture!;
  }

  Future<List<Song>> _loadResolvedSongs(
    BuildContext context,
    UserPlaylist pl,
    PlayListProvider playList,
    UserPlaylistProvider userPl,
  ) async {
    if (!context.mounted) return [];
    final folder = context.read<FolderProvider>();
    final od = context.read<OneDriveController>();
    if (!playList.initialized) {
      await playList.init(folder, oneDrive: od);
    }
    if (!context.mounted) return [];
    await playList.refreshOneDriveLibraryOverlay(od);
    if (!context.mounted) return [];
    return userPl.songsForPlaylistWithDiskFallback(pl, playList.libraryMergedSongs);
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
    _lastAutoScrollPathNorm = null;
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    final p = context.read<PlayListProvider>();
    if (_lastOrderedSongs.isEmpty) return;
    if (_autoscrollInFlight) return;
    _autoscrollInFlight = true;
    scheduleScrollListToCurrentSong(
      context: context,
      controller: _listScrollController,
      songs: _lastOrderedSongs,
      itemExtent: kSongPlaylistRowExtent,
      playList: p,
      scrollToTopWhenCurrentMissingFromList: true,
      onScrollApplied: (path) {
        if (!mounted) return;
        setState(() {
          _lastAutoScrollPathNorm = path;
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
    _loadSort();
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSort() async {
    try {
      final prefs = await loadUserPlaylistSortPreferences();
      if (mounted) {
        setState(() {
          _sortType = prefs.type;
          _isAscending = prefs.ascending;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSort() =>
      saveUserPlaylistSortPreferences(_sortType, _isAscending);

  void _invalidateResolvedSongsCache() {
    if (!mounted) return;
    setState(() {
      _memoOrderKey = null;
      _memoOrderedSongs = null;
      _songsResolveKey = null;
      _songsResolveFuture = null;
    });
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

  void _selectAllVisible(List<Song> visible) {
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

  Future<void> _confirmBatchDelete(
    BuildContext context,
    List<Song> orderedSongs,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(orderedSongs);
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
        _invalidateResolvedSongsCache();
        showAppSnackBar(
          context,
          l10n.librarySongsDeletedN(selected.length),
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      appLog.e('user playlist batch delete failed', error: e);
      if (context.mounted) {
        showAppSnackBar(context, '$e', kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _batchAddToPlaylists(
    BuildContext context,
    List<Song> orderedSongs,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(orderedSongs);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return;
    }
    final ok = await showAddManyToUserPlaylistsSheet(context, selected);
    if (ok && context.mounted) {
      _exitBatchSelect();
    }
  }

  Future<void> _batchUploadOneDrive(
    BuildContext context,
    List<Song> orderedSongs,
  ) async {
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveDownloadQueueController>();
    final selected = _selectedSongsInListOrder(orderedSongs);
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

  Widget _userPlaylistBatchActionBar(
    BuildContext context,
    AppLocalizations l10n,
    List<Song> orderedSongs,
  ) {
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
                onPressed: () => _selectAllVisible(orderedSongs),
                child: Text(l10n.libraryBatchSelectAll),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_selectedNormPaths.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.libraryBatchUploadOneDrive,
                icon: const Icon(Icons.cloud_upload_outlined),
                onPressed: () => _batchUploadOneDrive(context, orderedSongs),
              ),
              IconButton(
                tooltip: l10n.libraryBatchAddToPlaylist,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _batchAddToPlaylists(context, orderedSongs),
              ),
              IconButton(
                tooltip: l10n.libraryBatchDelete,
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () => _confirmBatchDelete(context, orderedSongs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showSongSortBottomSheet(
      context,
      sortType: _sortType,
      isAscending: _isAscending,
      includeAddedToPlaylistOption: true,
      onApply: (type, ascending) {
        setState(() {
          _sortType = type;
          _isAscending = ascending;
          _lastAutoScrollPathNorm = null;
          _autoscrollInFlight = false;
        });
        _saveSort();
      },
    );
  }

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    UserPlaylistProvider user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.playlistDeleteTitle,
      message: l10n.playlistDeleteMessage,
      icon: Icons.delete_outline_rounded,
      confirmIsDestructive: true,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
    );
    if (ok == true && context.mounted) {
      await user.deletePlaylist(widget.playlistId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    UserPlaylist playlist,
    UserPlaylistProvider user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showAppTextPromptDialog(
      context: context,
      title: l10n.playlistRenameTitle,
      initialValue: playlist.name,
      fieldLabel: l10n.fieldName,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionSave,
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await user.renamePlaylist(widget.playlistId, name);
    }
  }

  Future<void> _exportThisPlaylist(
    BuildContext context,
    UserPlaylist playlist,
    UserPlaylistProvider user,
  ) async {
    final map = user.buildExportMapForPlaylists([playlist.id]);
    if ((map['playlists'] as List<dynamic>).isEmpty) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        showAppSnackBar(context, l10n.exportCannot, kind: AppSnackKind.error);
      }
      return;
    }
    final jsonStr = const JsonEncoder.withIndent('  ').convert(map);
    final fileName = suggestedSubsetPlaylistsFileName(user, {playlist.id});
    final l10n = AppLocalizations.of(context);
    try {
      final path = await pickSaveUserPlaylistJson(
        jsonStr: jsonStr,
        dialogTitle: l10n.exportDialogTitle,
        fileName: fileName,
      );
      if (!context.mounted) return;
      if (path != null && path.isNotEmpty) {
        showAppSnackBar(
          context,
          l10n.exportSaved(path),
          kind: AppSnackKind.success,
          duration: const Duration(seconds: 2),
        );
      } else {
        showAppSnackBar(context, l10n.exportCancelled);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          l10n.exportFailed('$e'),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserPlaylistProvider, PlayListProvider>(
      builder: (context, userPl, playList, _) {
        final l10n = AppLocalizations.of(context);
        UserPlaylist? playlist;
        for (final p in userPl.playlists) {
          if (p.id == widget.playlistId) {
            playlist = p;
            break;
          }
        }
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.playlistNotFound)),
            body: Center(child: Text(l10n.playlistNotFoundMessage)),
          );
        }

        final pl = playlist;
        final pathAddIndex = {
          for (var i = 0; i < pl.songPaths.length; i++) pl.songPaths[i]: i,
        };

        return FutureBuilder<List<Song>>(
          future: _songsFuture(context, pl, playList, userPl),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SongPlaylistThemedScaffold(
                appBar: AppBar(
                  title: Text(
                    pl.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              );
            }
            if (snap.hasError) {
              return SongPlaylistThemedScaffold(
                appBar: AppBar(
                  title: Text(
                    pl.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              );
            }

            final rawSongs = snap.data ?? [];
            final orderKey =
                '${pl.songPaths.join('\x1e')}|$_sortType|$_isAscending|${pl.id}';
            final List<Song> orderedSongs;
            if (_memoOrderKey == orderKey && _memoOrderedSongs != null) {
              orderedSongs = _memoOrderedSongs!;
            } else {
              orderedSongs = sortSongsCopy(
                rawSongs,
                _sortType,
                _isAscending,
                pathAddIndex: pathAddIndex,
              );
              _memoOrderKey = orderKey;
              _memoOrderedSongs = orderedSongs;
            }

            _lastOrderedSongs = orderedSongs;
            final current = playList.currentSong;
            if (current == null) {
              _lastAutoScrollPathNorm = null;
              _autoscrollInFlight = false;
            } else if (orderedSongs.isNotEmpty) {
              final n = normSongPath(current.path);
              if (n != _lastAutoScrollPathNorm && !_autoscrollInFlight) {
                _autoscrollInFlight = true;
                scheduleScrollListToCurrentSong(
                  context: context,
                  controller: _listScrollController,
                  songs: orderedSongs,
                  itemExtent: kSongPlaylistRowExtent,
                  playList: playList,
                  scrollToTopWhenCurrentMissingFromList: true,
                  onScrollApplied: (path) {
                    if (!mounted) return;
                    setState(() {
                      _lastAutoScrollPathNorm = path;
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
                        : pl.name,
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
                        tooltip: l10n.homeSearchTooltip,
                        onPressed: orderedSongs.isEmpty
                            ? null
                            : () {
                                showSearch(
                                  context: context,
                                  delegate: SongSearchDelegate(
                                    orderedSongs,
                                    playList,
                                    playbackContextQueue: orderedSongs,
                                    userPlaylistIdForContext: pl.id,
                                    searchFieldLabelText:
                                        l10n.playlistSearchHint,
                                    onSongMore: (ctx, song) {
                                      showLibrarySongMoreActionsSheet(
                                        ctx,
                                        song,
                                        afterMutation: () {
                                          if (!mounted) return;
                                          _invalidateResolvedSongsCache();
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort),
                        tooltip: l10n.tooltipSort,
                        onPressed: _showSortOptions,
                      ),
                      PopupMenuButton<String>(
                        icon:
                            const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'cover') {
                            await showPlaylistCoverStyleSheet(context, pl);
                          } else if (value == 'rename') {
                            await _renamePlaylist(context, pl, userPl);
                          } else if (value == 'export') {
                            await _exportThisPlaylist(context, pl, userPl);
                          } else if (value == 'delete') {
                            await _confirmDeletePlaylist(context, userPl);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'cover',
                            child: Text(l10n.playlistCoverMenuItem),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(l10n.menuRename),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Text(l10n.menuExportThis),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.menuDeletePlaylist),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                body: SongPlaylistBodyUnderlapColumn(
                  child: orderedSongs.isEmpty
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
                                l10n.playlistEmptyNoSongs,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SongPlaylistSongListView(
                                scrollController: _listScrollController,
                                songs: orderedSongs,
                                listBottomInsetExtra:
                                    _batchSelect ? 64 : 0,
                                itemBuilder:
                                    (context, song, index, isRowCurrent) {
                                  return Dismissible(
                                    key: ValueKey<String>(
                                      '${pl.id}_${index}_${normSongPath(song.path)}',
                                    ),
                                    direction: _batchSelect
                                        ? DismissDirection.none
                                        : DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(right: 20),
                                      color: Colors.red.shade800,
                                      child: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (_) {
                                      _memoOrderKey = null;
                                      _memoOrderedSongs = null;
                                      _songsResolveKey = null;
                                      _songsResolveFuture = null;
                                      userPl.removeSongFromPlaylist(
                                        pl.id,
                                        song,
                                      );
                                    },
                                    child: CompactSongListRow(
                                      key: ValueKey<String>(
                                        'row_${pl.id}_${index}_${normSongPath(song.path)}',
                                      ),
                                      song: song,
                                      title:
                                          song.title ?? l10n.pageUnknownTitle,
                                      subtitle:
                                          songListSecondaryLine(song),
                                      isCurrent: isRowCurrent,
                                      showAddToPlaylist: false,
                                      onMoreMenuTap: () {
                                        showLibrarySongMoreActionsSheet(
                                          context,
                                          song,
                                          afterMutation: () {
                                            if (!mounted) return;
                                            _invalidateResolvedSongsCache();
                                          },
                                        );
                                      },
                                      selectionMode: _batchSelect,
                                      isSelected: _selectedNormPaths
                                          .contains(
                                        normSongPath(song.path),
                                      ),
                                      onSelectionTap: () =>
                                          _toggleBatchPath(song.path),
                                      onLongPress: () {
                                        setState(() {
                                          _batchSelect = true;
                                          _selectedNormPaths.add(
                                            normSongPath(song.path),
                                          );
                                        });
                                      },
                                      onTap: () async {
                                        if (_batchSelect) {
                                          _toggleBatchPath(song.path);
                                          return;
                                        }
                                        final playListProv = context
                                            .read<PlayListProvider>();
                                        if (isRowCurrent) {
                                          await toggleCurrentRowPlayback(
                                            playListProv,
                                          );
                                          return;
                                        }
                                        await playListProv
                                            .setPlaybackQueueAndPlay(
                                          orderedSongs,
                                          index,
                                          session: PlaybackSessionSurface
                                              .userPlaylist,
                                          userPlaylistId: pl.id,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_batchSelect)
                              _userPlaylistBatchActionBar(
                                context,
                                l10n,
                                orderedSongs,
                              ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
