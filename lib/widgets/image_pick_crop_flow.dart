// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/utils/wallpaper_image_bytes.dart';

/// 首页横滑歌单卡片 [_MixCard] 装饰区域宽高比：宽 128、槽位高 168（见 home_page.dart）。
/// [Crop] 的 [aspectRatio] 为 **宽 ÷ 高**，故为竖长方形（小于 1）。
const double kPlaylistCoverCropAspectRatio = 128 / 168;

/// 内嵌封面裁剪：正方形框（宽 ÷ 高 = 1）。
const double kEmbeddedCoverCropAspectRatio = 1.0;

/// 主题壁纸：初始裁剪框相对最大可用区域的比例（略缩小，减轻贴屏幕/图片边缘误触）。
const double _kWallpaperInitialCropSizeRatio = 0.92;

InitialRectBuilder resolveCropInitialRectBuilder({
  required double effectiveAspect,
  double? fixedAspect,
  InitialRectBuilder? fixedAspectInitialRect,
}) {
  if (fixedAspect == null) {
    return InitialRectBuilder.withSizeAndRatio(
      size: _kWallpaperInitialCropSizeRatio,
      aspectRatio: effectiveAspect,
    );
  }
  return fixedAspectInitialRect ??
      InitialRectBuilder.withSizeAndRatio(
        size: 0.92,
        aspectRatio: fixedAspect,
      );
}

/// 相册选图 → 全屏裁剪 → 返回裁剪后的 PNG 字节；取消则为 `null`。
///
/// 先在根导航压入全屏流程页再打开系统相册，避免选图返回时先闪一下设置页/底部抽屉。
Future<Uint8List?> pickImageWithCrop({
  required BuildContext context,
  required AppLocalizations l10n,
  double? aspectRatio,
  InitialRectBuilder? fixedAspectInitialRect,
}) {
  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _ImageCropFlowHost(
        l10n: l10n,
        aspectRatio: aspectRatio,
        fixedAspectInitialRect: fixedAspectInitialRect,
      ),
    ),
  );
}

/// 内嵌标签封面：相册 → **正方形**裁剪（复用 [ImageCropEditorPage] / `crop_your_image`）。
Future<Uint8List?> pickSquareEmbeddedCoverImage({
  required BuildContext context,
  required AppLocalizations l10n,
}) {
  return pickImageWithCrop(
    context: context,
    l10n: l10n,
    aspectRatio: kEmbeddedCoverCropAspectRatio,
    fixedAspectInitialRect: InitialRectBuilder.withSizeAndRatio(
      size: 0.92,
      aspectRatio: kEmbeddedCoverCropAspectRatio,
    ),
  );
}

enum _ImageCropFlowPhase { picking, preparing, editing }

/// 选图 + 预处理 + 裁剪的单页流程（根导航全屏）。
class _ImageCropFlowHost extends StatefulWidget {
  const _ImageCropFlowHost({
    required this.l10n,
    required this.aspectRatio,
    this.fixedAspectInitialRect,
  });

  final AppLocalizations l10n;
  final double? aspectRatio;
  final InitialRectBuilder? fixedAspectInitialRect;

  @override
  State<_ImageCropFlowHost> createState() => _ImageCropFlowHostState();
}

class _ImageCropFlowHostState extends State<_ImageCropFlowHost> {
  _ImageCropFlowPhase _phase = _ImageCropFlowPhase.picking;
  Uint8List? _imageBytes;
  double? _cropAspectRatio;
  InitialRectBuilder? _initialRectBuilder;
  bool _pickerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPickerFlow());
  }

  Future<void> _runPickerFlow() async {
    if (_pickerStarted) return;
    _pickerStarted = true;

    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (xfile == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _phase = _ImageCropFlowPhase.preparing);

    Uint8List bytes;
    try {
      bytes = await xfile.readAsBytes();
      bytes = await normalizeWallpaperImageBytes(bytes);
    } catch (_) {
      _failAndClose(widget.l10n.imageCropFailure);
      return;
    }

    if (!await canDecodeWallpaperImageBytes(bytes)) {
      _failAndClose(widget.l10n.imageCropFailure);
      return;
    }

    if (!mounted) return;

    final mq = MediaQuery.sizeOf(context);
    final h = mq.height;
    final effectiveAspect =
        widget.aspectRatio ?? (h > 0 ? mq.width / h : 1.0);

    setState(() {
      _imageBytes = bytes;
      _cropAspectRatio = effectiveAspect;
      _initialRectBuilder = resolveCropInitialRectBuilder(
        effectiveAspect: effectiveAspect,
        fixedAspect: widget.aspectRatio,
        fixedAspectInitialRect: widget.fixedAspectInitialRect,
      );
      _phase = _ImageCropFlowPhase.editing;
    });
  }

  void _failAndClose(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _ImageCropFlowPhase.editing &&
        _imageBytes != null &&
        _cropAspectRatio != null &&
        _initialRectBuilder != null) {
      return ImageCropEditorPage(
        imageBytes: _imageBytes!,
        cropAspectRatio: _cropAspectRatio!,
        initialRectBuilder: _initialRectBuilder!,
        l10n: widget.l10n,
      );
    }

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
      ),
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      ),
    );
  }
}

/// 共用裁剪页（主题背景 / 歌单封面）。
class ImageCropEditorPage extends StatefulWidget {
  const ImageCropEditorPage({
    super.key,
    required this.imageBytes,
    required this.cropAspectRatio,
    required this.l10n,
    required this.initialRectBuilder,
  });

  final Uint8List imageBytes;
  /// 裁剪框锁定宽高比（宽÷高）。
  final double cropAspectRatio;
  final InitialRectBuilder initialRectBuilder;
  final AppLocalizations l10n;

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
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.imageBytes,
                controller: _cropController,
                aspectRatio: widget.cropAspectRatio,
                initialRectBuilder: widget.initialRectBuilder,
                interactive: true,
                baseColor: Colors.black,
                maskColor: Colors.white.withValues(alpha: 0.45),
                radius: 0,
                progressIndicator: const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
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
          ],
        ),
      ),
    );
  }
}
