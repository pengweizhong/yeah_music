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
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/cloud_track_list_utils.dart';
import 'package:yeah_music/utils/onedrive_queue_navigation.dart';
import 'package:yeah_music/widgets/cloud_track_search_delegate.dart';
import 'package:yeah_music/widgets/cloud_track_sort_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// OneDrive：索引目录下的云端曲目；纯列表，支持搜索 / 排序；点播按需下载并读本地缓存。
class OneDriveCloudPlaylistPage extends StatefulWidget {
  const OneDriveCloudPlaylistPage({super.key});

  @override
  State<OneDriveCloudPlaylistPage> createState() =>
      _OneDriveCloudPlaylistPageState();
}

class _OneDriveCloudPlaylistPageState extends State<OneDriveCloudPlaylistPage> {
  CloudTrackSortType _sortType = CloudTrackSortType.fileName;
  bool _ascending = true;

  bool _batchSelect = false;
  final Set<String> _selectedItemIds = {};

  void _exitBatchSelect() {
    setState(() {
      _batchSelect = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleSelectItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  bool _allVisibleSelected(List<OneDriveCloudTrack> tracks) {
    if (tracks.isEmpty) return false;
    return tracks.every((t) => _selectedItemIds.contains(t.itemId));
  }

  void _toggleSelectAllVisible(List<OneDriveCloudTrack> tracks) {
    final ids = tracks.map((t) => t.itemId).toSet();
    if (ids.isEmpty) return;
    setState(() {
      if (_allVisibleSelected(tracks)) {
        _selectedItemIds.removeWhere(ids.contains);
      } else {
        _selectedItemIds.addAll(ids);
      }
    });
  }

  List<OneDriveCloudTrack> _selectedInListOrder(
    List<OneDriveCloudTrack> ordered,
  ) {
    final out = <OneDriveCloudTrack>[];
    for (final t in ordered) {
      if (_selectedItemIds.contains(t.itemId)) out.add(t);
    }
    return out;
  }

  Future<void> _batchEnqueueDownload(
    BuildContext context,
    List<OneDriveCloudTrack> ordered,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedInListOrder(ordered);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return;
    }
    await context.read<OneDriveDownloadQueueController>().enqueueCloudTracks(
      selected,
    );
    if (!context.mounted) return;
    _exitBatchSelect();
    showAppSnackBar(
      context,
      l10n.oneDriveEnqueueAddedMany(selected.length),
      kind: AppSnackKind.success,
      action: SnackBarAction(
        label: l10n.oneDriveDownloadViewQueue,
        onPressed: openOneDriveTransferQueue,
      ),
    );
  }

  Widget _cloudBatchActionBar(
    BuildContext context,
    AppLocalizations l10n,
    List<OneDriveCloudTrack> ordered,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _toggleSelectAllVisible(ordered),
                child: Text(
                  _allVisibleSelected(ordered)
                      ? l10n.deselectAll
                      : l10n.libraryBatchSelectAll,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_selectedItemIds.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.oneDriveDownloadQueueTooltip,
                icon: const Icon(Icons.download_for_offline_outlined),
                onPressed: () => _batchEnqueueDownload(context, ordered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    final s = await SettingsService.loadOneDriveCloudListSort();
    if (!mounted) return;
    setState(() {
      _sortType = s.type;
      _ascending = s.asc;
    });
  }

  List<OneDriveCloudTrack> _ordered(OneDriveController od) {
    return sortCloudTracksCopy(od.cloudTracks, _sortType, _ascending);
  }

  Future<void> _applySort(CloudTrackSortType t, bool asc) async {
    setState(() {
      _sortType = t;
      _ascending = asc;
    });
    await SettingsService.saveOneDriveCloudListSort(t, asc);
  }

  Future<void> _openSearch(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    final ordered = _ordered(od);
    final picked = await showSearch<OneDriveCloudTrack?>(
      context: context,
      delegate: CloudTrackSearchDelegate(
        sortedTracks: ordered,
        searchFieldLabelText: l10n.oneDriveCloudSearchHint,
      ),
    );
    if (!context.mounted || picked == null) return;
    await _tapTrack(context, picked);
  }

  void _showSortSheet(BuildContext context) {
    showCloudTrackSortBottomSheet(
      context,
      sortType: _sortType,
      isAscending: _ascending,
      onApply: _applySort,
    );
  }

  Future<void> _showCloudLibraryMoreSheet(
    BuildContext context,
    OneDriveController od,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final headerStyle = Theme.of(sheetContext).textTheme.titleMedium
            ?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(sheetContext).colorScheme.onSurface,
            );
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
                        style: headerStyle,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded),
                      title: Text(l10n.oneDriveRescanIndex),
                      enabled:
                          od.indexFolders.isNotEmpty && !od.cloudIndexBuilding,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _runRescan(context, od);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.drive_folder_upload_outlined),
                      title: Text(l10n.oneDriveBrowseFolders),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _browseAdd(context, od);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(l10n.oneDriveBrowserTitle),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        if (!context.mounted) return;
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const OneDriveBrowserPage(),
                          ),
                        );
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

  Future<void> _confirmRemoveFolder(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
    OneDriveIndexFolder folder,
  ) async {
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.oneDriveRemoveIndexFolderTitle,
      message: l10n.oneDriveRemoveIndexFolderMessage(
        folder.label.isEmpty ? folder.itemId : folder.label,
      ),
      confirmIsDestructive: true,
      confirmLabel: l10n.oneDriveRemoveIndexFolderAction,
    );
    if (ok != true || !context.mounted) return;
    await od.removeIndexFolder(folder.itemId);
  }

  Widget _buildPinnedCloudLibraryHeader(
    BuildContext context, {
    required AppLocalizations l10n,
    required OneDriveController od,
    required List<OneDriveCloudTrack> tracks,
    required String localeTag,
  }) {
    final topInset = songPlaylistUnderlapTopInset(context);
    final lastScanText = od.cloudIndexAt != null
        ? l10n.oneDriveLastIndexed(
            DateFormat.yMMMd(localeTag).add_jm().format(od.cloudIndexAt!),
          )
        : l10n.oneDriveLastIndexedNever;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: topInset + (od.cloudIndexBuilding ? 8 : 12),
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastScanText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.oneDriveTracksCount(tracks.length),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.oneDriveIndexRootsLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: od.signedIn && !od.cloudIndexBuilding
                    ? () => _browseAdd(context, od)
                    : null,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.oneDriveBrowseFolders),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.92),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          Text(
            l10n.oneDriveIndexFoldersRecursiveHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (od.indexFolders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.oneDriveNoIndexRoots,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: od.indexFolders.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                itemBuilder: (ctx, i) {
                  final folder = od.indexFolders[i];
                  final label = folder.label.isEmpty
                      ? folder.itemId
                      : folder.label;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFFFFB74D),
                      size: 22,
                    ),
                    title: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    trailing: IconButton(
                      tooltip: l10n.oneDriveRemoveIndexFolderAction,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      onPressed: od.cloudIndexBuilding
                          ? null
                          : () =>
                                _confirmRemoveFolder(context, l10n, od, folder),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _browseAdd(BuildContext context, OneDriveController od) async {
    final picked = await Navigator.of(context)
        .push<List<OneDriveFolderPickResult>>(
          MaterialPageRoute(
            builder: (_) => const OneDriveBrowserPage(
              pickFolderForIndex: true,
              pickMultipleIndexFolders: true,
            ),
          ),
        );
    if (!context.mounted || picked == null || picked.isEmpty) return;
    for (final p in picked) {
      await od.addIndexFolder(p.itemId, p.name);
    }
    if (!context.mounted) return;
    await _runRescan(context, od);
  }

  Future<void> _runRescan(BuildContext context, OneDriveController od) async {
    try {
      await od.rebuildCloudIndex();
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context).oneDriveError('$e'),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  Future<void> _tapTrack(BuildContext context, OneDriveCloudTrack t) async {
    final l10n = AppLocalizations.of(context);
    await context.read<OneDriveDownloadQueueController>().enqueueCloudTracks([
      t,
    ]);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      l10n.oneDriveEnqueueAddedSingle(t.fileName),
      kind: AppSnackKind.success,
      action: SnackBarAction(
        label: l10n.oneDriveDownloadViewQueue,
        onPressed: openOneDriveTransferQueue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, OneDriveController>(
      builder: (context, theme, od, _) {
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        final tracks = _ordered(od);

        return PopScope(
          canPop: !_batchSelect,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _batchSelect) {
              _exitBatchSelect();
            }
          },
          child: theme.buildThemedBackground(
            context: context,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              extendBody: true,
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: _batchSelect
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _exitBatchSelect,
                      )
                    : null,
                title: Text(
                  _batchSelect
                      ? '${_selectedItemIds.length}'
                      : l10n.oneDriveCloudLibraryTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  if (_batchSelect)
                    TextButton(
                      onPressed: _exitBatchSelect,
                      child: Text(
                        l10n.libraryBatchDone,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  else ...[
                    IconButton(
                      tooltip: l10n.oneDriveDownloadQueueTooltip,
                      icon: const Icon(Icons.download_for_offline_rounded),
                      onPressed: od.signedIn
                          ? () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const OneDriveDownloadQueuePage(),
                                ),
                              );
                            }
                          : null,
                    ),
                    IconButton(
                      tooltip: l10n.tooltipMore,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                      onPressed: od.signedIn
                          ? () => _showCloudLibraryMoreSheet(context, od, l10n)
                          : null,
                    ),
                    IconButton(
                      tooltip: l10n.homeSearchTooltip,
                      icon: const Icon(Icons.search_rounded),
                      onPressed:
                          od.signedIn &&
                              od.cloudTracks.isNotEmpty &&
                              !od.cloudIndexBuilding
                          ? () => _openSearch(context, l10n, od)
                          : null,
                    ),
                    IconButton(
                      tooltip: l10n.tooltipSort,
                      icon: const Icon(Icons.sort_rounded),
                      onPressed:
                          od.signedIn &&
                              od.cloudTracks.isNotEmpty &&
                              !od.cloudIndexBuilding
                          ? () => _showSortSheet(context)
                          : null,
                    ),
                  ],
                ],
              ),
              body: Builder(
                builder: (ctx) => Column(
                  children: [
                    if (od.cloudIndexBuilding)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Color(0x22FFFFFF),
                        color: Color(0xFF64B5F6),
                      ),
                    if (od.cloudIndexError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          l10n.oneDriveError(od.cloudIndexError!),
                          style: const TextStyle(
                            color: Color(0xFFFFAB91),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    _buildPinnedCloudLibraryHeader(
                      ctx,
                      l10n: l10n,
                      od: od,
                      tracks: tracks,
                      localeTag: localeTag,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildBodyList(
                              context,
                              theme,
                              od,
                              l10n,
                              tracks,
                            ),
                          ),
                          if (_batchSelect &&
                              tracks.isNotEmpty &&
                              !od.cloudIndexBuilding)
                            _cloudBatchActionBar(context, l10n, tracks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: const MiniPlayer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyList(
    BuildContext context,
    ThemeConfigProvider theme,
    OneDriveController od,
    AppLocalizations l10n,
    List<OneDriveCloudTrack> tracks,
  ) {
    if (od.cloudIndexBuilding && tracks.isEmpty) {
      return Center(
        child: Text(
          l10n.oneDriveIndexingEllipsis,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    if (od.indexFolders.isEmpty && !od.cloudIndexBuilding) {
      return Center(
        child: Icon(
          Icons.library_music_outlined,
          size: 56,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      );
    }
    if (tracks.isEmpty && !od.cloudIndexBuilding) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.oneDriveCloudLibraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 120 + (_batchSelect ? 56 : 0)),
      itemCount: tracks.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (context, index) {
        final t = tracks[index];
        final sel = _selectedItemIds.contains(t.itemId);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: _batchSelect
              ? Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  value: sel,
                  onChanged: od.cloudIndexBuilding
                      ? null
                      : (_) => _toggleSelectItem(t.itemId),
                  activeColor: const Color(0xFF81D4FA),
                  checkColor: const Color(0xFF0A0E14),
                )
              : const Icon(
                  Icons.audiotrack_rounded,
                  color: Color(0xFF81D4FA),
                  size: 22,
                ),
          title: Text(
            t.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            t.displayPath,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: od.cloudIndexBuilding
              ? null
              : () {
                  if (_batchSelect) {
                    _toggleSelectItem(t.itemId);
                  } else {
                    _tapTrack(context, t);
                  }
                },
          onLongPress: od.cloudIndexBuilding
              ? null
              : () {
                  setState(() {
                    _batchSelect = true;
                    _selectedItemIds.add(t.itemId);
                  });
                },
        );
      },
    );
  }
}
