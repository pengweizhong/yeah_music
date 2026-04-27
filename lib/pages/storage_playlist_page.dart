import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

  Future<void> _exportPlaylists(BuildContext context, UserPlaylistProvider user) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert(user.buildExportMap());
    final suggestedName =
        'yeah_music_playlists_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.json';

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '导出歌单备份',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(jsonStr)),
      );

      if (!context.mounted) return;
      if (path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出：$path')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消导出')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<void> _importPlaylists(BuildContext context, UserPlaylistProvider user) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取文件（可尝试较小备份或检查权限）')),
          );
        }
        return;
      }
      final jsonStr = utf8.decode(bytes);

      late final Map<String, dynamic> doc;
      try {
        doc = parseUserPlaylistExportJson(jsonStr);
      } on FormatException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法解析：${e.message}')));
        }
        return;
      }

      if (!context.mounted) return;
      final replaceAll = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入歌单'),
          content: const SingleChildScrollView(
            child: Text(
              '歌曲以「完整文件路径」区分：同名、同歌手、不同文件或不同音质会对应不同路径，导入后不会误合并。\n\n'
              '• 合并导入：与本地「歌单 id」相同的条目会合并曲目列表（路径去重）；备份中有而本地没有的歌单会新建。\n'
              '• 替换全部：先清空本地全部歌单，再按备份恢复（谨慎操作）。',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('合并导入')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('替换全部')),
          ],
        ),
      );

      if (replaceAll == null || !context.mounted) return;

      await user.applyImportedDocument(doc, replaceAll: replaceAll);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(replaceAll ? '已替换导入' : '已合并导入')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
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
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) async {
                    if (v == 'export') {
                      await _exportPlaylists(context, userPl);
                    } else if (v == 'import') {
                      await _importPlaylists(context, userPl);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'import', child: Text('导入歌单…')),
                    PopupMenuItem(value: 'export', child: Text('导出歌单…')),
                  ],
                ),
              ],
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
                            '还没有歌单\n在播放页或歌曲列表可将歌曲加入歌单\n\n可通过 ⋮ 导入/导出备份',
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
