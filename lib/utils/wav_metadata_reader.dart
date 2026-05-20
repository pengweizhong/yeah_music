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

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:charset/charset.dart';
import 'package:path/path.dart' as p;

bool pathLooksLikeWav(String filepath) =>
    p.extension(filepath.toLowerCase()) == '.wav';

/// WAV：RIFF chunk 整块与偶对齐；
/// LIST/INFO 文本：UTF‑8（严格）→ GBK → Latin‑1；
/// 歌词：**LIST** 中带歌词语义的 INFO 子块、**末尾 ID3v1** 注释、[USLT] 嵌入式 **ID3v2**。
AudioMetadata readWavMetadataYep(File file, {bool getImage = false}) {
  final raf = file.openSync(mode: FileMode.read);
  try {
    final len = raf.lengthSync();
    if (len < 36) throw const FormatException('wav too short');

    raf.setPositionSync(0);
    final hdr = raf.readSync(12);
    if (hdr.length < 12) throw const FormatException('wav truncated');
    if (String.fromCharCodes(hdr.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(hdr.sublist(8, 12)) != 'WAVE') {
      throw const FormatException('not RIFF/WAVE');
    }

    String? title;
    String? artist;
    String? album;
    DateTime? year;
    int? trackNumber;
    int? trackTotal;
    final lyricChunks = <String>[];
    String? genre;

    var sampleRate = 0;
    var byteRate = 0;
    var dataChunkSizeSum = 0;

    final pictures = <Picture>[];

    void considerTitle(String v) {
      final s = v.trim();
      if (s.isEmpty) return;
      title ??= s;
    }

    void considerArtist(String v) {
      final s = v.trim();
      if (s.isEmpty) return;
      artist ??= s;
    }

    void considerAlbum(String v) {
      final s = v.trim();
      if (s.isEmpty) return;
      album ??= s;
    }

    void considerGenre(String v) {
      final s = v.trim();
      if (s.isEmpty) return;
      genre ??= s;
    }

    void addLyrics(String s) {
      final t = s.trim();
      if (t.isEmpty) return;
      if (!lyricChunks.contains(t)) lyricChunks.add(t);
    }

    const lyricInfoTags = <String>{
      'ICMT', 'IMED', 'IYLT', 'ILYC', 'ILRC', 'IWRI', 'ILYR', 'IYRC', 'IBUS',
    };

    void parseInfoInner(Uint8List infoInner) {
      var off = 0;
      while (off + 8 <= infoInner.length) {
        final tag = ascii.decode(infoInner.sublist(off, off + 4));
        off += 4;
        final subSize =
            ByteData.sublistView(infoInner, off).getUint32(0, Endian.little);
        off += 4;
        final end = off + subSize;
        if (end > infoInner.length) break;

        final raw =
            subSize > 0 ? Uint8List.sublistView(infoInner, off, end) : Uint8List(0);

        off += subSize;
        final text = _decodeEmbeddedInfoBytes(raw);

        switch (tag) {
          case 'INAM':
            considerTitle(text);
          case 'IART':
            considerArtist(text);
          case 'IPRD':
          case 'IPRO':
          case 'IALB':
            considerAlbum(text);
          case 'IGNR':
            considerGenre(text);
          case _ when lyricInfoTags.contains(tag):
            addLyrics(text);
          case 'DISP':
            if (getImage) {
              final pic = _tryPictureFromDispOrRaw(raw);
              if (pic != null) pictures.add(pic);
            }
          case 'ITRK':
            if (text.contains('/')) {
              final pts = text.split('/');
              trackNumber ??= int.tryParse(pts[0].trim());
              if (pts.length >= 2) {
                trackTotal ??= int.tryParse(pts[1].trim());
              }
            } else {
              trackNumber ??= int.tryParse(text.trim());
            }
          case 'ICRD':
            year ??= _parseYearFlexible(text.trim());
          default:
            final cap = getImage &&
                raw.isNotEmpty &&
                pictures.length < 4 &&
                raw.length <= 8192 * 1024 &&
                raw.length > 96;
            if (!cap) break;
            final pic = _trySniffImage(raw);
            if (pic != null) pictures.add(pic);
        }

        if (subSize.isOdd && off < infoInner.length) {
          off += 1;
        }
      }
    }

    void applyBext(Uint8List body) {
      if (body.length < 336) return;
      considerTitle(_decodeAsciiFixedLatin1OrRecover(body.sublist(0, 256)));
      considerArtist(_decodeAsciiFixedLatin1OrRecover(body.sublist(256, 288)));
    }

    var chunkStart = 12;

    while (chunkStart + 8 <= len) {
      raf.setPositionSync(chunkStart);
      final head = raf.readSync(8);
      if (head.length < 8) break;

      final chunkId = ascii.decode(head.sublist(0, 4));
      final chunkSize =
          ByteData.sublistView(head.sublist(4)).getUint32(0, Endian.little);

      final bodyStart = chunkStart + 8;
      final readable = len - bodyStart;
      final need = readable < 0 ? 0 : readable;
      final toRead = chunkSize.clamp(0, need).toInt();

      Uint8List body = Uint8List(0);
      if (toRead > 0) {
        raf.setPositionSync(bodyStart);
        body = raf.readSync(toRead);
      }

      switch (chunkId) {
        case 'fmt ':
          if (body.length >= 12) {
            final fmtBd = ByteData.sublistView(body);
            sampleRate = fmtBd.getUint32(4, Endian.little);
            byteRate = fmtBd.getUint32(8, Endian.little);
          }
        case 'LIST':
          if (body.length >= 4) {
            final form = ascii.decode(body.sublist(0, 4));
            if (form == 'INFO') parseInfoInner(body.sublist(4));
          }
        case 'data':
          dataChunkSizeSum += chunkSize;
        case 'bext':
          applyBext(body);
        default:
          extractUsLtFromId3Haystack(body, lyricChunks);
      }

      final next = chunkStart + 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (next <= chunkStart || next > len) break;
      chunkStart = next;
    }

    _pullTailHaystackEmbeddedId3(
      raf,
      fileLen: len,
      lyricChunks: lyricChunks,
    );

    if (len >= 128) {
      raf.setPositionSync(len - 128);
      final tail128 = raf.readSync(128);
      mergeId3v1TailAscii(
        tail128,
        considerTitle: considerTitle,
        considerArtist: considerArtist,
        considerAlbum: considerAlbum,
        considerGenre: considerGenre,
        lyricChunks: lyricChunks,
        trackSetter: (n) => trackNumber ??= n,
        yearSetter: (y) => year ??= y,
      );
    }

    final mergedLyric =
        lyricChunks.isEmpty ? null : lyricChunks.join('\n');

    Duration? dur;
    if (byteRate > 0 && dataChunkSizeSum > 0) {
      dur = Duration(
        microseconds:
            ((dataChunkSizeSum / byteRate) * 1000000).round(),
      );
    }

    final out = AudioMetadata(
      file: file,
      album: album,
      artist: artist,
      bitrate: byteRate > 0 ? byteRate : null,
      duration: dur,
      language: null,
      lyrics: mergedLyric,
      sampleRate: sampleRate > 0 ? sampleRate : null,
      title: title,
      totalDisc: null,
      trackNumber: trackNumber,
      trackTotal: trackTotal,
      year: year,
      discNumber: null,
    );

    out.genres.clear();
    if (genre != null && genre!.trim().isNotEmpty) {
      out.genres.add(genre!.trim());
    }
    out.pictures.clear();
    out.pictures.addAll(pictures);
    return out;
  } finally {
    try {
      raf.closeSync();
    } catch (_) {}
  }
}

/// 给同一批字节多套解码打分，偏重「可读」与东亚文字，压低明显乱码（孤 surrogate、replacement、mojibake 特征）。
int _embeddingTextScore(String s) {
  if (s.isEmpty) return -100000;
  var score = math.min(s.length * 5, 500);
  for (final u in s.runes) {
    if (u == 0xFFFD) return -100000;
    if (u >= 0xd800 && u <= 0xdfff) score -= 400;
    if (u >= 0x80 && u < 0xa0) score -= 2;
    if (u >= 0x3400 && u <= 0x9fff) score += 14;
    if (u >= 0xf900 && u <= 0xfaff) score += 10;
    if (u >= 0x3040 && u <= 0x31ff || u >= 0x1100 && u <= 0x11ff || u >= 0x3140 && u <= 0x318f) score += 6;
    if (u >= 0x400 && u <= 0x052f) score += 3;
    if ((u >= 0x0020 && u <= 0x007e)) score += 1;
  }

  final mojib =
      RegExp(r'Ã.|Â.|â€œ|â€|ï»¿|Å.|Ž|¤').allMatches(s).length;
  score -= math.min(mojib * 10, 60);

  final badCtrl = s.runes
      .where((u) {
        if (u >= 0x20) return false;
        return u != 0x09 && u != 0x0a && u != 0x0d && u != 0x0c && u != 0x0b;
      })
      .length;
  if (badCtrl > 3) score -= math.min(badCtrl * 3, 50);

  return score;
}

/// 「UTF‑8 字节被当成 GB18030 解」时出现的高频字面（锟斤拷体系），字面仍是汉字会骗过正向分。
int _kunStyleMojibakePenalty(String s) {
  if (s.isEmpty) return 0;
  var penalty = 0;
  final runeLen = s.runes.length;
  final safeLen = math.max(runeLen, 1);

  final kunHits = RegExp('锟').allMatches(s).length;
  if (kunHits > 0) {
    penalty += kunHits * 48;
    if (kunHits / safeLen >= 0.10) penalty += 520;
  }

  const hallmark = <String>[
    '锟斤拷',
    '锟铰拷',
    '锟铰讹拷',
    '锟侥碉',
    '锟叫匡',
    '锟铰…',
    '锟铰伙',
  ];
  for (final fragment in hallmark) {
    if (s.contains(fragment)) penalty += 650;
  }

  if (RegExp(r'锟[斤拷铰叫伙绢酮鲛鹁鹊]').hasMatch(s)) penalty += 220;

  if (kunHits >= 1 && RegExp(r'[鲛讹铰]').hasMatch(s)) penalty += 180;

  if (RegExp(r'€|â€™|Ã—').hasMatch(s)) penalty += 40;

  return penalty;
}

/// 「把 UTF‑8/GBK 误当 UTF‑16 解码」易产生箭头、运算符、 vulgar 分数（½）、上下标与杂项符号；这些在歌名里也极少成串出现。
int _junkSymbolGarbagePenalty(String s) {
  if (s.isEmpty) return 0;
  final runes = s.runes.toList();
  final n = runes.length;
  if (n == 0) return 0;

  var funky = 0;
  for (final u in runes) {
    if (_runeLooksLikeSymbolicSalad(u)) funky++;
  }
  final ratio = funky / n;
  var p = funky * 18;
  if (ratio >= 0.06) {
    p += (ratio * 900).round();
  }
  if (RegExp(r'[½¼¾⅓⅔⅛⅜⅝]').hasMatch(s)) p += 120;
  if (RegExp(r'[¿¡]').hasMatch(s)) p += 35;
  return p;
}

bool _runeLooksLikeSymbolicSalad(int u) {
  // Arrows / operators / dingbats / blocks that dominate mis-decoded UTF‑16 blobs.
  if (u >= 0x2190 && u <= 0x245f) return true;
  if (u >= 0x24b6 && u <= 0x24e9) return true;
  if (u >= 0x2500 && u <= 0x27bf) return true;
  if (u >= 0x2900 && u <= 0x297f) return true;
  if (u >= 0xa700 && u <= 0xa71f) return true;
  if (u >= 0xfff0 && u <= 0xffff) return true;
  if ((u >= 0x2070 && u <= 0x209f) || (u >= 0x2150 && u <= 0x218f)) return true;
  if (u >= 0x2000 &&
      u <= 0x206f &&
      u != 0x2002 &&
      u != 0x2003 &&
      u != 0x200b &&
      u != 0x2010 &&
      u != 0x2013 &&
      u != 0x2014 &&
      u != 0x2018 &&
      u != 0x2019 &&
      u != 0x201c &&
      u != 0x201d) {
    return true;
  }
  return false;
}

/// U+FFFD 的 UTF‑8 (`EF BF BD`) 被当作 Latin‑1 显示成的三连字；以及 UTF‑8 多字节拆开后的 `Â/Ã…`。
int _latin1Utf8MojibakePenalty(String s) {
  if (s.isEmpty) return 0;
  var p = RegExp('\u00ef\u00bf\u00bd').allMatches(s).length * 220;
  p += ('Â'.allMatches(s).length + 'Ã'.allMatches(s).length) * 26;
  if (RegExp(r'Ä[A-Za-z]').hasMatch(s)) p += 45;
  if (RegExp(r'Å[^\s]').hasMatch(s)) p += 35;
  return p;
}

bool _looksLikeUtf8BytesShownAsLatin1(String s) {
  if (RegExp('\u00ef\u00bf\u00bd').hasMatch(s)) return true;
  final n = ('Â'.allMatches(s).length + 'Ã'.allMatches(s).length);
  if (n >= 2) return true;
  return n >= 1 && s.length >= 6 && RegExp(r'Â.|Ã.').hasMatch(s);
}

/// 若已为「Latin‑1 误读 UTF‑8」形态，则用 `latin1.encode`→`UTF‑8/GBK` 拉回正文（供 WAV 与各格式展示层共用）。
String normalizeLatin1MisreadUtf8(String s) {
  var cur = s.trim();
  if (cur.isEmpty) return '';

  for (var depth = 0; depth < 4; depth++) {
    if (!_looksLikeUtf8BytesShownAsLatin1(cur)) return cur;
    List<int> bytes;
    try {
      bytes = latin1.encode(cur);
    } catch (_) {
      return cur;
    }

    final variants = <String>[];
    try {
      variants.add(utf8.decode(bytes, allowMalformed: false).trim());
    } catch (_) {}
    try {
      variants.add(gbk.decode(bytes).trim());
    } catch (_) {}

    final baseFit = _labelDecodedFitness(cur);
    String? bestPick;
    var bestFit = baseFit;

    for (final v in variants) {
      if (v.isEmpty ||
          looksLikeGbkOfUtf8Garbage(v) ||
          _replacementInMetadata(v)) {
        continue;
      }
      final f = _labelDecodedFitness(v);
      if (f > bestFit) {
        bestFit = f;
        bestPick = v;
      }
    }

    if (bestPick == null || bestPick == cur) return cur;
    if (!_looksLikeUtf8BytesShownAsLatin1(bestPick)) {
      cur = bestPick;
      return cur;
    }
    if (bestFit > baseFit + 20) {
      cur = bestPick;
      continue;
    }
    return cur;
  }
  return cur;
}

/// Windows 常见于 INFO 的无 BOM：`T\x00i\x00t\x00…`（仅用这种强特征，避免 UTF‑8/GBK 误当 UTF‑16）。
bool _looksLikeUtf16LeAsciiDominant(Uint8List b) {
  if (b.length < 10 || !b.length.isEven) return false;
  final pairs = b.length ~/ 2;
  var asciiLe = 0;
  for (var i = 0; i + 1 < b.length; i += 2) {
    final lo = b[i];
    final hi = b[i + 1];
    if (hi == 0 && lo >= 0x20 && lo <= 0x7e) asciiLe++;
  }
  return asciiLe * 100 >= pairs * 52;
}

bool _looksLikeUtf16BeAsciiDominant(Uint8List b) {
  if (b.length < 10 || !b.length.isEven) return false;
  final pairs = b.length ~/ 2;
  var asciiBe = 0;
  for (var i = 0; i + 1 < b.length; i += 2) {
    final hi = b[i];
    final lo = b[i + 1];
    if (lo == 0 && hi >= 0x20 && hi <= 0x7e) asciiBe++;
  }
  return asciiBe * 100 >= pairs * 52;
}

/// LIST/INFO 文本里常夹 `0x00` 填充，留在流里会导致严格 UTF‑8 失败，进而误选 GBK 出现「锟铰讹拷」。
Uint8List _bytesWithoutNul(Uint8List raw) {
  var n = 0;
  for (var i = 0; i < raw.length; i++) {
    if (raw[i] != 0) n++;
  }
  if (n == raw.length) return raw;
  final out = Uint8List(n);
  var w = 0;
  for (var i = 0; i < raw.length; i++) {
    if (raw[i] != 0) out[w++] = raw[i];
  }
  return out;
}

/// LIST/INFO 里常见「在多字节 UTF‑8 末尾被截断」；去掉尾部 1～3 个残缺字节后往往可严格解码。
String? _tryDecodeUtf8DroppingIncompleteTail(Uint8List b) {
  final maxDrop = math.min(3, b.length - 1);
  if (maxDrop < 1) return null;
  for (var drop = 1; drop <= maxDrop; drop++) {
    final end = b.length - drop;
    if (end <= 0) continue;
    try {
      final s =
          utf8.decode(Uint8List.sublistView(b, 0, end), allowMalformed: false)
              .trim();
      if (s.isNotEmpty) return s;
    } catch (_) {}
  }
  return null;
}

bool _replacementInMetadata(String s) =>
    s.runes.any((u) => u == 0xfffd);

/// 典型「UTF‑8 字节流被按 GBK 解读」；应用从候选中剔除，避免压过正确 UTF‑8。
bool _isLikelyUtf8StreamMisreadAsGbk(String s) {
  if (!s.contains('锟')) return false;
  if (RegExp(r'锟[铰斤拷侥叫伙绢酮鲛鹁鹊碉讹]').hasMatch(s)) return true;
  if (RegExp(r'锟铰').hasMatch(s) || RegExp(r'锟侥').hasMatch(s)) return true;
  if (RegExp(r'拷拷|碉拷|讹拷').hasMatch(s)) return true;
  final kun = '锟'.allMatches(s).length;
  return kun >= 2 && RegExp(r'[拷讹铰碉侥斤]').hasMatch(s);
}

int _labelDecodedFitness(String s) =>
    _embeddingTextScore(s) -
        _kunStyleMojibakePenalty(s) -
        _junkSymbolGarbagePenalty(s) -
        _latin1Utf8MojibakePenalty(s);

void _collectLabelCandidate(Set<String> out, String? s) {
  if (s == null || s.isEmpty) return;
  final t = s.replaceAll('\x00', '').trim();
  if (t.isEmpty) return;
  out.add(t);
}

/// RIFF LIST/INFO：`UTF‑16(BOM)`、无 BOM UTF‑16 候选、`UTF‑8`、`GBK`、UTF‑8‑as‑Latin1 拉回，择优。
String _decodeEmbeddedInfoBytes(Uint8List raw) {
  final trimmed = _trimTrailingZeros(raw);
  if (trimmed.isEmpty) return '';

  if (trimmed.length >= 4 &&
      trimmed[0] == 0xff &&
      trimmed[1] == 0xfe) {
    return _decodeUtf16Le(trimmed, start: 2);
  }
  if (trimmed.length >= 4 &&
      trimmed[0] == 0xfe &&
      trimmed[1] == 0xff) {
    return _decodeUtf16Be(trimmed, start: 2);
  }

  final noNul = _bytesWithoutNul(trimmed);
  if (noNul.isNotEmpty) {
    try {
      final u = utf8.decode(noNul, allowMalformed: false).trim();
      if (u.isNotEmpty) {
        return normalizeLatin1MisreadUtf8(u);
      }
    } catch (_) {}
    final cut = _tryDecodeUtf8DroppingIncompleteTail(noNul);
    if (cut != null && cut.isNotEmpty) {
      return normalizeLatin1MisreadUtf8(cut);
    }
  }

  final uniq = <String>{};

  if (trimmed.length >= 4 &&
      trimmed.length.isEven &&
      _looksLikeUtf16LeAsciiDominant(trimmed)) {
    _collectLabelCandidate(uniq, _decodeUtf16Le(trimmed));
  }
  if (trimmed.length >= 4 &&
      trimmed.length.isEven &&
      _looksLikeUtf16BeAsciiDominant(trimmed)) {
    _collectLabelCandidate(uniq, _decodeUtf16Be(trimmed));
  }

  if (noNul.isNotEmpty) {
    try {
      _collectLabelCandidate(uniq, gbk.decode(noNul.toList()));
    } catch (_) {}
    try {
      _collectLabelCandidate(
        uniq,
        gbkRecoverFromMisreadLatinStrings(noNul.toList()),
      );
    } catch (_) {}
  }

  try {
    _collectLabelCandidate(uniq, latin1.decode(trimmed, allowInvalid: false));
  } catch (_) {}
  _collectLabelCandidate(
    uniq,
    latin1.decode(trimmed, allowInvalid: true),
  );

  if (uniq.isEmpty) return '';

  final uniqList = uniq.toList();
  final eligible = uniqList
      .where(
        (c) =>
            !_isLikelyUtf8StreamMisreadAsGbk(c) &&
            !_replacementInMetadata(c),
      )
      .toList();
  final pool = eligible.isNotEmpty ? eligible : uniqList;

  String? best;
  var bestScore = -100001;
  for (final c in pool) {
    var fitness = _labelDecodedFitness(c);
    if (fitness > bestScore ||
        (fitness == bestScore && c.length > (best?.length ?? 0))) {
      bestScore = fitness;
      best = c;
    }
  }

  return normalizeLatin1MisreadUtf8(best ?? '');
}

/// 是否像「UTF‑8 流被按 GBK 解」的展示（与 WAV 元数据内部判断一致）。
bool looksLikeGbkOfUtf8Garbage(String s) =>
    _isLikelyUtf8StreamMisreadAsGbk(s);

bool containsUnicodeReplacementChar(String s) => _replacementInMetadata(s);

bool _looksLikeBrokenShortSymbolicLabel(String s) {
  final runes = s.runes.toList();
  if (runes.isEmpty || runes.length > 24) return false;
  var cjk = 0;
  var asciiLetters = 0;
  var junk = 0;
  for (final u in runes) {
    if (u >= 0x4e00 && u <= 0x9fff) cjk++;
    if (u >= 0x3040 && u <= 0x30ff ||
        u >= 0x31f0 && u <= 0x31ff ||
        u >= 0xac00 && u <= 0xd7af) {
      cjk++;
      continue;
    }
    if ((u >= 0x61 && u <= 0x7a) || (u >= 0x41 && u <= 0x5a)) asciiLetters++;
    if (u == 0xb6 || u == 0xfffd || u == 0xbf || u == 0xa1) junk++;
    if (_runeLooksLikeSymbolicSalad(u)) junk++;
  }
  if (cjk > 0) return false;
  if (asciiLetters >= 3) return false;
  if (junk >= 2) return true;
  if (junk >= 1 && runes.length <= 6) return true;
  return false;
}

/// 嵌入式标题/专辑等解码结果仍明显不可信时，应由 [FileUtils.loadSongMeta] 改用文件名或置空字段。
bool embeddedDisplayTextLooksCorrupt(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (_replacementInMetadata(t)) return true;
  if (_isLikelyUtf8StreamMisreadAsGbk(t)) return true;
  if (_looksLikeUtf8BytesShownAsLatin1(t)) return true;
  if (_looksLikeBrokenShortSymbolicLabel(t)) return true;
  return false;
}

/// 供 [FileUtils.decodeString] 择优：可读分减去「锟斤拷」系误判惩罚。
int tagEmbeddingTextScoreForUi(String s) => _labelDecodedFitness(s);

/// 同上：从 Latin‑1 可逆字节里拉 UTF‑8 / GBK（与 WAV 解码一致）。
String recoverLabelFromLatin1Misread(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return '';
  try {
    return gbkRecoverFromMisreadLatinStrings(bytes);
  } catch (_) {
    return '';
  }
}

Uint8List _trimTrailingZeros(Uint8List raw) {
  var end = raw.length;
  while (end > 0 && raw[end - 1] == 0) {
    end--;
  }
  return end <= 0
      ? Uint8List(0)
      : Uint8List.sublistView(raw, 0, end);
}

String _decodeUtf16Le(Uint8List src, {int start = 0}) {
  final codes = <int>[];
  var i = start;
  while (i + 1 < src.length) {
    codes.add(src[i] | (src[i + 1] << 8));
    i += 2;
  }
  final end = codes.indexWhere((c) => c == 0);
  final seq = end < 0 ? codes : codes.sublist(0, end);
  return String.fromCharCodes(seq.where((u) => u != 0)).trim();
}

String _decodeUtf16Be(Uint8List src, {int start = 0}) {
  final codes = <int>[];
  var i = start;
  while (i + 1 < src.length) {
    codes.add((src[i] << 8) | src[i + 1]);
    i += 2;
  }
  final end = codes.indexWhere((c) => c == 0);
  final seq = end < 0 ? codes : codes.sublist(0, end);
  return String.fromCharCodes(seq.where((u) => u != 0)).trim();
}

String _decodeAsciiFixedLatin1OrRecover(Uint8List raw) {
  if (raw.isEmpty) return '';
  final ix = raw.indexWhere((b) => b == 0);
  final slice =
      ix <= 0 ? ix < 0 ? raw : Uint8List(0) : Uint8List.sublistView(raw, 0, ix);

  try {
    return utf8.decode(slice, allowMalformed: false).trim();
  } catch (_) {}
  try {
    return gbk.decode(slice.toList()).trim();
  } catch (_) {}
  return latin1.decode(slice, allowInvalid: true).trim();
}

DateTime? _parseYearFlexible(String s) {
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  if (d != null && d.year >= 1583) return DateTime(d.year);
  if (s.length >= 4) {
    final y = int.tryParse(s.substring(0, 4));
    if (y != null && y > 1000 && y < 2100) return DateTime(y);
  }
  return null;
}

Picture? _trySniffImage(Uint8List data) {
  for (var i = 0; i + 1 < data.length; i++) {
    if (data[i] != 0xff || data[i + 1] != 0xd8) continue;
    for (var j = data.length; j >= i + 4; j--) {
      if (data[j - 2] == 0xff && data[j - 1] == 0xd9) {
        final b = Uint8List.sublistView(data, i, j);
        if (b.length > 64) {
          return Picture(b, 'image/jpeg', PictureType.coverFront);
        }
      }
    }
  }

  if (data.length >= 24 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4e &&
      data[3] == 0x47 &&
      data[4] == 0x0d &&
      data[5] == 0x0a &&
      data[6] == 0x1a &&
      data[7] == 0x0a) {
    return Picture(
      Uint8List.fromList(data),
      'image/png',
      PictureType.coverFront,
    );
  }

  return null;
}

Picture? _tryPictureFromDispOrRaw(Uint8List raw) =>
    raw.length < 8 ? null : _trySniffImage(raw);

void mergeId3v1TailAscii(
  Uint8List tag, {
  required void Function(String) considerTitle,
  required void Function(String) considerArtist,
  required void Function(String) considerAlbum,
  required void Function(String) considerGenre,
  required List<String> lyricChunks,
  required void Function(int?) trackSetter,
  required void Function(DateTime?) yearSetter,
}) {
  if (tag.length < 128) return;
  if (ascii.decode(tag.sublist(0, 3)) != 'TAG') return;

  considerTitle(_decodeId3v1Cp125X(tag.sublist(3, 33)));
  considerArtist(_decodeId3v1Cp125X(tag.sublist(33, 63)));
  considerAlbum(_decodeId3v1Cp125X(tag.sublist(63, 93)));

  final ys = _decodeId3v1Cp125X(tag.sublist(93, 97));
  if (ys.length >= 4) {
    final y = int.tryParse(ys.substring(0, 4));
    if (y != null && y > 999 && y < 2100) yearSetter(DateTime(y));
  }

  final commentText =
      _decodeEmbeddedInfoBytes(Uint8List.sublistView(tag, 97, 127)).trim();
  if (commentText.isNotEmpty) {
    lyricChunks.add(commentText);
  }

  final tnB = tag[126];
  if (tnB > 0 && tnB < 255) trackSetter(tnB);

  final gtxt = id3GenreName(tag[127]);
  if (gtxt != null) considerGenre(gtxt);
}

String _decodeId3v1Cp125X(Uint8List slice) {
  if (slice.isEmpty) return '';
  var end = slice.length;
  while (end > 0 && slice[end - 1] == 0) {
    end--;
  }
  if (end == 0) return '';
  final real = Uint8List.sublistView(slice, 0, end);

  try {
    return latin1.decode(real, allowInvalid: false).trim();
  } catch (_) {}
  try {
    return gbkRecoverFromMisreadLatinStrings(real.toList()).trim();
  } catch (_) {
    return '';
  }
}

/// 字节先按 Latin‑1 → String，再走与 [gbkRecoverFromMisreadLatinStrings] 相同逻辑。
String gbkRecoverFromMisreadLatinStrings(List<int> bytes) {
  final s =
      latin1.decode(Uint8List.fromList(bytes), allowInvalid: true).trimRight();
  if (s.isEmpty) return '';

  List<int>? tryLat;
  try {
    tryLat = latin1.encode(s);
  } catch (_) {
    return s;
  }

  try {
    final u = utf8.decode(tryLat, allowMalformed: false);
    if (u.trim().isNotEmpty) return u.trim();
  } catch (_) {}

  try {
    final g = gbk.decode(tryLat);
    if (g.trim().isNotEmpty) return g.trim();
  } catch (_) {}

  return s;
}

String? id3GenreName(int id) {
  const names = [
    'Blues', 'Classic Rock', 'Country', 'Dance', 'Disco', 'Funk', 'Grunge',
    'Hip-Hop', 'Jazz', 'Metal', 'New Age', 'Oldies', 'Other', 'Pop',
    'R&B', 'Rap', 'Reggae', 'Rock', 'Techno', 'Industrial',
    'Alternative', 'Ska', 'Death Metal', 'Pranks', 'Soundtrack',
    'Euro-Techno', 'Ambient', 'Trip-Hop', 'Vocal', 'Jazz+Funk', 'Fusion',
    'Trance', 'Classical', 'Instrumental', 'Acid', 'House',
    'Game', 'Sound Clip', 'Gospel', 'Noise', 'Alt Rock', 'Bass', 'Soul',
    'Punk', 'Space', 'Meditative', 'Instrumental Pop', 'Instrumental Rock',
    'Ethnic', 'Gothic', 'Darkwave',
  ];
  if (id >= 0 && id < names.length) return names[id];
  return null;
}

void extractUsLtFromId3Haystack(Uint8List hay, List<String> out) {
  if (hay.length < 10) return;

  void loopWindow(Uint8List w) {
    var i = 0;
    while (i + 10 <= w.length) {
      if (!(w[i] == 73 && w[i + 1] == 68 && w[i + 2] == 51)) {
        i++;
        continue;
      }
      final maj = w[i + 3];
      if (maj < 2 || maj > 4) {
        i++;
        continue;
      }
      final payloadSize =
          synchsafeFour(w[i + 6], w[i + 7], w[i + 8], w[i + 9]);
      final tagSpan = 10 + payloadSize;
      if (tagSpan < 10 || i + tagSpan > w.length) {
        i++;
        continue;
      }
      consumeOneFullId3v2ToLyrics(w, i, tagSpan, out);
      i += tagSpan;
    }
  }

  loopWindow(hay);
}

void _pullTailHaystackEmbeddedId3(
  RandomAccessFile raf, {
  required int fileLen,
  required List<String> lyricChunks,
}) {
  if (fileLen < 10) return;
  const maxHay = 2 * 1024 * 1024;
  final sz = math.min(maxHay, fileLen);
  raf.setPositionSync(fileLen - sz);
  final hay = raf.readSync(sz);
  extractUsLtFromId3Haystack(hay, lyricChunks);
}

int synchsafeFour(int a, int b, int c, int d) =>
    ((a & 127) << 21) |
    ((b & 127) << 14) |
    ((c & 127) << 7) |
    (d & 127);

void consumeOneFullId3v2ToLyrics(
  Uint8List buf,
  int offset,
  int tagSpan,
  List<String> out,
) {
  final endExclusive = math.min(offset + tagSpan, buf.length);
  if (offset + 10 > endExclusive) return;

  final maj = buf[offset + 3];
  if (maj != 3 && maj != 4) return;

  var pos = offset + 10;

  final flagsByte = buf[offset + 5];
  if ((flagsByte & 0x40) != 0 && maj == 4 && pos + 4 <= endExclusive) {
    final extStart = pos;
    final extLen = synchsafeFour(
      buf[pos],
      buf[pos + 1],
      buf[pos + 2],
      buf[pos + 3],
    );
    const minExtOk = 6;
    if (extLen < minExtOk || extStart + extLen > endExclusive) {
      return;
    }
    pos = extStart + extLen;
  }

  while (pos + 10 <= endExclusive) {
    final fidBytes = Uint8List.sublistView(buf, pos, pos + 4);
    if (fidBytes[0] == 0 &&
        fidBytes[1] == 0 &&
        fidBytes[2] == 0 &&
        fidBytes[3] == 0) {
      break;
    }
    final frameId = latin1.decode(fidBytes, allowInvalid: true);

    late int sz;
    if (maj == 4) {
      sz = synchsafeFour(
          buf[pos + 4],
          buf[pos + 5],
          buf[pos + 6],
          buf[pos + 7],
      );
      pos += 10;
    } else {
      sz = ByteData.sublistView(buf, pos + 4).getUint32(0, Endian.big);
      pos += 10;
    }

    if (sz <= 0 || pos + sz > endExclusive) break;

    if (frameId == 'USLT') {
      final txt = lyricFromUlstPayload(
        Uint8List.sublistView(buf, pos, pos + sz),
      );
      if (txt.isNotEmpty && !out.contains(txt)) out.add(txt);
    }

    pos += sz;
  }
}

/// USLT/Payload：`encoding`(1)+语言(3)+描述+0/00+正文。
String lyricFromUlstPayload(Uint8List payload) {
  if (payload.length < 4) return '';
  final enc = payload[0];
  final rest = Uint8List.sublistView(payload, 4);

  var o = 0;
  if (enc == 1 || enc == 2) {
    while (o + 1 < rest.length &&
        !(rest[o] == 0 && rest[o + 1] == 0)) {
      o += 2;
    }
    while (o < rest.length && rest[o] == 0 && o + 1 < rest.length) {
      o += 2;
    }
    o = o.clamp(0, rest.length);
  } else {
    final z = rest.indexOf(0);
    o = (z >= 0 ? z + 1 : rest.length).clamp(0, rest.length);
  }

  Uint8List textBytes = o <= rest.length
      ? Uint8List.sublistView(rest, o, rest.length)
      : Uint8List(0);

  textBytes = _trimTrailingZeros(textBytes);

  switch (enc) {
    case 0:
      return latin1
          .decode(textBytes, allowInvalid: true)
          .trim();
    case 1:
      if (textBytes.length >= 2 &&
          textBytes[0] == 0xff &&
          textBytes[1] == 0xfe) {
        return _decodeUtf16Le(textBytes, start: 2);
      }
      if (textBytes.length >= 2 &&
          textBytes[0] == 0xfe &&
          textBytes[1] == 0xff) {
        return _decodeUtf16Be(textBytes, start: 2);
      }
      return _decodeUtf16Le(textBytes, start: 0);
    case 2:
      return _decodeUtf16Be(textBytes);
    case 3:
      return utf8.decode(textBytes, allowMalformed: true).trim();
    default:
      try {
        return utf8.decode(textBytes, allowMalformed: false).trim();
      } catch (_) {}
      return gbk
          .decode(textBytes.toList())
          .trim();
  }
}
