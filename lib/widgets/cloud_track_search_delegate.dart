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
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/utils/cloud_track_list_utils.dart';
import 'package:yeah_music/widgets/library_batch_action_bar.dart';

/// 云端曲库搜索关闭时的结果：点播下载，或在主列表中定位。
sealed class CloudTrackSearchOutcome {
  const CloudTrackSearchOutcome();
}

final class CloudTrackSearchPlay extends CloudTrackSearchOutcome {
  const CloudTrackSearchPlay(this.track);
  final OneDriveCloudTrack track;
}

final class CloudTrackSearchLocate extends CloudTrackSearchOutcome {
  const CloudTrackSearchLocate(this.track);
  final OneDriveCloudTrack track;
}

/// 云端曲库内搜索：匹配文件名或 [OneDriveCloudTrack.displayPath]；支持多选与定位。
class CloudTrackSearchDelegate extends SearchDelegate<CloudTrackSearchOutcome?> {
  CloudTrackSearchDelegate({
    required this.sortedTracksProvider,
    required this.searchFieldLabelText,
    required this.onBatchDownload,
    required this.onBatchDeleteRemote,
  }) : super(
          searchFieldStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        );

  /// 每次构建时读取最新排序列表（删除远程文件后搜索结果同步更新）。
  final List<OneDriveCloudTrack> Function() sortedTracksProvider;
  final String searchFieldLabelText;
  final Future<bool> Function(
    BuildContext context,
    List<OneDriveCloudTrack> selected,
  ) onBatchDownload;
  final Future<bool> Function(
    BuildContext context,
    List<OneDriveCloudTrack> selected,
  ) onBatchDeleteRemote;

  bool _batchSelect = false;
  final Set<String> _selectedItemIds = <String>{};
  final ValueNotifier<int> _uiGeneration = ValueNotifier(0);

  void _markDirty() {
    _uiGeneration.value++;
  }

  void _exitBatchSelect() {
    _batchSelect = false;
    _selectedItemIds.clear();
    _markDirty();
  }

  void _toggleSelectItem(String itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
    } else {
      _selectedItemIds.add(itemId);
    }
    _markDirty();
  }

  bool _allVisibleSelected(List<OneDriveCloudTrack> visible) {
    if (visible.isEmpty) return false;
    return visible.every((t) => _selectedItemIds.contains(t.itemId));
  }

  void _toggleSelectAllVisible(List<OneDriveCloudTrack> visible) {
    final ids = visible.map((t) => t.itemId).toSet();
    if (ids.isEmpty) return;
    if (_allVisibleSelected(visible)) {
      _selectedItemIds.removeWhere(ids.contains);
    } else {
      _selectedItemIds.addAll(ids);
    }
    _markDirty();
  }

  List<OneDriveCloudTrack> _selectedInListOrder(List<OneDriveCloudTrack> visible) {
    final out = <OneDriveCloudTrack>[];
    for (final t in visible) {
      if (_selectedItemIds.contains(t.itemId)) out.add(t);
    }
    return out;
  }

  @override
  String get searchFieldLabel => searchFieldLabelText;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        toolbarTextStyle: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
      ),
    );
  }

  @override
  Widget? buildFlexibleSpace(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: const SizedBox.expand(),
        );
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      ValueListenableBuilder<int>(
        valueListenable: _uiGeneration,
        builder: (context, _, _) {
          if (_batchSelect) {
            return TextButton(
              onPressed: _exitBatchSelect,
              child: Text(
                AppLocalizations.of(context).libraryBatchDone,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (query.isEmpty) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () => query = '',
          );
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _uiGeneration,
      builder: (context, _, _) {
        return IconButton(
          icon: Icon(
            _batchSelect ? Icons.close : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            if (_batchSelect) {
              _exitBatchSelect();
            } else {
              close(context, null);
            }
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _body(context);

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: ValueListenableBuilder<int>(
            valueListenable: _uiGeneration,
            builder: (context, _, _) {
              return ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: _list(context),
              );
            },
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = sortedTracksProvider();
    final filtered = filterCloudTracksByQuery(sorted, query);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoMatchingSongs,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: 120 + (_batchSelect ? 56 : 0)),
            itemCount: filtered.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0x22FFFFFF)),
            itemBuilder: (context, index) {
              final t = filtered[index];
              final sel = _selectedItemIds.contains(t.itemId);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: _batchSelect
                    ? Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        value: sel,
                        onChanged: (_) => _toggleSelectItem(t.itemId),
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
                trailing: _batchSelect
                    ? null
                    : IconButton(
                        tooltip: l10n.oneDriveCloudLocateInList,
                        icon: Icon(
                          Icons.my_location,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 22,
                        ),
                        onPressed: () =>
                            close(context, CloudTrackSearchLocate(t)),
                      ),
                onTap: () {
                  if (_batchSelect) {
                    _toggleSelectItem(t.itemId);
                  } else {
                    close(context, CloudTrackSearchPlay(t));
                  }
                },
                onLongPress: () {
                  if (!_batchSelect) {
                    _batchSelect = true;
                    _selectedItemIds.add(t.itemId);
                    _markDirty();
                  }
                },
              );
            },
          ),
        ),
        if (_batchSelect)
          LibraryBatchActionBar(
            selectedCount: _selectedItemIds.length,
            selectAllLabel: _allVisibleSelected(filtered)
                ? l10n.deselectAll
                : l10n.libraryBatchSelectAll,
            onSelectAll: () => _toggleSelectAllVisible(filtered),
            onDeleteRemote: () async {
              final selected = _selectedInListOrder(filtered);
              if (await onBatchDeleteRemote(context, selected) &&
                  context.mounted) {
                _exitBatchSelect();
              }
            },
            deleteRemoteTooltip: l10n.oneDriveCloudBatchDelete,
            onDownload: () async {
              final selected = _selectedInListOrder(filtered);
              if (await onBatchDownload(context, selected) &&
                  context.mounted) {
                _exitBatchSelect();
              }
            },
            downloadTooltip: l10n.oneDriveDownloadQueueTooltip,
          ),
      ],
    );
  }
}
