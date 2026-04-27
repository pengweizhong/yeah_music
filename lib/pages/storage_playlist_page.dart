import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';
import 'package:yeah_music/utils/user_playlist_backup_io.dart';

const _kSelectAccent = Color(0xFF8AB4F8);

/// 用户歌单（持久化在 Hive）
class StoragePlayListPage extends StatefulWidget {
  const StoragePlayListPage({super.key});

  @override
  State<StoragePlayListPage> createState() => _StoragePlayListPageState();
}

class _StoragePlayListPageState extends State<StoragePlayListPage> {
  bool _selectMode = false;
  /// `true` 时每次点选仅保留一个歌单（单选）；`false` 为多选切换
  bool _singleSelectOnly = false;
  final Set<String> _selectedPlaylistIds = {};

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

  /// [selectedIds] 为 `null` 时导出全部；否则仅导出集合中的歌单（须非空）
  Future<void> _exportPlaylists(
    BuildContext context,
    UserPlaylistProvider user, {
    Set<String>? selectedIds,
  }) async {
    final Map<String, dynamic> map;
    if (selectedIds == null) {
      map = user.buildExportMap();
    } else {
      if (selectedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先选择要导出的歌单')),
          );
        }
        return;
      }
      map = user.buildExportMapForPlaylists(selectedIds);
      if ((map['playlists'] as List<dynamic>).isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有可导出的歌单，请检查选择')),
          );
        }
        return;
      }
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert(map);
    final suggestedName = selectedIds == null
        ? suggestedAllPlaylistsFileName()
        : suggestedSubsetPlaylistsFileName(user, selectedIds);

    try {
      final path = await pickSaveUserPlaylistJson(
        jsonStr: jsonStr,
        dialogTitle: selectedIds == null
            ? '导出全部歌单'
            : (selectedIds.length == 1 ? '导出歌单' : '导出所选歌单'),
        fileName: suggestedName,
      );

      if (!context.mounted) return;
      if (path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出：$path')));
        if (_selectMode) {
          setState(() {
            _selectMode = false;
            _singleSelectOnly = false;
            _selectedPlaylistIds.clear();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消导出')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _singleSelectOnly = false;
      _selectedPlaylistIds.clear();
    });
  }

  void _enterSelectMode({required bool singleOnly}) {
    setState(() {
      _selectMode = true;
      _singleSelectOnly = singleOnly;
      _selectedPlaylistIds.clear();
    });
  }

  Widget _playlistMenuItemRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor ?? Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.2)),
        ),
      ],
    );
  }

  Future<void> _handleMainMenu(String v, UserPlaylistProvider user) async {
    switch (v) {
      case 'enter_single':
        _enterSelectMode(singleOnly: true);
        break;
      case 'enter_multi':
        _enterSelectMode(singleOnly: false);
        break;
      case 'import':
        await _importPlaylists(context, user);
        break;
      case 'export_all':
        await _exportPlaylists(context, user, selectedIds: null);
        break;
    }
  }

  Future<void> _handleSelectMenu(String v, UserPlaylistProvider user) async {
    switch (v) {
      case 'toggle_all':
        if (!_singleSelectOnly) {
          _toggleSelectAll(user);
        }
        break;
      case 'delete':
        if (_selectedPlaylistIds.isNotEmpty) {
          await _confirmDeleteSelected(context, user);
        }
        break;
      case 'export_selected':
        if (_selectedPlaylistIds.isNotEmpty) {
          await _exportPlaylists(
            context,
            user,
            selectedIds: Set<String>.from(_selectedPlaylistIds),
          );
        }
        break;
    }
  }

  Widget _selectLeadingIcon(bool selected) {
    if (_singleSelectOnly) {
      return Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? _kSelectAccent : Colors.white38,
        size: 26,
      );
    }
    return Icon(
      selected ? Icons.check_box : Icons.check_box_outline_blank,
      color: selected ? _kSelectAccent : Colors.white38,
      size: 26,
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context, UserPlaylistProvider user) async {
    if (_selectedPlaylistIds.isEmpty) return;
    final n = _selectedPlaylistIds.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(n == 1 ? '删除歌单' : '批量删除歌单'),
        content: Text(
          n == 1
              ? '确定删除该歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。'
              : '确定删除已选的 $n 个歌单？歌单内引用会丢失，不会删除磁盘上的音乐文件。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red.shade700),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await user.deletePlaylists(_selectedPlaylistIds);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(n == 1 ? '已删除歌单' : '已删除 $n 个歌单')),
    );
    _exitSelectMode();
  }

  void _toggleSelectAll(UserPlaylistProvider user) {
    setState(() {
      if (_selectedPlaylistIds.length == user.playlists.length) {
        _selectedPlaylistIds.clear();
      } else {
        _selectedPlaylistIds
          ..clear()
          ..addAll(user.playlists.map((e) => e.id));
      }
    });
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
            appBar: _selectMode
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: '完成',
                      onPressed: _exitSelectMode,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _singleSelectOnly ? '单选' : '多选',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '已选 ${_selectedPlaylistIds.length} / ${userPl.playlists.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: '操作',
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: const Color(0xFF2D2D2D),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        offset: const Offset(0, kToolbarHeight),
                        onSelected: (v) => _handleSelectMenu(v, userPl),
                        itemBuilder: (context) {
                          final allOn = _selectedPlaylistIds.length == userPl.playlists.length &&
                              userPl.playlists.isNotEmpty;
                          return [
                            if (!_singleSelectOnly)
                              PopupMenuItem(
                                value: 'toggle_all',
                                enabled: userPl.playlists.isNotEmpty,
                                child: _playlistMenuItemRow(
                                  allOn ? Icons.deselect : Icons.select_all,
                                  allOn ? '取消全选' : '全选',
                                ),
                              ),
                            PopupMenuItem(
                              value: 'export_selected',
                              enabled: _selectedPlaylistIds.isNotEmpty,
                              child: _playlistMenuItemRow(
                                Icons.upload_file_outlined,
                                '导出所选',
                                iconColor: _selectedPlaylistIds.isNotEmpty ? Colors.white70 : Colors.white30,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              enabled: _selectedPlaylistIds.isNotEmpty,
                              child: _playlistMenuItemRow(
                                Icons.delete_outline_rounded,
                                '删除',
                                iconColor: _selectedPlaylistIds.isNotEmpty
                                    ? const Color(0xFFFFAB91)
                                    : Colors.white30,
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  )
                : AppBar(
                    title: const Text('歌单', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: '更多',
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: const Color(0xFF2D2D2D),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        offset: const Offset(0, kToolbarHeight),
                        onSelected: (v) => _handleMainMenu(v, userPl),
                        itemBuilder: (context) {
                          final hasLists = userPl.playlists.isNotEmpty;
                          return [
                            if (hasLists) ...[
                              const PopupMenuItem(
                                value: 'enter_single',
                                child: _PlaylistMenuRowStatic(
                                  icon: Icons.radio_button_checked,
                                  label: '单选',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'enter_multi',
                                child: _PlaylistMenuRowStatic(
                                  icon: Icons.check_box_outlined,
                                  label: '多选',
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                            ],
                            const PopupMenuItem(
                              value: 'import',
                              child: _PlaylistMenuRowStatic(
                                icon: Icons.file_download_outlined,
                                label: '导入歌单',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'export_all',
                              child: _PlaylistMenuRowStatic(
                                icon: Icons.save_alt_outlined,
                                label: '导出全部',
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
            floatingActionButton: _selectMode
                ? null
                : FloatingActionButton.extended(
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
                            '还没有歌单\n在播放页或歌曲列表可将歌曲加入歌单\n\n可在右上角「⋮」中导入/导出、单选/多选',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: userPl.playlists.length,
                          itemBuilder: (context, index) {
                            final pl = userPl.playlists[index];
                            final selected = _selectedPlaylistIds.contains(pl.id);
                            void toggleSelection() {
                              setState(() {
                                if (_singleSelectOnly) {
                                  if (selected) {
                                    _selectedPlaylistIds.clear();
                                  } else {
                                    _selectedPlaylistIds
                                      ..clear()
                                      ..add(pl.id);
                                  }
                                } else if (selected) {
                                  _selectedPlaylistIds.remove(pl.id);
                                } else {
                                  _selectedPlaylistIds.add(pl.id);
                                }
                              });
                            }

                            if (_selectMode) {
                              return Padding(
                                key: ValueKey('sel_${pl.id}'),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: toggleSelection,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected
                                              ? _kSelectAccent.withValues(alpha: 0.6)
                                              : Colors.white.withValues(alpha: 0.12),
                                          width: 1.2,
                                        ),
                                        color: selected
                                            ? _kSelectAccent.withValues(alpha: 0.12)
                                            : Colors.white.withValues(alpha: 0.04),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            _selectLeadingIcon(selected),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pl.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${pl.songPaths.length} 首 · 创建于 ${pl.createdAt.toString().split(' ').first}',
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.52),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListTile(
                              leading: const Icon(Icons.queue_music, color: Colors.white70),
                              title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${pl.songPaths.length} 首 · 创建于 ${pl.createdAt.toString().split(' ').first}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                              onLongPress: () {
                                setState(() {
                                  _selectMode = true;
                                  _singleSelectOnly = false;
                                  _selectedPlaylistIds
                                    ..clear()
                                    ..add(pl.id);
                                });
                              },
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

class _PlaylistMenuRowStatic extends StatelessWidget {
  const _PlaylistMenuRowStatic({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, height: 1.2)),
        ),
      ],
    );
  }
}
