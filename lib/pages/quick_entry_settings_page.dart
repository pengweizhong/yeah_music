import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/services/settings_service.dart';

/// 首页「快捷入口」显隐与排序
class QuickEntrySettingsPage extends StatefulWidget {
  const QuickEntrySettingsPage({super.key, required this.initial});

  final QuickEntryConfig initial;

  @override
  State<QuickEntrySettingsPage> createState() => _QuickEntrySettingsPageState();
}

class _QuickEntrySettingsPageState extends State<QuickEntrySettingsPage> {
  late List<String> _order;
  late Set<String> _hidden;

  @override
  void initState() {
    super.initState();
    final c = QuickEntryConfig(
      order: List<String>.from(widget.initial.order),
      hidden: Set<String>.from(widget.initial.hidden),
    );
    c.normalizeInPlace();
    _order = c.order;
    _hidden = c.hidden;
  }

  String _title(String id, AppLocalizations l10n) {
    switch (id) {
      case QuickEntryConfig.idLibrary:
        return l10n.homeEntryLibrary;
      case QuickEntryConfig.idPlaylists:
        return l10n.homeEntryMyPlaylists;
      case QuickEntryConfig.idRecent:
        return l10n.homeEntryRecent;
      case QuickEntryConfig.idMostPlayed:
        return l10n.homeEntryMostPlayed;
      case QuickEntryConfig.idDiscover:
        return l10n.homeEntryDiscover;
      case QuickEntryConfig.idCloudLibrary:
        return l10n.homeEntryCloudLibrary;
      case QuickEntryConfig.idOneDrive:
        return l10n.homeEntryOneDrive;
      case QuickEntryConfig.idOneDriveCachePlaylist:
        return l10n.homeEntryOneDriveCachePlaylist;
      default:
        return id;
    }
  }

  IconData _icon(String id) {
    switch (id) {
      case QuickEntryConfig.idLibrary:
        return Icons.library_music_rounded;
      case QuickEntryConfig.idPlaylists:
        return Icons.playlist_play_rounded;
      case QuickEntryConfig.idRecent:
        return Icons.history_rounded;
      case QuickEntryConfig.idMostPlayed:
        return Icons.equalizer_rounded;
      case QuickEntryConfig.idDiscover:
        return Icons.explore_rounded;
      case QuickEntryConfig.idCloudLibrary:
        return Icons.cloud_queue_rounded;
      case QuickEntryConfig.idOneDrive:
        return Icons.cloud_rounded;
      case QuickEntryConfig.idOneDriveCachePlaylist:
        return Icons.download_done_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  Future<void> _saveAndPop() async {
    final c = QuickEntryConfig(order: List<String>.from(_order), hidden: Set<String>.from(_hidden));
    c.normalizeInPlace();
    await SettingsService.saveQuickEntryConfig(c);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            await _saveAndPop();
          },
          child: themeConfig.buildThemedBackground(
            context: context,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  l10n.quickEntrySettingsTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: _saveAndPop,
                  tooltip: l10n.tooltipBack,
                ),
                actions: [
                  TextButton(
                    onPressed: _saveAndPop,
                    child: Text(
                      l10n.tooltipDone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      l10n.quickEntryReorderHint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      buildDefaultDragHandles: false,
                      itemCount: _order.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final x = _order.removeAt(oldIndex);
                          _order.insert(newIndex, x);
                        });
                      },
                      itemBuilder: (context, index) {
                        final id = _order[index];
                        final show = !_hidden.contains(id);
                        return Card(
                          key: ValueKey<String>(id),
                          color: Colors.white.withValues(alpha: 0.08),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Icon(
                              _icon(id),
                              color: show
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                            title: Text(
                              _title(id, l10n),
                              style: TextStyle(
                                color: show
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              l10n.quickEntryShowOnHome,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: show,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v) {
                                        _hidden.remove(id);
                                      } else {
                                        _hidden.add(id);
                                      }
                                    });
                                  },
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ],
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
          ),
        );
      },
    );
  }
}
