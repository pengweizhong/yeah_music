import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/song.dart';

Future<void> showAddToUserPlaylistsSheet(BuildContext context, Song song) async {
  final provider = context.read<UserPlaylistProvider>();
  if (!provider.initialized) {
    await provider.init();
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _AddToUserPlaylistsBody(song: song),
    ),
  );
}

class _AddToUserPlaylistsBody extends StatefulWidget {
  const _AddToUserPlaylistsBody({required this.song});

  final Song song;

  @override
  State<_AddToUserPlaylistsBody> createState() => _AddToUserPlaylistsBodyState();
}

class _AddToUserPlaylistsBodyState extends State<_AddToUserPlaylistsBody> {
  late Set<String> _selected;
  final TextEditingController _newNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserPlaylistProvider>();
    _selected = {...user.playlistIdsContainingSong(widget.song)};
  }

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _createAndSelect(UserPlaylistProvider user) async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) return;
    final pl = await user.createPlaylist(name);
    if (!mounted) return;
    setState(() {
      _selected.add(pl.id);
      _newNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserPlaylistProvider>();
    final playlists = user.playlists;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              '加入歌单 · ${widget.song.title ?? widget.song.path.split('/').last}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '可多选；取消勾选将从对应歌单移除该歌曲',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newNameController,
                    decoration: const InputDecoration(
                      hintText: '新建歌单名称',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createAndSelect(user),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _createAndSelect(user),
                  child: const Text('创建'),
                ),
              ],
            ),
          ),
          Flexible(
            child: playlists.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('暂无歌单，请先输入名称并创建'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      final checked = _selected.contains(pl.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(pl.id);
                            } else {
                              _selected.remove(pl.id);
                            }
                          });
                        },
                        title: Text(pl.name),
                        subtitle: Text('${pl.songPaths.length} 首'),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    await user.setSongInPlaylists(widget.song, Set<String>.from(_selected));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已更新歌单（${_selected.length} 个）')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
