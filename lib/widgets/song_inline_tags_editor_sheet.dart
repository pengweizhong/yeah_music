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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show Picture, PictureType;
import 'package:audio_metadata_reader/src/metadata/base.dart'
    show Mp3Metadata, Mp4Metadata, ParserTag, RiffMetadata, VorbisMetadata;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/music_tag_editor_launcher.dart';
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/song_embedded_metadata_writer.dart';
import 'package:yeah_music/utils/wav_riff_metadata_bridge.dart'
    show readAllMetadataForWrite;
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/widgets/image_pick_crop_flow.dart';

/// 底部表单：编辑内嵌标签（写入磁盘后再由调用方刷新内存/Hive）。
/// 会先弹出风险提示，确认后再打开表单。
Future<void> showSongInlineTagsEditorSheet({
  required BuildContext navigatorContext,
  required Song song,
  required Future<void> Function(String path) onSavedReload,
}) async {
  final l10n = AppLocalizations.of(navigatorContext);
  final proceed = await showAppConfirmDialog(
    context: navigatorContext,
    title: l10n.songPageInlineTagsUnstableTitle,
    message: l10n.songPageInlineTagsUnstableBody,
    cancelLabel: l10n.songPageInlineTagsUnstableCancel,
    confirmLabel: l10n.songPageInlineTagsUnstableContinue,
    barrierDismissible: false,
  );
  if (proceed != true) return;
  if (!navigatorContext.mounted) return;
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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: _SongInlineTagsEditorBody(
              song: song,
              navigatorContext: navigatorContext,
              onSavedReload: onSavedReload,
            ),
          ),
        ),
      );
    },
  );
}

Picture? _primaryEmbeddedPicture(ParserTag meta) {
  if (meta is Mp3Metadata) {
    for (final p in meta.pictures) {
      if (p.pictureType == PictureType.coverFront) return p;
    }
    return meta.pictures.isNotEmpty ? meta.pictures.first : null;
  }
  if (meta is Mp4Metadata) {
    return meta.picture;
  }
  if (meta is VorbisMetadata) {
    for (final p in meta.pictures) {
      if (p.pictureType == PictureType.coverFront) return p;
    }
    return meta.pictures.isNotEmpty ? meta.pictures.first : null;
  }
  if (meta is RiffMetadata) {
    for (final p in meta.pictures) {
      if (p.pictureType == PictureType.coverFront) return p;
    }
    return meta.pictures.isNotEmpty ? meta.pictures.first : null;
  }
  return null;
}

Picture? _primaryFromSongPictures(List<Picture>? pics) {
  if (pics == null || pics.isEmpty) return null;
  for (final p in pics) {
    if (p.pictureType == PictureType.coverFront) return p;
  }
  return pics.first;
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

  Uint8List? _diskCoverPreviewBytes;
  EmbeddedCoverEditKind _coverEdit = EmbeddedCoverEditKind.unchanged;
  Uint8List? _replacementCoverBytes;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadEmbeddedCoverPreview());
    });
  }

  Future<void> _loadEmbeddedCoverPreview() async {
    try {
      final meta = readAllMetadataForWrite(File(widget.song.path.trim()));
      final pic = _primaryEmbeddedPicture(meta);
      if (!mounted) return;
      setState(() {
        _diskCoverPreviewBytes =
            pic != null ? Uint8List.fromList(pic.bytes) : null;
      });
    } catch (_) {
      final fallback = _primaryFromSongPictures(widget.song.pictures);
      if (!mounted) return;
      setState(() {
        _diskCoverPreviewBytes =
            fallback != null ? Uint8List.fromList(fallback.bytes) : null;
      });
    }
  }

  Uint8List? _previewCoverBytes() {
    switch (_coverEdit) {
      case EmbeddedCoverEditKind.removed:
        return null;
      case EmbeddedCoverEditKind.replacedWithBytes:
        return _replacementCoverBytes;
      case EmbeddedCoverEditKind.unchanged:
        return _diskCoverPreviewBytes;
    }
  }

  Future<void> _pickCoverReplacement(AppLocalizations l10n) async {
    final cropped = await pickSquareEmbeddedCoverImage(
      context: context,
      l10n: l10n,
    );
    if (cropped == null || !mounted || cropped.isEmpty) return;
    final jpeg = cropped.length >= 2 &&
        cropped[0] == 0xff &&
        cropped[1] == 0xd8;
    final png = cropped.length >= 8 &&
        cropped[0] == 0x89 &&
        cropped[1] == 0x50 &&
        cropped[2] == 0x4e &&
        cropped[3] == 0x47;
    if (!jpeg && !png) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageInlineTagsCoverInvalid,
        kind: AppSnackKind.error,
      );
      return;
    }
    setState(() {
      _coverEdit = EmbeddedCoverEditKind.replacedWithBytes;
      _replacementCoverBytes = Uint8List.fromList(cropped);
    });
  }

  void _removeEmbeddedCover() {
    setState(() {
      _coverEdit = EmbeddedCoverEditKind.removed;
      _replacementCoverBytes = null;
    });
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

  InputDecoration _dec(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withValues(alpha: 0.45);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2),
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
          coverEdit: _coverEdit,
          replacementCoverBytes: _replacementCoverBytes,
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
            showAppSnackBar(
              context,
              l10n.songPageStorageManageAllFilesHint,
              kind: AppSnackKind.neutral,
              duration: const Duration(seconds: 4),
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
      showAppSnackBar(
        widget.navigatorContext,
        l10n.songPageInlineTagsSaved,
        kind: AppSnackKind.success,
      );
    } catch (e, st) {
      appLog.e(
        'inline tags save failed path=$path ext=${p.extension(path)}',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      final msg = _shortError(e);
      showAppSnackBar(
        context,
        l10n.songPageInlineTagsSaveFailed(msg),
        kind: AppSnackKind.error,
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
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final scrollBottomPad = 16.0 + (bottomInset > 0 ? 8.0 : 0.0);
    final preview = _previewCoverBytes();
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              style: TextStyle(color: onSurface),
              decoration: _dec(context, l10n.songPageInlineTagsFieldTitle),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            TextField(
              controller: _artist,
              style: TextStyle(color: onSurface),
              decoration: _dec(context, l10n.songPageInlineTagsFieldArtist),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            TextField(
              controller: _album,
              style: TextStyle(color: onSurface),
              decoration: _dec(context, l10n.songPageInlineTagsFieldAlbum),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.songPageInlineTagsCoverSection,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: preview != null && preview.isNotEmpty
                        ? Image.memory(
                            preview,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.album_rounded,
                              size: 40,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _pickCoverReplacement(l10n),
                        child: Text(l10n.songPageInlineTagsCoverReplace),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed:
                            _saving ? null : _removeEmbeddedCover,
                        child: Text(l10n.songPageInlineTagsCoverRemove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextField(
              controller: _year,
              style: TextStyle(color: onSurface),
              keyboardType: TextInputType.number,
              decoration: _dec(context, l10n.songPageInlineTagsFieldYear),
              textInputAction: TextInputAction.next,
              enabled: !_saving,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackNumber,
                    style: TextStyle(color: onSurface),
                    keyboardType: TextInputType.number,
                    decoration: _dec(
                      context,
                      l10n.songPageInlineTagsFieldTrackNumber,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _trackTotal,
                    style: TextStyle(color: onSurface),
                    keyboardType: TextInputType.number,
                    decoration: _dec(
                      context,
                      l10n.songPageInlineTagsFieldTrackTotal,
                    ),
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
                    style: TextStyle(color: onSurface),
                    keyboardType: TextInputType.number,
                    decoration: _dec(
                      context,
                      l10n.songPageInlineTagsFieldDiscNumber,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _discTotal,
                    style: TextStyle(color: onSurface),
                    keyboardType: TextInputType.number,
                    decoration: _dec(
                      context,
                      l10n.songPageInlineTagsFieldDiscTotal,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            TextField(
              controller: _lyrics,
              style: TextStyle(color: onSurface),
              decoration: _dec(context, l10n.songPageInlineTagsFieldLyrics),
              maxLines: 6,
              minLines: 3,
              enabled: !_saving,
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 96),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
              child: _saving
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Text(l10n.songPageInlineTagsSave),
            ),
          ],
        ),
      ),
    );
  }
}
