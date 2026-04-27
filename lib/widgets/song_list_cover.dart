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

/// 列表/迷你播放条用封面：按逻辑尺寸与设备 DPR 限制解码，减轻内存峰值；滑动中不卸 [Image]，
/// 已解码资源由 [ImageCache] 与 [ApplicationUtils] 的 provider 缓存复用，避免整屏闪动。
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

    // 不使用 frameBuilder 渐显：停滑/回收后再挂上 Image 时，缓存命中的图也会首帧
    // frame==null 被做成 opacity:0 再 100ms 渐显，体感像“重新加载”。底层已有占位色。
    final img = Image(
      image: image,
      width: size,
      height: size,
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
