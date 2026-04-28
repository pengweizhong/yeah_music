import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/welcome/app_startup_clock.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

/// 与欢迎页相同的渐变 + 话术 + **[启动耗时]**（帧级平滑累加）+ 底栏。
class WelcomeCountdownView extends StatefulWidget {
  const WelcomeCountdownView({
    super.key,
    required this.statusListenable,
    required this.dataReady,
    required this.glow,
    this.onEnter,
    this.showEnterButton = true,
  });

  final ValueListenable<String> statusListenable;
  final bool dataReady;
  final AnimationController glow;
  final VoidCallback? onEnter;
  final bool showEnterButton;

  @override
  State<WelcomeCountdownView> createState() => _WelcomeCountdownViewState();
}

class _WelcomeCountdownViewState extends State<WelcomeCountdownView>
    with SingleTickerProviderStateMixin {
  late Ticker _elapsedTicker;

  /// 与实际 [AppStartupClock] 解耦，主线程卡顿后仍「丝滑」步进追上，避免直接从 1s 跳到 7s。
  double _displaySec = 0;
  Duration? _prevTickerElapsed;

  @override
  void initState() {
    super.initState();
    AppStartupClock.ensureStarted();
    _elapsedTicker = createTicker(_onElapsedTick)..start();
  }

  void _onElapsedTick(Duration elapsed) {
    var dt = (_prevTickerElapsed == null)
        ? (1 / 172)
        : (elapsed - _prevTickerElapsed!).inMicroseconds / 1e6;
    _prevTickerElapsed = elapsed;
    if (dt <= 0 || dt.isNaN) return;
    // 长时间无帧后再调度：别把整段时差吞进一格，仍能分帧逼近
    if (dt > 0.22) dt = 0.22;

    final target = AppStartupClock.elapsed.inMicroseconds / 1e6;
    final gap = target - _displaySec;

    double move =
        gap * (1 - math.exp(-26 * dt)); // 指数靠拢，卡住后也不一步跳到底
    // 单帧最多前进约 72ms「表显」，读秒匀速累加视感；再卡也会多帧追平
    const maxPerFrame = 0.072;
    if (move.abs() > maxPerFrame) move = move.sign * maxPerFrame;

    setState(() {
      _displaySec += move;
      if ((target - _displaySec).abs() < 0.006 || gap.abs() < 0.002) {
        _displaySec = target;
      }
    });
  }

  @override
  void dispose() {
    _elapsedTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  animation: widget.glow,
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
                              widget.glow.value,
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
                  l10n.appTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeTagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<String>(
                  valueListenable: widget.statusListenable,
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
                _ElapsedCard(
                  dataReady: widget.dataReady,
                  secondsFormatted: _displaySec.toStringAsFixed(2),
                ),
                const SizedBox(height: 28),
                const RepaintBoundary(
                  child: _SplashIndeterminateControl(),
                ),
                const Spacer(flex: 2),
                if (widget.showEnterButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onEnter,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget.dataReady
                            ? const Color(0xFFE8EAFF).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white.withValues(
                          alpha: widget.dataReady ? 0.95 : 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: widget.dataReady
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        widget.dataReady
                            ? l10n.welcomeEnter
                            : l10n.welcomeEnterWait,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.dataReady
                        ? l10n.welcomeHintWhenReady
                        : l10n.welcomeHintWhenNotReady,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.32),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!widget.showEnterButton)
                  Text(
                    l10n.welcomePreparing,
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

class _ElapsedCard extends StatelessWidget {
  const _ElapsedCard({
    required this.dataReady,
    required this.secondsFormatted,
  });

  final bool dataReady;
  final String secondsFormatted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeCountdownLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dataReady
                      ? l10n.welcomeCountdownSubDoneReady
                      : l10n.welcomeStartupSubLoading,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.34),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            secondsFormatted,
            style: TextStyle(
              color: dataReady ? const Color(0xFF8BE38B) : Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.secondsUnit,
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
