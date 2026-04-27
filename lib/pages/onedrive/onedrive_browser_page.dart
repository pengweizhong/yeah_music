import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_session_surface.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';

class _NavFrame {
  _NavFrame({this.parentItemId, required this.title});
  final String? parentItemId;
  final String title;
}

class OneDriveBrowserPage extends StatefulWidget {
  const OneDriveBrowserPage({super.key});

  @override
  State<OneDriveBrowserPage> createState() => _OneDriveBrowserPageState();
}

class _OneDriveBrowserPageState extends State<OneDriveBrowserPage> {
  final List<_NavFrame> _stack = [];
  List<OneDriveGraphItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final od = context.read<OneDriveController>();
    final parent = _stack.isEmpty ? null : _stack.last.parentItemId;
    try {
      final list = await od.listChildren(parent);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _playFile(OneDriveGraphItem item) async {
    if (item.isFolder || !OneDriveConfig.isAudioFileName(item.name)) return;
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveController>();
    final play = context.read<PlayListProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final song = await od.songForPlayableItem(item);
      if (!mounted) return;
      Navigator.pop(context);
      await play.setPlaybackQueueAndPlay(
        [song],
        0,
        session: PlaybackSessionSurface.adHoc,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.oneDriveError('$e'))),
        );
      }
    }
  }

  Future<void> _playAllInFolder() async {
    final l10n = AppLocalizations.of(context);
    final od = context.read<OneDriveController>();
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
      final songs = await od.buildQueueForAudioItems(_items);
      if (!mounted) return;
      Navigator.pop(context);
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.oneDriveEmptyFolder)),
        );
        return;
      }
      await play.setPlaybackQueueAndPlay(
        songs,
        0,
        session: PlaybackSessionSurface.adHoc,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.oneDriveError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, theme, _) {
        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                _stack.isEmpty
                    ? l10n.oneDriveBrowserTitle
                    : _stack.map((e) => e.title).join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (_stack.isNotEmpty) {
                    setState(() {
                      _stack.removeLast();
                    });
                    _reload();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: [
                if (_items.any(
                  (e) => !e.isFolder && OneDriveConfig.isAudioFileName(e.name),
                ))
                  TextButton(
                    onPressed: _loading ? null : _playAllInFolder,
                    child: Text(
                      l10n.oneDrivePlayAll,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            body: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          l10n.oneDriveError(_error!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              l10n.oneDriveEmptyFolder,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                              16,
                              100,
                            ),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0x22FFFFFF),
                            ),
                            itemBuilder: (context, i) {
                              final it = _items[i];
                              return ListTile(
                                leading: Icon(
                                  it.isFolder
                                      ? Icons.folder_rounded
                                      : Icons.audio_file_rounded,
                                  color: it.isFolder
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFF4FC3F7),
                                ),
                                title: Text(
                                  it.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  if (it.isFolder) {
                                    setState(() {
                                      _stack.add(
                                        _NavFrame(
                                          parentItemId: it.id,
                                          title: it.name,
                                        ),
                                      );
                                    });
                                    _reload();
                                  } else {
                                    _playFile(it);
                                  }
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
}
