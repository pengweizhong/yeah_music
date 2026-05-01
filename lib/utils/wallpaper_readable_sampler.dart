import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

/// 从壁纸缩略采样得到的、在图上整体最「不容易撞色的」一对前景色。
class WallpaperReadableSample {
  const WallpaperReadableSample({
    required this.foreground,
    required this.foregroundMuted,
  });

  final Color foreground;
  final Color foregroundMuted;
}

double _relLuminanceChannel(double v) {
  v /= 255.0;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// sRGB 像素 → WCAG 相对亮度 [0,1]
double _relLuminanceFromColor(Color c) {
  int ch(double x) => (x.clamp(0.0, 1.0) * 255.0).round();
  return _relLuminanceRgb(ch(c.r), ch(c.g), ch(c.b));
}

/// sRGB 像素 → WCAG 相对亮度 [0,1]
double _relLuminanceRgb(int r, int g, int b) {
  final rl = _relLuminanceChannel(r.toDouble());
  final gl = _relLuminanceChannel(g.toDouble());
  final bl = _relLuminanceChannel(b.toDouble());
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
}

double _contrastRatio(double l1, double l2) {
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 取对比度分布的低分位作为鲁棒分数（忽略少量高光/死黑噪点）。
double _lowPercentileContrast(double lFg, List<double> lBgs, double p) {
  final crs = <double>[];
  for (final lBg in lBgs) {
    crs.add(_contrastRatio(lFg, lBg));
  }
  crs.sort();
  final n = crs.length;
  final k = (n * p).floor().clamp(0, n - 1);
  return crs[k];
}

/// 解码壁纸为约 [target] 边长缩略图并采样；失败返回 null。
///
/// [sampleLumaScale]：模拟蒙层压暗（0~1，越小越偏向暗底），应与 [ThemeConfigProvider] 的背景图雾化一致。
Future<WallpaperReadableSample?> sampleWallpaperReadableColors(
  String path, {
  int target = 72,
  double sampleLumaScale = 1.0,
}) async {
  if (path.isEmpty) return null;
  final f = File(path);
  if (!f.existsSync()) return null;

  Uint8List bytes;
  try {
    bytes = await f.readAsBytes();
  } catch (_) {
    return null;
  }
  if (bytes.isEmpty) return null;

  ui.Codec codec;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: target,
      targetHeight: target,
    );
  } catch (_) {
    return null;
  }

  ui.FrameInfo frame;
  try {
    frame = await codec.getNextFrame();
  } catch (_) {
    return null;
  }

  final image = frame.image;
  final w = image.width;
  final h = image.height;
  final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  try {
    image.dispose();
  } catch (_) {}

  if (bd == null || w <= 0 || h <= 0) return null;

  final n = w * h;
  final lBgs = List<double>.filled(n, 0);
  final scale = sampleLumaScale.clamp(0.2, 1.0);

  var i = 0;
  for (var py = 0; py < h; py++) {
    for (var px = 0; px < w; px++) {
      final o = (py * w + px) * 4;
      final r = bd.getUint8(o);
      final g = bd.getUint8(o + 1);
      final b = bd.getUint8(o + 2);
      lBgs[i] = (_relLuminanceRgb(r, g, b) * scale).clamp(0.0, 1.0);
      i++;
    }
  }

  final lInk = _relLuminanceFromColor(kGradLightInk);

  /// 约第 7 个百分位：代表「偏难读」区域，又不会被单点脏像素绑架。
  const tailP = 0.07;
  const lWhite = 1.0;
  final scoreWhite = _lowPercentileContrast(lWhite, lBgs, tailP);
  final scoreInk = _lowPercentileContrast(lInk, lBgs, tailP);

  if (scoreWhite >= scoreInk) {
    return const WallpaperReadableSample(
      foreground: Colors.white,
      foregroundMuted: Color(0xFFD2DEEE),
    );
  }

  return const WallpaperReadableSample(
    foreground: kGradLightInk,
    foregroundMuted: kGradLightInkMuted,
  );
}
