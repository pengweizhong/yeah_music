// Copyright (c) 2025 Yeah Music
//
// 仅生成 Windows **任务栏/窗口** 用 app_icon.ico（与 Linux 一致：不做锐化/对比度 hack）。
//
// **托盘区主图标** 已与 Linux 相同，直接用 assets/icons/yeah_music1.png，
// 见 lib/widgets/linux_tray_host.dart + tray_manager GDI+ 缩放。
//
//   dart run tool/generate_windows_app_icon.dart
//   flutter clean && flutter run -d windows

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _sourcePath = 'assets/icons/yeah_music1.png';
const _runnerIcoPath = 'windows/runner/resources/app_icon.ico';

const _sizes = <int>[16, 20, 24, 32, 40, 48, 64, 96, 128, 256];
const _trimPaddingPx = 0;

void main() {
  final sourceFile = File(_sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing source: $_sourcePath');
    exitCode = 1;
    return;
  }

  final decoded = decodeImage(sourceFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode $_sourcePath');
    exitCode = 1;
    return;
  }

  final src = _trimTransparentMargins(decoded);
  stdout.writeln(
    'Source ${decoded.width}x${decoded.height} -> content ${src.width}x${src.height}',
  );
  stdout.writeln('Preset: Linux-like (cubic downscale only, no sharpen)');

  final frames = <Image>[];
  for (final size in _sizes) {
    if (size > 256) continue;
    frames.add(_downscaleTo(src, size, size));
  }

  final container = frames.first;
  for (var i = 1; i < frames.length; i++) {
    container.addFrame(frames[i]);
  }

  final bytes = encodeIco(container, singleFrame: false);
  final out = File(_runnerIcoPath);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);

  stdout.writeln('Wrote $_runnerIcoPath (${frames.length} sizes)');
  stdout.writeln('Tray icon: assets/icons/yeah_music1.png (same as Linux, no .ico)');
  stdout.writeln('Next: flutter clean && flutter run -d windows');
}

Image _trimTransparentMargins(Image src) {
  final trimmed = trim(src, mode: TrimMode.transparent);
  if (_trimPaddingPx > 0) {
    final padded = Image(
      width: trimmed.width + _trimPaddingPx * 2,
      height: trimmed.height + _trimPaddingPx * 2,
      numChannels: 4,
    );
    compositeImage(
      padded,
      trimmed,
      dstX: _trimPaddingPx,
      dstY: _trimPaddingPx,
      blend: BlendMode.direct,
    );
    return _squareCanvas(padded);
  }
  return _squareCanvas(trimmed);
}

Image _squareCanvas(Image src) {
  final side = math.max(src.width, src.height);
  if (side == src.width && side == src.height) {
    return Image.from(src);
  }
  final square = Image(width: side, height: side, numChannels: 4);
  compositeImage(
    square,
    src,
    dstX: (side - src.width) ~/ 2,
    dstY: (side - src.height) ~/ 2,
    blend: BlendMode.direct,
  );
  return square;
}

Image _downscaleTo(Image src, int width, int height) {
  var img = src;
  var w = img.width;
  var h = img.height;

  while (w > width * 1.25 || h > height * 1.25) {
    w = math.max(width, w ~/ 2);
    h = math.max(height, h ~/ 2);
    img = copyResize(
      img,
      width: w,
      height: h,
      interpolation: Interpolation.cubic,
    );
  }

  if (w != width || h != height) {
    img = copyResize(
      img,
      width: width,
      height: height,
      interpolation: Interpolation.cubic,
    );
  }
  return img;
}
