import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_sound_preset.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/playback_sound_effect_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

String _formatBandHz(double centerHz) {
  if (centerHz >= 1000) {
    final k = centerHz / 1000.0;
    final s = k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    return '$s kHz';
  }
  return '${centerHz.round()} Hz';
}

/// 自定义频段 dB；非 Android 仅提示。保存后写入 [PlaybackSoundPreset.custom]。
Future<void> showPlaybackSoundCustomEqSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playbackSoundCustomSheetTitle),
        content: Text(l10n.playbackSoundPresetUnsupportedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionOK),
          ),
        ],
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final h = MediaQuery.sizeOf(sheetContext).height;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FrostedGlassBottomSheet(
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: (h * 0.72).clamp(280.0, 620.0),
              child: const _PlaybackSoundCustomEqBody(),
            ),
          ),
        ),
      );
    },
  );
}

class _PlaybackSoundCustomEqBody extends StatefulWidget {
  const _PlaybackSoundCustomEqBody();

  @override
  State<_PlaybackSoundCustomEqBody> createState() =>
      _PlaybackSoundCustomEqBodyState();
}

class _PlaybackSoundCustomEqBodyState extends State<_PlaybackSoundCustomEqBody> {
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;
  List<double> _gains = [];
  List<double> _centerHz = [];
  double _minDb = -12;
  double _maxDb = 12;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final eq = MusicService.androidEqualizer;
    if (eq == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).playbackSoundCustomLoadError;
        });
      }
      return;
    }
    try {
      await eq.setEnabled(true);
      final params = await eq.parameters.timeout(const Duration(seconds: 4));
      final saved = await SettingsService.loadPlaybackSoundCustomBandGainsDb();
      final n = params.bands.length;
      final gains = List<double>.generate(n, (i) {
        if (i < saved.length) {
          return saved[i].clamp(params.minDecibels, params.maxDecibels);
        }
        return params.bands[i].gain.clamp(params.minDecibels, params.maxDecibels);
      });
      if (!mounted) return;
      setState(() {
        _loading = false;
        _minDb = params.minDecibels;
        _maxDb = params.maxDecibels;
        _centerHz = params.bands.map((b) => b.centerFrequency).toList();
        _gains = gains;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).playbackSoundCustomLoadError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).playbackSoundCustomLoadError;
      });
    }
  }

  void _resetFlat() {
    setState(() {
      _gains = List<double>.filled(_gains.length, 0.0);
    });
  }

  Future<void> _saveApply() async {
    await SettingsService.savePlaybackSoundCustomBandGainsDb(
      List<double>.from(_gains),
    );
    await SettingsService.savePlaybackSoundPreset(PlaybackSoundPreset.custom);
    await PlaybackSoundEffectService.applyPreset(
      PlaybackSoundPreset.custom,
      equalizer: MusicService.androidEqualizer,
      loudness: MusicService.androidLoudnessEnhancer,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.playbackSoundCustomSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              TextButton(
                onPressed: _loading || _error != null || _gains.isEmpty
                    ? null
                    : _resetFlat,
                child: Text(l10n.playbackSoundCustomReset),
              ),
              TextButton(
                onPressed: _loading || _error != null || _gains.isEmpty
                    ? null
                    : _saveApply,
                child: Text(l10n.playbackSoundCustomSaveApply),
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.gradFg(0.72),
                      ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _gains.length,
              itemBuilder: (context, i) {
                final hz = i < _centerHz.length ? _centerHz[i] : 0.0;
                final v = _gains[i].clamp(_minDb, _maxDb);
                final divisions = ((_maxDb - _minDb) * 2).round().clamp(8, 96);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatBandHz(hz),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${v.toStringAsFixed(1)} dB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.gradFg(0.7),
                                ),
                          ),
                        ],
                      ),
                      Slider(
                        value: v,
                        min: _minDb,
                        max: _maxDb,
                        divisions: divisions,
                        label: '${v.toStringAsFixed(1)} dB',
                        onChanged: (nv) {
                          setState(() {
                            _gains[i] = nv;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
