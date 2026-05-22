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
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/utils/onedrive_queue_navigation.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/library_song_more_actions_sheet.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';
import 'package:yeah_music/widgets/song_sort_bottom_sheet.dart';

/// OneDrive 点播落到本地的音频汇总（默认缓存目录与用户下载目录递归扫描）。
class OneDriveCachedPlaylistPage extends StatefulWidget {
  const OneDriveCachedPlaylistPage({super.key});

  @override
  State<OneDriveCachedPlaylistPage> createState() =>
      _OneDriveCachedPlaylistPageState();
}

class _OneDriveCachedPlaylistPageState
    extends State<OneDriveCachedPlaylistPage> {
  final ScrollController _listScrollController = ScrollController();

  List<Song>? _songs;
  Object? _error;

  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  String? _memoOrderKey;
  List<Song>? _memoOrderedSongs;

  bool _batchSelect = false;
  final Set<String> _selectedNormPaths = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadSort());
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _loadSort() async {
    try {
      final prefs = await loadSongSortPreferences();
      if (mounted) {
        setState(() {
          _sortType = prefs.type;
          _isAscending = prefs.ascending;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSort() => saveSongSortPreferences(_sortType, _isAscending);

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
      if (context.mounted) {
        _exitBatchSelect();
        showAppSnackBar(
          context,
          l10n.librarySongsDeletedN(selected.length),
          kind: AppSnackKind.success,
        );
        unawaited(_reload());
      }
    } catch (e) {
      appLog.e('cached playlist batch delete failed', error: e);
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

  Widget _cachedBatchActionBar(
    BuildContext context,
    AppLocalizations l10n,
    List<Song> ordered,
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
                onPressed: () => _selectAllVisible(ordered),
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
                onPressed: () => _batchUploadOneDrive(context, ordered),
              ),
              IconButton(
                tooltip: l10n.libraryBatchAddToPlaylist,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _batchAddToPlaylists(context, ordered),
              ),
              IconButton(
                tooltip: l10n.libraryBatchDelete,
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () => _confirmBatchDelete(context, ordered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet() {
    showSongSortBottomSheet(
      context,
      sortType: _sortType,
      isAscending: _isAscending,
      includeAddedToPlaylistOption: false,
      onApply: (type, ascending) {
        setState(() {
          _sortType = type;
          _isAscending = ascending;
          _memoOrderKey = null;
          _memoOrderedSongs = null;
        });
        _saveSort();
      },
    );
  }

  void _showSearch(
    BuildContext context,
    AppLocalizations l10n,
    List<Song> ordered,
  ) {
    showSearch<Song?>(
      context: context,
      delegate: SongSearchDelegate(
        ordered,
        context.read<PlayListProvider>(),
        playbackContextQueue: ordered,
        searchFieldLabelText: l10n.homeSearchHint,
        onSongMore: (ctx, song) => showLibrarySongMoreActionsSheet(
          ctx,
          song,
          afterMutation: () {
            if (mounted) unawaited(_reload());
          },
        ),
      ),
    );
  }

  void _openCachedSongMore(BuildContext context, Song song) {
    showLibrarySongMoreActionsSheet(
      context,
      song,
      afterMutation: () {
        if (mounted) unawaited(_reload());
      },
    );
  }

  Future<void> _reload() async {
    setState(() {
      _error = null;
      _songs = null;
      _memoOrderKey = null;
      _memoOrderedSongs = null;
    });
    try {
      final od = context.read<OneDriveController>();
      final list = await od.loadLocallyCachedOneDriveSongs();
      if (!mounted) return;
      setState(() => _songs = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  List<Song> _orderedSongs(List<Song> raw) {
    final key =
        '${raw.length}|$_sortType|$_isAscending|${raw.map((s) => s.path).join('\x1e')}';
    if (_memoOrderKey == key && _memoOrderedSongs != null) {
      return _memoOrderedSongs!;
    }
    final out = sortSongsCopy(raw, _sortType, _isAscending);
    _memoOrderKey = key;
    _memoOrderedSongs = out;
    return out;
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
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
                : l10n.oneDriveCachedPlaylistTitle,
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
            else ...[
              Builder(
                builder: (ctx) {
                  final raw = _songs;
                  final enabled = raw != null && raw.isNotEmpty;
                  final ordered = enabled ? _orderedSongs(raw) : const <Song>[];
                  return IconButton(
                    tooltip: l10n.homeSearchTooltip,
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: enabled
                        ? () => _showSearch(ctx, l10n, ordered)
                        : null,
                  );
                },
              ),
              IconButton(
                tooltip: l10n.tooltipSort,
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortSheet,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  unawaited(_reload());
                },
              ),
            ],
          ],
        ),
        body: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return SongPlaylistBodyUnderlapColumn(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.black54,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.oneDriveError('$_error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_songs == null) {
      return SongPlaylistBodyUnderlapColumn(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.black54,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final raw = _songs!;
    if (raw.isEmpty) {
      return SongPlaylistBodyUnderlapColumn(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.black54,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.oneDriveCachedPlaylistEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ordered = _orderedSongs(raw);

    return SongPlaylistBodyUnderlapColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SongPlaylistSongListView(
              scrollController: _listScrollController,
              songs: ordered,
              listBottomInsetExtra: _batchSelect ? 64 : 0,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onRefresh: _reload,
              itemBuilder: (context, song, index, isRowCurrent) {
                final playList = context.read<PlayListProvider>();
                return CompactSongListRow(
                  key: ValueKey<String>(
                    'od_cached_${index}_${normSongPath(song.path)}',
                  ),
                  song: song,
                  title: song.title ?? l10n.pageUnknownTitle,
                  subtitle: songListSecondaryLine(song),
                  isCurrent: isRowCurrent,
                  showAddToPlaylist: false,
                  onMoreMenuTap: () => _openCachedSongMore(context, song),
                  selectionMode: _batchSelect,
                  isSelected: _selectedNormPaths.contains(
                    normSongPath(song.path),
                  ),
                  onSelectionTap: () => _toggleBatchPath(song.path),
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
                      await toggleCurrentRowPlayback(playList);
                      return;
                    }
                    await playList.setPlaybackQueueAndPlay(
                      ordered,
                      index,
                      session: PlaybackSessionSurface.adHoc,
                    );
                  },
                );
              },
            ),
          ),
          if (_batchSelect) _cachedBatchActionBar(context, l10n, ordered),
        ],
      ),
    );
  }
}
