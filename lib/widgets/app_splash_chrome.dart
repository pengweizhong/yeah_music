import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// 与 [WelcomeEntryPage]、Hive 阶段启动层共用，避免多段全屏切主题时「闪黑 / 白屏」。
///
/// 若提供 [statusListenable]，只重建副标题行，[CircularProgressIndicator] 所在子树不随状态文案重复构建，减轻掉帧感。
class AppSplashChrome extends StatelessWidget {
  const AppSplashChrome({
    super.key,
    this.title = 'Yeah Music',
    this.subtitle,
    this.statusListenable,
    this.showProgress = true,
  });

  final String title;
  final String? subtitle;
  final ValueListenable<String>? statusListenable;
  final bool showProgress;

  static const List<Color> gradientColors = [
    Color(0xFF121820),
    Color(0xFF050608),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gradientColors[1],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              if (statusListenable != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ValueListenableBuilder<String>(
                    valueListenable: statusListenable!,
                    builder: (context, value, child) {
                      return Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                ),
              ] else if (subtitle != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              if (showProgress) ...[
                const SizedBox(height: 32),
                // 独立重绘子层 + 系统菊花（分段淡化），比整页 setState 时驱动 Material 环状进度条更不易「一顿一顿」
                const RepaintBoundary(
                  child: _SplashIndeterminateControl(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashIndeterminateControl extends StatelessWidget {
  const _SplashIndeterminateControl();

  @override
  Widget build(BuildContext context) {
    return const CupertinoActivityIndicator(
      color: Color(0xA0FFFFFF),
      radius: 14,
    );
  }
}
