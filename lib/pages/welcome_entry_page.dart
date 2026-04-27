import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
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

const _kDeferLoadMs = 80;

class WelcomeEntryPage extends StatefulWidget {
  const WelcomeEntryPage({super.key, this.preHiveCountdownLeft});

  /// 若经 [AppStartupGate] 已倒计过若干秒，在此接续剩余秒，避免重计为 [kWelcomeCountdownStart]。
  final int? preHiveCountdownLeft;

  @override
  State<WelcomeEntryPage> createState() => _WelcomeEntryPageState();
}

class _WelcomeEntryPageState extends State<WelcomeEntryPage>
    with SingleTickerProviderStateMixin {
  Object? _error;
  int _pass = 0;
  WelcomeFakeStatusRotator? _fake;

  bool _dataReady = false;
  bool _navigated = false;
  HomeInitialData? _initial;

  int _secondsLeft = kWelcomeCountdownStart;
  Timer? _countdownTimer;

  late final AnimationController _glow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final hints = welcomeFakeLoadHintsList(l10n);
    if (_fake == null) {
      _fake = WelcomeFakeStatusRotator(hints)..start();
    } else {
      _fake!.setHintsIfChanged(hints);
    }
  }

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _startCountdown(from: widget.preHiveCountdownLeft);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRun());
  }

  @override
  void dispose() {
    _glow.dispose();
    _countdownTimer?.cancel();
    _fake?.dispose();
    super.dispose();
  }

  void _startCountdown({int? from}) {
    _countdownTimer?.cancel();
    final start = (from ?? kWelcomeCountdownStart).clamp(0, 99);
    setState(() => _secondsLeft = start);
    if (start <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoEnter());
      return;
    }
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
      appLog.e('欢迎页预加载失败', error: e, stackTrace: st);
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
      await user.init();
    }
    if (!mounted) throw StateError('unmounted');
    await Future<void>.delayed(Duration.zero);
    if (!play.initialized) {
      await play.init(folder);
    }
    if (!mounted) throw StateError('unmounted');
    await Future<void>.delayed(Duration.zero);
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
    _fake?.restart();
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
    final fake = _fake;
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
    if (fake == null) {
      return const SizedBox.shrink();
    }
    return WelcomeCountdownView(
      key: ValueKey(_pass),
      statusListenable: fake.hint,
      secondsLeft: _secondsLeft,
      dataReady: _dataReady,
      glow: _glow,
      onEnter: _onTapEnter,
    );
  }
}
