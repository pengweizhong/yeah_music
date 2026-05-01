import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:yeah_music/app_scaffold_messenger.dart';
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
import 'package:yeah_music/widgets/app_prompts.dart';
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
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(l10n.menuRename),
                  onTap: () async {
                      Navigator.pop(sheetContext);
                      final ok = await _renameSongStem(context, song);
                      if (ok) afterMutation?.call();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add),
                    title: Text(l10n.tooltipAddToPlaylist),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await showAddToUserPlaylistsSheet(context, song);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.queue_play_next_outlined),
                    title: Text(l10n.menuPlayNextAfterCurrent),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      final playList = context.read<PlayListProvider>();
                      final ok = playList.enqueuePlayAfterCurrent(song);
                      if (!context.mounted) return;
                      showAppSnackBar(
                        context,
                        ok
                            ? l10n.libraryPlayNextAfterCurrentQueued
                            : l10n.libraryPlayNextAfterCurrentNotInQueue,
                        kind:
                            ok ? AppSnackKind.success : AppSnackKind.neutral,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_attributes_outlined),
                    title: Text(l10n.songPageMoreEditMusicTagsInline),
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
                      leading: const Icon(Icons.edit_note_outlined),
                      title: Text(l10n.songPageMoreEditMusicTagsExternal),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await MusicTagEditorLauncher.openMusicTagEditorWithFeedback(
                          context,
                          song,
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.songPageMoreQueryMetadata),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await tryShowAudioMetadataDialogForSong(context, song);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded),
                    title: Text(l10n.libraryReloadMetadata),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (song.path.trim().isEmpty) return;
                      await _reloadSongMetadataFromDisk(context, song);
                      afterMutation?.call();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy_all_outlined),
                    title: Text(l10n.libraryCloneSong),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final ok = await _cloneSongStem(context, song);
                      if (ok) afterMutation?.call();
                    },
                  ),
                  Divider(height: 1, color: Theme.of(sheetContext).dividerColor),
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
  showAppSnackBar(context, l10n.libraryReloadMetadataDone,
      kind: AppSnackKind.success);
}

/// 删除成功返回 true（用户取消或失败为 false）。
Future<bool> _confirmDeleteLibrarySong(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final displayName =
      (song.title?.trim().isNotEmpty ?? false) ? song.title!.trim() : p.basename(song.path);

  final step1 = await showAppConfirmDialog(
    context: context,
    title: l10n.songPageDeleteDiskWarningTitle,
    message: l10n.songPageDeleteDiskWarningBody,
    icon: Icons.warning_amber_rounded,
    cancelLabel: l10n.actionCancel,
    confirmLabel: l10n.songPageDeleteContinue,
  );
  if (step1 != true || !context.mounted) return false;

  final step2 = await showAppConfirmDialog(
    context: context,
    title: l10n.songPageDeleteFinalConfirmTitle,
    message: l10n.songPageDeleteFinalConfirmBody(displayName),
    icon: Icons.delete_outline_rounded,
    confirmIsDestructive: true,
    cancelLabel: l10n.actionCancel,
    confirmLabel: l10n.actionDelete,
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
      showAppSnackBar(context, l10n.librarySongsDeletedN(1),
          kind: AppSnackKind.success);
    }
    return true;
  } catch (e) {
    appLog.e('library song delete failed', error: e);
    if (context.mounted) {
      showAppSnackBar(context, '$e', kind: AppSnackKind.error);
    }
    return false;
  }
}

Future<bool> _cloneSongStem(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final base = p.basenameWithoutExtension(song.path);
  final scheme = Theme.of(context).colorScheme;
  final initial = '$base${l10n.libraryCloneSongDefaultSuffix}';
  final newStem = await showAppTextPromptDialog(
    context: context,
    title: l10n.libraryCloneSongTitle,
    subtitle: Text(
      l10n.libraryCloneSongHint,
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
        height: 1.4,
      ),
    ),
    initialValue: initial.isEmpty ? base : initial,
    fieldLabel: l10n.libraryRenameSingleFieldLabel,
  );
  if (newStem == null || !context.mounted) return false;
  final folder = context.read<FolderProvider>();
  final playList = context.read<PlayListProvider>();
  showAppBlockingProgressDialog(
    context: context,
    title: l10n.libraryCloneSongProgressTitle,
    message: l10n.libraryCloneSongProgressMessage,
    linearProgressBar: true,
  );
  try {
    final dest = await cloneLibrarySongToStem(
      folderProvider: folder,
      playListProvider: playList,
      song: song,
      newStem: newStem,
    );
    final failed = dest == null;
    final feedbackMsg =
        failed ? l10n.libraryCloneSongFailed : l10n.libraryCloneSongDone;
    final feedbackKind =
        failed ? AppSnackKind.error : AppSnackKind.success;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mountedCtx =
          context.mounted ? context : appScaffoldMessengerKey.currentContext;
      if (mountedCtx == null) return;
      showAppSnackBar(mountedCtx, feedbackMsg, kind: feedbackKind);
    });
    return !failed;
  } catch (e) {
    appLog.e('single clone failed', error: e);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mountedCtx =
          context.mounted ? context : appScaffoldMessengerKey.currentContext;
      if (mountedCtx == null) return;
      showAppSnackBar(mountedCtx, '$e', kind: AppSnackKind.error);
    });
    return false;
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

Future<bool> _renameSongStem(BuildContext context, Song song) async {
  final l10n = AppLocalizations.of(context);
  final base = p.basenameWithoutExtension(song.path);
  final scheme = Theme.of(context).colorScheme;
  final newStem = await showAppTextPromptDialog(
    context: context,
    title: l10n.libraryRenameSingleTitle,
    subtitle: Text(
      l10n.libraryRenameSingleHint,
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
        height: 1.4,
      ),
    ),
    initialValue: base,
    fieldLabel: l10n.libraryRenameSingleFieldLabel,
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
      showAppSnackBar(context, l10n.libraryRenameSingleDone,
          kind: AppSnackKind.success);
    }
    return true;
  } catch (e) {
    appLog.e('single rename failed', error: e);
    if (context.mounted) {
      showAppSnackBar(context, '$e', kind: AppSnackKind.error);
    }
    return false;
  }
}
