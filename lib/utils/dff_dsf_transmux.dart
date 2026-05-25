// Copyright (c) 2025 Yeah Music
//
// media_kit 内置 FFmpeg 仅启用 dsf demuxer，不含 dff/iff。
// DFF 为交错 MSBF → DSF planar MSBF（bits=8），与 libmpv/FFmpeg dsf demuxer 一致。

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/logging/app_log.dart';

/// 会话内 DFF→DSF 路径，避免同曲反复全量复制。
final Map<String, String> _sessionDsfPathByDff = {};

class DffAudioInfo {
  const DffAudioInfo({
    required this.channels,
    required this.dsdRateHz,
    required this.dataOffset,
    required this.dataSize,
    required this.bitsPerSample,
  });

  final int channels;
  final int dsdRateHz;
  final int dataOffset;
  final int dataSize;
  /// 写入 DSF fmt：bits=8 → MSBF；rate 字段 = dsdRateHz×8（FFmpeg 会 /8 得 2822400）。
  final int bitsPerSample;

  /// 1-bit DSD：每声道 sample 数 = 字节数×8。
  int get samplesPerChannel {
    if (channels <= 0 || dataSize <= 0) return 0;
    return (dataSize ~/ channels) * 8;
  }

  Duration get estimatedDuration {
    if (channels <= 0 || dsdRateHz <= 0 || dataSize <= 0) {
      return Duration.zero;
    }
    final seconds = (dataSize * 8) / (channels * dsdRateHz);
    if (!seconds.isFinite || seconds <= 0) return Duration.zero;
    return Duration(microseconds: (seconds * 1000000).round());
  }
}

/// 解析 DFF（DSDIFF/FRM8）并返回 DSD 数据区信息；失败返回 null。
Future<DffAudioInfo?> parseDffAudioInfo(File file) async {
  if (!file.path.toLowerCase().endsWith('.dff')) return null;
  final raf = await file.open(mode: FileMode.read);
  try {
    final fileLen = await raf.length();
    if (fileLen < 64) return null;
    final hdr = await raf.read(16);
    if (String.fromCharCodes(hdr.sublist(0, 4)) != 'FRM8') return null;
    if (String.fromCharCodes(hdr.sublist(12, 16)) != 'DSD ') return null;

    var pos = 16;
    int? dataOffset;
    int? dataSize;
    var channels = 2;
    var dsdRateHz = 2822400;
    const bits = 8;

    while (pos + 12 <= fileLen) {
      await raf.setPosition(pos);
      final id = await raf.read(4);
      if (id.length < 4) break;
      final idStr = String.fromCharCodes(id);
      final sizeBytes = await raf.read(8);
      if (sizeBytes.length < 8) break;
      final chunkSize = _readUint64Be(sizeBytes, 0);
      final bodyStart = pos + 12;
      if (chunkSize <= 0 || bodyStart + chunkSize > fileLen) break;

      if (idStr == 'PROP') {
        final prop = await _readAt(raf, bodyStart, chunkSize);
        final parsed = _parsePropChunk(prop);
        if (parsed != null) {
          channels = parsed.$1;
          if (parsed.$2 > 0) dsdRateHz = parsed.$2;
        }
      } else if (idStr == 'DSD ') {
        dataOffset = bodyStart;
        dataSize = chunkSize;
        break;
      }

      pos = bodyStart + chunkSize;
    }

    if (dataOffset == null || dataSize == null || dataSize <= 0) {
      return null;
    }
    if (dataSize % channels != 0) return null;
    return DffAudioInfo(
      channels: channels.clamp(1, 8),
      dsdRateHz: dsdRateHz,
      dataOffset: dataOffset,
      dataSize: dataSize,
      bitsPerSample: bits,
    );
  } catch (e, st) {
    appLog.w('DFF 解析失败: ${file.path}', error: e, stackTrace: st);
    return null;
  } finally {
    await raf.close();
  }
}

(int channels, int dsdRateHz)? _parsePropChunk(Uint8List prop) {
  var channels = 2;
  var rateHz = 2822400;
  var pos = 0;
  if (prop.length >= 4 && String.fromCharCodes(prop.sublist(0, 4)) == 'SND ') {
    pos = 4;
  }
  while (pos + 12 <= prop.length) {
    final id = String.fromCharCodes(prop.sublist(pos, pos + 4));
    final size = _readUint64Be(prop, pos + 4);
    final bodyStart = pos + 12;
    if (size <= 0 || bodyStart + size > prop.length) break;
    if (id == 'CHNL') {
      final body = prop.sublist(bodyStart, bodyStart + size);
      if (body.length >= 2) {
        final n = _readUint16Be(body, 0);
        if (n > 0) channels = n;
      }
    } else if (id == 'ABSS' && size >= 12) {
      final body = prop.sublist(bodyStart, bodyStart + size);
      final rate = _readUint32Be(body, 8);
      if (rate > 1_000_000) rateHz = rate;
    } else if (id == 'FS  ' && size >= 8) {
      final body = prop.sublist(bodyStart, bodyStart + size);
      final rate = _readUint32Be(body, 4);
      if (rate > 1_000_000) rateHz = rate;
    }
    pos = bodyStart + size;
  }
  return (channels, rateHz);
}

Future<Directory> _dffDsfCacheDir() async {
  Directory base;
  try {
    base = await getApplicationSupportDirectory();
  } catch (_) {
    base = await getTemporaryDirectory();
  }
  final dir = Directory(p.join(base.path, 'yeah_dff_dsf_cache'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// 生成/复用缓存的 .dsf，供 mpv dsf demuxer 打开。
Future<String?> ensureDsfPlaybackPathForDff(String dffPath) async {
  if (!dffPath.toLowerCase().endsWith('.dff')) return null;

  final session = _sessionDsfPathByDff[dffPath];
  if (session != null) {
    final cached = File(session);
    if (await cached.exists()) {
      final info = await parseDffAudioInfo(File(dffPath));
      if (info != null) {
        final minBytes = 28 + 12 + 52 + 12 + info.dataSize;
        if (await cached.length() >= minBytes) {
          return session;
        }
      }
      try {
        await cached.delete();
      } catch (_) {}
    }
    _sessionDsfPathByDff.remove(dffPath);
  }

  final src = File(dffPath);
  if (!await src.exists()) return null;

  final info = await parseDffAudioInfo(src);
  if (info == null) return null;

  final stat = await src.stat();
  // v8c：planar + bits=8(MSBF) + rate×8，避免 mpv 在 ~27s 误触发 LoopMode.one 重播。
  final cacheKey = sha1
      .convert(
        'v8c|$dffPath|${stat.size}|${stat.modified.millisecondsSinceEpoch}'
            .codeUnits,
      )
      .toString();
  final minDsfBytes = 28 + 12 + 52 + 12 + info.dataSize;
  final cacheDir = await _dffDsfCacheDir();
  final outPath = p.join(cacheDir.path, '$cacheKey.dsf');
  final out = File(outPath);
  if (await out.exists()) {
    final outStat = await out.stat();
    if (outStat.size >= minDsfBytes) {
      _sessionDsfPathByDff[dffPath] = outPath;
      return outPath;
    }
    try {
      await out.delete();
    } catch (_) {}
  }

  try {
    appLog.d(
      'DFF→DSF 转封装开始: ${p.basename(dffPath)} → ${p.basename(outPath)} (cache: ${cacheDir.path})',
    );
    final partPath = '$outPath.part';
    final part = File(partPath);
    if (await part.exists()) {
      try {
        await part.delete();
      } catch (_) {}
    }
    await _writeDsfFromDff(src, part, info);
    if (await out.exists()) {
      try {
        await out.delete();
      } catch (_) {}
    }
    await part.rename(outPath);
    _sessionDsfPathByDff[dffPath] = outPath;
    final outLen = await out.length();
    appLog.d('DFF→DSF 转封装完成: $outLen bytes');
    return outPath;
  } catch (e, st) {
    appLog.e('DFF→DSF 转封装失败: $dffPath', error: e, stackTrace: st);
    try {
      if (await out.exists()) await out.delete();
      final part = File('$outPath.part');
      if (await part.exists()) await part.delete();
    } catch (_) {}
    return null;
  }
}

Future<void> _writeDsfFromDff(
  File dff,
  File dsfOut,
  DffAudioInfo info,
) async {
  final channels = info.channels;
  final rateField = info.dsdRateHz * 8;
  const bitsField = 8; // DSD_MSBF_PLANAR
  final sampleCount = info.samplesPerChannel;
  const blockAlign = 4096;
  final channelType = channels <= 1
      ? 1
      : channels == 2
          ? 2
          : channels <= 4
              ? 4
              : 6;

  final header = BytesBuilder(copy: false);
  void w32(int v) => header.add(_uint32Le(v));
  void w64(int v) => header.add(_uint64Le(v));

  header.add('DSD '.codeUnits);
  w64(28);
  w64(0);
  w64(0);

  header.add('fmt '.codeUnits);
  w64(52);
  w32(1);
  w32(0);
  w32(channelType);
  w32(channels);
  w32(rateField);
  w32(bitsField);
  w64(sampleCount);
  w32(blockAlign);
  w32(0);

  header.add('data'.codeUnits);
  w64(info.dataSize + 12);

  final sink = dsfOut.openWrite(mode: FileMode.writeOnly);
  try {
    sink.add(header.toBytes());
    await _writePlanarMsbfPayload(dff, sink, info);
  } finally {
    await sink.flush();
    await sink.close();
  }
}

/// DFF 交错 → DSF planar（分声道块拷贝，约 30～90 秒）。
Future<void> _writePlanarMsbfPayload(
  File dff,
  IOSink sink,
  DffAudioInfo info,
) async {
  final channels = info.channels;
  final bytesPerChannel = info.dataSize ~/ channels;
  final src = await dff.open(mode: FileMode.read);
  try {
    if (channels == 1) {
      await src.setPosition(info.dataOffset);
      await _pipeBytes(src, sink, info.dataSize);
      return;
    }
    const interleavedChunk = 2 * 1024 * 1024;
    for (var ch = 0; ch < channels; ch++) {
      var written = 0;
      while (written < bytesPerChannel) {
        final framesThisBlock = math.min(
          interleavedChunk ~/ channels,
          bytesPerChannel - written,
        );
        if (framesThisBlock <= 0) break;

        final interleaved = Uint8List(framesThisBlock * channels);
        await src.setPosition(info.dataOffset + written * channels);
        var got = 0;
        while (got < interleaved.length) {
          final n = await src.readInto(
            interleaved,
            got,
            interleaved.length - got,
          );
          if (n <= 0) break;
          got += n;
        }
        if (got < channels) break;

        final frames = got ~/ channels;
        final planar = Uint8List(frames);
        for (var i = 0; i < frames; i++) {
          planar[i] = interleaved[i * channels + ch];
        }
        sink.add(planar);
        written += frames;
        if (frames < framesThisBlock) break;
        if (written % (8 * 1024 * 1024) == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    }
  } finally {
    await src.close();
  }
}

/// 清空 DFF→DSF 转封装缓存（设置页或排错时可调用）。
Future<void> clearDffDsfTransmuxCache() async {
  _sessionDsfPathByDff.clear();
  for (final root in await _allDffDsfCacheRoots()) {
    final ff = Directory(p.join(root.path, 'ffmpeg_flac'));
    if (await ff.exists()) {
      try {
        await ff.delete(recursive: true);
      } catch (_) {}
    }
    if (!await root.exists()) continue;
    try {
      await for (final e in root.list()) {
        if (e is File) {
          await e.delete();
        }
      }
    } catch (e, st) {
      appLog.w('清理 DFF 缓存失败: ${root.path}', error: e, stackTrace: st);
    }
  }
}

/// 供用户/文档引用的缓存目录说明（沙盒内实际路径）。
Future<List<String>> dffDsfCacheDirectoryPaths() async {
  return (await _allDffDsfCacheRoots()).map((d) => d.path).toList();
}

Future<List<Directory>> _allDffDsfCacheRoots() async {
  final roots = <Directory>[];
  try {
    roots.add(await _dffDsfCacheDir());
  } catch (_) {}
  try {
    final tmp = await getTemporaryDirectory();
    roots.add(Directory(p.join(tmp.path, 'yeah_dff_dsf_cache')));
  } catch (_) {}
  return roots;
}

Future<void> _pipeBytes(
  RandomAccessFile src,
  IOSink sink,
  int length,
) async {
  var left = length;
  const chunk = 1024 * 1024;
  while (left > 0) {
    final n = left > chunk ? chunk : left;
    final buf = await src.read(n);
    if (buf.isEmpty) break;
    sink.add(buf);
    left -= buf.length;
  }
}

Future<Uint8List> _readAt(RandomAccessFile raf, int offset, int length) async {
  await raf.setPosition(offset);
  final out = BytesBuilder(copy: false);
  var left = length;
  while (left > 0) {
    final n = left > 65536 ? 65536 : left;
    final b = await raf.read(n);
    if (b.isEmpty) break;
    out.add(b);
    left -= b.length;
  }
  return out.toBytes();
}

int _readUint16Be(Uint8List b, int o) => (b[o] << 8) | b[o + 1];

int _readUint32Be(Uint8List b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

int _readUint64Be(Uint8List b, int o) {
  var v = 0;
  for (var i = 0; i < 8; i++) {
    v = (v << 8) | b[o + i];
  }
  return v;
}

Uint8List _uint32Le(int v) {
  final b = Uint8List(4);
  b[0] = v & 0xff;
  b[1] = (v >> 8) & 0xff;
  b[2] = (v >> 16) & 0xff;
  b[3] = (v >> 24) & 0xff;
  return b;
}

Uint8List _uint64Le(int v) {
  final b = Uint8List(8);
  var x = v;
  for (var i = 0; i < 8; i++) {
    b[i] = x & 0xff;
    x >>= 8;
  }
  return b;
}
