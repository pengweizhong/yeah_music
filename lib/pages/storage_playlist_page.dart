import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/pages/user_playlist_detail_page.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
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
    final name = await showFrostedDialog<String>(
      context: context,
      maxWidth: 400,
      child: Builder(
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          final scheme = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.homeCreatePlaylist,
                  style: const TextStyle(
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
                    labelText: l10n.fieldName,
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: Text(l10n.actionCreate),
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
      await user.createPlaylist(name);
    }
  }

  /// [selectedIds] 为 `null` 时导出全部；否则仅导出集合中的歌单（须非空）
  Future<void> _exportPlaylists(
    BuildContext context,
    UserPlaylistProvider user, {
    Set<String>? selectedIds,
  }) async {
    final l10n = AppLocalizations.of(context);
    final Map<String, dynamic> map;
    if (selectedIds == null) {
      map = user.buildExportMap();
    } else {
      if (selectedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportSelectFirst)),
          );
        }
        return;
      }
      map = user.buildExportMapForPlaylists(selectedIds);
      if ((map['playlists'] as List<dynamic>).isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportNoneToExport)),
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
            ? l10n.exportAllPlaylists
            : (selectedIds.length == 1
                ? l10n.exportDialogTitle
                : l10n.exportSelectedPlaylists),
        fileName: suggestedName,
      );

      if (!context.mounted) return;
      if (path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSaved(path))),
        );
        if (_selectMode) {
          setState(() {
            _selectMode = false;
            _singleSelectOnly = false;
            _selectedPlaylistIds.clear();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportCancelled)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed('$e'))),
        );
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
    final ok = await showFrostedDialog<bool>(
      context: context,
      maxWidth: 400,
      child: Builder(
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  n == 1
                      ? l10n.playlistDeleteTitle
                      : l10n.playlistDeleteBatchTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  n == 1
                      ? l10n.playlistDeleteMessage
                      : l10n.playlistDeleteBatchMessage(n),
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade700,
                      ),
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final l10nAfter = AppLocalizations.of(context);
    await user.deletePlaylists(_selectedPlaylistIds);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n == 1
              ? l10nAfter.playlistDeletedOne
              : l10nAfter.playlistsDeletedN(n),
        ),
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importCannotRead)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importParseError(e.message))),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final replaceAll = await showFrostedDialog<bool>(
        context: context,
        maxWidth: 420,
        child: Builder(
          builder: (ctx) {
            final sl = AppLocalizations.of(ctx);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    sl.menuImportPlaylists,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    child: Text(
                      sl.importDialogBody,
                      style: const TextStyle(color: Colors.white, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(sl.actionCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(sl.importMerge),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(sl.importReplaceAll),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (replaceAll == null || !context.mounted) return;

      await user.applyImportedDocument(doc, replaceAll: replaceAll);
      if (context.mounted) {
        final m = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              replaceAll ? m.importReplaced : m.importMerged,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final m = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.importFailed('$e'))));
      }
    }
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
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                            color: Colors.white.withValues(alpha: 0.65),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: l10n.tooltipMoreActions,
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: const Color(0xFF2D2D2D),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        offset: const Offset(0, kToolbarHeight),
                        onSelected: (v) => _handleSelectMenu(v, userPl),
                        itemBuilder: (context) {
                          final m = AppLocalizations.of(context);
                          final allOn = _selectedPlaylistIds.length == userPl.playlists.length &&
                              userPl.playlists.isNotEmpty;
                          return [
                            if (!_singleSelectOnly)
                              PopupMenuItem(
                                value: 'toggle_all',
                                enabled: userPl.playlists.isNotEmpty,
                                child: _playlistMenuItemRow(
                                  allOn ? Icons.deselect : Icons.select_all,
                                  allOn ? m.deselectAll : m.selectAll,
                                ),
                              ),
                            PopupMenuItem(
                              value: 'export_selected',
                              enabled: _selectedPlaylistIds.isNotEmpty,
                              child: _playlistMenuItemRow(
                                Icons.upload_file_outlined,
                                m.exportSelected,
                                iconColor: _selectedPlaylistIds.isNotEmpty ? Colors.white70 : Colors.white30,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              enabled: _selectedPlaylistIds.isNotEmpty,
                              child: _playlistMenuItemRow(
                                Icons.delete_outline_rounded,
                                m.actionDelete,
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
                    title: Text(
                      l10n.playlistPageTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: l10n.tooltipMore,
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: const Color(0xFF2D2D2D),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        offset: const Offset(0, kToolbarHeight),
                        onSelected: (v) => _handleMainMenu(v, userPl),
                        itemBuilder: (context) {
                          final m = AppLocalizations.of(context);
                          final hasLists = userPl.playlists.isNotEmpty;
                          return [
                            if (hasLists) ...[
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
                              const PopupMenuDivider(height: 1),
                            ],
                            PopupMenuItem(
                              value: 'import',
                              child: _PlaylistMenuRowStatic(
                                icon: Icons.file_download_outlined,
                                label: m.menuImportPlaylists,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'export_all',
                              child: _PlaylistMenuRowStatic(
                                icon: Icons.save_alt_outlined,
                                label: m.exportAll,
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
                    label: Text(l10n.fabNewPlaylist),
                  ),
            body: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                Expanded(
                  child: userPl.playlists.isEmpty
                      ? Center(
                          child: Text(
                            l10n.emptyPlaylistsHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        )
                      : _selectMode
                          ? ListView.builder(
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
                                                      '${l10n.homeTrackCount(pl.songPaths.length)} · ${l10n.playlistCreatedOn(pl.createdAt.toString().split(' ').first)}',
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
                              },
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                              buildDefaultDragHandles: false,
                              itemCount: userPl.playlists.length,
                              onReorder: userPl.reorderPlaylists,
                              itemBuilder: (context, index) {
                                final pl = userPl.playlists[index];
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
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            UserPlaylistDetailPage(playlistId: pl.id),
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
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(12),
                                                            color: Colors.white.withValues(alpha: 0.08),
                                                          ),
                                                          child: Icon(
                                                            Icons.queue_music_rounded,
                                                            color: Colors.white.withValues(alpha: 0.88),
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
                                              index: index,
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
