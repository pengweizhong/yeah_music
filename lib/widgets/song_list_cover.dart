import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

/// 与深色播放主题协调的列表封面占位，避免白底在解码前露出。
Color songListCoverPlaceholderColor() => const Color(0xFF2E2E2E);

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
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Stack(
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
            Center(
              child: Icon(
                Icons.album,
                size: size * 0.38,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 列表/迷你播放条用封面；内嵌字节由 [SongLibraryMetadataHydrator] 按需补全。
///
/// 冷启动时首页「继续播放」与底部 [MiniPlayer] 可能共用同一 [Song] 实例；
/// 若仅一处 hydrate，另一处仍持有占位 [ImageProvider] 缓存，需在本组件内补全并 [setState]。
class SongListCover extends StatefulWidget {
  const SongListCover({
    super.key,
    required this.song,
    this.size = 48,
    this.borderRadius,
  });

  final Song song;
  final double size;
  final BorderRadius? borderRadius;

  @override
  State<SongListCover> createState() => _SongListCoverState();
}

class _SongListCoverState extends State<SongListCover> {
  int _coverFp = 0;

  @override
  void initState() {
    super.initState();
    _coverFp = ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
  }

  @override
  void didUpdateWidget(SongListCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextFp =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (oldWidget.song.path != widget.song.path) {
      _coverFp = nextFp;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCoverReady());
      return;
    }
    if (nextFp != _coverFp) {
      ApplicationUtils.evictSongCoverProvidersForPath(widget.song.path);
      setState(() => _coverFp = nextFp);
    }
  }

  Future<void> _ensureCoverReady() async {
    final before =
        ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    await SongLibraryMetadataHydrator.hydrateIfNeeded(widget.song);
    if (!mounted) return;
    final after = ApplicationUtils.coverBytesFingerprint(widget.song.imageBytes);
    if (before != after) {
      ApplicationUtils.evictSongCoverProvidersForPath(widget.song.path);
    }
    final fp = after;
    if (fp != _coverFp) {
      setState(() => _coverFp = fp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = ApplicationUtils.getImageCoverProvider(
      song,
      size: widget.size,
      devicePixelRatio: dpr,
    );

    final img = Image(
      key: ValueKey<String>('${song.path}#$_coverFp'),
      image: image,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: songListCoverPlaceholderColor(),
          child: Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withValues(alpha: 0.45),
              size: widget.size * 0.45,
            ),
          ),
        );
      },
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
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
        ),
      ),
    );
  }
}
