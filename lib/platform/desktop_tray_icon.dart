// Copyright (c) 2025 Yeah Music
//
// Resolves a filesystem path for the tray / tray-menu icons (bundled or temp copy).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns an on-disk path suitable for [TrayManager.setIcon].
Future<String> resolveDesktopTrayIconPath(String assetPath) async {
  final bundled = _bundledAssetFile(assetPath);
  if (await bundled.exists() && await bundled.length() > 0) {
    return bundled.path;
  }

  final bytes = await _loadAssetBytes(assetPath);
  final ext = p.extension(assetPath);
  final stem = p.basenameWithoutExtension(assetPath);
  final out = File(
    p.join(
      (await getTemporaryDirectory()).path,
      'yeah_music_tray_$stem${ext.isEmpty ? '.ico' : ext}',
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

/// flutter_assets → 工程目录（debug）→ [rootBundle]。
Future<Uint8List> _loadAssetBytes(String assetPath) async {
  final bundled = _bundledAssetFile(assetPath);
  if (await bundled.exists()) {
    final len = await bundled.length();
    if (len > 0) return bundled.readAsBytes();
  }

  final fromProject = File(p.join(Directory.current.path, assetPath));
  if (await fromProject.exists()) {
    final len = await fromProject.length();
    if (len > 0) return fromProject.readAsBytes();
  }

  try {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    throw FlutterError('Unable to load asset: "$assetPath".');
  }
}
