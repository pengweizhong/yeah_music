import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';

/// 用户歌单（持久化在 Hive）
class StoragePlayListPage extends StatefulWidget {
  const StoragePlayListPage({super.key});

  @override
  State<StoragePlayListPage> createState() => _StoragePlayListPageState();
}

class _StoragePlayListPageState extends State<StoragePlayListPage> {
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
        await playListProvider.init(folderProvider);
      }
    });
  }

  Future<void> _createPlaylist(BuildContext context, UserPlaylistProvider user) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '歌单名称'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('创建')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && context.mounted) {
      await user.createPlaylist(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPl = context.watch<UserPlaylistProvider>();

    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return Container(
          decoration: themeConfig.getBackgroundDecoration(),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('歌单', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _createPlaylist(context, userPl),
              icon: const Icon(Icons.playlist_add),
              label: const Text('新建歌单'),
            ),
            body: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                Expanded(
                  child: userPl.playlists.isEmpty
                      ? Center(
                          child: Text(
                            '还没有歌单\n在播放页或歌曲列表可将歌曲加入歌单',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.65)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: userPl.playlists.length,
                          itemBuilder: (context, index) {
                            final pl = userPl.playlists[index];
                            return ListTile(
                              leading: const Icon(Icons.queue_music, color: Colors.white70),
                              title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${pl.songPaths.length} 首 · 创建于 ${pl.createdAt.toString().split(' ').first}',
                                style: TextStyle(color: Colors.white.withOpacity(0.55)),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserPlaylistDetailPage(playlistId: pl.id),
                                  ),
                                );
                              },
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
  }
}
