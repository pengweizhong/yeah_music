import 'package:flutter/material.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/widgets/list_cover_image_policy.dart';

/// 与深色播放主题协调的列表封面占位，避免白底在解码前露出。
Color songListCoverPlaceholderColor() => const Color(0xFF2E2E2E);

/// 与 [SongListCover] 同尺寸占位（无 [Image]），在 [ListCoverImagePolicy] 抑制或无需封面时使用。
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

/// 列表/迷你播放条用封面：按逻辑尺寸与设备 DPR 限制解码，减轻滚动卡顿与内存峰值。
/// 在 [ScrollAwareListFrame] 内、滑动进行中仅显示 [SongListCoverStaticShell]，不挂载 [Image]。
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
    if (ListCoverImagePolicy.shouldSuppressDecode(context)) {
      return SongListCoverStaticShell(
        size: size,
        borderRadius: borderRadius,
      );
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = ApplicationUtils.getImageCoverProvider(
      song,
      size: size,
      devicePixelRatio: dpr,
    );

    final img = Image(
      image: image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: child,
        );
      },
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
