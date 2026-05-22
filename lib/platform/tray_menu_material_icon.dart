// Copyright (c) 2025 Yeah Music
//
// Renders Material icons to temp image files for native tray context menus.

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
const Color _kBmpBackground = Color(0xFFFFFFFF);

/// Windows 菜单位图：32×32 绘制后由 GDI 缩到 SM_CXSMICON（比 16 直接画更清晰）。
const int _kWindowsBmpSize = 32;
const int _kLinuxPngSize = 24;

final Map<int, String> _pathCache = {};

/// Filesystem path for a tray menu icon (`.bmp` on Windows, `.png` on Linux).
Future<String> trayMenuMaterialIconPath(IconData icon) async {
  final pixelSize = Platform.isWindows ? _kWindowsBmpSize : _kLinuxPngSize;
  final key = Object.hash(
    icon.codePoint,
    icon.fontFamily,
    6,
    pixelSize,
    _kIconColor.toARGB32(),
    Platform.operatingSystem,
  );
  final cached = _pathCache[key];
  if (cached != null && await File(cached).exists()) {
    return cached;
  }

  final ext = Platform.isWindows ? '.bmp' : '.png';
  final path = p.join(
    (await getTemporaryDirectory()).path,
    'yeah_tray_v6_${icon.codePoint}$ext',
  );

  final rgba = await _rasterizeIcon(icon, pixelSize: pixelSize);
  final bytes = Platform.isWindows
      ? _encodeBmp24(pixelSize, pixelSize, _flattenRgbaForBmp(rgba))
      : await _encodePng(pixelSize, pixelSize, rgba);
  await File(path).writeAsBytes(bytes, flush: true);
  _pathCache[key] = path;
  return path;
}

Future<Uint8List> _rasterizeIcon(IconData icon, {required int pixelSize}) async {
  final scale = pixelSize / _kLogical;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(scale);
  if (Platform.isWindows) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _kLogical, _kLogical),
      Paint()..color = _kBmpBackground,
    );
  }
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

Uint8List _flattenRgbaForBmp(Uint8List rgba) {
  final out = Uint8List.fromList(rgba);
  const bgR = 255;
  const bgG = 255;
  const bgB = 255;
  for (var i = 0; i < out.length; i += 4) {
    final a = out[i + 3] / 255.0;
    out[i] = (out[i] * a + bgR * (1 - a)).round();
    out[i + 1] = (out[i + 1] * a + bgG * (1 - a)).round();
    out[i + 2] = (out[i + 2] * a + bgB * (1 - a)).round();
    out[i + 3] = 255;
  }
  return out;
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

Uint8List _encodeBmp24(int width, int height, Uint8List rgba) {
  final rowStride = ((width * 3 + 3) ~/ 4) * 4;
  final pixelBytes = rowStride * height;
  const headerSize = 54;
  final out = Uint8List(headerSize + pixelBytes);

  void set32(int offset, int value) {
    out[offset] = value & 0xff;
    out[offset + 1] = (value >> 8) & 0xff;
    out[offset + 2] = (value >> 16) & 0xff;
    out[offset + 3] = (value >> 24) & 0xff;
  }

  out[0] = 0x42;
  out[1] = 0x4d;
  set32(2, out.length);
  set32(10, headerSize);
  set32(14, 40);
  set32(18, width);
  set32(22, height);
  out[26] = 1;
  out[28] = 24;

  var dst = headerSize;
  for (var y = height - 1; y >= 0; y--) {
    final rowStart = dst;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      out[dst++] = rgba[i + 2];
      out[dst++] = rgba[i + 1];
      out[dst++] = rgba[i];
    }
    while (dst - rowStart < rowStride) {
      out[dst++] = 0;
    }
  }
  return out;
}
