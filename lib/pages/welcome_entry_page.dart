import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/welcome/app_startup_clock.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/home_initial_data.dart';
import 'package:yeah_music/models/quick_entry_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/home_page.dart';
import 'package:yeah_music/services/recent_play_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/welcome/welcome_countdown_view.dart';
import 'package:yeah_music/welcome/welcome_fake_status.dart';
import 'package:yeah_music/welcome/welcome_l10n.dart';
import 'package:yeah_music/widgets/app_splash_chrome.dart';

/// 仅在首帧与计时器轮转之后拉起预载，避免与话术轮播抢时钟。
const _kDeferLoadMs = 16;

class WelcomeEntryPage extends StatefulWidget {
  const WelcomeEntryPage({super.key});

  @override
  State<WelcomeEntryPage> createState() => _WelcomeEntryPageState();
}

class _WelcomeEntryPageState extends State<WelcomeEntryPage>
    with SingleTickerProviderStateMixin {
  Object? _error;
  int _pass = 0;

  bool _dataReady = false;
  bool _navigated = false;
  HomeInitialData? _initial;

  late final AnimationController _glow;
  late final WelcomeFakeStatusRotator _fake;

  @override
  void initState() {
    super.initState();
    _fake = WelcomeFakeStatusRotator(
      List<String>.from(kWelcomeFakeHintsPlaceholder),
    )..start();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickBackgroundPreload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fake.setHintsIfChanged(
      welcomeFakeLoadHintsList(AppLocalizations.of(context)),
    );
  }

  void _kickBackgroundPreload() {
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: _kDeferLoadMs));
      if (!mounted) return;
      // 多让出一帧调度，计时 Ticker 与光晕先于重 IO 多跑两轮
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await _runLoad();
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _fake.dispose();
    super.dispose();
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.welcomeNotReadyMessage),
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

  Future<void> _runLoad() async {
    if (_navigated || !mounted) return;
    try {
      _initial = await _load();
    } catch (e, st) {
      appLog.e('欢迎页预加载失败', error: e, stackTrace: st);
      if (mounted) setState(() => _error = e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _dataReady = true;
      _error = null;
    });
    _tryAutoEnter();
  }

  Future<HomeInitialData> _load() async {
    if (!mounted) {
      throw StateError('unmounted');
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) throw StateError('unmounted');

    final user = context.read<UserPlaylistProvider>();

    late final List<String> p;
    late final List<({String path, int count})> top;
    late final QuickEntryConfig? c;

    final batch = <Future<void>>[
      RecentPlayService.getPaths(limit: 50).then((v) => p = v),
      RecentPlayService.getTopByPlayCount(limit: 40).then((v) => top = v),
      SettingsService.loadQuickEntryConfig().then((v) => c = v),
    ];
    if (!user.initialized) {
      batch.add(user.init());
    }
    await Future.wait<void>(batch);
    if (!mounted) throw StateError('unmounted');
    await Future<void>.delayed(Duration.zero);

    return HomeInitialData(
      recentPaths: p,
      mostPlayedRaw: top,
      quickEntry: c ?? QuickEntryConfig.defaultConfig(),
    );
  }

  void _retry() {
    AppStartupClock.reset();
    _fake.restart();
    _dataReady = false;
    _initial = null;
    _navigated = false;
    setState(() {
      _error = null;
      _pass++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickBackgroundPreload());
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AppSplashChrome(
              key: ValueKey(_pass),
              title: l10n.appTitle,
              subtitle: l10n.welcomeLoadError('$_error'),
              showProgress: false,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: FilledButton.tonal(
                  onPressed: _retry,
                  child: Text(l10n.actionRetry),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return WelcomeCountdownView(
      key: ValueKey(_pass),
      statusListenable: _fake.hint,
      dataReady: _dataReady,
      glow: _glow,
      onEnter: _onTapEnter,
    );
  }
}
