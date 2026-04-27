import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/welcome/welcome_countdown_view.dart';
import 'package:yeah_music/welcome/welcome_fake_status.dart';
import 'package:yeah_music/welcome/welcome_l10n.dart';

/// Hive 未就绪时显示在 [AppStartupGate] 内；在带 [AppLocalizations] 的 [context] 下创建假加载轮播。
class PreHiveStartupView extends StatefulWidget {
  const PreHiveStartupView({
    super.key,
    required this.glow,
    required this.secondsLeft,
  });

  final AnimationController glow;
  final int secondsLeft;

  @override
  State<PreHiveStartupView> createState() => _PreHiveStartupViewState();
}

class _PreHiveStartupViewState extends State<PreHiveStartupView> {
  WelcomeFakeStatusRotator? _fake;

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
  void dispose() {
    _fake?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fake = _fake;
    if (fake == null) {
      return const SizedBox.shrink();
    }
    return WelcomeCountdownView(
      statusListenable: fake.hint,
      secondsLeft: widget.secondsLeft,
      dataReady: false,
      glow: widget.glow,
      showEnterButton: false,
    );
  }
}
