import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/utils/application_utils.dart';

class UserPlaylistDetailPage extends StatelessWidget {
  const UserPlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  String _subtitle(Song song) {
    if (song.artist == null || song.artist!.isEmpty) {
      return song.album ?? '';
    }
    if (song.album == null || song.album!.isEmpty) {
      return song.artist!;
    }
    return '${song.artist} · ${song.album}';
  }

  Future<void> _confirmDeletePlaylist(BuildContext context, UserPlaylistProvider user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除歌单'),
        content: const Text('确定删除该歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await user.deletePlaylist(playlistId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    UserPlaylist playlist,
    UserPlaylistProvider user,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && context.mounted) {
      await user.renamePlaylist(playlistId, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserPlaylistProvider, PlayListProvider>(
      builder: (context, userPl, playList, _) {
        UserPlaylist? playlist;
        for (final p in userPl.playlists) {
          if (p.id == playlistId) {
            playlist = p;
            break;
          }
        }
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('歌单不存在')),
            body: const Center(child: Text('该歌单可能已被删除')),
          );
        }

        final pl = playlist;
        final songs = userPl.songsForPlaylist(pl, playList.playList);

        return Consumer<ThemeConfigProvider>(
          builder: (context, themeConfig, _) {
            return Container(
              decoration: themeConfig.getBackgroundDecoration(),
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          await _renamePlaylist(context, pl, userPl);
                        } else if (value == 'delete') {
                          await _confirmDeletePlaylist(context, userPl);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('重命名')),
                        PopupMenuItem(value: 'delete', child: Text('删除歌单')),
                      ],
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                    Expanded(
                      child: songs.isEmpty
                          ? Center(
                              child: Text(
                                '暂无可用歌曲\n（请先在「音乐源」扫描，或歌曲路径已失效）',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                return Dismissible(
                                  key: ValueKey('${pl.id}_${song.path}_$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red.shade800,
                                    child: const Icon(Icons.remove_circle_outline, color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    userPl.removeSongFromPlaylist(pl.id, song);
                                  },
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Image(
                                          fit: BoxFit.cover,
                                          image: ApplicationUtils.getImageCoverProvider(song),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      song.title ?? '未知音乐',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      _subtitle(song),
                                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    ),
                                    onTap: () async {
                                      final playListProv = context.read<PlayListProvider>();
                                      await playListProv.setPlaybackQueueAndPlay(songs, index);
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => SongPage(index: index)),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                bottomNavigationBar: const MiniPlayer(),
              ),
            );
          },
        );
      },
    );
  }
}
