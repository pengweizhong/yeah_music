import 'package:flutter/material.dart';

/// Hive 初始化前全屏占位。替换项目里 `assets/launch/startup_loading.gif` 即可自定义（建议小体积）。
///
/// 修改资源路径时：同步更新 [pubspec.yaml] 的 `assets` 列表。
const String kStartupHiveLoadingAsset = 'assets/launch/startup_loading.gif';

/// 深色底 + 可选 GIF + 底部转圈，避免冷启动长时间纯黑/纯静态。
class StartupHiveLoadingSplash extends StatefulWidget {
  const StartupHiveLoadingSplash({
    super.key,
    this.backgroundColor = const Color(0xFF0A0E14),
  });

  final Color backgroundColor;

  @override
  State<StartupHiveLoadingSplash> createState() =>
      _StartupHiveLoadingSplashState();
}

class _StartupHiveLoadingSplashState extends State<StartupHiveLoadingSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return Opacity(
                  opacity: fade.value,
                  child: Transform.scale(
                    scale: scale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                kStartupHiveLoadingAsset,
                width: 128,
                height: 128,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
