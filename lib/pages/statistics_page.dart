import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/song_audio_quality_badge.dart';

class _PlaybackHiveSlice {
  const _PlaybackHiveSlice({
    required this.recentEntries,
    required this.tracksWithCounts,
    required this.totalPlayEvents,
    required this.odCachedCount,
    required this.totalListenedWallMs,
  });

  final int recentEntries;
  final int tracksWithCounts;
  final int totalPlayEvents;
  final int odCachedCount;
  final int totalListenedWallMs;
}

/// 抽屉入口：本地曲库规模、收听累计、歌单与 OneDrive 概要。
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const List<SongAudioQualityTier> _qualityTierOrder = [
    SongAudioQualityTier.dsd,
    SongAudioQualityTier.hr,
    SongAudioQualityTier.sq,
    SongAudioQualityTier.hq,
    SongAudioQualityTier.std,
    SongAudioQualityTier.lq,
  ];

  late Future<_PlaybackHiveSlice> _sliceFuture;
  bool _primedHiveSlice = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_primedHiveSlice) {
      _primedHiveSlice = true;
      MusicService.flushListeningWallClockIntoHive();
      _sliceFuture = _loadSlice(context.read<OneDriveController>());
    }
  }

  Future<void> _reload(BuildContext context, OneDriveController od) async {
    final l10n = AppLocalizations.of(context);
    MusicService.flushListeningWallClockIntoHive();
    showAppSnackBar(context, l10n.statisticsReloadStarted);
    final fut = _loadSlice(od);
    setState(() {
      _sliceFuture = fut;
    });
    try {
      await fut;
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.statisticsReloadDone,
        kind: AppSnackKind.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.statisticsReloadFailed,
        kind: AppSnackKind.error,
      );
    }
  }

  Future<_PlaybackHiveSlice> _loadSlice(OneDriveController od) async {
    final recent = await RecentPlayService.getRecentListStoredCount();
    final totals = await RecentPlayService.getPlayCountTotals();
    final listenedMs = await RecentPlayService.getTotalListenedMilliseconds();
    final cached = await od.loadLocallyCachedOneDriveSongs();
    return _PlaybackHiveSlice(
      recentEntries: recent,
      tracksWithCounts: totals.tracksWithCounts,
      totalPlayEvents: totals.totalPlayEvents,
      odCachedCount: cached.length,
      totalListenedWallMs: listenedMs,
    );
  }

  String _formatListeningTotal(AppLocalizations l10n, int ms) {
    if (ms <= 0) return l10n.statisticsDurationMOnly(0);
    return _formatDuration(l10n, Duration(milliseconds: ms));
  }

  String _formatDuration(AppLocalizations l10n, Duration d) {
    if (d.inMilliseconds <= 0) return l10n.statisticsDurationUnknown;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return l10n.statisticsDurationHM(h, m);
    final mins = d.inMinutes;
    return l10n.statisticsDurationMOnly(mins < 1 ? 1 : mins);
  }

  /// (展示标签, 曲目数)；无扩展名归入「其他」
  List<MapEntry<String, int>> _sortedFormatPairs(
    List<Song> songs,
    AppLocalizations l10n,
  ) {
    final raw = <String, int>{};
    for (final s in songs) {
      var ext = p.extension(s.path).toLowerCase();
      if (ext.startsWith('.')) ext = ext.substring(1);
      final label =
          ext.isEmpty ? l10n.statisticsFormatsOther : ext.toUpperCase();
      raw[label] = (raw[label] ?? 0) + 1;
    }
    final list = raw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _qualityDistributionWrap(
    BuildContext context,
    AppLocalizations l10n,
    List<Song> lib,
  ) {
    final dashStyle = TextStyle(
      color: context.gradFg(0.45),
      fontSize: 14,
    );
    if (lib.isEmpty) {
      return Text('—', style: dashStyle);
    }
    final counts = <SongAudioQualityTier, int>{};
    var unknown = 0;
    for (final s in lib) {
      final t = classifySongAudioQuality(s);
      if (t == null) {
        unknown++;
      } else {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final chips = <Widget>[];
    for (final tier in _qualityTierOrder) {
      final n = counts[tier];
      if (n != null && n > 0) {
        chips.add(
          Tooltip(
            message: songAudioQualityLocalizedTitle(l10n, tier),
            child: _formatChip(context, tier.shortLabel, n),
          ),
        );
      }
    }
    if (unknown > 0) {
      chips.add(
        Tooltip(
          message: l10n.statisticsQualityUnknown,
          child: _formatChip(context, l10n.statisticsQualityUnknown, unknown),
        ),
      );
    }
    if (chips.isEmpty) {
      return Text('—', style: dashStyle);
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: false,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.statisticsTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
              actions: [
                IconButton(
                  tooltip: l10n.statisticsReloadTooltip,
                  icon: Icon(Icons.refresh_rounded, color: context.gradFg()),
                  onPressed: () => _reload(
                    context,
                    context.read<OneDriveController>(),
                  ),
                ),
              ],
            ),
            body: Consumer4<PlayListProvider, FolderProvider,
                UserPlaylistProvider, OneDriveController>(
              builder: (context, play, folders, upl, od, _) {

                final showMini = play.initialized &&
                    play.currentSong != null &&
                    play.playList.isNotEmpty;
                final bottomPad = MediaQuery.paddingOf(context).bottom +
                    8 +
                    (showMini ? MiniPlayer.barHeight : 0.0);

                if (!play.initialized) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPad),
                      child: Text(
                        l10n.statisticsNotInitialized,
                        style: TextStyle(color: context.gradFg(0.72)),
                      ),
                    ),
                  );
                }

                final lib = play.libraryMergedSongs;
                var sumDur = Duration.zero;
                for (final s in lib) {
                  final d = s.duration;
                  if (d != null && d.inMilliseconds > 0) {
                    sumDur += d;
                  }
                }

                final playlistCount = upl.playlists.length;
                var playlistRefs = 0;
                for (final pl in upl.playlists) {
                  playlistRefs += pl.songPaths.length;
                }

                final formatPairs = _sortedFormatPairs(lib, l10n);
                const formatShow = 8;
                final shownFormats = formatPairs.take(formatShow).toList();
                final moreFormatKinds =
                    formatPairs.length > formatShow ? formatPairs.length - formatShow : 0;

                final indexedCloud =
                    od.signedIn ? od.cloudTracks.length : null;

                return FutureBuilder<_PlaybackHiveSlice>(
                  future: _sliceFuture,
                  builder: (context, snap) {
                    final slice = snap.data;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
                      children: [
                        Text(
                          l10n.statisticsSubtitle,
                          style: TextStyle(
                            color: context.gradFg(0.62),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle(context, l10n.statisticsSectionLibrary),
                        _tile(
                          context,
                          icon: Icons.library_music_outlined,
                          title: l10n.statisticsTracksLabel,
                          value: '${lib.length}',
                        ),
                        _tile(
                          context,
                          icon: Icons.folder_open_outlined,
                          title: l10n.statisticsFoldersLabel,
                          value: '${folders.folders.length}',
                        ),
                        _tile(
                          context,
                          icon: Icons.schedule_outlined,
                          title: l10n.statisticsDurationLabel,
                          value: _formatDuration(l10n, sumDur),
                          subtitle: l10n.statisticsDurationHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.statisticsFormatsLabel,
                          style: TextStyle(
                            color: context.gradFg(0.58),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (formatPairs.isEmpty)
                          Text(
                            '—',
                            style: TextStyle(
                              color: context.gradFg(0.45),
                              fontSize: 14,
                            ),
                          )
                        else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final e in shownFormats)
                                _formatChip(context, e.key, e.value),
                            ],
                          ),
                          if (moreFormatKinds > 0) ...[
                            const SizedBox(height: 10),
                            Text(
                              l10n.statisticsFormatsMore(moreFormatKinds),
                              style: TextStyle(
                                color: context.gradFg(0.48),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 18),
                        Text(
                          l10n.statisticsQualityLabel,
                          style: TextStyle(
                            color: context.gradFg(0.58),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.statisticsQualityHint,
                          style: TextStyle(
                            color: context.gradFg(0.45),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _qualityDistributionWrap(context, l10n, lib),
                        const SizedBox(height: 22),
                        _sectionTitle(context, l10n.statisticsSectionPlayback),
                        if (slice == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: context.gradFg(0.35),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          _tile(
                            context,
                            icon: Icons.timer_outlined,
                            title: l10n.statisticsHistoricalListeningLabel,
                            value: _formatListeningTotal(
                              l10n,
                              slice.totalListenedWallMs,
                            ),
                            subtitle: l10n.statisticsHistoricalListeningHint,
                          ),
                          _tile(
                            context,
                            icon: Icons.play_circle_outline,
                            title: l10n.statisticsPlaybackTotalLabel,
                            value: '${slice.totalPlayEvents}',
                            subtitle: l10n.statisticsPlaybackTotalSubtitle,
                          ),
                          _tile(
                            context,
                            icon: Icons.history_toggle_off_outlined,
                            title: l10n.statisticsPlaybackDistinctLabel,
                            value: '${slice.tracksWithCounts}',
                          ),
                          _tile(
                            context,
                            icon: Icons.recent_actors_outlined,
                            title: l10n.statisticsRecentEntriesLabel,
                            value: '${slice.recentEntries}',
                            subtitle: l10n.statisticsRecentEntriesSubtitle(
                              RecentPlayService.maxStoredRecentPaths,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _sectionTitle(
                          context,
                          l10n.statisticsSectionPlaylists,
                        ),
                        _tile(
                          context,
                          icon: Icons.queue_music_outlined,
                          title: l10n.statisticsPlaylistsCountLabel,
                          value: '$playlistCount',
                        ),
                        _tile(
                          context,
                          icon: Icons.link_outlined,
                          title: l10n.statisticsPlaylistRefsLabel,
                          value: '$playlistRefs',
                          subtitle: l10n.statisticsPlaylistRefsSubtitle,
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle(context, l10n.statisticsSectionOneDrive),
                        if (!od.signedIn)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 8),
                            child: Text(
                              l10n.statisticsOneDriveUnavailable,
                              style: TextStyle(
                                color: context.gradFg(0.55),
                                fontSize: 14,
                              ),
                            ),
                          )
                        else ...[
                          _tile(
                            context,
                            icon: Icons.cloud_queue_outlined,
                            title: l10n.statisticsOneDriveIndexedLabel,
                            value: '$indexedCloud',
                          ),
                          _tile(
                            context,
                            icon: Icons.download_for_offline_outlined,
                            title: l10n.statisticsOneDriveCachedLabel,
                            value: slice != null ? '${slice.odCachedCount}' : '…',
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: context.gradFg(0.92),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    final fg = context.gradFg();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: fg.withValues(alpha: 0.85)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: fg,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.48),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatChip(BuildContext context, String label, int count) {
    final fg = context.gradFg();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradBorder(0.35)),
        color: fg.withValues(alpha: Theme.of(context).brightness ==
                Brightness.dark
            ? 0.06
            : 0.04),
      ),
      child: Text(
        '$label · $count',
        style: TextStyle(
          color: fg.withValues(alpha: 0.88),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
