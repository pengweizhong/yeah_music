// Copyright (c) 2025 Yeah Music
//
// Resolves a filesystem path for the tray icon (bundled or temp copy).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns an on-disk path suitable for [TrayManager.setIcon].
///
/// 始终把最新 ICO 写到临时目录（按内容指纹命名），避免：
/// - 直接返回旧的 `flutter_assets` 路径导致改图不生效；
/// - 固定文件名 `yeah_music_tray_*.ico` 被 tray 插件缓存。
Future<String> resolveDesktopTrayIconPath(String assetPath) async {
  final bytes = await _loadNewestAssetBytes(assetPath);
  final ext = p.extension(assetPath);
  if (ext.isEmpty) {
    throw FlutterError('Tray icon asset must have extension: "$assetPath"');
  }
  final stem = p.basenameWithoutExtension(assetPath);
  final fingerprint = _bytesFingerprint(bytes);
  final out = File(
    p.join(
      (await getTemporaryDirectory()).path,
      'yeah_tray_${stem}_$fingerprint$ext',
    ),
  );
  await out.writeAsBytes(bytes, flush: true);
  return out.path;
}

File _bundledAssetFile(String assetPath) {
  return File(
    p.join(
      p.dirname(Platform.resolvedExecutable),
      'data',
      'flutter_assets',
      assetPath,
    ),
  );
}

File? _projectAssetFile(String assetPath) {
  final cwd = Directory.current.path;
  if (cwd.isEmpty) return null;
  return File(p.join(cwd, assetPath));
}

/// 取工程目录 / 构建产物 / rootBundle 中**最新**的一份 ICO 字节。
Future<Uint8List> _loadNewestAssetBytes(String assetPath) async {
  final candidates = <_AssetCandidate>[];

  final project = _projectAssetFile(assetPath);
  if (project != null) {
    await _tryAddFileCandidate(candidates, project);
  }

  await _tryAddFileCandidate(candidates, _bundledAssetFile(assetPath));

  if (candidates.isEmpty) {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      throw FlutterError(
        'Unable to load tray icon "$assetPath". '
        'Run: dart run tool/generate_windows_app_icon.dart && flutter run',
      );
    }
  }

  candidates.sort((a, b) => b.modified.compareTo(a.modified));
  return candidates.first.bytes;
}

Future<void> _tryAddFileCandidate(
  List<_AssetCandidate> out,
  File file,
) async {
  if (!await file.exists()) return;
  final len = await file.length();
  if (len <= 0) return;
  final modified = await file.lastModified();
  final bytes = await file.readAsBytes();
  out.add(_AssetCandidate(bytes: bytes, modified: modified));
}

int _bytesFingerprint(Uint8List bytes) {
  var h = bytes.length;
  final step = bytes.length < 128 ? 1 : bytes.length ~/ 64;
  for (var i = 0; i < bytes.length; i += step) {
    h = 0x1fffffff & (h + bytes[i] * (i + 1));
  }
  return h;
}

class _AssetCandidate {
  _AssetCandidate({required this.bytes, required this.modified});
  final Uint8List bytes;
  final DateTime modified;
}
