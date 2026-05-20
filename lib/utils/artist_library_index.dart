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

import 'dart:typed_data';

import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';

const String _kSep = '\x1e';

/// 用于索引、去重、匹配的艺人 token（小写、空白规整）。
String normalizeArtistToken(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(_kSep, ' ');
  return s.toLowerCase();
}

/// 将元数据里的 [artist] 拆成若干艺人名（合唱、feat. 等）。
List<String> parseArtistTokens(String raw) {
  if (raw.trim().isEmpty) return [];
  var s = raw.replaceAll('，', ',').replaceAll('、', ',').trim();
  final out = <String>[];
  for (final part in s.split(RegExp(r'[,;，、]'))) {
    final p = part.trim();
    if (p.isEmpty) continue;
    out.addAll(_splitCompoundArtist(p));
  }
  return out.where((e) => e.isNotEmpty).toList();
}

bool _hasCjk(String s) => RegExp(r'[\u4e00-\u9fff]').hasMatch(s);

/// 两段均为短纯西文字、且无中日韩时，视为乐队缩写（如 AC/DC），不按合唱拆 `/`。
bool _likelyBandSlashNotCollab(String a, String b) {
  if (_hasCjk(a) || _hasCjk(b)) return false;
  bool asciiChunk(String x) {
    final u = x.trim();
    if (u.isEmpty || u.length > 8) return false;
    return RegExp(r'^[A-Za-z.\-]+$').hasMatch(u);
  }

  return asciiChunk(a) && asciiChunk(b);
}

/// `徐良/小凌`、`徐良/Britneylee小暖` 等无空格斜杠合唱；保留 `AC/DC` 等为单 token。
List<String> _splitSlashCollabIfApplicable(String s) {
  final t = s.replaceAll('／', '/').trim();
  if (!t.contains('/')) return [s];
  final parts = t
      .split('/')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length < 2) return [s];
  if (parts.length == 2 && _likelyBandSlashNotCollab(parts[0], parts[1])) {
    return [s];
  }
  return parts;
}

List<String> _splitCompoundArtist(String segment) {
  var pieces = <String>[segment.trim()];
  if (pieces.isEmpty || pieces.first.isEmpty) return [];

  final spacePatterns = <RegExp>[
    RegExp(r'\s*[·・]\s*'),
    RegExp(r'\s+(?:feat\.?|featuring|ft\.?)\s+', caseSensitive: false),
    RegExp(r'\s+&\s+'),
    RegExp(r'\s+/\s+'),
    RegExp(r'\s+and\s+', caseSensitive: false),
    RegExp(r'\s+x\s+', caseSensitive: false),
    RegExp(r'\s+vs\.?\s+', caseSensitive: false),
    RegExp(r'\s+和\s+'),
    RegExp(r'\s+与\s+'),
  ];
  for (final re in spacePatterns) {
    pieces = pieces
        .expand((c) => c.split(re).map((x) => x.trim()))
        .where((x) => x.isNotEmpty)
        .toList();
  }

  // 无空格 &：`徐良&小凌`、`汪苏泷&徐良`
  pieces = pieces
      .expand((c) => c.split('&').map((x) => x.trim()))
      .where((x) => x.isNotEmpty)
      .toList();

  // 无空格 /：含中日韩或较长片段时拆合唱；短双拉丁保留（AC/DC）
  pieces = pieces.expand(_splitSlashCollabIfApplicable).toList();

  return pieces;
}

String _canonicalCollabKey(Set<String> norms) {
  final sorted = norms.toList()..sort();
  return sorted.join(_kSep);
}

/// 未知艺人列表在路由里使用的 entryKey（与空串原始艺人一致）。
const String kArtistUnknownEntryKey = '';

String soloArtistEntryKey(String norm) => '__s__$_kSep$norm';

String collabArtistEntryKey(String canonicalNormsJoined) =>
    '__c__$_kSep$canonicalNormsJoined';

bool isSoloArtistEntryKey(String entryKey) =>
    entryKey.startsWith('__s__$_kSep');

bool isCollabArtistEntryKey(String entryKey) =>
    entryKey.startsWith('__c__$_kSep');

bool isUnknownArtistEntryKey(String entryKey) =>
    entryKey == kArtistUnknownEntryKey;

/// [Song.artist] 与各 [Song.performers] 条目中解析出的所有艺人 token（用于索引与「某歌手下列曲」匹配）。
List<String> allArtistTokensForSong(Song song) {
  final out = <String>[];
  final a = song.artist?.trim();
  if (a != null && a.isNotEmpty) {
    out.addAll(parseArtistTokens(a));
  }
  for (final perf in song.performers) {
    out.addAll(parseArtistTokens(perf.trim()));
  }
  return out;
}

Uint8List? _nonEmptyCoverBytes(Song song) {
  final b = song.imageBytes;
  if (b == null || b.isEmpty) return null;
  return b;
}

/// 艺术家浏览页一行：合唱组合单独一行；每位单人也一行，且包含其参与的所有合唱曲目。
class ArtistIndexRow {
  const ArtistIndexRow({
    required this.entryKey,
    required this.title,
    required this.count,
    this.coverBytes,
  });

  final String entryKey;
  final String title;
  final int count;
  /// 该艺人/组合下任意一首带内嵌封面的曲目（先遇到的优先）。
  final Uint8List? coverBytes;
}

/// 拆分 [Song.artist]、构建合唱与单人行的工具。
abstract final class ArtistLibraryIndex {
  static List<ArtistIndexRow> buildRows(List<Song> songs, AppLocalizations l10n) {
    final soloPaths = <String, Set<String>>{};
    final collabPaths = <String, Set<String>>{};
    final normDisplay = <String, String>{};
    final collabTitle = <String, String>{};
    final unknownPaths = <String>{};
    final soloCover = <String, Uint8List>{};
    final collabCover = <String, Uint8List>{};
    Uint8List? unknownCover;

    void noteDisplay(String norm, String displayToken) {
      normDisplay.putIfAbsent(norm, () => displayToken.trim());
    }

    for (final song in songs) {
      final path = song.path;
      final tokens = allArtistTokensForSong(song);
      if (tokens.isEmpty) {
        unknownPaths.add(path);
        final bytes = _nonEmptyCoverBytes(song);
        if (bytes != null && unknownCover == null) unknownCover = bytes;
        continue;
      }
      final norms = <String>{};
      for (final t in tokens) {
        final n = normalizeArtistToken(t);
        if (n.isEmpty) continue;
        norms.add(n);
        noteDisplay(n, t);
        soloPaths.putIfAbsent(n, () => {}).add(path);
        final bytes = _nonEmptyCoverBytes(song);
        if (bytes != null) {
          soloCover.putIfAbsent(n, () => bytes);
        }
      }
      if (norms.length >= 2) {
        final canon = _canonicalCollabKey(norms);
        collabPaths.putIfAbsent(canon, () => {}).add(path);
        collabTitle.putIfAbsent(canon, () {
          final order = norms.toList()..sort();
          return order.map((n) => normDisplay[n] ?? n).join(' · ');
        });
        final bytes = _nonEmptyCoverBytes(song);
        if (bytes != null) {
          collabCover.putIfAbsent(canon, () => bytes);
        }
      }
    }

    final out = <ArtistIndexRow>[];

    if (unknownPaths.isNotEmpty) {
      out.add(
        ArtistIndexRow(
          entryKey: kArtistUnknownEntryKey,
          title: l10n.artistsUnknownArtist,
          count: unknownPaths.length,
          coverBytes: unknownCover,
        ),
      );
    }

    final soloKeys = soloPaths.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final norm in soloKeys) {
      final c = soloPaths[norm]!.length;
      final title = normDisplay[norm] ?? norm;
      out.add(
        ArtistIndexRow(
          entryKey: soloArtistEntryKey(norm),
          title: title,
          count: c,
          coverBytes: soloCover[norm],
        ),
      );
    }

    final collabKeys = collabPaths.keys.toList()
      ..sort((a, b) {
        final ta = collabTitle[a] ?? a;
        final tb = collabTitle[b] ?? b;
        return ta.toLowerCase().compareTo(tb.toLowerCase());
      });
    for (final canon in collabKeys) {
      out.add(
        ArtistIndexRow(
          entryKey: collabArtistEntryKey(canon),
          title: collabTitle[canon] ?? canon.split(_kSep).join(' · '),
          count: collabPaths[canon]!.length,
          coverBytes: collabCover[canon],
        ),
      );
    }

    out.sort((a, b) {
      final ua = isUnknownArtistEntryKey(a.entryKey);
      final ub = isUnknownArtistEntryKey(b.entryKey);
      if (ua && !ub) return 1;
      if (!ua && ub) return -1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return out;
  }

  /// 某 entry 下列出的曲目（路径去重保持曲库顺序：按 [merged] 顺序筛选）。
  static List<Song> songsForEntry(
    String entryKey,
    List<Song> merged,
  ) {
    if (isUnknownArtistEntryKey(entryKey)) {
      return merged.where(_songIsUnknownArtist).toList();
    }
    if (isSoloArtistEntryKey(entryKey)) {
      final norm = entryKey.substring('__s__$_kSep'.length);
      return merged.where((s) => _songMatchesSoloNorm(s, norm)).toList();
    }
    if (isCollabArtistEntryKey(entryKey)) {
      final canon = entryKey.substring('__c__$_kSep'.length);
      final want = canon.split(_kSep).where((e) => e.isNotEmpty).toSet();
      return merged.where((s) => _songMatchesCollabCanon(s, want)).toList();
    }
    return [];
  }

  static bool _songIsUnknownArtist(Song s) {
    return allArtistTokensForSong(s).isEmpty;
  }

  static bool _songMatchesSoloNorm(Song s, String norm) {
    for (final t in allArtistTokensForSong(s)) {
      if (normalizeArtistToken(t) == norm) return true;
    }
    return false;
  }

  static bool _songMatchesCollabCanon(Song s, Set<String> wantNorms) {
    if (wantNorms.length < 2) return false;
    final got = <String>{};
    for (final t in allArtistTokensForSong(s)) {
      final n = normalizeArtistToken(t);
      if (n.isNotEmpty) got.add(n);
    }
    if (got.length < 2) return false;
    if (got.length != wantNorms.length) return false;
    for (final w in wantNorms) {
      if (!got.contains(w)) return false;
    }
    return true;
  }
}
