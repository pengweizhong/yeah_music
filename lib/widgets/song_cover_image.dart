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
  });

  final Song song;
  final double decodeSize;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final FilterQuality filterQuality;

  @override
  State<SongCoverImage> createState() => _SongCoverImageState();
}

class _SongCoverImageState extends State<SongCoverImage> {
  int _displayFp = 0;
  ImageProvider? _holdProvider;

  @override
  void initState() {
    super.initState();
    _displayFp = ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
  }

  @override
  void didUpdateWidget(SongCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
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
      } else {
        _displayFp = 0;
        _holdProvider = null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
      return;
    }
    final nextFp =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (nextFp != _displayFp) {
      if (nextFp > 0) {
        ApplicationUtils.evictSongCoverProvidersForPath(widget.song.path);
        setState(() {
          _displayFp = nextFp;
          _holdProvider = null;
        });
      }
    }
  }

  Future<void> _ensureCoverReady() async {
    final before =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    await SongLibraryMetadataHydrator.hydrateIfNeeded(widget.song);
    if (!mounted) return;
    final after =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (before != after && after > 0) {
      ApplicationUtils.evictSongCoverProvidersForPath(widget.song.path);
    }
    if (after > 0) {
      if (after != _displayFp || _holdProvider != null) {
        setState(() {
          _displayFp = after;
          _holdProvider = null;
        });
      }
      return;
    }
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
