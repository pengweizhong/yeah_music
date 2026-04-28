import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';
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
  String? _lastAutoScrollPathNorm;
  bool _autoscrollInFlight = false;
  List<Song> _lastOrderedSongs = const [];

  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  /// 与排序 / 歌单 path 组合一致时复用，避免 [Consumer2] 频繁重建时全量 [sortSongsCopy]
  String? _memoOrderKey;
  List<Song>? _memoOrderedSongs;

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
    final ok = await showFrostedDialog<bool>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.playlistDeleteTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.playlistDeleteMessage,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
    final controller = TextEditingController(text: playlist.name);
    final name = await showFrostedDialog<String>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.playlistRenameTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: l10n.fieldName,
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.primary),
                    ),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: Text(l10n.actionSave),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportCannot)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportSaved(path))));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportCancelled)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportFailed('$e'))));
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
        final rawSongs = userPl.songsForPlaylist(pl, playList.playList);
        final pathAddIndex = {
          for (var i = 0; i < pl.songPaths.length; i++) pl.songPaths[i]: i,
        };
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

        return SongPlaylistThemedScaffold(
          appBar: AppBar(
            title: Text(
              pl.name,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
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
                            searchFieldLabelText: l10n.playlistSearchHint,
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
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'rename') {
                    await _renamePlaylist(context, pl, userPl);
                  } else if (value == 'export') {
                    await _exportThisPlaylist(context, pl, userPl);
                  } else if (value == 'delete') {
                    await _confirmDeletePlaylist(context, userPl);
                  }
                },
                itemBuilder: (context) => [
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
          ),
          body: SongPlaylistBodyUnderlapColumn(
            child: orderedSongs.isEmpty
                ? Center(
                    child: Text(
                      l10n.playlistEmptyNoSongs,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : SongPlaylistSongListView(
                    scrollController: _listScrollController,
                    songs: orderedSongs,
                    itemBuilder: (context, song, index, isRowCurrent) {
                      return Dismissible(
                        key: ValueKey('${pl.id}_${song.path}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade800,
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          _memoOrderKey = null;
                          _memoOrderedSongs = null;
                          userPl.removeSongFromPlaylist(pl.id, song);
                        },
                        child: CompactSongListRow(
                          key: ValueKey('row_${pl.id}_${song.path}'),
                          song: song,
                          title: song.title ?? l10n.pageUnknownTitle,
                          subtitle: songListSecondaryLine(song),
                          isCurrent: isRowCurrent,
                          onTap: () async {
                            final playListProv =
                                context.read<PlayListProvider>();
                            if (isRowCurrent) {
                              await toggleCurrentRowPlayback(playListProv);
                              return;
                            }
                            await playListProv.setPlaybackQueueAndPlay(
                              orderedSongs,
                              index,
                              session: PlaybackSessionSurface.userPlaylist,
                              userPlaylistId: pl.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
