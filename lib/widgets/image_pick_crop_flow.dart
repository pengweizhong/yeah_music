import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yeah_music/l10n/app_localizations.dart';

/// 首页横滑歌单卡片 [_MixCard] 装饰区域宽高比：宽 128、槽位高 168（见 home_page.dart）。
/// [Crop] 的 [aspectRatio] 为 **宽 ÷ 高**，故为竖长方形（小于 1）。
const double kPlaylistCoverCropAspectRatio = 128 / 168;

/// 相册选图 → 全屏裁剪 → 返回裁剪后的 PNG 字节；取消则为 `null`。
///
/// [aspectRatio] 为 `null` 时不锁定比例（主题背景等）。
Future<Uint8List?> pickImageWithCrop({
  required BuildContext context,
  required AppLocalizations l10n,
  double? aspectRatio,
}) async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(source: ImageSource.gallery);
  if (xfile == null) return null;
  final bytes = await xfile.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => ImageCropEditorPage(
        imageBytes: bytes,
        aspectRatio: aspectRatio,
        l10n: l10n,
      ),
    ),
  );
}

/// 共用裁剪页（主题背景 / 歌单封面）。
class ImageCropEditorPage extends StatefulWidget {
  const ImageCropEditorPage({
    super.key,
    required this.imageBytes,
    required this.l10n,
    this.aspectRatio,
  });

  final Uint8List imageBytes;
  final AppLocalizations l10n;
  final double? aspectRatio;

  @override
  State<ImageCropEditorPage> createState() => _ImageCropEditorPageState();
}

class _ImageCropEditorPageState extends State<ImageCropEditorPage> {
  final _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.l10n.imageCropTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            child: Text(
              widget.l10n.actionOK,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Crop(
          image: widget.imageBytes,
          controller: _cropController,
          aspectRatio: widget.aspectRatio,
          interactive: true,
          baseColor: Colors.black,
          maskColor: Colors.white.withValues(alpha: 0.45),
          radius: 0,
          onCropped: (CropResult result) {
            if (result is CropSuccess) {
              Navigator.pop(context, result.croppedImage);
              return;
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.l10n.imageCropFailure)),
            );
          },
        ),
      ),
    );
  }
}
