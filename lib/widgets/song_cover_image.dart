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

import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

/// 列表滚动解码真封面前的衬底（仅在有内嵌图时使用）。
Color songListCoverPlaceholderColor() => const Color(0xFF2E2E2E);

/// 播放页 / 列表 / 迷你条共用封面：按需 hydrate，切歌时在新封面就绪前保留上一张，避免默认图标闪烁。
class SongCoverImage extends StatefulWidget {
  const SongCoverImage({
    super.key,
    required this.song,
    this.decodeSize = 48,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.filterQuality = FilterQuality.low,
    /// 为 false 时不主动读文件（由其它可见实例 hydrate）；仍监听路径级封面更新。
    this.eagerHydrate = true,
  });

  final Song song;
  final double decodeSize;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final FilterQuality filterQuality;
  final bool eagerHydrate;

  @override
  State<SongCoverImage> createState() => _SongCoverImageState();
}

class _SongCoverImageState extends State<SongCoverImage> {
  int _displayFp = 0;
  ImageProvider? _holdProvider;
  VoidCallback? _coverListener;
  String _listenedPath = '';

  @override
  void initState() {
    super.initState();
    _displayFp = ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    _attachCoverListener(widget.song.path);
    if (widget.eagerHydrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
    }
  }

  @override
  void dispose() {
    _detachCoverListener();
    super.dispose();
  }

  void _attachCoverListener(String path) {
    if (path.isEmpty) return;
    _listenedPath = path;
    _coverListener = _onSongCoverChanged;
    ApplicationUtils.songCoverListenable(path).addListener(_coverListener!);
  }

  void _detachCoverListener() {
    if (_listenedPath.isEmpty || _coverListener == null) return;
    ApplicationUtils.songCoverListenable(
      _listenedPath,
    ).removeListener(_coverListener!);
    _coverListener = null;
    _listenedPath = '';
  }

  void _onSongCoverChanged() {
    if (!mounted) return;
    final nextFp =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (nextFp == _displayFp && _holdProvider == null) return;
    setState(() {
      if (nextFp > 0) {
        _displayFp = nextFp;
        _holdProvider = null;
      } else if (_holdProvider == null) {
        _displayFp = 0;
      }
    });
  }

  @override
  void didUpdateWidget(SongCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      _detachCoverListener();
      _attachCoverListener(widget.song.path);
      final newFp =
          ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
      final oldFp =
          ApplicationUtils.coverBytesFingerprint(oldWidget.song.imageBytes);
      if (newFp > 0) {
        _displayFp = newFp;
        _holdProvider = null;
      } else if (oldFp > 0) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        _holdProvider = ApplicationUtils.getImageCoverProvider(
          oldWidget.song,
          size: widget.decodeSize,
          devicePixelRatio: dpr,
        );
        _displayFp = oldFp;
      } else {
        _displayFp = 0;
        _holdProvider = null;
      }
      if (widget.eagerHydrate) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
      }
      return;
    }
    if (!oldWidget.eagerHydrate && widget.eagerHydrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
    }
    final nextFp =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (nextFp != _displayFp && nextFp > 0) {
      setState(() {
        _displayFp = nextFp;
        _holdProvider = null;
      });
    }
  }

  Future<void> _ensureCoverReady() async {
    final before =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    await SongLibraryMetadataHydrator.hydrateIfNeeded(widget.song);
    if (!mounted) return;
    final after =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    // 指纹变更时的 evict / 广播由 [SongLibraryMetadataHydrator] 统一处理。
    if (after > 0) {
      if (after != _displayFp || _holdProvider != null) {
        setState(() {
          _displayFp = after;
          _holdProvider = null;
        });
      }
      return;
    }
    if (before == after && _holdProvider == null) return;
    if (_holdProvider != null) {
      setState(() {
        _holdProvider = null;
        _displayFp = 0;
      });
    }
  }

  bool _showsEmbeddedArt() {
    final fp = ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    return fp > 0 || _holdProvider != null;
  }

  ImageProvider _resolveProvider(BuildContext context) {
    final song = widget.song;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    if (fp > 0) {
      return ApplicationUtils.getImageCoverProvider(
        song,
        size: widget.decodeSize,
        devicePixelRatio: dpr,
      );
    }
    if (_holdProvider != null) {
      return _holdProvider!;
    }
    return ApplicationUtils.getImageCoverProvider(
      song,
      size: widget.decodeSize,
      devicePixelRatio: dpr,
    );
  }

  ImageProvider _defaultProvider(BuildContext context) {
    return ApplicationUtils.getImageCoverProvider(
      widget.song,
      size: widget.decodeSize,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  Widget _buildImage(BuildContext context, ImageProvider provider, int keyFp) {
    final embedded = _showsEmbeddedArt();
    return Image(
      key: ValueKey<String>('${widget.song.path}#$keyFp'),
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: embedded ? widget.fit : BoxFit.contain,
      filterQuality: widget.filterQuality,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Image(
          image: _defaultProvider(context),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          filterQuality: widget.filterQuality,
          gaplessPlayback: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final fp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    final keyFp = fp > 0 ? fp : (_holdProvider != null ? _displayFp : 0);
    final provider = _resolveProvider(context);
    final img = _buildImage(context, provider, keyFp);

    final Widget painted;
    if (_showsEmbeddedArt()) {
      painted = Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: songListCoverPlaceholderColor()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          img,
        ],
      );
    } else {
      painted = img;
    }

    final child = ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: painted,
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }
    return child;
  }
}
