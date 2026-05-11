import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/models/playback_sound_preset.dart';
import 'package:yeah_music/services/settings_service.dart';

/// 按频段中心频率（Hz）插值得到目标增益（dB），再按设备 [minDecibels]/[maxDecibels] 夹取。
double _interpolateGainDb(
  List<({double hz, double db})> anchors,
  double centerHz,
) {
  if (anchors.isEmpty) return 0;
  if (centerHz <= anchors.first.hz) return anchors.first.db;
  if (centerHz >= anchors.last.hz) return anchors.last.db;
  for (var i = 0; i < anchors.length - 1; i++) {
    final a = anchors[i];
    final b = anchors[i + 1];
    if (centerHz <= b.hz) {
      final t = (centerHz - a.hz) / (b.hz - a.hz);
      return a.db + t * (b.db - a.db);
    }
  }
  return anchors.last.db;
}

List<({double hz, double db})> _anchorsFor(PlaybackSoundPreset preset) {
  switch (preset) {
    case PlaybackSoundPreset.standard:
      return const [
        (hz: 40.0, db: 0.0),
        (hz: 8000.0, db: 0.0),
      ];
    case PlaybackSoundPreset.pureVocals:
      return const [
        (hz: 60.0, db: -6.0),
        (hz: 180.0, db: -5.0),
        (hz: 400.0, db: -3.0),
        (hz: 900.0, db: 1.5),
        (hz: 2200.0, db: 3.0),
        (hz: 5000.0, db: 2.0),
        (hz: 12000.0, db: -0.5),
      ];
    case PlaybackSoundPreset.spatialWide:
      return const [
        (hz: 60.0, db: 3.0),
        (hz: 250.0, db: 1.2),
        (hz: 800.0, db: -2.0),
        (hz: 2500.0, db: -1.2),
        (hz: 6000.0, db: 3.5),
        (hz: 14000.0, db: 2.5),
      ];
    case PlaybackSoundPreset.rock:
      return const [
        (hz: 60.0, db: 6.0),
        (hz: 200.0, db: 4.5),
        (hz: 600.0, db: 1.5),
        (hz: 2000.0, db: 0.5),
        (hz: 5000.0, db: 3.0),
        (hz: 12000.0, db: 4.0),
      ];
    case PlaybackSoundPreset.pop:
      return const [
        (hz: 60.0, db: 2.8),
        (hz: 300.0, db: 2.0),
        (hz: 1000.0, db: 1.2),
        (hz: 3500.0, db: 3.0),
        (hz: 9000.0, db: 2.5),
        (hz: 14000.0, db: 1.2),
      ];
    case PlaybackSoundPreset.electronic:
      return const [
        (hz: 40.0, db: 6.5),
        (hz: 120.0, db: 5.5),
        (hz: 400.0, db: 2.0),
        (hz: 2000.0, db: 0.0),
        (hz: 6000.0, db: 4.0),
        (hz: 14000.0, db: 4.5),
      ];
    case PlaybackSoundPreset.classical:
      return const [
        (hz: 60.0, db: -1.0),
        (hz: 250.0, db: 0.0),
        (hz: 800.0, db: 1.0),
        (hz: 2500.0, db: 1.5),
        (hz: 7000.0, db: 2.0),
        (hz: 14000.0, db: 1.0),
      ];
    case PlaybackSoundPreset.jazz:
      return const [
        (hz: 80.0, db: 1.5),
        (hz: 300.0, db: 2.5),
        (hz: 900.0, db: 1.0),
        (hz: 3000.0, db: 0.5),
        (hz: 8000.0, db: 1.5),
        (hz: 14000.0, db: 0.5),
      ];
    case PlaybackSoundPreset.liveStage:
      return const [
        (hz: 45.0, db: 3.0),
        (hz: 120.0, db: 3.5),
        (hz: 350.0, db: 1.0),
        (hz: 900.0, db: -0.5),
        (hz: 2800.0, db: 2.5),
        (hz: 6500.0, db: 4.0),
        (hz: 14000.0, db: 4.2),
      ];
    case PlaybackSoundPreset.cozyRoom:
      return const [
        (hz: 55.0, db: 5.5),
        (hz: 160.0, db: 4.8),
        (hz: 380.0, db: 4.0),
        (hz: 700.0, db: 3.0),
        (hz: 1400.0, db: 1.0),
        (hz: 4000.0, db: 3.5),
        (hz: 9000.0, db: 4.8),
        (hz: 14000.0, db: 3.2),
      ];
    case PlaybackSoundPreset.podcastVoice:
      return const [
        (hz: 70.0, db: -3.5),
        (hz: 200.0, db: -4.0),
        (hz: 450.0, db: -1.5),
        (hz: 1400.0, db: 2.0),
        (hz: 3200.0, db: 4.2),
        (hz: 6500.0, db: 3.2),
        (hz: 11000.0, db: 1.2),
      ];
    case PlaybackSoundPreset.metal:
      return const [
        (hz: 45.0, db: 5.8),
        (hz: 130.0, db: 5.2),
        (hz: 420.0, db: 2.8),
        (hz: 1200.0, db: 0.8),
        (hz: 3800.0, db: 5.2),
        (hz: 8000.0, db: 4.2),
        (hz: 14000.0, db: 3.0),
      ];
    case PlaybackSoundPreset.hipHop:
      return const [
        (hz: 40.0, db: 6.2),
        (hz: 95.0, db: 5.2),
        (hz: 280.0, db: 2.2),
        (hz: 1800.0, db: 1.2),
        (hz: 3200.0, db: 3.6),
        (hz: 7000.0, db: 3.2),
        (hz: 12000.0, db: 1.5),
      ];
    case PlaybackSoundPreset.loFi:
      return const [
        (hz: 70.0, db: 2.8),
        (hz: 280.0, db: 3.8),
        (hz: 800.0, db: 2.2),
        (hz: 2200.0, db: -0.8),
        (hz: 4000.0, db: -2.2),
        (hz: 8500.0, db: -4.8),
        (hz: 14000.0, db: -3.5),
      ];
    case PlaybackSoundPreset.nightComfort:
      return const [
        (hz: 55.0, db: 1.5),
        (hz: 200.0, db: 2.0),
        (hz: 800.0, db: 0.8),
        (hz: 2800.0, db: -1.2),
        (hz: 5200.0, db: -3.2),
        (hz: 9000.0, db: -4.5),
        (hz: 14000.0, db: -4.2),
      ];
    case PlaybackSoundPreset.bassBoost:
      return const [
        (hz: 50.0, db: 8.0),
        (hz: 120.0, db: 6.5),
        (hz: 300.0, db: 3.0),
        (hz: 1000.0, db: 0.5),
        (hz: 4000.0, db: 0.0),
        (hz: 12000.0, db: 0.0),
      ];
    case PlaybackSoundPreset.custom:
      return const [(hz: 40.0, db: 0.0), (hz: 8000.0, db: 0.0)];
  }
}

/// 应用 Android 硬件音效（需在 [AudioPlayer] 已挂载且效果已绑定到播放器后调用）。
class PlaybackSoundEffectService {
  PlaybackSoundEffectService._();

  /// [equalizer] / [loudness] 与 [MusicService] 内 [AudioPlayer] 的 pipeline 一致。
  static Future<void> applyPreset(
    PlaybackSoundPreset preset, {
    required AndroidEqualizer? equalizer,
    required AndroidLoudnessEnhancer? loudness,
  }) async {
    if (equalizer == null || loudness == null) return;

    if (preset == PlaybackSoundPreset.standard) {
      await equalizer.setEnabled(false);
      await loudness.setTargetGain(0);
      await loudness.setEnabled(false);
      return;
    }

    await loudness.setEnabled(false);
    await loudness.setTargetGain(0);

    await equalizer.setEnabled(true);
    late final AndroidEqualizerParameters params;
    try {
      params = await equalizer.parameters.timeout(const Duration(seconds: 4));
    } on TimeoutException {
      await equalizer.setEnabled(false);
      return;
    } catch (_) {
      await equalizer.setEnabled(false);
      return;
    }
    final minDb = params.minDecibels;
    final maxDb = params.maxDecibels;

    if (preset == PlaybackSoundPreset.custom) {
      final raw = await SettingsService.loadPlaybackSoundCustomBandGainsDb();
      for (var i = 0; i < params.bands.length; i++) {
        var db = i < raw.length ? raw[i] : 0.0;
        db = db.clamp(minDb, maxDb);
        await params.bands[i].setGain(db);
      }
      return;
    }

    final anchors = _anchorsFor(preset);
    for (final band in params.bands) {
      var db = _interpolateGainDb(anchors, band.centerFrequency);
      db = db.clamp(minDb, maxDb);
      await band.setGain(db);
    }

    if (preset == PlaybackSoundPreset.bassBoost) {
      /// 响度增强与 EQ 频段上限无关；约 +6 dB 上限避免过载。
      await loudness.setTargetGain(6.0);
      await loudness.setEnabled(true);
    }
  }
}
