import 'package:flutter/material.dart';

/// 应用内展示的 Yeah Music Logo（固定使用白底主视觉资源）。
class AppThemedBrandingLogo extends StatelessWidget {
  const AppThemedBrandingLogo({
    super.key,
    required this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  final double height;
  final double? width;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  static const String assetPath = 'assets/icons/yeah_music.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}
