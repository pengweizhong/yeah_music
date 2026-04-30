import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/widgets/onedrive_bulk_download_sheet.dart';
import 'package:yeah_music/utils/cloud_track_list_utils.dart';
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

  Future<void> _browseAdd(BuildContext context, OneDriveController od) async {
    final picked = await Navigator.of(context).push<OneDriveFolderPickResult>(
      MaterialPageRoute(
        builder: (_) => const OneDriveBrowserPage(pickFolderForIndex: true),
      ),
    );
    if (!context.mounted || picked == null) return;
    await od.addIndexFolder(picked.itemId, picked.name);
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

  Future<void> _playAll(BuildContext context, OneDriveController od) async {
    final l10n = AppLocalizations.of(context);
    final queue = sortCloudTracksCopy(od.cloudTracks, _sortType, _ascending);
    if (queue.isEmpty) {
      showAppSnackBar(context, l10n.oneDriveEmptyFolder);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => OneDriveBulkDownloadSheet(
        runBatch: (c) => c.runBatchFromCloudTracks(queue),
      ),
    );
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
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const OneDriveDownloadQueuePage(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, OneDriveController>(
      builder: (context, theme, od, _) {
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        final lastFmt = od.cloudIndexAt != null
            ? DateFormat.yMMMd(localeTag).add_jm().format(od.cloudIndexAt!)
            : '';
        final tracks = _ordered(od);

        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.oneDriveCloudLibraryTitle,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              actions: [
                IconButton(
                  tooltip: l10n.oneDriveDownloadQueueTooltip,
                  icon: const Icon(Icons.download_for_offline_rounded),
                  onPressed: od.signedIn
                      ? () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const OneDriveDownloadQueuePage(),
                            ),
                          );
                        }
                      : null,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  color: const Color(0xFF1E1E1E),
                  onSelected: od.signedIn && !od.cloudIndexBuilding
                      ? (value) async {
                          if (value == 'rescan') {
                            await _runRescan(context, od);
                          } else if (value == 'add') {
                            await _browseAdd(context, od);
                          } else if (value == 'browse' && context.mounted) {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OneDriveBrowserPage(),
                              ),
                            );
                          }
                        }
                      : null,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'rescan',
                      enabled: od.indexFolders.isNotEmpty,
                      child: Text(l10n.oneDriveRescanIndex),
                    ),
                    PopupMenuItem(
                      value: 'add',
                      child: Text(l10n.oneDriveBrowseFolders),
                    ),
                    PopupMenuItem(
                      value: 'browse',
                      child: Text(l10n.oneDriveBrowserTitle),
                    ),
                  ],
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
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top:
                          songPlaylistUnderlapTopInset(ctx) +
                          (od.cloudIndexBuilding ? 8 : 12),
                      bottom: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lastFmt.isNotEmpty && !od.cloudIndexBuilding) ...[
                          Text(
                            l10n.oneDriveLastIndexed(lastFmt),
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
                          const SizedBox(height: 10),
                        ],
                        if (tracks.isNotEmpty && !od.cloudIndexBuilding)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: od.signedIn
                                  ? () => _playAll(context, od)
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(l10n.oneDrivePlayAllTracks),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildBodyList(context, theme, od, l10n, tracks),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const MiniPlayer(),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.oneDriveNoIndexRoots,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.45,
            ),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 120),
      itemCount: tracks.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (context, index) {
        final t = tracks[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(
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
          onTap: od.cloudIndexBuilding ? null : () => _tapTrack(context, t),
        );
      },
    );
  }
}
