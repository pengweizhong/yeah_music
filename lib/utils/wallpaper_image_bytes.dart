import 'dart:typed_data';
import 'dart:ui' as ui;

const int kWallpaperImageMaxSide = 2048;

/// 写入主题壁纸 / 交给 [Image.file] 前统一为可解码 PNG，并限制边长。
Future<Uint8List> normalizeWallpaperImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return bytes;
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: kWallpaperImageMaxSide,
    );
    final frame = await codec.getNextFrame();
    image = frame.image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null || png.lengthInBytes == 0) return bytes;
    return png.buffer.asUint8List();
  } catch (_) {
    return bytes;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

Future<bool> canDecodeWallpaperImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return false;
  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: kWallpaperImageMaxSide,
    );
    await codec.getNextFrame();
    return true;
  } catch (_) {
    return false;
  } finally {
    codec?.dispose();
  }
}
