import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

/// 欢迎页/启动门控共用的倒计时刻度起点（与欢迎页 [WelcomeEntryPage] 一致）
const int kWelcomeCountdownStart = 5;

/// 与欢迎页相同的渐变 + 标题 + 假状态文案 + 倒计时 + 底栏。
class WelcomeCountdownView extends StatelessWidget {
  const WelcomeCountdownView({
    super.key,
    required this.statusListenable,
    required this.secondsLeft,
    required this.dataReady,
    required this.glow,
    this.onEnter,
    this.showEnterButton = true,
  });

  final ValueListenable<String> statusListenable;
  final int secondsLeft;
  final bool dataReady;
  final AnimationController glow;
  final VoidCallback? onEnter;
  final bool showEnterButton;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppSplashChrome.gradientColors[1],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppSplashChrome.gradientColors[0],
              const Color(0xFF0A0D12),
              AppSplashChrome.gradientColors[1],
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: glow,
                  builder: (context, child) {
                    return Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(
                              const Color(0x403D8BFF),
                              const Color(0x55667EEA),
                              glow.value,
                            )!,
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2D3A5C).withValues(alpha: 0.9),
                            const Color(0xFF141A24),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        Icons.headphones_rounded,
                        size: 44,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Yeah Music',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '每一次聆听，都从这里开始',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<String>(
                  valueListenable: statusListenable,
                  builder: (context, value, child) {
                    return Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _CountdownCard(secondsLeft: secondsLeft, dataReady: dataReady),
                const SizedBox(height: 28),
                const RepaintBoundary(
                  child: _SplashIndeterminateControl(),
                ),
                const Spacer(flex: 2),
                if (showEnterButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onEnter,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: dataReady
                            ? const Color(0xFFE8EAFF).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white.withValues(
                          alpha: dataReady ? 0.95 : 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: dataReady
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        dataReady ? '进入应用' : '进入应用（需等待加载完成）',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataReady
                        ? '加载已完成，可立即进入，也可等待倒计时结束自动进入。'
                        : '倒计时结束且加载完成后，将自动进入应用。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.32),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!showEnterButton)
                  Text(
                    '正在完成启动准备…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.32),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                SizedBox(height: 12 + bottomPad),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.secondsLeft,
    required this.dataReady,
  });

  final int secondsLeft;
  final bool dataReady;

  @override
  Widget build(BuildContext context) {
    final s = secondsLeft.clamp(0, 99);
    final done = s <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '进入倒计时',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                done
                    ? (dataReady ? '可以进入了' : '请等待数据就绪')
                    : '默认 $kWelcomeCountdownStart 秒，结束后自动进入',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.32),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            done ? '0' : s.toString().padLeft(2, '0'),
            style: TextStyle(
              color: done
                  ? (dataReady
                      ? const Color(0xFF8BE38B)
                      : Colors.white38)
                  : Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '秒',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
