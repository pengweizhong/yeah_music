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

  /// 与播放页 [LyricsUtils.findCurrentLyricIndex] 一致：仅在行索引变化时需刷新 UI / 通知。
  ExternalLyricLineAtPosition resolveAt({
    required Song? song,
    required Duration position,
    required AppLocalizations? l10n,
  }) {
    final idle = l10n?.menuBarLyricsIdle ?? 'Yeah Music';
    final noLyrics = l10n?.menuBarLyricsNoLyrics ?? 'No lyrics';

    if (song == null) {
      return ExternalLyricLineAtPosition(
        lyricIndex: -1,
        displayLine: sanitizeExternalLyricLine(idle),
        hasEmbeddedLyrics: false,
        publishKeySuffix: '',
      );
    }

    final raw = song.lyrics;
    if (raw == null || raw.trim().isEmpty) {
      return ExternalLyricLineAtPosition(
        lyricIndex: -1,
        displayLine: sanitizeExternalLyricLine(noLyrics),
        hasEmbeddedLyrics: false,
        publishKeySuffix: '',
      );
    }

    final path = song.path;
    if (_parsedForPath != path || _parsedLyricsBlob != raw) {
      _parsedForPath = path;
      _parsedLyricsBlob = raw;
      _parsed = LyricsUtils.parseLyrics(raw);
    }

    if (_parsed.isEmpty) {
      return ExternalLyricLineAtPosition(
        lyricIndex: -1,
        displayLine: sanitizeExternalLyricLine(noLyrics),
        hasEmbeddedLyrics: false,
        publishKeySuffix: '',
      );
    }

    final idx = LyricsUtils.findCurrentLyricIndex(_parsed, position);
    if (idx < 0 || idx >= _parsed.length) {
      return ExternalLyricLineAtPosition(
        lyricIndex: -1,
        displayLine: sanitizeExternalLyricLine('…'),
        hasEmbeddedLyrics: true,
        publishKeySuffix: 'gap',
      );
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
    final effectiveMode = modeMap[idx] ?? globalMode;
    final publishKeySuffix =
        '$effectiveMode|${lyricStyle.showOriginal}|${lyricStyle.showTranslations}';
    if (lyricLine.isEmpty) {
      return ExternalLyricLineAtPosition(
        lyricIndex: idx,
        displayLine: sanitizeExternalLyricLine(noLyrics),
        hasEmbeddedLyrics: true,
        publishKeySuffix: publishKeySuffix,
      );
    }
    return ExternalLyricLineAtPosition(
      lyricIndex: idx,
      displayLine: sanitizeExternalLyricLine(lyricLine),
      hasEmbeddedLyrics: true,
      publishKeySuffix: publishKeySuffix,
    );
  }

  String formatLine({
    required Song? song,
    required Duration position,
    required AppLocalizations? l10n,
  }) {
    return resolveAt(song: song, position: position, l10n: l10n).displayLine;
  }
}

/// [ExternalLyricLineFormatter.resolveAt] 的结果。
class ExternalLyricLineAtPosition {
  const ExternalLyricLineAtPosition({
    required this.lyricIndex,
    required this.displayLine,
    required this.hasEmbeddedLyrics,
    required this.publishKeySuffix,
  });

  /// 当前时间轴行；-1 表示两行之间或曲目前空白。
  final int lyricIndex;
  final String displayLine;
  final bool hasEmbeddedLyrics;

  /// 与 [DesktopLyricsPayloadBuilder.linesToShowForLyricLine] 一致，供通知去重 key 区分显示模式切换。
  final String publishKeySuffix;
}
