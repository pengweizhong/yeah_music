// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/navigation/app_route_observer.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/utils/onedrive_queue_navigation.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/library_batch_action_bar.dart';
import 'package:yeah_music/widgets/library_song_more_actions_sheet.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// 最近播放（按 [RecentPlayService] 记录的路径解析；交互与曲库列表对齐）。
class RecentPlaysPage extends StatefulWidget {
  const RecentPlaysPage({super.key});

  @override
  State<RecentPlaysPage> createState() => _RecentPlaysPageState();
}

class _RecentPlaysPageState extends State<RecentPlaysPage> with RouteAware {
  final ScrollController _listScrollController = ScrollController();
  bool _routeObserverSubscribed = false;
  bool _didInitialScrollToCurrent = false;
  bool _initialScrollInFlight = false;

  List<String> _paths = [];
  bool _loading = true;

  bool _batchSelect = false;
  final Set<String> _selectedNormPaths = {};

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
    _didInitialScrollToCurrent = false;
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    final playList = context.read<PlayListProvider>();
    if (!playList.playbackSessionIsRecentList) return;
    final items = playList.resolveRecentSongsFromPaths(_paths);
    if (items.isEmpty) return;
    if (_initialScrollInFlight) return;
    _initialScrollInFlight = true;
    scheduleScrollListToCurrentSong(
      context: context,
      controller: _listScrollController,
      songs: items,
      itemExtent: effectiveSongPlaylistRowExtent(),
      playList: playList,
      scrollToTopWhenCurrentMissingFromList: true,
      onScrollApplied: (_) {
        if (mounted) setState(() => _initialScrollInFlight = false);
      },
      onScrollFailed: () {
        if (mounted) setState(() => _initialScrollInFlight = false);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final paths = await RecentPlayService.getPaths(
      limit: RecentPlayService.maxStoredRecentPaths,
    );
    if (mounted) {
      setState(() {
        _paths = paths;
        _loading = false;
      });
    }
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

  void _selectAllRecent(List<Song> visible) {
    setState(() {
      for (final s in visible) {
        _selectedNormPaths.add(normSongPath(s.path));
      }
    });
  }

  List<Song> _selectedSongsInListOrder(List<Song> ordered) {
    final out = <Song>[];
    for (final s in ordered) {
      if (_selectedNormPaths.contains(normSongPath(s.path))) {
        out.add(s);
      }
    }
    return out;
  }

  Future<void> _confirmBatchDelete(
    BuildContext context,
    List<Song> ordered,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(ordered);
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
      if (!context.mounted) return;
      _exitBatchSelect();
      await _load();
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.librarySongsDeletedN(selected.length),
        kind: AppSnackKind.success,
      );
    } catch (e) {
      appLog.e('recent plays batch delete failed', error: e);
      if (context.mounted) {
        showAppSnackBar(context, '$e', kind: AppSnackKind.error);
      }
    }
  }

  Future<void> _batchAddToPlaylists(
    BuildContext context,
    List<Song> ordered,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSongsInListOrder(ordered);
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
    List<Song> ordered,
  ) async {
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveDownloadQueueController>();
    final selected = _selectedSongsInListOrder(ordered);
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

  Widget _batchActionBar(
    BuildContext context,
    AppLocalizations l10n,
    List<Song> ordered,
  ) {
    return LibraryBatchActionBar(
      selectedCount: _selectedNormPaths.length,
      onSelectAll: () => _selectAllRecent(ordered),
      onUploadOneDrive: () => _batchUploadOneDrive(context, ordered),
      onAddToPlaylist: () => _batchAddToPlaylists(context, ordered),
      onDelete: () => _confirmBatchDelete(context, ordered),
    );
  }

  void _openSearch(
    BuildContext context,
    List<Song> items,
    PlayListProvider playList,
    AppLocalizations l10n,
  ) {
    showSearch(
      context: context,
      delegate: SongSearchDelegate(
        items,
        playList,
        playbackContextQueue: items,
        playbackQueueSession: PlaybackSessionSurface.recentList,
        playbackQueueRecordRecent: false,
        playbackQueueBumpPlayCount: true,
        searchFieldLabelText: l10n.homeSearchHint,
        onSongMore: (ctx, song) {
          showLibrarySongMoreActionsSheet(
            ctx,
            song,
            afterMutation: () {
              unawaited(_load());
              if (mounted) setState(() {});
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                : l10n.homeSectionRecentPlays,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            if (_batchSelect)
              TextButton(
                onPressed: _exitBatchSelect,
                child: Text(
                  l10n.libraryBatchDone,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n.homeSearchTooltip,
                onPressed: () {
                  final playList = context.read<PlayListProvider>();
                  final items = playList.resolveRecentSongsFromPaths(_paths);
                  _openSearch(context, items, playList, l10n);
                },
              ),
          ],
        ),
        body: _loading
            ? SongPlaylistBodyUnderlapColumn(
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              )
            : Consumer<PlayListProvider>(
                builder: (context, playList, _) {
                  if (!playList.initialized) {
                    return SongPlaylistBodyUnderlapColumn(
                      child: Center(
                        child: Text(
                          l10n.homeLoadingLibrary,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                  final items = playList.resolveRecentSongsFromPaths(_paths);
                  if (items.isNotEmpty &&
                      !_didInitialScrollToCurrent &&
                      !_initialScrollInFlight &&
                      playList.playbackSessionIsRecentList) {
                    _initialScrollInFlight = true;
                    scheduleScrollListToCurrentSong(
                      context: context,
                      controller: _listScrollController,
                      songs: items,
                      itemExtent: effectiveSongPlaylistRowExtent(),
                      playList: playList,
                      scrollToTopWhenCurrentMissingFromList: true,
                      onScrollApplied: (_) {
                        if (!mounted) return;
                        setState(() {
                          _didInitialScrollToCurrent = true;
                          _initialScrollInFlight = false;
                        });
                      },
                      onScrollFailed: () {
                        if (mounted) {
                          setState(() => _initialScrollInFlight = false);
                        }
                      },
                    );
                  }
                  if (items.isEmpty) {
                    return SongPlaylistBodyUnderlapColumn(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.recentPlaysEmptyTitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.homeRecentEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SongPlaylistBodyUnderlapColumn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SongPlaylistSongListView(
                            scrollController: _listScrollController,
                            songs: items,
                            listBottomInsetExtra: _batchSelect ? 64 : 0,
                            itemExtent: kSongPlaylistRowExtent,
                            itemBuilder: (context, song, index, isCurrent) {
                              return CompactSongListRow(
                                key: ValueKey<String>(
                                  'recent_${index}_${normSongPath(song.path)}',
                                ),
                                song: song,
                                title: song.title ?? l10n.pageUnknownTitle,
                                subtitle: songListSecondaryLine(song),
                                isCurrent: isCurrent,
                                showAddToPlaylist: false,
                                onMoreMenuTap: () {
                                  showLibrarySongMoreActionsSheet(
                                    context,
                                    song,
                                    afterMutation: () {
                                      unawaited(_load());
                                      if (mounted) setState(() {});
                                    },
                                  );
                                },
                                selectionMode: _batchSelect,
                                isSelected: _selectedNormPaths.contains(
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
                                  if (isCurrent) {
                                    await toggleCurrentRowPlayback(playList);
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  await playList.setPlaybackQueueAndPlay(
                                    List<Song>.from(items),
                                    index,
                                    recordRecent: false,
                                    bumpPlayCount: true,
                                    session: PlaybackSessionSurface.recentList,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        if (_batchSelect) _batchActionBar(context, l10n, items),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
