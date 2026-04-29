import 'dart:math';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';

String _formatMetaBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '${(n / (1024 * 1024)).toStringAsFixed(2)} MB';
}

Uint8List? _pickCoverBytes(AudioMetadata meta, Song song) {
  final pics = meta.pictures;
  Picture? front;
  for (final pic in pics) {
    if (pic.pictureType == PictureType.coverFront && pic.bytes.isNotEmpty) {
      front = pic;
      break;
    }
  }
  final fromMeta = front?.bytes ?? (pics.isNotEmpty ? pics.first.bytes : null);
  if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
  final hiveBytes = song.imageBytes;
  if (hiveBytes != null && hiveBytes.isNotEmpty) return hiveBytes;
  return null;
}

/// 展示嵌套标签中的音频文件元数据（含封面与尽可能多的可读字段）。
Future<void> showAudioMetadataDialog({
  required BuildContext context,
  required Song song,
  required AudioMetadata meta,
  required int sizeBytes,
}) async {
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SongMetadataDialogBody(
      l10n: l10n,
      song: song,
      meta: meta,
      sizeBytes: sizeBytes,
    ),
  );
}

class _SongMetadataDialogBody extends StatelessWidget {
  const _SongMetadataDialogBody({
    required this.l10n,
    required this.song,
    required this.meta,
    required this.sizeBytes,
  });

  final AppLocalizations l10n;
  final Song song;
  final AudioMetadata meta;
  final int sizeBytes;

  String _decode(String? s) => FileUtils.decodeString(s ?? '');

  String _dashIfEmpty(String s) => s.trim().isEmpty ? '—' : s;

  String _durStr() {
    final d = meta.duration;
    if (d == null) return '—';
    return LyricsUtils.formatDuration(d);
  }

  String _bitrateStr() {
    final b = meta.bitrate;
    if (b == null || b <= 0) return '—';
    return '${(b / 1000).round()} kbps';
  }

  String _hzStr() {
    final s = meta.sampleRate;
    if (s == null || s <= 0) return '—';
    return '$s Hz';
  }

  String _yearStr() {
    final y = meta.year;
    if (y == null) return '—';
    return '${y.year}';
  }

  String _trackStr() {
    final tn = meta.trackNumber;
    final tt = meta.trackTotal;
    if (tn == null && tt == null) return '—';
    if (tn != null && tt != null) return '$tn / $tt';
    return '${tn ?? tt}';
  }

  String _discStr() {
    final dn = meta.discNumber;
    final td = meta.totalDisc;
    if (dn == null && td == null) return '—';
    if (dn != null && td != null) return '$dn / $td';
    return '${dn ?? td}';
  }

  String _genreStr() {
    final g = meta.genres;
    if (g.isEmpty) return '—';
    final joined = g.map(FileUtils.decodeString).join(', ').trim();
    return joined.isEmpty ? '—' : joined;
  }

  String _performersStr() {
    if (meta.performers.isEmpty) return '—';
    return meta.performers.map(FileUtils.decodeString).join(', ');
  }

  String _formatExtension(String path) {
    final ext = p.extension(path);
    if (ext.isEmpty) return '—';
    return ext.replaceFirst('.', '').toUpperCase();
  }

  String _headerTitle() {
    final t = _decode(meta.title);
    if (t.trim().isNotEmpty) return t.trim();
    final st = song.title?.trim();
    if (st != null && st.isNotEmpty) return st;
    return p.basename(song.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final path = song.path.trim();
    final coverBytes = _pickCoverBytes(meta, song);
    final lyricsRaw = meta.lyrics?.trim();

    final Widget coverChild;
    if (coverBytes != null) {
      coverChild = Image.memory(
        coverBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _CoverPlaceholder(scheme: scheme),
      );
    } else {
      coverChild = _CoverPlaceholder(scheme: scheme);
    }

    Widget kv(String label, String value) {
      final display = value.trim().isEmpty ? '—' : value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: SelectableText(
                display,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionTitle(String text, {double topPad = 12}) {
      return Padding(
        padding: EdgeInsets.only(top: topPad, bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final artist = _dashIfEmpty(_decode(meta.artist));
    final album = _dashIfEmpty(_decode(meta.album));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: min(440.0, mq.size.width - 40),
        height: mq.size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.songPageMetadataDialogTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 132,
                      height: 132,
                      child: coverChild,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _headerTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (artist != '—')
                          Text(
                            artist,
                            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (album != '—') ...[
                          const SizedBox(height: 6),
                          Text(
                            album,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.95),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  sectionTitle(l10n.songPageMetaSectionTags, topPad: 0),
                  kv(l10n.songPageMetaFieldTitle, _decode(meta.title)),
                  kv(l10n.songPageMetaFieldArtist, _decode(meta.artist)),
                  kv(l10n.songPageMetaFieldAlbum, _decode(meta.album)),
                  kv(l10n.songPageMetaFieldPerformers, _performersStr()),
                  kv(l10n.songPageMetaFieldGenre, _genreStr()),
                  kv(l10n.songPageMetaFieldLanguage, _dashIfEmpty(_decode(meta.language))),
                  kv(l10n.songPageMetaFieldYear, _yearStr()),
                  kv(l10n.songPageMetaFieldTrack, _trackStr()),
                  kv(l10n.songPageMetaFieldDisc, _discStr()),
                  sectionTitle(l10n.songPageMetaSectionAudio),
                  kv(l10n.songPageMetaFieldDuration, _durStr()),
                  kv(l10n.songPageMetaFieldBitrate, _bitrateStr()),
                  kv(l10n.songPageMetaFieldSampleRate, _hzStr()),
                  if (lyricsRaw != null && lyricsRaw.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded: false,
                        title: Text(
                          l10n.songPageMetaFieldEmbeddedLyrics,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              lyricsRaw,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  sectionTitle(l10n.songPageMetaSectionFile),
                  kv(l10n.songPageMetaFieldFormat, _formatExtension(path)),
                  kv(l10n.songPageMetaFieldPath, path),
                  kv(
                    l10n.songPageMetaFieldSize,
                    sizeBytes > 0 ? _formatMetaBytes(sizeBytes) : '—',
                  ),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(l10n.actionOK),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 56,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
