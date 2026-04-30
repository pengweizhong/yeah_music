import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/onedrive_download_queue_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';
import 'package:yeah_music/widgets/onedrive_bulk_download_sheet.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/song_playlist_page_shell.dart';

/// 从 [OneDriveBrowserPage] 退回时传给「添加到云端索引」的选中文件夹。
class OneDriveFolderPickResult {
  OneDriveFolderPickResult({required this.itemId, required this.name});
  final String itemId;
  final String name;
}

class _NavFrame {
  _NavFrame({this.parentItemId, required this.title});
  final String? parentItemId;
  final String title;
}

class OneDriveBrowserPage extends StatefulWidget {
  const OneDriveBrowserPage({
    super.key,
    this.pickFolderForIndex = false,
    this.folderPickSubtitle,
  });

  /// `true` 时用于云端曲库：仅选文件夹返回 [OneDriveFolderPickResult]，点播文件被禁用。
  final bool pickFolderForIndex;

  /// 选文件夹模式下的说明文案；为 `null` 时用默认「云端曲库」提示。
  final String? folderPickSubtitle;

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
    final folderLabel = _stack.isEmpty
        ? l10n.oneDriveBrowserTitle
        : _stack.map((e) => e.title).join(' / ');
    await context.read<OneDriveDownloadQueueController>().enqueueGraphItems([
      (item: item, title: item.name, subtitle: folderLabel),
    ]);
    if (!mounted) return;
    showAppSnackBar(
      context,
      l10n.oneDriveEnqueueAddedSingle(item.name),
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

  Future<void> _playAllInFolder() async {
    final l10n = AppLocalizations.of(context);
    final audioItems = _items
        .where((e) => !e.isFolder && OneDriveConfig.isAudioFileName(e.name))
        .toList();
    if (audioItems.isEmpty) {
      showAppSnackBar(context, l10n.oneDriveEmptyFolder);
      return;
    }
    final folderLabel = _stack.isEmpty
        ? l10n.oneDriveBrowserTitle
        : _stack.map((e) => e.title).join(' / ');
    final entries = audioItems
        .map((e) => (item: e, title: e.name, subtitle: folderLabel))
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => OneDriveBulkDownloadSheet(
        runBatch: (c) => c.runBatchFromGraphItems(entries),
      ),
    );
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
              title: widget.pickFolderForIndex
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _stack.isEmpty
                              ? l10n.oneDriveBrowserTitle
                              : _stack.map((e) => e.title).join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.folderPickSubtitle ??
                              l10n.oneDrivePickFolderForIndex,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    )
                  : Text(
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
                if (!widget.pickFolderForIndex)
                  IconButton(
                    tooltip: l10n.oneDriveDownloadQueueTooltip,
                    icon: const Icon(Icons.download_for_offline_rounded),
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const OneDriveDownloadQueuePage(),
                        ),
                      );
                    },
                  ),
                if (widget.pickFolderForIndex && _stack.isNotEmpty)
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            final frame = _stack.last;
                            final id = frame.parentItemId;
                            if (id == null) return;
                            Navigator.pop(
                              context,
                              OneDriveFolderPickResult(
                                itemId: id,
                                name: frame.title,
                              ),
                            );
                          },
                    child: Text(
                      l10n.oneDriveUseCurrentFolder,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (!widget.pickFolderForIndex &&
                    _items.any(
                      (e) =>
                          !e.isFolder && OneDriveConfig.isAudioFileName(e.name),
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
                : Builder(
                    builder: (ctx) => ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        songPlaylistUnderlapTopInset(ctx) + 8,
                        16,
                        100,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0x22FFFFFF)),
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
                          trailing: it.isFolder && widget.pickFolderForIndex
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.playlist_add,
                                    color: Color(0xFFB0BEC5),
                                  ),
                                  tooltip: l10n.oneDriveAddFolderTooltip,
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                      OneDriveFolderPickResult(
                                        itemId: it.id,
                                        name: it.name,
                                      ),
                                    );
                                  },
                                )
                              : null,
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
                              if (widget.pickFolderForIndex) {
                                return;
                              }
                              _playFile(it);
                            }
                          },
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
