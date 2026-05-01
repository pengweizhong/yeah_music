import 'package:flutter/material.dart';

/// 简单背景组件（移除动画，提升性能）
class AnimatedGradientBackground extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.colors,
    required this.child,
    this.duration = const Duration(seconds: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

/// 从封面提取颜色的辅助类
class GradientColorExtractor {
  /// 处理颜色：降低饱和度和亮度，创建柔和的渐变
  static List<Color> processColors(List<Color> colors) {
    final processedColors = <Color>[];
    
    for (int i = 0; i < colors.length && i < 4; i++) {
      final hsl = HSLColor.fromColor(colors[i]);
      final saturation = (hsl.saturation * (0.25 + i * 0.03)).clamp(0.0, 1.0);
      final lightness = (0.08 + i * 0.02).clamp(0.0, 1.0);
      
      processedColors.add(
        hsl
            .withSaturation(saturation)
            .withLightness(lightness)
            .toColor()
      );
    }
    
    while (processedColors.length < 4) {
      processedColors.add(Colors.black);
    }
    
    return processedColors;
  }

  /// 获取默认颜色（与 [ThemeConfigProvider] 深色默认渐变协调）
  static List<Color> getDefaultColors() {
    return [
      const Color(0xFF1C2128),
      const Color(0xFF252B34),
      const Color(0xFF181C22),
      const Color(0xFF14181E),
    ];
  }
}

