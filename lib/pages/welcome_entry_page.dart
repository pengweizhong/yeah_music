import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/home_initial_data.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

var log = Logger(printer: SimplePrinter());

const _kCountdownStart = 5;
const _kDeferLoadMs = 80;

const _kNotReadyMessage = '请稍等，资源尚未加载完成。';

class WelcomeEntryPage extends StatefulWidget {
  const WelcomeEntryPage({super.key});

  @override
  State<WelcomeEntryPage> createState() => _WelcomeEntryPageState();
}

class _WelcomeEntryPageState extends State<WelcomeEntryPage>
    with SingleTickerProviderStateMixin {
  Object? _error;
  int _pass = 0;
  late final ValueNotifier<String> _status;

  bool _dataReady = false;
  bool _navigated = false;
  HomeInitialData? _initial;

  int _secondsLeft = _kCountdownStart;
  Timer? _countdownTimer;

  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _status = ValueNotifier<String>('正在准备你的音乐空间…');
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRun());
  }

  @override
  void dispose() {
    _glow.dispose();
    _countdownTimer?.cancel();
    _status.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _kCountdownStart);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft -= 1;
        }
        if (_secondsLeft <= 0) {
          t.cancel();
        }
      });
      if (_secondsLeft <= 0) {
        _tryAutoEnter();
      }
    });
  }

  void _tryAutoEnter() {
    if (!mounted || _navigated) return;
    if (_dataReady && _initial != null) {
      _enterHome();
    }
  }

  void _onTapEnter() {
    if (!mounted) return;
    if (!_dataReady || _initial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(_kNotReadyMessage),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    _enterHome();
  }

  Future<void> _enterHome() async {
    if (!mounted || _navigated) return;
    final initial = _initial;
    if (initial == null) return;
    _navigated = true;
    _countdownTimer?.cancel();
    final route = PageRouteBuilder<void>(
      pageBuilder: (context, a, s) => HomePage(initial: initial),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, a, s, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    );
    await Navigator.of(context).pushReplacement(route);
  }

  Future<void> _scheduleRun() async {
    await Future<void>.delayed(
      const Duration(milliseconds: _kDeferLoadMs),
    );
    if (!mounted) return;
    await _runLoad();
  }

  Future<void> _runLoad() async {
    if (_navigated) return;
    setState(() {
      _error = null;
    });
    try {
      _initial = await _load();
    } catch (e, st) {
      log.e('欢迎页预加载失败: $e', error: e, stackTrace: st);
      if (mounted) setState(() => _error = e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _dataReady = true;
    });
    if (_secondsLeft <= 0) {
      _tryAutoEnter();
    }
  }

  Future<HomeInitialData> _load() async {
    if (!mounted) {
      throw StateError('unmounted');
    }
    final folder = context.read<FolderProvider>();
    final play = context.read<PlayListProvider>();
    final user = context.read<UserPlaylistProvider>();

    if (!user.initialized) {
      _status.value = '正在同步歌单…';
      await user.init();
    }
    if (!mounted) throw StateError('unmounted');
    await Future<void>.delayed(Duration.zero);
    if (!play.initialized) {
      _status.value = '正在加载曲库与播放状态…';
      await play.init(folder);
    }
    if (!mounted) throw StateError('unmounted');
    await Future<void>.delayed(Duration.zero);
    _status.value = '正在读取最近播放…';
    final p = await RecentPlayService.getPaths(limit: 50);
    final top = await RecentPlayService.getTopByPlayCount(limit: 40);
    final c = await SettingsService.loadQuickEntryConfig();
    return HomeInitialData(
      recentPaths: p,
      mostPlayedRaw: top,
      quickEntry: c ?? QuickEntryConfig.defaultConfig(),
    );
  }

  void _retry() {
    _status.value = '正在准备你的音乐空间…';
    _dataReady = false;
    _initial = null;
    _navigated = false;
    setState(() {
      _error = null;
      _pass++;
    });
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRun());
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AppSplashChrome(
              key: ValueKey(_pass),
              title: 'Yeah Music',
              subtitle: '加载出错了。请检查存储权限或稍后重试。\n\n$_error',
              showProgress: false,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: FilledButton.tonal(
                  onPressed: _retry,
                  child: const Text('重试'),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _WelcomeScaffold(
      key: ValueKey(_pass),
      statusListenable: _status,
      secondsLeft: _secondsLeft,
      dataReady: _dataReady,
      glow: _glow,
      onEnter: _onTapEnter,
    );
  }
}

// ---------------------------------------------------------------------------
// 欢迎页视觉
// ---------------------------------------------------------------------------

class _WelcomeScaffold extends StatelessWidget {
  const _WelcomeScaffold({
    super.key,
    required this.statusListenable,
    required this.secondsLeft,
    required this.dataReady,
    required this.glow,
    required this.onEnter,
  });

  final ValueListenable<String> statusListenable;
  final int secondsLeft;
  final bool dataReady;
  final AnimationController glow;
  final VoidCallback onEnter;

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
                    : '默认 $_kCountdownStart 秒，结束后自动进入',
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
