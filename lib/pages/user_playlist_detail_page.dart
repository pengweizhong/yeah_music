import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/song_list_sort.dart';
import 'package:yeah_music/utils/user_playlist_backup_io.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/song_sort_bottom_sheet.dart';

class UserPlaylistDetailPage extends StatefulWidget {
  const UserPlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<UserPlaylistDetailPage> createState() => _UserPlaylistDetailPageState();
}

class _UserPlaylistDetailPageState extends State<UserPlaylistDetailPage> {
  SongListSortType _sortType = SongListSortType.name;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSort();
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

  Future<void> _saveSort() => saveUserPlaylistSortPreferences(_sortType, _isAscending);

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
        });
        _saveSort();
      },
    );
  }

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
    final ok = await showFrostedDialog<bool>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '删除歌单',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '确定删除该歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('删除'),
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
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '重命名歌单',
                  style: TextStyle(
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
                    labelText: '名称',
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
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('保存'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法导出该歌单')),
        );
      }
      return;
    }
    final jsonStr = const JsonEncoder.withIndent('  ').convert(map);
    final fileName = suggestedSubsetPlaylistsFileName(user, {playlist.id});
    try {
      final path = await pickSaveUserPlaylistJson(
        jsonStr: jsonStr,
        dialogTitle: '导出歌单',
        fileName: fileName,
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserPlaylistProvider, PlayListProvider>(
      builder: (context, userPl, playList, _) {
        UserPlaylist? playlist;
        for (final p in userPl.playlists) {
          if (p.id == widget.playlistId) {
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
        final rawSongs = userPl.songsForPlaylist(pl, playList.playList);
        final pathAddIndex = {for (var i = 0; i < pl.songPaths.length; i++) pl.songPaths[i]: i};
        final orderedSongs = sortSongsCopy(
          rawSongs,
          _sortType,
          _isAscending,
          pathAddIndex: pathAddIndex,
        );

        return Consumer<ThemeConfigProvider>(
          builder: (context, themeConfig, _) {
            return themeConfig.buildThemedBackground(
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
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: '搜索',
                      onPressed: orderedSongs.isEmpty
                          ? null
                          : () {
                              showSearch(
                                context: context,
                                delegate: SongSearchDelegate(
                                  orderedSongs,
                                  playList,
                                  playbackContextQueue: orderedSongs,
                                ),
                              );
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      tooltip: '排序',
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('重命名')),
                        PopupMenuItem(value: 'export', child: Text('导出本歌单…')),
                        PopupMenuItem(value: 'delete', child: Text('删除歌单')),
                      ],
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                    Expanded(
                      child: orderedSongs.isEmpty
                          ? Center(
                              child: Text(
                                '暂无可用歌曲\n（请先在「音乐源」扫描，或歌曲路径已失效）',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: orderedSongs.length,
                              itemBuilder: (context, index) {
                                final song = orderedSongs[index];
                                return Dismissible(
                                  key: ValueKey('${pl.id}_${song.path}'),
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
                                    trailing: IconButton(
                                      icon: const Icon(Icons.playlist_add, color: Colors.white70),
                                      tooltip: '加入歌单',
                                      onPressed: () => showAddToUserPlaylistsSheet(context, song),
                                    ),
                                    onTap: () async {
                                      final playListProv = context.read<PlayListProvider>();
                                      await playListProv.setPlaybackQueueAndPlay(orderedSongs, index);
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
