import 'package:characters/characters.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/lyric_entry.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/desktop_lyrics_payload_builder.dart';
import 'package:yeah_music/utils/lyrics_utils.dart';

/// 菜单栏、桌面悬浮等外部展示用的单行歌词（与 [LyricSettings] 翻译行开关一致）。
const int kExternalLyricLineMaxGraphemes = 512;

String sanitizeExternalLyricLine(String text) {
  final t = text.trim();
  if (t.isEmpty) return t;
  final ch = t.characters;
  if (ch.length <= kExternalLyricLineMaxGraphemes) return t;
  return '${ch.take(kExternalLyricLineMaxGraphemes)}…';
}

class ExternalLyricLineFormatter {
  ExternalLyricLineFormatter({required this.lyricStyle});

  LyricSettings lyricStyle;

  String? _parsedForPath;
  String? _parsedLyricsBlob;
  List<LyricEntry> _parsed = [];

  void invalidate() {
    _parsedForPath = null;
    _parsedLyricsBlob = null;
    _parsed = [];
  }

  String formatLine({
    required Song? song,
    required Duration position,
    required AppLocalizations? l10n,
  }) {
    final idle = l10n?.menuBarLyricsIdle ?? 'Yeah Music';
    final noLyrics = l10n?.menuBarLyricsNoLyrics ?? 'No lyrics';

    if (song == null) {
      return sanitizeExternalLyricLine(idle);
    }

    final raw = song.lyrics;
    if (raw == null || raw.trim().isEmpty) {
      return sanitizeExternalLyricLine(noLyrics);
    }

    final path = song.path;
    if (_parsedForPath != path || _parsedLyricsBlob != raw) {
      _parsedForPath = path;
      _parsedLyricsBlob = raw;
      _parsed = LyricsUtils.parseLyrics(raw);
    }

    if (_parsed.isEmpty) {
      return sanitizeExternalLyricLine(noLyrics);
    }

    final idx = LyricsUtils.findCurrentLyricIndex(_parsed, position);
    if (idx < 0 || idx >= _parsed.length) {
      return sanitizeExternalLyricLine('…');
    }

    lyricStyle.normalizeLayoutFields();
    final modeMap = lyricStyle.lyricDisplayMode;
    final globalMode = lyricStyle.resolvedGlobalLyricDisplayMode;
    final parts = DesktopLyricsPayloadBuilder.linesToShowForLyricLine(
      line: _parsed[idx],
      settings: lyricStyle,
      lineSpecificMode: modeMap[idx],
      globalDisplayMode: globalMode,
    );
    if (parts.isEmpty && _parsed[idx].lines.isNotEmpty) {
      parts.add(_parsed[idx].lines[0]);
    }

    final lyricLine = parts.join(' · ');
    if (lyricLine.isEmpty) {
      return sanitizeExternalLyricLine(noLyrics);
    }
    return sanitizeExternalLyricLine(lyricLine);
  }
}
