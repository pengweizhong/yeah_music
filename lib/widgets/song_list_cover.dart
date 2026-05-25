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
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';
import 'package:yeah_music/widgets/song_cover_image.dart';

export 'package:yeah_music/widgets/song_cover_image.dart'
    show songListCoverPlaceholderColor;

/// 与 [SongListCover] 同尺寸占位（无 [Image]），在仅需静态壳层时使用（如迷你条无封面源等情况）。
class SongListCoverStaticShell extends StatelessWidget {
  const SongListCoverStaticShell({
    super.key,
    this.size = 48,
    this.borderRadius,
  });

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image(
          image: ApplicationUtils.getImageCoverProvider(
            Song(''),
            size: size,
            devicePixelRatio: dpr,
          ),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

/// 列表/迷你播放条用封面；实现见 [SongCoverImage]。
class SongListCover extends StatefulWidget {
  const SongListCover({
    super.key,
    required this.song,
    this.size = 48,
    this.borderRadius,
    this.eagerHydrate = true,
  });

  final Song song;
  final double size;
  final BorderRadius? borderRadius;
  final bool eagerHydrate;

  @override
  State<SongListCover> createState() => _SongListCoverState();
}

class _SongListCoverState extends State<SongListCover> {
  Future<bool>? _ongoingHydrate;

  @override
  void initState() {
    super.initState();
    if (widget.eagerHydrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateWhenVisible());
    }
  }

  @override
  void didUpdateWidget(SongListCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      _ongoingHydrate = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateWhenVisible());
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || info.visibleFraction < 0.06) return;
    _hydrateWhenVisible();
  }

  void _hydrateWhenVisible() {
    if (!mounted) return;
    final fut = _ongoingHydrate ??=
        SongLibraryMetadataHydrator.hydrateIfNeeded(widget.song).whenComplete(() {
      _ongoingHydrate = null;
    });
    fut.then((changed) {
      if (!mounted || !changed) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey<String>('song_list_cover_vis_${widget.song.path}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: SongCoverImage(
        song: widget.song,
        decodeSize: widget.size,
        width: widget.size,
        height: widget.size,
        borderRadius: widget.borderRadius,
        eagerHydrate: widget.eagerHydrate,
      ),
    );
  }
}
