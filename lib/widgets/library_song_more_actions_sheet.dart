import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_tag_editor_launcher.dart';
import 'package:yeah_music/utils/library_song_batch_ops.dart';
import 'package:yeah_music/utils/song_metadata_reload_utils.dart';
import 'package:yeah_music/widgets/add_to_user_playlists_sheet.dart';
import 'package:yeah_music/widgets/song_inline_tags_editor_sheet.dart';
import 'package:yeah_music/widgets/song_metadata_dialog.dart';

const int _kLibraryReloadMetaMaxEmbeddedArtBytes = 512 * 1024;

/// 曲库 / 本地缓存曲目共用的「更多」底部菜单（重命名、加入歌单、标签、删除等）。
Future<void> showLibrarySongMoreActionsSheet(
  BuildContext context,
  Song song, {
  VoidCallback? afterMutation,
}) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FrostedGlassBottomSheet(
          child: Theme(
            data: frostedBottomSheetContentTheme(sheetContext),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      l10n.songPageMoreSheetTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.drive_file_rename_outline, color: Colors.white),
                    title: Text(l10n.menuRename,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final ok = await _renameSongStem(context, song);
                      if (ok) afterMutation?.call();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add, color: Colors.white),
                    title: Text(l10n.tooltipAddToPlaylist,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await showAddToUserPlaylistsSheet(context, song);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.edit_attributes_outlined, color: Colors.white),
                    title: Text(
                      l10n.songPageMoreEditMusicTagsInline,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await showSongInlineTagsEditorSheet(
                        navigatorContext: context,
                        song: song,
                        onSavedReload: (path) async {
                          await reloadAllSongInstancesAfterFileMetadataChanged(
                            context,
                            path,
                            maxEmbeddedArtBytes:
                                _kLibraryReloadMetaMaxEmbeddedArtBytes,
                          );
                          afterMutation?.call();
                        },
                      );
                    },
                  ),
                  if (Platform.isAndroid)
                    ListTile(
                      leading:
                          const Icon(Icons.edit_note_outlined, color: Colors.white),
                      title: Text(
                        l10n.songPageMoreEditMusicTagsExternal,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await MusicTagEditorLauncher.openMusicTagEditorWithFeedback(
                          context,
                          song,
                        );
                      },
                    ),
                  ListTile(
                    leading:
                        const Icon(Icons.info_outline_rounded, color: Colors.white),
                    title: Text(l10n.songPageMoreQueryMetadata,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await tryShowAudioMetadataDialogForSong(context, song);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded, color: Colors.white),
                    title: Text(l10n.libraryReloadMetadata,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (song.path.trim().isEmpty) return;
                      await _reloadSongMetadataFromDisk(context, song);
                      afterMutation?.call();
                    },
                  ),
                  const Divider(height: 1, color: Color(0x33FFFFFF)),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                    title: Text(
                      l10n.actionDelete,
                      style: TextStyle(
                          color: Theme.of(sheetContext).colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!context.mounted) return;
                        final ok =
                            await _confirmDeleteLibrarySong(context, song);
                        if (ok) afterMutation?.call();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _reloadSongMetadataFromDisk(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final path = song.path.trim();
  if (path.isEmpty) return;
  await reloadAllSongInstancesAfterFileMetadataChanged(
    context,
    path,
    maxEmbeddedArtBytes: _kLibraryReloadMetaMaxEmbeddedArtBytes,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.libraryReloadMetadataDone)),
  );
}

/// 删除成功返回 true（用户取消或失败为 false）。
Future<bool> _confirmDeleteLibrarySong(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final displayName =
      (song.title?.trim().isNotEmpty ?? false) ? song.title!.trim() : p.basename(song.path);

  final step1 = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.songPageDeleteDiskWarningTitle),
      content: Text(l10n.songPageDeleteDiskWarningBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.songPageDeleteContinue),
        ),
      ],
    ),
  );
  if (step1 != true || !context.mounted) return false;

  final step2 = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.songPageDeleteFinalConfirmTitle),
      content: Text(l10n.songPageDeleteFinalConfirmBody(displayName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  if (step2 != true || !context.mounted) return false;

  final folder = context.read<FolderProvider>();
  final playList = context.read<PlayListProvider>();
  final userPl = context.read<UserPlaylistProvider>();
  if (!userPl.initialized) await userPl.init();
  try {
    await deleteLibrarySongsAndRefresh(
      folderProvider: folder,
      playListProvider: playList,
      userPlaylistProvider: userPl,
      songs: [song],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.playlistDeletedOne)),
      );
    }
    return true;
  } catch (e) {
    appLog.e('library song delete failed', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
    return false;
  }
}

Future<bool> _renameSongStem(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final base = p.basenameWithoutExtension(song.path);
  final newStem = await showDialog<String?>(
    context: context,
    builder: (ctx) => SingleSongStemRenameDialog(
      l10n: l10n,
      initialStem: base,
    ),
  );
  if (newStem == null || !context.mounted) return false;
  final folder = context.read<FolderProvider>();
  final playList = context.read<PlayListProvider>();
  final userPl = context.read<UserPlaylistProvider>();
  if (!userPl.initialized) await userPl.init();
  try {
    await renameLibrarySongToStem(
      folderProvider: folder,
      playListProvider: playList,
      userPlaylistProvider: userPl,
      song: song,
      newStem: newStem,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryRenameSingleDone)),
      );
    }
    return true;
  } catch (e) {
    appLog.e('single rename failed', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
    return false;
  }
}

/// 单首重命名：在 [State] 内创建并 [dispose] [TextEditingController]。
class SingleSongStemRenameDialog extends StatefulWidget {
  const SingleSongStemRenameDialog({
    super.key,
    required this.l10n,
    required this.initialStem,
  });

  final AppLocalizations l10n;
  final String initialStem;

  @override
  State<SingleSongStemRenameDialog> createState() =>
      _SingleSongStemRenameDialogState();
}

class _SingleSongStemRenameDialogState extends State<SingleSongStemRenameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialStem);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.libraryRenameSingleTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.l10n.libraryRenameSingleHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.l10n.libraryRenameSingleFieldLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, null),
          child: Text(widget.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<String?>(context, _ctrl.text.trim()),
          child: Text(widget.l10n.actionOK),
        ),
      ],
    );
  }
}
