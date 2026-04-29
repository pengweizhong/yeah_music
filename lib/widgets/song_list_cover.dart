import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';

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

/// 列表/迷你播放条用封面；内嵌字节由列表行等处 [SongLibraryMetadataHydrator] 补全后展示。
/// 解码按 [Song.path] 去重缓存，同路径多处共享字节。
class SongListCover extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = ApplicationUtils.getImageCoverProvider(
      song,
      size: size,
      devicePixelRatio: dpr,
    );

    final img = Image(
      key: ValueKey<String>(
        '${song.path}#${ApplicationUtils.coverBytesFingerprint(song.imageBytes)}',
      ),
      image: image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: false,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: songListCoverPlaceholderColor(),
          child: Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withValues(alpha: 0.45),
              size: size * 0.45,
            ),
          ),
        );
      },
    );

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
            img,
          ],
        ),
      ),
    );
  }
}
