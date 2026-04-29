import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';
import 'package:yeah_music/widgets/song_sort_bottom_sheet.dart';

/// OneDrive 点播落到本地的音频汇总（默认缓存目录与用户下载目录的非递归扫描）。
class OneDriveCachedPlaylistPage extends StatefulWidget {
  const OneDriveCachedPlaylistPage({super.key});

  @override
  State<OneDriveCachedPlaylistPage> createState() =>
      _OneDriveCachedPlaylistPageState();
}

class _OneDriveCachedPlaylistPageState extends State<OneDriveCachedPlaylistPage> {
  final ScrollController _listScrollController = ScrollController();

  List<Song>? _songs;
  Object? _error;

  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  String? _memoOrderKey;
  List<Song>? _memoOrderedSongs;

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

  Future<void> _saveSort() =>
      saveSongSortPreferences(_sortType, _isAscending);

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
        searchFieldLabelText: l10n.playlistSearchHint,
      ),
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
    return SongPlaylistThemedScaffold(
      appBar: AppBar(
        title: Text(
          l10n.oneDriveCachedPlaylistTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          Builder(
            builder: (ctx) {
              final raw = _songs;
              final enabled = raw != null && raw.isNotEmpty;
              final ordered =
                  enabled ? _orderedSongs(raw) : const <Song>[];
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
            onPressed: _reload,
          ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return SongPlaylistBodyUnderlapColumn(
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
      );
    }
    if (_songs == null) {
      return SongPlaylistBodyUnderlapColumn(
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }
    final raw = _songs!;
    if (raw.isEmpty) {
      return SongPlaylistBodyUnderlapColumn(
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
      );
    }

    final ordered = _orderedSongs(raw);

    return SongPlaylistBodyUnderlapColumn(
      child: SongPlaylistSongListView(
        scrollController: _listScrollController,
        songs: ordered,
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
            onTap: () async {
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
    );
  }
}
