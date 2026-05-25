// Copyright (c) 2025 Yeah Music
//
// DSF/DFF：不走整文件 [readMetadata]；DSF 通过头指针读 ID3 与 fmt 采样率。

import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show AudioMetadata, ID3v2Parser, Mp3Metadata, Picture, readMetadata;
import 'package:yeah_music/logging/app_log.dart';

class DsdFileMetadata {
  const DsdFileMetadata({
    this.title,
    this.album,
    this.artist,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.sampleRate,
    this.duration,
    this.pictures,
  });

  final String? title;
  final String? album;
  final String? artist;
  final DateTime? year;
  final int? trackNumber;
  final int? discNumber;
  final int? sampleRate;
  final Duration? duration;
  final List<Picture>? pictures;
}

int _readUint64LE(Uint8List b, int offset) {
  var v = 0;
  for (var i = 0; i < 8; i++) {
    v |= b[offset + i] << (8 * i);
  }
  return v;
}

int _readUint32LE(Uint8List b, int offset) {
  return b[offset] |
      (b[offset + 1] << 8) |
      (b[offset + 2] << 16) |
      (b[offset + 3] << 24);
}

/// 从 DSF 文件读取内嵌 ID3 与 fmt 采样信息；DFF 仅尝试尾部 ID3。
Future<DsdFileMetadata?> readDsdEmbeddedMetadata(
  File file, {
  bool loadPictures = false,
}) async {
  final path = file.path.toLowerCase();
  if (path.endsWith('.dsf')) {
    return _readDsf(file, loadPictures: loadPictures);
  }
  if (path.endsWith('.dff')) {
    return _readDffId3Tail(file, loadPictures: loadPictures);
  }
  return null;
}

Future<DsdFileMetadata?> _readDsf(
  File file, {
  required bool loadPictures,
}) async {
  final raf = await file.open(mode: FileMode.read);
  try {
    final header = await raf.read(28);
    if (header.length < 28) return null;
    if (String.fromCharCodes(header.sublist(0, 4)) != 'DSD ') return null;

    final metaPtr = _readUint64LE(header, 20);
    final dataPtr = _readUint64LE(header, 12);
    int? sampleRate;
    Duration? duration;

    if (dataPtr > 0 && dataPtr < await raf.length()) {
      await raf.setPosition(dataPtr);
      final fmtHdr = await raf.read(12);
      if (fmtHdr.length >= 12 &&
          String.fromCharCodes(fmtHdr.sublist(0, 4)) == 'fmt ') {
        final fmtSize = _readUint64LE(fmtHdr, 4);
        if (fmtSize >= 40) {
          final fmt = await raf.read(40);
          if (fmt.length >= 40) {
            sampleRate = _readUint32LE(fmt, 16);
            final sampleCount = _readUint64LE(fmt, 24);
            if (sampleRate > 0 && sampleCount > 0) {
              final seconds = sampleCount / sampleRate;
              if (seconds.isFinite && seconds > 0) {
                duration = Duration(
                  milliseconds: (seconds * 1000).round(),
                );
              }
            }
          }
        }
      }
    }

    AudioMetadata? tags;
    if (metaPtr > 0 && metaPtr < await raf.length()) {
      await raf.setPosition(metaPtr);
      final id3Hdr = await raf.read(12);
      if (id3Hdr.length >= 12 &&
          String.fromCharCodes(id3Hdr.sublist(0, 4)) == 'ID3 ') {
        final id3Size = _readUint64LE(id3Hdr, 4);
        if (id3Size > 0 && id3Size < 32 * 1024 * 1024) {
          final id3Bytes = await raf.read(id3Size);
          tags = await _parseId3Bytes(id3Bytes, loadPictures: loadPictures);
        }
      }
    }

    if (tags == null && sampleRate == null && duration == null) {
      return null;
    }
    return DsdFileMetadata(
      title: tags?.title,
      album: tags?.album,
      artist: tags?.artist,
      year: tags?.year,
      trackNumber: tags?.trackNumber,
      discNumber: tags?.discNumber,
      sampleRate: sampleRate,
      duration: duration ?? tags?.duration,
      pictures: loadPictures ? tags?.pictures : null,
    );
  } catch (e, st) {
    appLog.w('DSF 元数据读取失败: ${file.path}', error: e, stackTrace: st);
    return null;
  } finally {
    await raf.close();
  }
}

Future<DsdFileMetadata?> _readDffId3Tail(
  File file, {
  required bool loadPictures,
}) async {
  try {
    final len = await file.length();
    if (len < 128) return null;
    final tailLen = len > 256 * 1024 ? 256 * 1024 : len;
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(len - tailLen);
      final tail = await raf.read(tailLen);
      final idx = _indexOfId3(tail);
      if (idx < 0) return null;
      final id3Bytes = tail.sublist(idx);
      final tags = await _parseId3Bytes(id3Bytes, loadPictures: loadPictures);
      if (tags == null) return null;
      return DsdFileMetadata(
        title: tags.title,
        album: tags.album,
        artist: tags.artist,
        year: tags.year,
        trackNumber: tags.trackNumber,
        discNumber: tags.discNumber,
        duration: tags.duration,
        pictures: loadPictures ? tags.pictures : null,
      );
    } finally {
      await raf.close();
    }
  } catch (e, st) {
    appLog.w('DFF 元数据读取失败: ${file.path}', error: e, stackTrace: st);
    return null;
  }
}

int _indexOfId3(Uint8List bytes) {
  if (bytes.length < 10) return -1;
  for (var i = 0; i < bytes.length - 3; i++) {
    if (bytes[i] == 0x49 && bytes[i + 1] == 0x44 && bytes[i + 2] == 0x33) {
      return i;
    }
  }
  return -1;
}

Future<AudioMetadata?> _parseId3Bytes(
  Uint8List id3Bytes, {
  required bool loadPictures,
}) async {
  if (id3Bytes.length < 10) return null;
  final dir = await Directory.systemTemp.createTemp('yeah_dsd_id3_');
  final tmp = File('${dir.path}/tag.bin');
  try {
    await tmp.writeAsBytes(id3Bytes, flush: true);
    final raf = await tmp.open(mode: FileMode.read);
    try {
      final tag = ID3v2Parser().parse(raf);
      if (tag is! Mp3Metadata) return null;
      final meta = AudioMetadata(file: tmp);
      meta.title = tag.songName;
      meta.album = tag.album;
      meta.artist = tag.leadPerformer ?? tag.bandOrOrchestra;
      if (tag.year != null) {
        meta.year = DateTime(tag.year!);
      }
      meta.trackNumber = tag.trackNumber;
      if (tag.partOfSet != null) {
        final m = RegExp(r'^(\d+)').firstMatch(tag.partOfSet!.trim());
        if (m != null) meta.discNumber = int.tryParse(m.group(1)!);
      }
      meta.duration = tag.duration;
      if (loadPictures && tag.pictures.isNotEmpty) {
        meta.pictures = tag.pictures;
      }
      return meta;
    } finally {
      await raf.close();
    }
  } catch (e) {
    try {
      return readMetadata(tmp, getImage: loadPictures);
    } catch (_) {
      return null;
    }
  } finally {
    try {
      await tmp.delete();
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}
