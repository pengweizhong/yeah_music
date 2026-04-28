import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';

/// OneDrive：将用户配置的目录递归索引为曲目列表；点播再走按需下载。
class OneDriveCloudPlaylistPage extends StatelessWidget {
  const OneDriveCloudPlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, OneDriveController>(
      builder: (context, theme, od, _) {
        final localeTag = Localizations.localeOf(context).toLanguageTag();
        final lastIndexedFmt = od.cloudIndexAt != null
            ? DateFormat.yMMMd(localeTag).add_jm().format(od.cloudIndexAt!)
            : '';

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
              actions: [
                IconButton(
                  tooltip: l10n.oneDriveBrowserTitle,
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const OneDriveBrowserPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                    20,
                    8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      Text(
                        l10n.oneDriveCloudLibrarySubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: od.signedIn && !od.cloudIndexBuilding ? () => _browseAdd(context, od) : null,
                            icon: const Icon(Icons.folder_copy_outlined),
                            label: Text(l10n.oneDriveBrowseFolders),
                          ),
                          FilledButton.tonal(
                            onPressed: od.signedIn && !od.cloudIndexBuilding && od.indexFolders.isNotEmpty
                                ? () => _runRescan(context, od)
                                : null,
                            child: Text(l10n.oneDriveRescanIndex),
                          ),
                        ],
                      ),
                      if (od.cloudIndexError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.oneDriveError(od.cloudIndexError!),
                          style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 13),
                        ),
                      ],
                      if (od.cloudIndexBuilding) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.oneDriveIndexingEllipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (od.cloudIndexAt != null && lastIndexedFmt.isNotEmpty && !od.cloudIndexBuilding) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.oneDriveLastIndexed(lastIndexedFmt),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.oneDriveTracksCount(od.cloudTracks.length),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        l10n.oneDriveIndexRootsLabel,
                        style:
                            const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      if (od.indexFolders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child:
                              Text(l10n.oneDriveNoIndexRoots, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                        ),
                      ...od.indexFolders.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.folder_special_rounded,
                                color: Colors.orangeAccent.withValues(alpha: 0.9),
                              ),
                              title: Text(f.label, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                f.itemId,
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                                icon: Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: 0.55)),
                                onPressed:
                                    od.cloudIndexBuilding ? null : () async => od.removeIndexFolder(f.itemId),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (od.cloudTracks.isNotEmpty && !od.cloudIndexBuilding)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: od.signedIn ? () => _playAll(context, od) : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.oneDrivePlayAllTracks),
                          ),
                        ),
                      if (od.cloudTracks.isEmpty && od.indexFolders.isNotEmpty && !od.cloudIndexBuilding && od.cloudIndexError == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            l10n.oneDriveCloudLibraryEmpty,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), height: 1.5),
                          ),
                        ),
                    ]),
                  ),
                ),
                if (od.cloudTracks.isNotEmpty && !od.cloudIndexBuilding)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = od.cloudTracks[index];
                          final isLast = index == od.cloudTracks.length - 1;
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                leading: const Icon(Icons.audiotrack_rounded, color: Color(0xFF81D4FA), size: 22),
                                title: Text(
                                  t.fileName,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  t.displayPath,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap:
                                    od.cloudIndexBuilding ? null : () => _tapTrack(context, od, t),
                              ),
                              if (!isLast) const Divider(height: 1, color: Color(0x22FFFFFF)),
                            ],
                          );
                        },
                        childCount: od.cloudTracks.length,
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }

  static Future<void> _browseAdd(BuildContext context, OneDriveController od) async {
    final picked = await Navigator.of(context).push<OneDriveFolderPickResult>(
      MaterialPageRoute(builder: (_) => const OneDriveBrowserPage(pickFolderForIndex: true)),
    );
    if (!context.mounted || picked == null) return;
    await od.addIndexFolder(picked.itemId, picked.name);
    if (!context.mounted) return;
    await _runRescan(context, od);
  }

  static Future<void> _runRescan(BuildContext context, OneDriveController od) async {
    try {
      await od.rebuildCloudIndex();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).oneDriveError('$e'))),
        );
      }
    }
  }

  static Future<void> _playAll(BuildContext context, OneDriveController od) async {
    final l10n = AppLocalizations.of(context);
    final play = context.read<PlayListProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.oneDrivePreparing)),
          ],
        ),
      ),
    );
    try {
      final songs = await od.buildQueueForCloudTracks(od.cloudTracks.toList(growable: false));
      if (!context.mounted) return;
      Navigator.pop(context);
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.oneDriveEmptyFolder)));
        return;
      }
      await play.setPlaybackQueueAndPlay(songs, 0, session: PlaybackSessionSurface.adHoc);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.oneDriveError('$e'))));
      }
    }
  }

  static Future<void> _tapTrack(BuildContext context, OneDriveController od, OneDriveCloudTrack t) async {
    final l10n = AppLocalizations.of(context);
    final play = context.read<PlayListProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final song = await od.songForCloudTrack(t);
      if (!context.mounted) return;
      Navigator.pop(context);
      await play.setPlaybackQueueAndPlay([song], 0, session: PlaybackSessionSurface.adHoc);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.oneDriveError('$e'))));
      }
    }
  }
}
