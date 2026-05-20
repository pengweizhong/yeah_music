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

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

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
        await playListProvider.init(
          folderProvider,
          oneDrive: context.read<OneDriveController>(),
          userPlaylists: userPl,
        );
      }
    });
  }

  Future<void> _createPlaylist(
    BuildContext context,
    UserPlaylistProvider user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showAppTextPromptDialog(
      context: context,
      title: l10n.homeCreatePlaylist,
      fieldLabel: l10n.fieldName,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionCreate,
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await user.createPlaylist(name);
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
    }
  }

  Widget _selectLeadingIcon(BuildContext context, bool selected) {
    final muted = context.gradFg(0.38);
    if (_singleSelectOnly) {
      return Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? _kSelectAccent : muted,
        size: 26,
      );
    }
    return Icon(
      selected ? Icons.check_box : Icons.check_box_outline_blank,
      color: selected ? _kSelectAccent : muted,
      size: 26,
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    UserPlaylistProvider user,
  ) async {
    if (_selectedPlaylistIds.isEmpty) return;
    final n = _selectedPlaylistIds.length;
    final l10n = AppLocalizations.of(context);
    final ok = await showAppConfirmDialog(
      context: context,
      title: n == 1
          ? l10n.playlistDeleteTitle
          : l10n.playlistDeleteBatchTitle,
      message: n == 1
          ? l10n.playlistDeleteMessage
          : l10n.playlistDeleteBatchMessage(n),
      icon: Icons.delete_outline_rounded,
      confirmIsDestructive: true,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
    );
    if (ok != true || !context.mounted) return;
    final l10nAfter = AppLocalizations.of(context);
    await user.deletePlaylists(_selectedPlaylistIds);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      n == 1 ? l10nAfter.playlistDeletedOne : l10nAfter.playlistsDeletedN(n),
      kind: AppSnackKind.success,
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

  Future<void> _importPlaylists(
    BuildContext context,
    UserPlaylistProvider user,
  ) async {
    final l10n = AppLocalizations.of(context);
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
          showAppSnackBar(context, l10n.importCannotRead, kind: AppSnackKind.error);
        }
        return;
      }
      final jsonStr = utf8.decode(bytes);

      late final Map<String, dynamic> doc;
      try {
        doc = parseUserPlaylistExportJson(jsonStr);
      } on FormatException catch (e) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            l10n.importParseError(e.message),
            kind: AppSnackKind.error,
          );
        }
        return;
      }

      if (!context.mounted) return;
      final sl = AppLocalizations.of(context);
      final replaceAll = await showAppCustomDialog<bool>(
        context: context,
        title: sl.menuImportPlaylists,
        maxWidth: 420,
        bodyChildren: [
          SingleChildScrollView(
            child: Text(sl.importDialogBody),
          ),
        ],
        actions: [
          Builder(
            builder: (ctx) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(sl.actionCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(sl.importMerge),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(sl.importReplaceAll),
                ),
              ],
            ),
          ),
        ],
      );

      if (replaceAll == null || !context.mounted) return;

      await user.applyImportedDocument(doc, replaceAll: replaceAll);
      if (context.mounted) {
        final m = AppLocalizations.of(context);
        showAppSnackBar(
          context,
          replaceAll ? m.importReplaced : m.importMerged,
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final m = AppLocalizations.of(context);
        showAppSnackBar(
          context,
          m.importFailed('$e'),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  int _playlistOrdinalBefore(List<String> order, int index) {
    var n = 0;
    for (var i = 0; i < index; i++) {
      if (order[i] != UserPlaylistProvider.homeCarouselLibrarySentinel) {
        n++;
      }
    }
    return n;
  }

  void _openLibraryPage(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const PlayListPage(),
      ),
    );
  }

  UserPlaylistCoverStyle _libraryCardCoverStyle(UserPlaylistProvider user) {
    return user.homeLibraryCoverStyle ??
        UserPlaylistCoverStyle.gradient(
          const Color(0xFF1565C0),
          const Color(0xFF0D47A1),
        );
  }

  Widget _librarySelectBanner(
    BuildContext context,
    AppLocalizations l10n,
    PlayListProvider playList,
    UserPlaylistProvider userPl,
  ) {
    final coverStyle = _libraryCardCoverStyle(userPl);
    final title = userPl.resolvedHomeLibraryTitle(l10n.homeAllSongs);
    final allN = playList.initialized ? playList.libraryMergedSongs.length : 0;
    final subtitle = !playList.initialized
        ? l10n.homeAllSongsLoading
        : (allN == 0 ? l10n.homeScanMusicFolder : l10n.homeTrackCount(allN));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLibraryPage(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.gradBorder(0.12),
            ),
            color: context.gradFg(0.055),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: playlistCoverPreviewDecoration(
                    coverStyle: coverStyle,
                    fallbackGradientIndex: 0,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.library_music_rounded,
                    color: context.gradFg(0.92),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.gradFg(),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.gradFg(0.35),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.gradFg(0.5),
                          fontSize: 13,
                          height: 1.2,
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
    );
  }

  Widget _libraryReorderTile({
    required BuildContext context,
    required AppLocalizations l10n,
    required UserPlaylistProvider userPl,
    required PlayListProvider playList,
    required int listIndex,
  }) {
    final coverStyle = _libraryCardCoverStyle(userPl);
    final title = userPl.resolvedHomeLibraryTitle(l10n.homeAllSongs);
    final allN = playList.initialized ? playList.libraryMergedSongs.length : 0;
    final subtitle = !playList.initialized
        ? l10n.homeAllSongsLoading
        : (allN == 0 ? l10n.homeScanMusicFolder : l10n.homeTrackCount(allN));

    return Material(
      key: const ValueKey<String>(UserPlaylistProvider.homeCarouselLibrarySentinel),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            color: Colors.white.withValues(alpha: 0.055),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openLibraryPage(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: playlistCoverPreviewDecoration(
                                coverStyle: coverStyle,
                                fallbackGradientIndex: 0,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.library_music_rounded,
                                color: Colors.white.withValues(alpha: 0.92),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                      height: 1.2,
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
                ReorderableDragStartListener(
                  index: listIndex,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 10, 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playlistReorderTile({
    required BuildContext context,
    required AppLocalizations l10n,
    required UserPlaylist pl,
    required int listIndex,
    required int playlistOrdinal,
  }) {
    final dateStr = pl.createdAt.toString().split(' ').first;
    return Material(
      key: ValueKey<String>(pl.id),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            color: Colors.white.withValues(alpha: 0.055),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => UserPlaylistDetailPage(
                              playlistId: pl.id,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        setState(() {
                          _selectMode = true;
                          _singleSelectOnly = false;
                          _selectedPlaylistIds
                            ..clear()
                            ..add(pl.id);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: playlistCoverPreviewDecoration(
                                coverStyle: pl.coverStyle,
                                fallbackGradientIndex: playlistOrdinal,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white.withValues(alpha: 0.92),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    pl.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.homeTrackCount(pl.songPaths.length)} · ${l10n.playlistCreatedOn(dateStr)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                      height: 1.2,
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
                ReorderableDragStartListener(
                  index: listIndex,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPl = context.watch<UserPlaylistProvider>();

    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        final l10n = AppLocalizations.of(context);
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: _selectMode
                ? AppBar(
                    leading: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.gradFg(),
                      ),
                      tooltip: l10n.tooltipDone,
                      onPressed: _exitSelectMode,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _singleSelectOnly
                              ? l10n.playlistSelectModeSingle
                              : l10n.playlistSelectModeMulti,
                          style: TextStyle(
                            color: context.gradFg(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.playlistSelectCount(
                            _selectedPlaylistIds.length,
                            userPl.playlists.length,
                          ),
                          style: TextStyle(
                            color: context.gradFg(),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: context.gradFg()),
                    actions: [
                      if (!_singleSelectOnly && userPl.playlists.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final allOn =
                                _selectedPlaylistIds.length ==
                                    userPl.playlists.length &&
                                userPl.playlists.isNotEmpty;
                            return IconButton(
                              tooltip: allOn ? l10n.deselectAll : l10n.selectAll,
                              icon: Icon(
                                allOn
                                    ? Icons.deselect_rounded
                                    : Icons.select_all_rounded,
                                color: context.gradFg(),
                              ),
                              onPressed: () => _toggleSelectAll(userPl),
                            );
                          },
                        ),
                      IconButton(
                        tooltip: l10n.actionDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: _selectedPlaylistIds.isNotEmpty
                              ? const Color(0xFFFFAB91)
                              : context.gradFg(0.3),
                        ),
                        onPressed: _selectedPlaylistIds.isNotEmpty
                            ? () => _confirmDeleteSelected(context, userPl)
                            : null,
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(
                      l10n.playlistPageTitle,
                      style: TextStyle(
                        color: context.gradFg(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: context.gradFg()),
                    actions: [
                      if (userPl.playlists.isNotEmpty)
                        PopupMenuButton<String>(
                          tooltip:
                              '${l10n.playlistSelectModeSingle} · ${l10n.playlistSelectModeMulti}',
                          color: const Color(0xFF2D2D2D),
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          offset: const Offset(0, kToolbarHeight),
                          icon: Icon(
                            Icons.checklist_rounded,
                            color: context.gradFg(0.95),
                          ),
                          onSelected: (v) => _handleMainMenu(v, userPl),
                          itemBuilder: (context) {
                            final m = AppLocalizations.of(context);
                            return [
                              PopupMenuItem(
                                value: 'enter_single',
                                child: _PlaylistMenuRowStatic(
                                  icon: Icons.radio_button_checked,
                                  label: m.playlistSelectModeSingle,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'enter_multi',
                                child: _PlaylistMenuRowStatic(
                                  icon: Icons.check_box_outlined,
                                  label: m.playlistSelectModeMulti,
                                ),
                              ),
                            ];
                          },
                        ),
                      IconButton(
                        tooltip: l10n.menuImportPlaylists,
                        icon: Icon(
                          Icons.file_download_outlined,
                          color: context.gradFg(0.95),
                        ),
                        onPressed: () =>
                            _handleMainMenu('import', userPl),
                      ),
                    ],
                  ),
            floatingActionButton: _selectMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _createPlaylist(context, userPl),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(l10n.fabNewPlaylist),
                  ),
            body: SongPlaylistBodyUnderlapColumn(
              child: Consumer<PlayListProvider>(
                builder: (context, playList, _) {
                  final order = userPl.resolvedHomeCarouselOrder();
                  if (_selectMode) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: _librarySelectBanner(
                            context,
                            l10n,
                            playList,
                            userPl,
                          ),
                        ),
                        Expanded(
                          child: userPl.playlists.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                    ),
                                    child: Text(
                                      l10n.emptyPlaylistsHint,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: context.gradFg(0.65),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: userPl.playlists.length,
                                  itemBuilder: (context, index) {
                                    final pl = userPl.playlists[index];
                                    final selected =
                                        _selectedPlaylistIds.contains(pl.id);
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

                                    return Padding(
                                      key: ValueKey<String>('sel_${pl.id}'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: toggleSelection,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: selected
                                                    ? _kSelectAccent
                                                        .withValues(
                                                          alpha: 0.6,
                                                        )
                                                    : context.gradBorder(0.12),
                                                width: 1.2,
                                              ),
                                              color: selected
                                                  ? _kSelectAccent.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : context.gradFg(0.04),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  _selectLeadingIcon(
                                                    context,
                                                    selected,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          pl.name,
                                                          style:
                                                              TextStyle(
                                                            color: context.gradFg(),
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          '${l10n.homeTrackCount(pl.songPaths.length)} · ${l10n.playlistCreatedOn(pl.createdAt.toString().split(' ').first)}',
                                                          style: TextStyle(
                                                            color: context
                                                                .gradFg(0.52),
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
                                  },
                                ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          buildDefaultDragHandles: false,
                          itemCount: order.length,
                          onReorder: userPl.reorderHomeCarousel,
                          itemBuilder: (context, index) {
                            final slot = order[index];
                            if (slot ==
                                UserPlaylistProvider
                                    .homeCarouselLibrarySentinel) {
                              return _libraryReorderTile(
                                context: context,
                                l10n: l10n,
                                userPl: userPl,
                                playList: playList,
                                listIndex: index,
                              );
                            }
                            final pl = userPl.playlistById(slot);
                            if (pl == null) {
                              return SizedBox.shrink(
                                key: ValueKey<String>('missing_$slot'),
                              );
                            }
                            final ordinal = _playlistOrdinalBefore(
                              order,
                              index,
                            );
                            return _playlistReorderTile(
                              context: context,
                              l10n: l10n,
                              pl: pl,
                              listIndex: index,
                              playlistOrdinal: ordinal,
                            );
                          },
                        ),
                      ),
                      if (userPl.playlists.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          child: Text(
                            l10n.emptyPlaylistsHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
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

  /// 与本页 [PopupMenuButton] 的深色 `color` 一致，避免浅色主题下沿用黑字而不可读。
  static const Color _onDarkMenu = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: _onDarkMenu.withValues(alpha: 0.88)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              color: _onDarkMenu,
            ),
          ),
        ),
      ],
    );
  }
}
