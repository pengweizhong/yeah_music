// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

/// 将单首曲目加入用户歌单（底部表单）。
Future<bool> showAddToUserPlaylistsSheet(BuildContext context, Song song) {
  return showAddManyToUserPlaylistsSheet(context, [song]);
}

/// 将多首曲目批量加入用户歌单；返回是否在对话框内点了「确定」并成功保存。
Future<bool> showAddManyToUserPlaylistsSheet(
  BuildContext context,
  List<Song> songs,
) async {
  if (songs.isEmpty) return false;
  final provider = context.read<UserPlaylistProvider>();
  if (!provider.initialized) {
    await provider.init();
  }
  if (!context.mounted) return false;
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: FrostedGlassBottomSheet(
        child: _AddToUserPlaylistsBody(songs: songs),
      ),
    ),
  );
  return result ?? false;
}

class _AddToUserPlaylistsBody extends StatefulWidget {
  const _AddToUserPlaylistsBody({required this.songs});

  final List<Song> songs;

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
    if (widget.songs.length == 1) {
      _selected = {...user.playlistIdsContainingSong(widget.songs.first)};
    } else {
      _selected = {...user.playlistIdsContainingAllSongs(widget.songs)};
    }
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
    final l10n = AppLocalizations.of(context);
    final user = context.watch<UserPlaylistProvider>();
    final playlists = user.playlists;
    final first = widget.songs.first;
    final titleName = first.title ?? first.path.split('/').last;

    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onSurface;
    final onMuted = scheme.onSurfaceVariant;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.52;

    final sheetTitle = widget.songs.length == 1
        ? l10n.addToPlaylistTitle(titleName)
        : l10n.libraryBatchAddToPlaylistSheetTitle(widget.songs.length);

    final helpText = widget.songs.length == 1
        ? l10n.addToPlaylistMultiHelp
        : l10n.libraryBatchAddToPlaylistSheetHelp;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              sheetTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: on,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              helpText,
              style: TextStyle(
                fontSize: 12,
                color: onMuted.withValues(alpha: 0.95),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _newNameController,
                    style: TextStyle(color: on),
                    cursorColor: on,
                    decoration: InputDecoration(
                      hintText: l10n.addToPlaylistHint,
                      hintStyle: TextStyle(color: onMuted.withValues(alpha: 0.82)),
                      filled: true,
                      fillColor: on.withValues(alpha: 0.07),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: on.withValues(alpha: 0.22),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createAndSelect(user),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _createAndSelect(user),
                  child: Text(l10n.actionCreate),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: playlists.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.addToPlaylistNoPlaylistsYet,
                          style: TextStyle(
                            color: onMuted.withValues(alpha: 0.95),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
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
                        checkColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : Colors.black87,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return scheme.primary;
                          }
                          return on.withValues(alpha: 0.12);
                        }),
                        side: BorderSide(
                          color: on.withValues(alpha: 0.45),
                        ),
                        title: Text(
                          pl.name,
                          style: TextStyle(
                            color: on,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          l10n.homeTrackCount(pl.songPaths.length),
                          style: TextStyle(
                            color: onMuted.withValues(alpha: 0.95),
                            fontSize: 13,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : onMuted.withValues(alpha: 0.95),
                  ),
                  child: Text(l10n.actionCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    if (widget.songs.length == 1) {
                      await user.setSongInPlaylists(
                        widget.songs.first,
                        Set<String>.from(_selected),
                      );
                      if (!context.mounted) return;
                      showAppSnackBar(
                        context,
                        l10n.addToPlaylistUpdatedN(_selected.length),
                        kind: AppSnackKind.success,
                      );
                    } else {
                      await user.setSongsMembershipInPlaylists(
                        widget.songs,
                        Set<String>.from(_selected),
                      );
                      if (!context.mounted) return;
                      showAppSnackBar(
                        context,
                        l10n.libraryBatchAddToPlaylistDone,
                        kind: AppSnackKind.success,
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(l10n.actionOK),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
