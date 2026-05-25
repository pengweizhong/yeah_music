// Copyright (c) 2025 Yeah Music
//
// 桌面端：若系统存在完整 FFmpeg，将 DSD 转为 FLAC 再交给 mpv（解码正确、可 seek）。

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/utils/dff_dsf_transmux.dart' show dffDsfCacheDirectoryPaths;

String? _cachedFfmpegPath;

/// 解析本机 FFmpeg（Homebrew 等）；找不到返回 null。
Future<String?> resolveSystemFfmpeg() async {
  if (_cachedFfmpegPath != null) {
    if (File(_cachedFfmpegPath!).existsSync()) return _cachedFfmpegPath;
    _cachedFfmpegPath = null;
  }
  const candidates = [
    '/opt/homebrew/bin/ffmpeg',
    '/usr/local/bin/ffmpeg',
    '/opt/local/bin/ffmpeg',
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) {
      _cachedFfmpegPath = c;
      return c;
    }
  }
  try {
    final r = await Process.run('which', ['ffmpeg']);
    if (r.exitCode == 0) {
      final path = (r.stdout as String).trim().split('\n').first.trim();
      if (path.isNotEmpty && File(path).existsSync()) {
        _cachedFfmpegPath = path;
        return path;
      }
    }
  } catch (_) {}
  return null;
}

Future<Directory> _ffmpegFlacCacheDir() async {
  final roots = await dffDsfCacheDirectoryPaths();
  if (roots.isNotEmpty) {
    return Directory(p.join(roots.first, 'ffmpeg_flac'));
  }
  final tmp = await Directory.systemTemp.createTemp('yeah_dsd_ff_');
  return tmp;
}

/// 将 .dsf / .dff 转为缓存 FLAC；失败返回 null（调用方回退 DSF 转封装）。
Future<String?> ensureFfmpegFlacPlaybackPath(String audioPath) async {
  final lower = audioPath.toLowerCase();
  if (!lower.endsWith('.dsf') && !lower.endsWith('.dff')) return null;

  final src = File(audioPath);
  if (!await src.exists()) return null;

  final ffmpeg = await resolveSystemFfmpeg();
  if (ffmpeg == null) return null;

  final stat = await src.stat();
  final cacheKey = sha1
      .convert(
        'flac1|$audioPath|${stat.size}|${stat.modified.millisecondsSinceEpoch}'
            .codeUnits,
      )
      .toString();
  final cacheDir = await _ffmpegFlacCacheDir();
  if (!await cacheDir.exists()) {
    await cacheDir.create(recursive: true);
  }
  final outPath = p.join(cacheDir.path, '$cacheKey.flac');
  final out = File(outPath);
  if (await out.exists()) {
    final len = await out.length();
    if (len > 4096) return outPath;
    try {
      await out.delete();
    } catch (_) {}
  }

  final part = File('$outPath.part');
  if (await part.exists()) {
    try {
      await part.delete();
    } catch (_) {}
  }

  appLog.d('FFmpeg DSD→FLAC: ${p.basename(audioPath)}');
  final result = await Process.run(ffmpeg, [
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    audioPath,
    '-vn',
    '-c:a',
    'flac',
    '-compression_level',
    '5',
    '-ar',
    '48000',
    part.path,
  ]);
  if (result.exitCode != 0) {
    appLog.w(
      'FFmpeg DSD 转 FLAC 失败: ${p.basename(audioPath)}',
      error: '${result.stderr}',
    );
    try {
      if (await part.exists()) await part.delete();
    } catch (_) {}
    return null;
  }
  if (!await part.exists() || await part.length() < 4096) {
    return null;
  }
  if (await out.exists()) {
    try {
      await out.delete();
    } catch (_) {}
  }
  await part.rename(outPath);
  appLog.d('FFmpeg DSD→FLAC 完成: ${await out.length()} bytes');
  return outPath;
}
