import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/widgets/recent_play_list_row.dart';

/// 最近播放（按 [RecentPlayService] 记录的路径，在全库队列中解析并播放）
class RecentPlaysPage extends StatefulWidget {
  const RecentPlaysPage({super.key});

  @override
  State<RecentPlaysPage> createState() => _RecentPlaysPageState();
}

class _RecentPlaysPageState extends State<RecentPlaysPage> {
  List<String> _paths = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
                      return ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: 100 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final song = items[i];
                          final idx = playList.indexInLibraryByPath(song.path);
                          final isCurrent =
                              playList.currentSong?.path == song.path;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: RecentPlayListRow(
                              song: song,
                              subtitle: _secondaryLine(song),
                              isCurrent: isCurrent,
                              onTap: () async {
                                if (idx < 0) return;
                                playList.clearPlaybackQueueOverride();
                                if (!context.mounted) return;
                                await playList.playAt(idx);
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SongPage(
                                      index: idx,
                                      initialPage: 0,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
