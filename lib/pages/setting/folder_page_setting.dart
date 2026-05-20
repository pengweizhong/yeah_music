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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

import '../../widgets/song_playlist_page_shell.dart';
import '../../compments/bookmark_service.dart';
import '../../compments/frosted_glass_panel.dart';
import '../../compments/folder_provider.dart';
import '../../compments/play_list_provider.dart';
import '../../models/folder.dart';
import '../../utils/date_utils.dart';

class FolderPageSettings extends StatelessWidget {
  const FolderPageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    if (!folderProvider.initialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        final l10n = AppLocalizations.of(context);
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.folderAppBarTitle,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Builder(
              builder: (ctx) => ListView.builder(
                padding: EdgeInsets.only(
                  top: songPlaylistUnderlapTopInset(ctx),
                ),
                itemCount: folderProvider.folders.length,
                itemBuilder: (context, index) {
                  final folder = folderProvider.folders[index];
                  final n = folder.songList?.length ?? 0;
                  return ListTile(
                    title: Text(
                      folder.name ?? l10n.homeUnknownTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.homeTrackCount(n),
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                          ),
                          tooltip: l10n.tooltipFolderInfo,
                          onPressed: () {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              showDragHandle: false,
                              context: context,
                              builder: (sheetContext) {
                                final sl = AppLocalizations.of(sheetContext);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.viewInsetsOf(
                                      sheetContext,
                                    ).bottom,
                                  ),
                                  child: FrostedGlassBottomSheet(
                                    child: SafeArea(
                                      top: false,
                                      child: Builder(
                                        builder: (innerCtx) {
                                          final theme = Theme.of(innerCtx);
                                          final cs = theme.colorScheme;
                                          final body = theme.textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                color: cs.onSurface,
                                                fontSize: 15,
                                                height: 1.35,
                                              ) ??
                                              TextStyle(
                                                color: cs.onSurface,
                                                fontSize: 15,
                                                height: 1.35,
                                              );
                                          final labelStyle = body.copyWith(
                                            fontWeight: FontWeight.w700,
                                          );
                                          return SizedBox(
                                            height: 300,
                                            width: double.infinity,
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                16,
                                                4,
                                                16,
                                                20,
                                              ),
                                              child: DefaultTextStyle(
                                                style: body,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      sl.tooltipFolderInfo,
                                                      style: theme
                                                          .textTheme.titleMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: cs.onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          sl.folderInfoAlias,
                                                          style: labelStyle,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${folder.name}',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          sl.folderInfoPath,
                                                          style: labelStyle,
                                                        ),
                                                        Expanded(
                                                          child: SelectableText(
                                                            folder.path,
                                                            maxLines: null,
                                                            showCursor: true,
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: body,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          sl.folderInfoSongCount,
                                                          style: labelStyle,
                                                        ),
                                                        Text(
                                                          '${folder.songList?.length}',
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          sl.folderInfoAdded,
                                                          style: labelStyle,
                                                        ),
                                                        Text(
                                                          LocalDateUtils
                                                              .formatDateTime(
                                                            folder.createdAt,
                                                            'yyyy-MM-dd HH:mm:ss',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_outlined,
                            color: Colors.white,
                          ),
                          tooltip: l10n.tooltipReloadSongs,
                          onPressed: () async {
                            showAppBlockingProgressDialog(
                              context: context,
                              title: l10n.folderReloading,
                              message: l10n.folderScanningWait,
                            );

                            try {
                              await folderProvider.flushSongToFolder(
                                folder,
                                true,
                              );
                              context.read<PlayListProvider>().flushPlaylist(
                                folder,
                              );

                              // 关闭进度对话框
                              Navigator.of(context).pop();

                              // 显示成功提示
                              showAppSnackBar(
                                context,
                                l10n.folderLoadOk(
                                  folder.songList?.length ?? 0,
                                ),
                                kind: AppSnackKind.success,
                                duration: const Duration(seconds: 2),
                              );
                            } catch (e) {
                              // 关闭进度对话框
                              Navigator.of(context).pop();

                              // 显示错误提示
                              showAppSnackBar(
                                context,
                                l10n.folderLoadFailed('$e'),
                                kind: AppSnackKind.error,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: l10n.tooltipEdit,
                          onPressed: () {
                            _showRenameDialog(context, folder, folderProvider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          tooltip: l10n.tooltipRemoveFolder,
                          onPressed: () {
                            ApplicationUtils.alertDialog(
                              context,
                              l10n.folderRemoveTitle,
                              [
                                Text(
                                  l10n.folderRemoveMessage(folder.name ?? ''),
                                ),
                              ],
                              [
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<PlayListProvider>()
                                        .flushRemovePlaylist(folder);
                                    folderProvider.deleteFolder(folder);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    l10n.actionConfirm,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.actionCancel),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                await _showAddFolderDialog(context, folderProvider);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddFolderDialog(
    BuildContext context,
    FolderProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    // 打开系统文件夹选择器（async void + 漏注册 Channel 时会静默 MissingPluginException）
    String? selectedDirectory;
    try {
      if (Platform.isMacOS) {
        selectedDirectory = await BookmarkService.pickDirectory();
      } else {
        selectedDirectory = await FilePicker.platform.getDirectoryPath();
      }
    } on PlatformException catch (e) {
      if (!context.mounted) return;

      showAppSnackBar(
        context,
        '${l10n.folderAddErrorTitle}: ${e.message ?? e.code}',
        kind: AppSnackKind.error,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (!context.mounted) return;
    if (selectedDirectory == null) {
      showAppSnackBar(
        context,
        l10n.folderAddNoSelection,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    showAppBlockingProgressDialog(
      context: context,
      title: l10n.folderAddLoadingTitle,
      message: l10n.folderScanningWait,
    );

    try {
      // 这里可以从路径自动获取文件夹名称，也可以自己输入名称
      final path = selectedDirectory;
      Folder? addFolder = await provider.addFolder(path);

      // 关闭进度对话框
      Navigator.of(context).pop();

      if (addFolder == null) {
        ApplicationUtils.alertDialog(
          context,
          l10n.folderDuplicateDialogTitle,
          [Text(l10n.folderDuplicateMessage(path))],
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionGotIt),
            ),
          ],
        );
      } else {
        //通知歌单更新
        final playListProvider = context.read<PlayListProvider>();
        playListProvider.flushAddPlaylist(addFolder);

        // 显示成功提示
        showAppSnackBar(
          context,
          l10n.folderAddOk(addFolder.songList?.length ?? 0),
          kind: AppSnackKind.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      Navigator.of(context).pop();

      // 显示错误提示
      ApplicationUtils.alertDialog(
        context,
        l10n.folderAddErrorTitle,
        [Text(l10n.folderAddErrorMessage('$e'))],
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionOK),
          ),
        ],
      );
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    Folder folder,
    FolderProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showAppTextPromptDialog(
      context: context,
      title: l10n.folderRenameDialogTitle,
      initialValue: folder.name ?? '',
      hintText: l10n.fieldNewNameHint,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionOK,
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      provider.renameFolder(folder, name);
    }
  }
}
