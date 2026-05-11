import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/navigation/app_route_observer.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/library_index_cover_leading.dart';
import 'package:yeah_music/widgets/library_song_more_actions_sheet.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

String _rawAlbumKey(Song song) {
  final a = song.album?.trim();
  if (a == null || a.isEmpty) return '';
  return a;
}

String _albumTitleForKey(String rawKey, AppLocalizations l10n) {
  if (rawKey.isEmpty) return l10n.albumsUnknownAlbum;
  return rawKey;
}

int _albumTrackRank(Song s) {
  final n = s.trackNumber;
  if (n == null) return 1 << 20;
  return n;
}

List<Song> _sortSongsForAlbum(List<Song> picked) {
  final out = List<Song>.from(picked);
  out.sort((a, b) {
    final ta = _albumTrackRank(a);
    final tb = _albumTrackRank(b);
    if (ta != tb) return ta.compareTo(tb);
    final na = songListPrimaryTitle(a).toLowerCase();
    final nb = songListPrimaryTitle(b).toLowerCase();
    final c = na.compareTo(nb);
    if (c != 0) return c;
    return a.path.compareTo(b.path);
  });
  return out;
}

String _albumSongRowSubtitle(Song song) {
  final a = song.artist?.trim();
  if (a != null && a.isNotEmpty) return a;
  return '';
}

typedef AlbumBrowseRow = ({
  String rawKey,
  String title,
  int count,
  Uint8List? coverBytes,
});

/// 主界面：按 [Song.album] 聚合，未标专辑归入「未知专辑」。
class AlbumsBrowserPage extends StatefulWidget {
  const AlbumsBrowserPage({super.key});

  @override
  State<AlbumsBrowserPage> createState() => _AlbumsBrowserPageState();
}

class _AlbumsBrowserPageState extends State<AlbumsBrowserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final userPl = context.read<UserPlaylistProvider>();
      if (!userPl.initialized) {
        await userPl.init();
      }
      if (!mounted) return;
      final folderProvider = context.read<FolderProvider>();
      final playListProvider = context.read<PlayListProvider>();
      if (!playListProvider.initialized) {
        await playListProvider.init(
          folderProvider,
          oneDrive: context.read<OneDriveController>(),
          userPlaylists: userPl,
        );
      }
      if (mounted) setState(() {});
    });
  }

  void _openAlbumSearch(BuildContext context, List<AlbumBrowseRow> rows) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AlbumsBrowserSearchPage(allRows: rows),
      ),
    );
  }

  List<AlbumBrowseRow> _entries(
    List<Song> merged,
    AppLocalizations l10n,
  ) {
    final map = <String, int>{};
    final cover = <String, Uint8List>{};
    for (final s in merged) {
      final k = _rawAlbumKey(s);
      map[k] = (map[k] ?? 0) + 1;
      final b = s.imageBytes;
      if (b != null && b.isNotEmpty) {
        cover.putIfAbsent(k, () => b);
      }
    }
    final keys = map.keys.toList();
    bool isUnknown(String k) => k.isEmpty;
    keys.sort((a, b) {
      final au = isUnknown(a);
      final bu = isUnknown(b);
      if (au && !bu) return 1;
      if (!au && bu) return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return [
      for (final k in keys)
        (
          rawKey: k,
          title: _albumTitleForKey(k, l10n),
          count: map[k] ?? 0,
          coverBytes: cover[k],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SongPlaylistThemedScaffold(
      appBar: AppBar(
        title: Text(
          l10n.menuAlbums,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: l10n.homeSearchTooltip,
            onPressed: () {
              final playList = context.read<PlayListProvider>();
              if (!playList.initialized) return;
              final rows = _entries(playList.libraryMergedSongs, l10n);
              _openAlbumSearch(context, rows);
            },
          ),
        ],
      ),
      body: Consumer<PlayListProvider>(
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
          final merged = playList.libraryMergedSongs;
          if (merged.isEmpty) {
            return SongPlaylistBodyUnderlapColumn(
              child: Center(
                child: Text(
                  l10n.songsListEmpty,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            );
          }
          final rows = _entries(merged, l10n);
          return SongPlaylistBodyUnderlapColumn(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: songPlaylistListBottomPadding(context),
              ),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: LibraryIndexCoverLeading(
                    coverBytes: row.coverBytes,
                    fallbackIcon: Icons.album_rounded,
                    iconColor: context.gradFg(),
                  ),
                  title: Text(
                    row.title,
                    style: TextStyle(color: context.gradFg()),
                  ),
                  subtitle: Text(
                    l10n.oneDriveTracksCount(row.count),
                    style: TextStyle(color: context.gradFg(0.55)),
                  ),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AlbumSongsPage(
                          albumRawKey: row.rawKey,
                          albumDisplayTitle: row.title,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 与 [ArtistsBrowserSearchPage] 相同策略：独立路由 + TextField，全局主题背景 + 从搜索页 push 专辑详情。
class AlbumsBrowserSearchPage extends StatefulWidget {
  const AlbumsBrowserSearchPage({super.key, required this.allRows});

  final List<AlbumBrowseRow> allRows;

  @override
  State<AlbumsBrowserSearchPage> createState() => _AlbumsBrowserSearchPageState();
}

class _AlbumsBrowserSearchPageState extends State<AlbumsBrowserSearchPage> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<AlbumBrowseRow> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.allRows;
    return widget.allRows
        .where((r) => r.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final ink = isLight ? Colors.black : Colors.white;
    final hint = isLight ? Colors.black54 : const Color(0xB3FFFFFF);

    return SongPlaylistThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 8,
        title: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: ink,
          decoration: InputDecoration(
            hintText: l10n.albumsSearchHint,
            hintStyle: TextStyle(color: hint, fontSize: 18),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.trim().isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: ink),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      body: SongPlaylistBodyUnderlapColumn(
        child: Consumer<ThemeConfigProvider>(
          builder: (context, themeConfig, _) {
            final mq = MediaQuery.of(context);
            final sz = mq.size;
            final overlap = songPlaylistUnderlapTopInset(context);
            return Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: -overlap,
                  height: sz.height,
                  child: IgnorePointer(
                    child: themeConfig.buildThemedBackground(
                      context: context,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Positioned.fill(child: _buildResultsList(context, l10n)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, AppLocalizations l10n) {
    final filtered = _filtered();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.gradFg(0.35)),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoMatchingSongs,
              style: TextStyle(color: context.gradFg(0.55), fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: songPlaylistListBottomPadding(context)),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final row = filtered[index];
        return ListTile(
          leading: LibraryIndexCoverLeading(
            coverBytes: row.coverBytes,
            fallbackIcon: Icons.album_rounded,
            iconColor: context.gradFg(),
          ),
          title: Text(row.title, style: TextStyle(color: context.gradFg())),
          subtitle: Text(
            l10n.oneDriveTracksCount(row.count),
            style: TextStyle(color: context.gradFg(0.55)),
          ),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AlbumSongsPage(
                  albumRawKey: row.rawKey,
                  albumDisplayTitle: row.title,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 单张专辑下的曲目（优先音轨号，其次曲名）。
class AlbumSongsPage extends StatefulWidget {
  const AlbumSongsPage({
    super.key,
    required this.albumRawKey,
    required this.albumDisplayTitle,
  });

  final String albumRawKey;
  final String albumDisplayTitle;

  @override
  State<AlbumSongsPage> createState() => _AlbumSongsPageState();
}

class _AlbumSongsPageState extends State<AlbumSongsPage> with RouteAware {
  final ScrollController _listScrollController = ScrollController();
  bool _routeObserverSubscribed = false;
  bool _initialScrollInFlight = false;

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
    final playList = context.read<PlayListProvider>();
    if (!playList.playbackSessionIsLibraryByAlbum) return;
    final songs = _songsForAlbum(playList.libraryMergedSongs);
    if (songs.isEmpty) return;
    if (_initialScrollInFlight) return;
    _initialScrollInFlight = true;
    scheduleScrollListToCurrentSong(
      context: context,
      controller: _listScrollController,
      songs: songs,
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
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _listScrollController.dispose();
    super.dispose();
  }

  List<Song> _songsForAlbum(List<Song> merged) {
    final raw = widget.albumRawKey;
    final picked = <Song>[];
    for (final s in merged) {
      if (_rawAlbumKey(s) == raw) picked.add(s);
    }
    return _sortSongsForAlbum(picked);
  }

  void _openSearch(
    BuildContext context,
    List<Song> queue,
    PlayListProvider playList,
    AppLocalizations l10n,
  ) {
    showSearch(
      context: context,
      delegate: SongSearchDelegate(
        queue,
        playList,
        playbackContextQueue: queue,
        playbackQueueSession: PlaybackSessionSurface.libraryByAlbum,
        playbackQueueRecordRecent: true,
        playbackQueueBumpPlayCount: true,
        searchFieldLabelText: l10n.playlistSearchHint,
        onSongMore: (ctx, song) {
          showLibrarySongMoreActionsSheet(
            ctx,
            song,
            afterMutation: () {
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
    return SongPlaylistThemedScaffold(
      appBar: AppBar(
        title: Text(
          widget.albumDisplayTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.homeSearchTooltip,
            onPressed: () {
              final playList = context.read<PlayListProvider>();
              final q = _songsForAlbum(playList.libraryMergedSongs);
              _openSearch(context, q, playList, l10n);
            },
          ),
        ],
      ),
      body: Consumer<PlayListProvider>(
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
          final songs = _songsForAlbum(playList.libraryMergedSongs);
          if (songs.isEmpty) {
            return SongPlaylistBodyUnderlapColumn(
              child: Center(
                child: Text(
                  l10n.songsListEmpty,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            );
          }
          return SongPlaylistBodyUnderlapColumn(
            child: SongPlaylistSongListView(
              scrollController: _listScrollController,
              songs: songs,
              itemExtent: kSongPlaylistRowExtent,
              itemBuilder: (context, song, index, isCurrent) {
                final sub = _albumSongRowSubtitle(song);
                return CompactSongListRow(
                  key: ValueKey<String>(
                    'album_${index}_${normSongPath(song.path)}',
                  ),
                  song: song,
                  title: songListPrimaryTitle(song),
                  subtitle: sub,
                  isCurrent: isCurrent,
                  showAddToPlaylist: true,
                  onMoreMenuTap: () {
                    showLibrarySongMoreActionsSheet(
                      context,
                      song,
                      afterMutation: () {
                        if (mounted) setState(() {});
                      },
                    );
                  },
                  onTap: () async {
                    if (isCurrent) {
                      await toggleCurrentRowPlayback(playList);
                      return;
                    }
                    if (!context.mounted) return;
                    await playList.setPlaybackQueueAndPlay(
                      List<Song>.from(songs),
                      index,
                      session: PlaybackSessionSurface.libraryByAlbum,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
