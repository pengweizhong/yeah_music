import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_tag_editor_launcher.dart';
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/song_embedded_metadata_writer.dart';

/// 底部表单：编辑内嵌标签（写入磁盘后再由调用方刷新内存/Hive）。
Future<void> showSongInlineTagsEditorSheet({
  required BuildContext navigatorContext,
  required Song song,
  required Future<void> Function(String path) onSavedReload,
}) async {
  await showModalBottomSheet<void>(
    context: navigatorContext,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final bottomInset = mq.viewInsets.bottom;
      final visibleHeight = mq.size.height - bottomInset;
      final maxSheetHeight = visibleHeight * 0.92;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FrostedGlassBottomSheet(
          child: Theme(
            data: frostedBottomSheetContentTheme(sheetContext),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: _SongInlineTagsEditorBody(
                song: song,
                navigatorContext: navigatorContext,
                onSavedReload: onSavedReload,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SongInlineTagsEditorBody extends StatefulWidget {
  const _SongInlineTagsEditorBody({
    required this.song,
    required this.navigatorContext,
    required this.onSavedReload,
  });

  final Song song;
  final BuildContext navigatorContext;
  final Future<void> Function(String path) onSavedReload;

  @override
  State<_SongInlineTagsEditorBody> createState() =>
      _SongInlineTagsEditorBodyState();
}

class _SongInlineTagsEditorBodyState extends State<_SongInlineTagsEditorBody> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _year;
  late final TextEditingController _trackNumber;
  late final TextEditingController _trackTotal;
  late final TextEditingController _discNumber;
  late final TextEditingController _discTotal;
  late final TextEditingController _lyrics;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.song;
    final fallbackTitle = p.basenameWithoutExtension(s.path);
    _title = TextEditingController(
      text: (s.title?.trim().isNotEmpty ?? false) ? s.title! : fallbackTitle,
    );
    _artist = TextEditingController(text: s.artist ?? '');
    _album = TextEditingController(text: s.album ?? '');
    final y = s.year;
    _year = TextEditingController(
      text: (y != null && y.year > 0) ? '${y.year}' : '',
    );
    _trackNumber = TextEditingController(
      text: s.trackNumber != null ? '${s.trackNumber}' : '',
    );
    _trackTotal = TextEditingController(
      text: s.trackTotal != null ? '${s.trackTotal}' : '',
    );
    _discNumber = TextEditingController(
      text: s.discNumber != null ? '${s.discNumber}' : '',
    );
    _discTotal = TextEditingController(
      text: s.totalDisc != null ? '${s.totalDisc}' : '',
    );
    _lyrics = TextEditingController(text: s.lyrics ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _year.dispose();
    _trackNumber.dispose();
    _trackTotal.dispose();
    _discNumber.dispose();
    _discTotal.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  DateTime? _parseYear(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final y = int.tryParse(t);
    if (y == null || y <= 0 || y > 9999) {
      throw FormatException('year');
    }
    return DateTime(y);
  }

  int? _parseOptionalPositive(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 0) {
      throw FormatException('number');
    }
    return n;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_saving) return;
    setState(() => _saving = true);
    final path = widget.song.path.trim();
    try {
      final titleRaw = _title.text.trim();
      final effectiveTitle =
          titleRaw.isEmpty ? p.basenameWithoutExtension(path) : titleRaw;

      Future<void> writeOnce() async {
        await writeEmbeddedTagsForPath(
          path: path,
          title: effectiveTitle,
          artist: _artist.text.trim().isEmpty ? null : _artist.text.trim(),
          album: _album.text.trim().isEmpty ? null : _album.text.trim(),
          year: _parseYear(_year.text),
          trackNumber: _parseOptionalPositive(_trackNumber.text),
          trackTotal: _parseOptionalPositive(_trackTotal.text),
          discNumber: _parseOptionalPositive(_discNumber.text),
          totalDisc: _parseOptionalPositive(_discTotal.text),
          lyrics: _lyrics.text.trim().isEmpty ? null : _lyrics.text,
        );
      }

      try {
        await writeOnce();
      } catch (e) {
        if (Platform.isAndroid && looksLikeAndroidStorageAccessDenied(e)) {
          final ok = await ensureAndroidManageExternalStorageAccess();
          if (ok) {
            await writeOnce();
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.songPageStorageManageAllFilesHint)),
            );
            return;
          }
        } else {
          rethrow;
        }
      }

      if (Platform.isAndroid) {
        await MusicTagEditorLauncher.scanAudioFileAfterExternalEdit(path);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      await widget.onSavedReload(path);

      if (!widget.navigatorContext.mounted) return;
      ScaffoldMessenger.of(widget.navigatorContext).showSnackBar(
        SnackBar(content: Text(l10n.songPageInlineTagsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _shortError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.songPageInlineTagsSaveFailed(msg))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _shortError(Object e) {
    final s = e.toString();
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scrollBottomPad = 16.0 + (bottomInset > 0 ? 8.0 : 0.0);
    return SafeArea(
      top: false,
      bottom: false,
      maintainBottomViewPadding: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.songPageInlineTagsEditorTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(l10n.songPageInlineTagsFieldTitle),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            TextField(
              controller: _artist,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(l10n.songPageInlineTagsFieldArtist),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            TextField(
              controller: _album,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(l10n.songPageInlineTagsFieldAlbum),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            TextField(
              controller: _year,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _dec(l10n.songPageInlineTagsFieldYear),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackNumber,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _dec(l10n.songPageInlineTagsFieldTrackNumber),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _trackTotal,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _dec(l10n.songPageInlineTagsFieldTrackTotal),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discNumber,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _dec(l10n.songPageInlineTagsFieldDiscNumber),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _discTotal,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _dec(l10n.songPageInlineTagsFieldDiscTotal),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            TextField(
              controller: _lyrics,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(l10n.songPageInlineTagsFieldLyrics),
              maxLines: 6,
              minLines: 3,
              enabled: !_saving,
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 96),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.songPageInlineTagsSave),
            ),
          ],
        ),
      ),
    );
  }
}
