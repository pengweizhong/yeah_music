import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/toggle_current_row_playback.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/navigation/app_route_observer.dart';
import 'package:yeah_music/utils/scroll_list_to_current_song.dart';
import 'package:yeah_music/widgets/recent_play_list_row.dart';
import 'package:yeah_music/widgets/scroll_aware_list_frame.dart';
import 'package:yeah_music/widgets/scroll_to_current_locate_layer.dart';

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
      itemExtent: 86,
      playList: playList,
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

  String _secondaryLine(Song s) {
    if (s.artist == null || s.artist!.isEmpty) {
      return s.album ?? '';
    }
    if (s.album == null || s.album!.isEmpty) {
      return s.artist!;
    }
    return '${s.artist} · ${s.album}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('最近播放', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  )
                : Consumer<PlayListProvider>(
                    builder: (context, playList, _) {
                      if (!playList.initialized) {
                        return const Center(
                          child: Text(
                            '正在加载曲库…',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      final items = playList.resolveRecentSongsFromPaths(
                        _paths,
                      );
                      final pathToIdx = {
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
                          itemExtent: 86,
                          playList: playList,
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
                        return Center(
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
                                '还没有播放记录',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '在曲库或歌单中播放歌曲后会出现在这里',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SongListScrollToCurrentLocate(
                        controller: _listScrollController,
                        songs: items,
                        itemExtent: 86,
                        playList: playList,
                        child: ScrollAwareListFrame(
                          child: ListView.builder(
                            controller: _listScrollController,
                            itemExtent: 86,
                            cacheExtent: 280,
                            padding: EdgeInsets.only(
                              bottom: 100 + MediaQuery.paddingOf(context).bottom,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final song = items[i];
                              final idx = pathToIdx[song.path] ?? -1;
                              final isCurrent =
                                  playList.currentSong?.path == song.path;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: RecentPlayListRow(
                                  song: song,
                                  subtitle: _secondaryLine(song),
                                  isCurrent: isCurrent,
                                  onTap: () async {
                                    if (idx < 0) return;
                                    if (isCurrent) {
                                      await toggleCurrentRowPlayback(
                                        playList,
                                      );
                                      return;
                                    }
                                    playList.clearPlaybackQueueOverride();
                                    if (!context.mounted) return;
                                    await playList.playAt(
                                      idx,
                                      listSession:
                                          PlaybackSessionSurface.recentList,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }
}
