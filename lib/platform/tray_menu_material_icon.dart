// Copyright (c) 2025 Yeah Music
//
// Renders Material icons to temp PNG files for native tray context menus.
// Linux: GTK loads PNG at native resolution. Windows: GDI+ high-quality downscale.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const double _kLogical = 16;
const double _kFontSize = 14;
const Color _kIconColor = Color(0xFF424242);

/// 与 Linux GTK 一致：按文件像素显示，24px 即可清晰。
const int _kTrayMenuPngSize = 24;

final Map<int, String> _pathCache = {};

int get _menuIconRasterSize => _kTrayMenuPngSize;

/// Filesystem path for a tray menu icon (PNG).
Future<String> trayMenuMaterialIconPath(IconData icon) async {
  final pixelSize = _menuIconRasterSize;
  final key = Object.hash(
    icon.codePoint,
    icon.fontFamily,
    10,
    pixelSize,
    _kIconColor.toARGB32(),
    Platform.operatingSystem,
  );
  final cached = _pathCache[key];
  if (cached != null && await File(cached).exists()) {
    return cached;
  }

  final path = p.join(
    (await getTemporaryDirectory()).path,
    'yeah_tray_v10_${icon.codePoint}_$pixelSize.png',
  );

  final rgba = await _rasterizeIcon(icon, pixelSize: pixelSize);
  await File(path).writeAsBytes(
    await _encodePng(pixelSize, pixelSize, rgba),
    flush: true,
  );
  _pathCache[key] = path;
  return path;
}

Future<Uint8List> _rasterizeIcon(IconData icon, {required int pixelSize}) async {
  final scale = pixelSize / _kLogical;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(scale);
  final tp = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  );
  tp.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontFamily: icon.fontFamily ?? 'MaterialIcons',
      fontSize: _kFontSize,
      color: _kIconColor,
      height: 1,
    ),
  );
  tp.layout();
  tp.paint(
    canvas,
    Offset((_kLogical - tp.width) / 2, (_kLogical - tp.height) / 2),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(pixelSize, pixelSize);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (data == null) {
    throw StateError('Failed to rasterize tray menu icon ${icon.codePoint}');
  }
  return data.buffer.asUint8List();
}

Future<Uint8List> _encodePng(int w, int h, Uint8List rgba) async {
  final completer = Completer<Uint8List>();
  ui.decodeImageFromPixels(
    rgba,
    w,
    h,
    ui.PixelFormat.rgba8888,
    (ui.Image img) async {
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bd == null) {
        completer.completeError(StateError('PNG encode failed'));
      } else {
        completer.complete(bd.buffer.asUint8List());
      }
    },
  );
  return completer.future;
}
