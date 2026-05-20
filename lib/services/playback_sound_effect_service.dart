// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:yeah_music/logging/app_log.dart';
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

  /// 所有 EQ/响度写入串行化，避免换源、[androidAudioSessionId] 回调与 UI 改预设时多路 [setGain] 交错
  /// 造成爆音、破音（快速切歌时尤其明显）。
  static Future<void> _applySerialTail = Future.value();

  /// 换源前旁路：不访问 [AndroidEqualizer.parameters]（播放器尚未激活时 [parameters] 会一直挂起，卡死 [MusicService] 整条 [_playChain]）。
  /// 须与 [applyPreset] 一样走 [_applySerialTail]，避免与 UI/session 音效写入交错。
  static Future<void> applyHardAndroidBypassForSourceChange({
    required AndroidEqualizer? equalizer,
    required AndroidLoudnessEnhancer? loudness,
  }) {
    if (equalizer == null || loudness == null) return Future.value();
    final next = _applySerialTail.then(
      (_) => _applyHardBypassCore(equalizer: equalizer, loudness: loudness),
    );
    _applySerialTail = next.catchError((Object? e, StackTrace st) {
      appLog.d('applyHardAndroidBypassForSourceChange 失败(可忽略): $e',
          error: e, stackTrace: st);
    });
    return next;
  }

  static Future<void> _applyHardBypassCore({
    required AndroidEqualizer equalizer,
    required AndroidLoudnessEnhancer loudness,
  }) async {
    await loudness.setEnabled(false);
    await loudness.setTargetGain(0);
    await equalizer.setEnabled(false);
  }

  /// [equalizer] / [loudness] 与 [MusicService] 内 [AudioPlayer] 的 pipeline 一致。
  ///
  /// [smoothGainRamp]：从**当前各频段增益**插值到目标的步数更多、间隔更长（播放启动链路等应开启）；
  /// UI 改预设、session 防抖用 false，仍会做较短插值以避免阶跃，只是更快。
  static Future<void> applyPreset(
    PlaybackSoundPreset preset, {
    required AndroidEqualizer? equalizer,
    required AndroidLoudnessEnhancer? loudness,
    bool smoothGainRamp = false,
  }) {
    if (equalizer == null || loudness == null) return Future.value();
    final next = _applySerialTail.then(
      (_) => _applyPresetCore(
        preset,
        equalizer: equalizer,
        loudness: loudness,
        smoothGainRamp: smoothGainRamp,
      ),
    );
    _applySerialTail = next.catchError((Object? e, StackTrace st) {
      appLog.d('applyPreset 串行任务失败(可忽略): $e', error: e, stackTrace: st);
    });
    return next;
  }

  /// 各频段从 [fromDb] 线性插值到 [toDb]，避免「先一刀切到 0 再拉目标」在硬件上产生与曲目相关的 zip 爆音。
  static Future<void> _rampEqBandFromTo(
    AndroidEqualizerParameters params,
    List<double> fromDb,
    List<double> toDb,
    double minDb,
    double maxDb, {
    int steps = 18,
    int stepDelayMs = 2,
  }) async {
    if (fromDb.length != toDb.length ||
        fromDb.length != params.bands.length) {
      return;
    }
    for (var s = 1; s <= steps; s++) {
      final t = s / steps;
      for (var i = 0; i < params.bands.length; i++) {
        final v = fromDb[i] + (toDb[i] - fromDb[i]) * t;
        await params.bands[i].setGain(v.clamp(minDb, maxDb));
      }
      if (s < steps && stepDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: stepDelayMs));
      }
    }
  }

  static Future<void> _applyPresetCore(
    PlaybackSoundPreset preset, {
    required AndroidEqualizer equalizer,
    required AndroidLoudnessEnhancer loudness,
    bool smoothGainRamp = false,
  }) async {
    /// 「原声」：整机关 EQ + 响度，信号不经过硬件滤波器；开播前 [reapplyStoredAndroidSoundPreset] 走此路径。
    /// （曾改为「EQ 常开 + 频段爬回 0dB」软旁路，会在原声下仍把均衡器接回链路，部分机型开局反而易炸音，故恢复硬旁路。）
    if (preset == PlaybackSoundPreset.standard) {
      await equalizer.setEnabled(false);
      await loudness.setTargetGain(0);
      await loudness.setEnabled(false);
      return;
    }

    /// 不在中途关断 Equalizer；先关响度再保持 EQ 接通，从当前增益插值到目标，减轻阶跃爆音。
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
    final fromDb = params.bands.map((b) => b.gain).toList();

    final List<double> targetsDb;
    if (preset == PlaybackSoundPreset.custom) {
      final raw = await SettingsService.loadPlaybackSoundCustomBandGainsDb();
      targetsDb = [];
      for (var i = 0; i < params.bands.length; i++) {
        var db = i < raw.length ? raw[i] : 0.0;
        targetsDb.add(db.clamp(minDb, maxDb));
      }
    } else {
      final anchors = _anchorsFor(preset);
      targetsDb = [];
      for (final band in params.bands) {
        var db = _interpolateGainDb(anchors, band.centerFrequency);
        targetsDb.add(db.clamp(minDb, maxDb));
      }
    }

    final steps = smoothGainRamp ? 26 : 10;
    final stepMs = smoothGainRamp ? 3 : 1;
    await _rampEqBandFromTo(
      params,
      fromDb,
      targetsDb,
      minDb,
      maxDb,
      steps: steps,
      stepDelayMs: stepMs,
    );

    if (preset == PlaybackSoundPreset.bassBoost) {
      /// 响度增强在「一次 setEnabled(true)+大目标增益」时极易插入爆音；先 0 dB 接通再分步爬升。
      await Future<void>.delayed(
        Duration(milliseconds: smoothGainRamp ? 96 : 40),
      );
      await loudness.setTargetGain(0.0);
      await loudness.setEnabled(true);
      const targetFinalDb = 4.5;
      final loudSteps = smoothGainRamp ? 10 : 5;
      final loudStepMs = smoothGainRamp ? 14 : 10;
      for (var s = 1; s <= loudSteps; s++) {
        await loudness.setTargetGain(targetFinalDb * s / loudSteps);
        if (s < loudSteps) {
          await Future<void>.delayed(Duration(milliseconds: loudStepMs));
        }
      }
    }
  }
}
