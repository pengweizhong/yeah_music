import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/utils/song_display_lines.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/navigation/app_route_observer.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/widgets/compact_song_list_row.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// 最近播放（按 [RecentPlayService] 记录的路径，在全库队列中解析并播放）
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
      itemExtent: kSongPlaylistRowExtent,
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
    _load();
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
    final paths = await RecentPlayService.getPaths(limit: 50);
    if (mounted) {
      setState(() {
        _paths = paths;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SongPlaylistThemedScaffold(
      appBar: AppBar(
        title: Text(
          l10n.homeSectionRecentPlays,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
                final pathToIdx = <String, int>{
                  for (var i = 0; i < playList.playList.length; i++)
                    playList.playList[i].path: i,
                };
                if (items.isNotEmpty &&
                    !_didInitialScrollToCurrent &&
                    !_initialScrollInFlight &&
                    playList.playbackSessionIsRecentList) {
                  _initialScrollInFlight = true;
                  scheduleScrollListToCurrentSong(
                    context: context,
                    controller: _listScrollController,
                    songs: items,
                    itemExtent: kSongPlaylistRowExtent,
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
                  child: SongPlaylistSongListView(
                    scrollController: _listScrollController,
                    songs: items,
                    itemExtent: kSongPlaylistRowExtent,
                    itemBuilder: (context, song, index, isCurrent) {
                      final idx = pathToIdx[song.path] ?? -1;
                      return CompactSongListRow(
                        key: ValueKey<String>(
                          'recent_${index}_${normSongPath(song.path)}',
                        ),
                        song: song,
                        title: song.title ?? l10n.pageUnknownTitle,
                        subtitle: songListSecondaryLine(song),
                        isCurrent: isCurrent,
                        onTap: () async {
                          if (idx < 0) return;
                          if (isCurrent) {
                            await toggleCurrentRowPlayback(playList);
                            return;
                          }
                          playList.clearPlaybackQueueOverride();
                          if (!context.mounted) return;
                          await playList.playAt(
                            idx,
                            listSession: PlaybackSessionSurface.recentList,
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
