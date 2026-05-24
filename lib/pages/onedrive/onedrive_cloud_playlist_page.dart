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
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
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
import 'package:yeah_music/widgets/library_batch_action_bar.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// OneDrive：索引目录下的云端曲目；纯列表，支持搜索 / 排序；点播按需下载并读本地缓存。
class OneDriveCloudPlaylistPage extends StatefulWidget {
  const OneDriveCloudPlaylistPage({super.key});

  @override
  State<OneDriveCloudPlaylistPage> createState() =>
      _OneDriveCloudPlaylistPageState();
}

class _OneDriveCloudPlaylistPageState extends State<OneDriveCloudPlaylistPage> {
  static const double _cloudTrackRowExtent = 73;
  static const double _listTopPadding = 8;
  static const double _listSeparatorHeight = 1;
  static const double _cloudTrackRowSlotExtent =
      _cloudTrackRowExtent + _listSeparatorHeight;
  static const double _locateViewportAlignBias = 0.38;

  CloudTrackSortType _sortType = CloudTrackSortType.fileName;
  bool _ascending = true;

  final ScrollController _listScrollController = ScrollController();
  final GlobalKey _locateHighlightRowKey = GlobalKey();
  String? _scrollHighlightItemId;
  bool _batchSelect = false;
  final Set<String> _selectedItemIds = {};

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

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
  ) {
    return _batchEnqueueDownloadSelected(
      context,
      _selectedInListOrder(ordered),
      exitBatchOnSuccess: true,
    );
  }

  Future<bool> _batchEnqueueDownloadSelected(
    BuildContext context,
    List<OneDriveCloudTrack> selected, {
    bool exitBatchOnSuccess = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return false;
    }
    await context.read<OneDriveDownloadQueueController>().enqueueCloudTracks(
      selected,
    );
    if (!context.mounted) return false;
    if (exitBatchOnSuccess) _exitBatchSelect();
    showAppSnackBar(
      context,
      l10n.oneDriveEnqueueAddedMany(selected.length),
      kind: AppSnackKind.success,
      action: SnackBarAction(
        label: l10n.oneDriveDownloadViewQueue,
        onPressed: openOneDriveTransferQueue,
      ),
    );
    return true;
  }

  Future<void> _confirmBatchDeleteRemote(
    BuildContext context,
    List<OneDriveCloudTrack> ordered,
  ) {
    return _confirmBatchDeleteRemoteSelected(
      context,
      _selectedInListOrder(ordered),
      exitBatchOnSuccess: true,
    );
  }

  Future<bool> _confirmBatchDeleteRemoteSelected(
    BuildContext context,
    List<OneDriveCloudTrack> selected, {
    bool exitBatchOnSuccess = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (selected.isEmpty) {
      showAppSnackBar(context, l10n.libraryBatchNoneSelected);
      return false;
    }
    final ok = await showAppConfirmDialog(
      context: context,
      title: l10n.oneDriveCloudBatchDeleteConfirmTitle,
      message: l10n.oneDriveCloudBatchDeleteConfirmMessage(selected.length),
      icon: Icons.delete_outline_rounded,
      confirmIsDestructive: true,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
    );
    if (ok != true || !context.mounted) return false;

    final od = context.read<OneDriveController>();
    final queue = context.read<OneDriveDownloadQueueController>();
    showAppBlockingProgressDialog(
      context: context,
      title: l10n.oneDriveCloudBatchDeleteProgressTitle,
      message: l10n.oneDriveCloudBatchDeleteProgressMessage,
    );
    try {
      final result = await od.deleteCloudTracksRemote(selected);
      await queue.removeTasksForGraphItemIds(selected.map((t) => t.itemId));
      if (!context.mounted) return false;
      if (exitBatchOnSuccess) _exitBatchSelect();
      if (result.failed == 0) {
        showAppSnackBar(
          context,
          l10n.oneDriveCloudBatchDeleteDone(result.deleted),
          kind: AppSnackKind.success,
        );
      } else if (result.deleted > 0) {
        showAppSnackBar(
          context,
          l10n.oneDriveCloudBatchDeletePartial(result.deleted, result.failed),
          kind: AppSnackKind.neutral,
        );
      } else {
        showAppSnackBar(
          context,
          l10n.oneDriveCloudBatchDeleteFailed,
          kind: AppSnackKind.error,
        );
        return false;
      }
      return true;
    } on StateError catch (e) {
      if (!context.mounted) return false;
      final text = '$e'.contains('not signed')
          ? l10n.libraryBatchUploadNeedSignIn
          : '$e';
      showAppSnackBar(context, text, kind: AppSnackKind.error);
      return false;
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          l10n.oneDriveError('$e'),
          kind: AppSnackKind.error,
        );
      }
      return false;
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _cloudBatchActionBar(
    BuildContext context,
    AppLocalizations l10n,
    List<OneDriveCloudTrack> ordered,
  ) {
    return LibraryBatchActionBar(
      selectedCount: _selectedItemIds.length,
      selectAllLabel: _allVisibleSelected(ordered)
          ? l10n.deselectAll
          : l10n.libraryBatchSelectAll,
      onSelectAll: () => _toggleSelectAllVisible(ordered),
      onDeleteRemote: () => _confirmBatchDeleteRemote(context, ordered),
      deleteRemoteTooltip: l10n.oneDriveCloudBatchDelete,
      onDownload: () => _batchEnqueueDownload(context, ordered),
      downloadTooltip: l10n.oneDriveDownloadQueueTooltip,
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
    final outcome = await showSearch<CloudTrackSearchOutcome?>(
      context: context,
      delegate: CloudTrackSearchDelegate(
        sortedTracksProvider: () => _ordered(od),
        searchFieldLabelText: l10n.oneDriveCloudSearchHint,
        onBatchDownload: (ctx, selected) =>
            _batchEnqueueDownloadSelected(ctx, selected),
        onBatchDeleteRemote: (ctx, selected) =>
            _confirmBatchDeleteRemoteSelected(ctx, selected),
      ),
    );
    if (!context.mounted || outcome == null) return;
    switch (outcome) {
      case CloudTrackSearchPlay(:final track):
        await _tapTrack(context, track);
      case CloudTrackSearchLocate(:final track):
        _locateTrackInList(context, track);
    }
  }

  double _scrollOffsetForCloudTrackIndex(int index, ScrollPosition position) {
    final itemTop = _listTopPadding + index * _cloudTrackRowSlotExtent;
    return (itemTop - position.viewportDimension * _locateViewportAlignBias)
        .clamp(0.0, position.maxScrollExtent);
  }

  void _locateTrackInList(BuildContext context, OneDriveCloudTrack track) {
    final l10n = AppLocalizations.of(context);
    final ordered = _ordered(context.read<OneDriveController>());
    final index = ordered.indexWhere((t) => t.itemId == track.itemId);
    if (index < 0) {
      showAppSnackBar(
        context,
        l10n.oneDriveCloudLocateNotInList,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    setState(() => _scrollHighlightItemId = track.itemId);
    _scrollToLocatedTrack(index);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || _scrollHighlightItemId != track.itemId) return;
      setState(() => _scrollHighlightItemId = null);
    });
  }

  void _scrollToLocatedTrack(int index, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listScrollController.hasClients) {
        if (attempt < 20) {
          _scrollToLocatedTrack(index, attempt: attempt + 1);
        }
        return;
      }
      final position = _listScrollController.position;
      final target = _scrollOffsetForCloudTrackIndex(index, position);
      if (attempt == 0 || _locateHighlightRowKey.currentContext == null) {
        _listScrollController.jumpTo(target);
      }
      final rowContext = _locateHighlightRowKey.currentContext;
      if (rowContext != null) {
        Scrollable.ensureVisible(
          rowContext,
          duration: attempt == 0
              ? const Duration(milliseconds: 280)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          alignment: _locateViewportAlignBias,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
        return;
      }
      if (attempt < 20) {
        _scrollToLocatedTrack(index, attempt: attempt + 1);
      }
    });
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
                      leading: const Icon(Icons.folder_special_outlined),
                      title: Text(l10n.oneDriveIndexRootsLabel),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        if (!context.mounted) return;
                        final localeTag = Localizations.localeOf(
                          context,
                        ).toLanguageTag();
                        _showIndexedDirectoriesSheet(
                          context,
                          od: od,
                          l10n: l10n,
                          tracks: _ordered(od),
                          localeTag: localeTag,
                        );
                      },
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

  Future<void> _showIndexedDirectoriesSheet(
    BuildContext context, {
    required OneDriveController od,
    required AppLocalizations l10n,
    required List<OneDriveCloudTrack> tracks,
    required String localeTag,
  }) async {
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
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: FrostedGlassBottomSheet(
              child: Theme(
                data: frostedBottomSheetContentTheme(sheetContext),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.oneDriveIndexRootsLabel,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                sheetContext,
                              ).closeButtonTooltip,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Consumer<OneDriveController>(
                          builder: (context, liveOd, _) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: _buildIndexedDirectoriesPanel(
                                context,
                                l10n: l10n,
                                od: liveOd,
                                tracks: sortCloudTracksCopy(
                                  liveOd.cloudTracks,
                                  _sortType,
                                  _ascending,
                                ),
                                localeTag: localeTag,
                              ),
                            );
                          },
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
    );
  }

  Widget _buildIndexedDirectoriesPanel(
    BuildContext context, {
    required AppLocalizations l10n,
    required OneDriveController od,
    required List<OneDriveCloudTrack> tracks,
    required String localeTag,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final lastScanText = od.cloudIndexAt != null
        ? l10n.oneDriveLastIndexed(
            DateFormat.yMMMd(localeTag).add_jm().format(od.cloudIndexAt!),
          )
        : l10n.oneDriveLastIndexedNever;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lastScanText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.oneDriveTracksCount(tracks.length),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: od.signedIn && !od.cloudIndexBuilding
                    ? () => _runRescan(context, od)
                    : null,
                icon: od.cloudIndexBuilding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(l10n.oneDriveRescanIndex),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: od.signedIn && !od.cloudIndexBuilding
                  ? () => _browseAdd(context, od)
                  : null,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.oneDriveBrowseFolders),
            ),
          ],
        ),
        Text(
          l10n.oneDriveIndexFoldersRecursiveHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        if (od.indexFolders.isEmpty)
          Text(
            l10n.oneDriveNoIndexRoots,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          )
        else
          ...od.indexFolders.map((folder) {
            final label =
                folder.label.isEmpty ? folder.itemId : folder.label;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.folder_rounded,
                    color: Color(0xFFFFB74D),
                    size: 22,
                  ),
                  title: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: l10n.oneDriveRemoveIndexFolderAction,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: od.cloudIndexBuilding
                        ? null
                        : () => _confirmRemoveFolder(
                            context,
                            l10n,
                            od,
                            folder,
                          ),
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
              ],
            );
          }),
      ],
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
    final l10n = AppLocalizations.of(context);
    showAppBlockingProgressDialog(
      context: context,
      title: l10n.oneDriveCloudIndexRescanProgressTitle,
      message: l10n.oneDriveCloudIndexRescanProgressMessage,
    );
    try {
      await od.rebuildCloudIndex();
      if (!context.mounted) return;
      final err = od.cloudIndexError;
      if (err != null && err.isNotEmpty) {
        showAppSnackBar(
          context,
          l10n.oneDriveError(err),
          kind: AppSnackKind.error,
        );
      } else {
        showAppSnackBar(
          context,
          l10n.oneDriveCloudIndexRescanDone(od.cloudTracks.length),
          kind: AppSnackKind.success,
        );
      }
    } on StateError catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          l10n.oneDriveError('$e'),
          kind: AppSnackKind.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          l10n.oneDriveError('$e'),
          kind: AppSnackKind.error,
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
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
    return Consumer<OneDriveController>(
      builder: (context, od, _) {
        final tracks = _ordered(od);

        return PopScope(
          canPop: !_batchSelect,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _batchSelect) {
              _exitBatchSelect();
            }
          },
          child: SongPlaylistThemedScaffold(
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
            body: SongPlaylistBodyUnderlapColumn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (od.cloudIndexBuilding) ...[
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Color(0x22FFFFFF),
                      color: Color(0xFF64B5F6),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        l10n.oneDriveIndexingEllipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildBodyList(
                            context,
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
          ),
        );
      },
    );
  }

  Widget _buildBodyList(
    BuildContext context,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 56,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.oneDriveNoIndexRoots,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: od.signedIn
                    ? () => _showIndexedDirectoriesSheet(
                          context,
                          od: od,
                          l10n: l10n,
                          tracks: tracks,
                          localeTag: Localizations.localeOf(
                            context,
                          ).toLanguageTag(),
                        )
                    : null,
                child: Text(l10n.oneDriveIndexRootsLabel),
              ),
            ],
          ),
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
    return ListView.builder(
      controller: _listScrollController,
      padding: EdgeInsets.fromLTRB(
        8,
        _listTopPadding,
        8,
        songPlaylistListBottomPadding(context) + (_batchSelect ? 56 : 0),
      ),
      itemCount: tracks.length,
      itemExtent: _cloudTrackRowSlotExtent,
      itemBuilder: (context, index) {
        final t = tracks[index];
        final sel = _selectedItemIds.contains(t.itemId);
        final highlight = t.itemId == _scrollHighlightItemId;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              key: highlight
                  ? _locateHighlightRowKey
                  : ValueKey<String>('cloud_track_${t.itemId}'),
              color: highlight
                  ? const Color(0xFF81D4FA).withValues(alpha: 0.14)
                  : Colors.transparent,
              child: SizedBox(
                height: _cloudTrackRowExtent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
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
                    maxLines: 1,
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
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0x22FFFFFF)),
          ],
        );
      },
    );
  }
}
