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
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song_recognition_entry.dart';
import 'package:yeah_music/models/song_recognition_provider.dart';
import 'package:yeah_music/pages/song_recognition_api_config_page.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_backend_factory.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/services/song_recognition_history_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

String _formatSongRecHistoryTime(BuildContext context, DateTime createdAt) {
  final lang = Localizations.localeOf(context).toString();
  return DateFormat('yyyy-MM-dd HH:mm', lang).format(createdAt.toLocal());
}

/// 有曲目标题的匹配结果，在「仅成功」筛选中展示。
bool _songRecEntryIsMatchedHit(SongRecognitionEntry e) {
  return e.status == 'success' &&
      e.title != null &&
      e.title!.trim().isNotEmpty;
}

String _formatSongRecEntryForClipboard(
  AppLocalizations l10n,
  SongRecognitionEntry e,
  String timeLabel,
) {
  final lines = <String>[];
  lines.add('${l10n.songRecognizerCopyLabelTime}$timeLabel');
  final modeLabel = e.mode == SongRecognitionCaptureMode.inApp
      ? l10n.songRecognizerModeInApp
      : l10n.songRecognizerModeAmbient;
  lines.add('${l10n.songRecognizerCopyLabelMode}$modeLabel');
  if (e.provider != null) {
    final p = e.provider == SongRecognitionProvider.audd
        ? l10n.songRecognizerProviderAudd
        : l10n.songRecognizerProviderAcrcloud;
    lines.add('${l10n.songRecognizerCopyLabelService}$p');
  }
  if (_songRecEntryIsMatchedHit(e)) {
    lines.add('${l10n.songRecognizerCopyLabelSong}${e.title!.trim()}');
    final artist = e.artist?.trim();
    if (artist != null && artist.isNotEmpty) {
      lines.add('${l10n.songRecognizerCopyLabelArtist}$artist');
    }
    final album = e.album?.trim();
    if (album != null && album.isNotEmpty) {
      lines.add('${l10n.songRecognizerCopyLabelAlbum}$album');
    }
    final release = e.releaseDate?.trim();
    if (release != null && release.isNotEmpty) {
      lines.add('${l10n.songRecognizerCopyLabelReleased}$release');
    }
    final apple = e.appleMusicUrl?.trim();
    if (apple != null && apple.isNotEmpty) {
      lines.add('${l10n.songRecognizerCopyLabelAppleMusic}$apple');
    }
    final spotify = e.spotifyUrl?.trim();
    if (spotify != null && spotify.isNotEmpty) {
      lines.add('${l10n.songRecognizerCopyLabelSpotify}$spotify');
    }
  } else if (e.status == 'success') {
    lines.add(
      '${l10n.songRecognizerCopyLabelNoMatch}${l10n.songRecognizerNoMatch}',
    );
  } else {
    lines.add(
      '${l10n.songRecognizerCopyLabelError}${e.errorMessage ?? ''}',
    );
  }
  return lines.join('\n');
}

enum _SongRecAppendFlow {
  /// 本条流程结束（含已保存、跳过、未继续链式识别）。
  finished,
  /// 应用内：同一会话内立即再采一轮。
  chainInApp,
  /// 环境聆听：立即再采一轮。
  chainAmbient,
}

enum _SongRecHistoryFilter {
  all,
  matchedOnly,
  archived,
}

/// 听歌识曲：应用内录制 / 环境周期性采样；AudD 或 ACRCloud 策略识别，历史存 Hive。
class MusicRecognitionPage extends StatefulWidget {
  const MusicRecognitionPage({super.key});

  @override
  State<MusicRecognitionPage> createState() => _MusicRecognitionPageState();
}

class _MusicRecognitionPageState extends State<MusicRecognitionPage> {
  static const RecordConfig _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    numChannels: 1,
    bitRate: 128000,
    noiseSuppress: true,
    autoGain: true,
    audioInterruption: AudioInterruptionMode.none,
    iosConfig: IosRecordConfig(
      categoryOptions: [
        IosAudioCategoryOption.mixWithOthers,
        IosAudioCategoryOption.defaultToSpeaker,
        IosAudioCategoryOption.allowBluetooth,
        IosAudioCategoryOption.allowBluetoothA2DP,
      ],
    ),
    androidConfig: AndroidRecordConfig(
      muteAudio: false,
    ),
  );

  final AudioRecorder _recorder = AudioRecorder();

  List<SongRecognitionEntry> _history = [];
  _SongRecHistoryFilter _historyFilter = _SongRecHistoryFilter.all;
  SongRecognitionProvider _provider = SongRecognitionProvider.audd;

  SongRecognitionCaptureMode _mode = SongRecognitionCaptureMode.inApp;

  bool _listening = false;
  bool _recognizing = false;
  bool _ambientOn = false;
  bool _pipelineBusy = false;

  bool _recognitionCancelRequested = false;

  static const String _kRecUserCancelled = 'user_cancelled';

  Timer? _ambientTimer;

  Future<void> _reloadHistory() async {
    final list = await SongRecognitionHistoryService.loadAll();
    if (!mounted) return;
    setState(() => _history = list);
  }

  List<SongRecognitionEntry> get _visibleHistory {
    switch (_historyFilter) {
      case _SongRecHistoryFilter.all:
        return _history;
      case _SongRecHistoryFilter.matchedOnly:
        return _history
            .where(
              (e) => _songRecEntryIsMatchedHit(e) && !e.archived,
            )
            .toList();
      case _SongRecHistoryFilter.archived:
        return _history.where((e) => e.archived).toList();
    }
  }

  String _emptyHistoryHint(AppLocalizations l10n) {
    if (_history.isEmpty) return l10n.songRecognizerHistoryEmpty;
    switch (_historyFilter) {
      case _SongRecHistoryFilter.all:
        return l10n.songRecognizerHistoryEmpty;
      case _SongRecHistoryFilter.matchedOnly:
        return l10n.songRecognizerHistoryEmptyMatched;
      case _SongRecHistoryFilter.archived:
        return l10n.songRecognizerHistoryEmptyArchived;
    }
  }

  void _copyHistoryEntry(SongRecognitionEntry e) {
    final l10n = AppLocalizations.of(context);
    final time = _formatSongRecHistoryTime(context, e.createdAt);
    final text = _formatSongRecEntryForClipboard(l10n, e, time);
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      context,
      l10n.songRecognizerEntryCopied,
      kind: AppSnackKind.success,
    );
  }

  Future<void> _handleHistorySwipe(
    SongRecognitionEntry e,
    DismissDirection direction,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (direction == DismissDirection.endToStart) {
      final go = await showAppConfirmDialog(
        context: context,
        title: l10n.songRecognizerDeleteHistoryEntryTitle,
        message: l10n.songRecognizerDeleteHistoryEntryMessage,
        icon: Icons.delete_outline_rounded,
        cancelLabel: l10n.actionCancel,
        confirmLabel: l10n.actionDelete,
        confirmIsDestructive: true,
      );
      if (go == true && mounted) {
        await SongRecognitionHistoryService.deleteById(e.id);
        await _reloadHistory();
      }
    } else if (direction == DismissDirection.startToEnd) {
      if (e.archived) {
        await SongRecognitionHistoryService.updateEntry(
          e.copyWith(archived: false),
        );
        if (mounted) {
          showAppSnackBar(
            context,
            l10n.songRecognizerEntryRestoredFromArchive,
            kind: AppSnackKind.neutral,
          );
        }
      } else {
        await SongRecognitionHistoryService.updateEntry(
          e.copyWith(archived: true),
        );
        if (mounted) {
          showAppSnackBar(
            context,
            l10n.songRecognizerEntryArchived,
            kind: AppSnackKind.neutral,
          );
        }
      }
      if (mounted) await _reloadHistory();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = await SettingsService.loadSongRecognitionProvider();
      if (!mounted) return;
      setState(() => _provider = p);
      await _reloadHistory();
    });
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    if (_ambientOn) {
      unawaited(WakelockPlus.disable());
    }
    unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<bool> _ensureMic() async {
    if (kIsWeb) return false;
    // macOS / Windows / Linux：permission_handler 往往未接入，由系统与 record 处理首次授权。
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return true;
    }
    try {
      var s = await Permission.microphone.status;
      if (!s.isGranted) {
        s = await Permission.microphone.request();
      }
      return s.isGranted;
    } on MissingPluginException catch (e) {
      appLog.w('permission_handler unavailable, skipping mic pre-check: $e');
      return true;
    }
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  bool get _recognitionOccupied =>
      _pipelineBusy || _ambientOn || _listening || _recognizing;

  void _onPopWhileRecognizingInvoked(bool didPop) {
    if (kIsWeb || didPop) return;
    _recognitionCancelRequested = true;
    unawaited(_recorder.cancel());
    if (_ambientOn) {
      _stopAmbient(suppressCancelSnack: true);
    }
    if (mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context).songRecognizerSnackbarCancelled,
        kind: AppSnackKind.neutral,
      );
    }
  }

  SongRecognitionEntry _userCancelledEntry(SongRecognitionCaptureMode mode) {
    return SongRecognitionEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
      mode: mode,
      provider: _provider,
      status: 'error',
      errorMessage: _kRecUserCancelled,
    );
  }

  Future<void> _activateMixFriendlyCaptureSession() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers |
                  AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.measurement,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
        ),
      );
      await session.setActive(true);
    } catch (e, st) {
      appLog.w('mix-friendly capture session', error: e, stackTrace: st);
    }
  }

  Future<void> _deactivateCaptureSession() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e, st) {
      appLog.w('deactivate capture session', error: e, stackTrace: st);
    }
  }

  bool _isDuplicateCandidate(SongRecognitionEntry e) {
    if (_history.isEmpty) return false;
    final last = _history.first;
    if (e.status != 'success' || last.status != 'success') return false;
    final ta = '${e.title ?? ''}\n${e.artist ?? ''}';
    final tb = '${last.title ?? ''}\n${last.artist ?? ''}';
    if (ta != tb || ta.trim().isEmpty) return false;
    return DateTime.now().difference(last.createdAt) <
        const Duration(minutes: 4);
  }

  Future<SongRecognitionEntry> _captureAndRecognize(
    SongRecognitionCaptureMode mode,
    Duration recordFor,
  ) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'yeah_song_id_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await _activateMixFriendlyCaptureSession();
    try {
      await _recorder.start(_recordConfig, path: path);
      final totalMs = recordFor.inMilliseconds;
      const stepMs = 100;
      var elapsed = 0;
      while (elapsed < totalMs &&
          mounted &&
          !_recognitionCancelRequested) {
        final remaining = totalMs - elapsed;
        final slice = remaining < stepMs ? remaining : stepMs;
        await Future<void>.delayed(Duration(milliseconds: slice));
        elapsed += slice;
      }
      String? outPath;
      try {
        outPath = await _recorder.stop();
      } catch (_) {
        outPath = null;
      }
      if (_recognitionCancelRequested) {
        await _deleteTempFile(outPath ?? path);
        return _userCancelledEntry(mode);
      }
      final file = File(outPath ?? path);
      if (!await file.exists()) {
        await _deleteTempFile(outPath ?? path);
        return SongRecognitionEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          createdAt: DateTime.now(),
          mode: mode,
          provider: _provider,
          status: 'error',
          errorMessage: 'no audio file',
        );
      }
      if (_recognitionCancelRequested) {
        await _deleteTempFile(file.path);
        return _userCancelledEntry(mode);
      }
      try {
        final auddTok = await SettingsService.loadAuddApiToken();
        final acrConfig = await SettingsService.loadAcrCloudRecognitionConfig();
        final backend = MusicRecognitionBackendFactory.create(
          provider: _provider,
          auddApiToken: auddTok,
          acrCloudConfig: acrConfig,
        );
        final outcome = await backend.recognizeFile(file);
        await _deleteTempFile(file.path);
        if (_recognitionCancelRequested) {
          return _userCancelledEntry(mode);
        }
        final id = '${DateTime.now().microsecondsSinceEpoch}';
        if (outcome.isSuccess) {
          return SongRecognitionEntry(
            id: id,
            createdAt: DateTime.now(),
            mode: mode,
            provider: _provider,
            title: outcome.title,
            artist: outcome.artist,
            album: outcome.album,
            releaseDate: outcome.releaseDate,
            appleMusicUrl: outcome.appleMusicUrl,
            spotifyUrl: outcome.spotifyUrl,
            status: 'success',
          );
        }
        if (outcome.isNoMatch) {
          return SongRecognitionEntry(
            id: id,
            createdAt: DateTime.now(),
            mode: mode,
            provider: _provider,
            status: 'success',
            errorMessage: 'no_match',
          );
        }
        return SongRecognitionEntry(
          id: id,
          createdAt: DateTime.now(),
          mode: mode,
          provider: _provider,
          status: 'error',
          errorMessage: outcome.errorMessage ?? outcome.rawStatus,
        );
      } catch (e, st) {
        appLog.e('recognition pipeline', error: e, stackTrace: st);
        await _deleteTempFile(file.path);
        return SongRecognitionEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          createdAt: DateTime.now(),
          mode: mode,
          provider: _provider,
          status: 'error',
          errorMessage: e.toString(),
        );
      }
    } finally {
      await _deactivateCaptureSession();
    }
  }

  Future<void> _runInAppOnce() async {
    final l10n = AppLocalizations.of(context);
    if (kIsWeb) {
      showAppSnackBar(
        context,
        l10n.songRecognizerWebUnsupported,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (_pipelineBusy) return;
    _recognitionCancelRequested = false;
    if (_provider == SongRecognitionProvider.acrcloud) {
      final acr = await SettingsService.loadAcrCloudRecognitionConfig();
      if (!acr.isComplete) {
        if (mounted) {
          showAppSnackBar(
            context,
            l10n.songRecognizerAcrIncomplete,
            kind: AppSnackKind.error,
          );
        }
        return;
      }
    }
    if (!await _ensureMic()) {
      if (mounted) {
        showAppSnackBar(
          context,
          l10n.songRecognizerMicDenied,
          kind: AppSnackKind.error,
        );
      }
      return;
    }
    setState(() {
      _pipelineBusy = true;
    });
    if (mounted) {
      showAppSnackBar(
        context,
        l10n.songRecognizerSnackbarStarted,
        kind: AppSnackKind.neutral,
      );
    }
    try {
      while (mounted) {
        setState(() {
          _listening = true;
          _recognizing = false;
        });
        final entry = await _captureAndRecognize(
          SongRecognitionCaptureMode.inApp,
          const Duration(seconds: 10),
        );
        if (!mounted) return;
        if (entry.errorMessage == _kRecUserCancelled ||
            _recognitionCancelRequested) {
          break;
        }
        setState(() {
          _listening = false;
          _recognizing = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        setState(() => _recognizing = false);
        if (_recognitionCancelRequested) break;
        final flow = await _appendEntry(context, entry);
        if (!mounted) return;
        if (flow != _SongRecAppendFlow.chainInApp) break;
      }
    } finally {
      _recognitionCancelRequested = false;
      if (mounted) {
        setState(() {
          _pipelineBusy = false;
          _listening = false;
          _recognizing = false;
        });
      }
    }
  }

  Future<bool?> _showSongMatchConfirmDialog(
    BuildContext context,
    SongRecognitionEntry e,
  ) {
    final l10n = AppLocalizations.of(context);
    final titleText = e.title!.trim();
    final artist = e.artist?.trim();
    final album = e.album?.trim();
    final release = e.releaseDate?.trim();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: Text(l10n.songRecognizerMatchConfirmTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (artist != null && artist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '${l10n.songRecognizerMatchConfirmArtistLabel}: $artist',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                if (album != null && album.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${l10n.songRecognizerMatchConfirmAlbumLabel}: $album',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                if (release != null && release.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${l10n.songRecognizerMatchConfirmReleaseLabel}: $release',
                      style: textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.songRecognizerMatchConfirmNo),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.songRecognizerMatchConfirmYes),
            ),
          ],
        );
      },
    );
  }

  Future<_SongRecAppendFlow> _appendEntry(
    BuildContext context,
    SongRecognitionEntry e,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (e.status == 'error') {
      if (e.errorMessage == _kRecUserCancelled) {
        return _SongRecAppendFlow.finished;
      }
      if (!mounted) return _SongRecAppendFlow.finished;
      showAppSnackBar(
        context,
        '${l10n.songRecognizerError}: ${e.errorMessage ?? ''}',
        kind: AppSnackKind.error,
      );
      await SongRecognitionHistoryService.prepend(e);
      await _reloadHistory();
      return _SongRecAppendFlow.finished;
    }

    final hasTitle = e.title != null && e.title!.trim().isNotEmpty;
    if (!hasTitle) {
      if (!mounted) return _SongRecAppendFlow.finished;
      showAppSnackBar(
        context,
        l10n.songRecognizerNoMatch,
        kind: AppSnackKind.neutral,
      );
      await SongRecognitionHistoryService.prepend(e);
      await _reloadHistory();
      return _SongRecAppendFlow.finished;
    }

    if (_isDuplicateCandidate(e)) {
      if (!mounted) return _SongRecAppendFlow.finished;
      showAppSnackBar(
        context,
        l10n.songRecognizerDuplicateSkipped,
        kind: AppSnackKind.neutral,
      );
      await _reloadHistory();
      return _SongRecAppendFlow.finished;
    }
    if (!mounted) return _SongRecAppendFlow.finished;
    final confirm = await _showSongMatchConfirmDialog(context, e);
    if (!mounted) return _SongRecAppendFlow.finished;
    if (confirm != true) {
      if (confirm == false) {
        return e.mode == SongRecognitionCaptureMode.inApp
            ? _SongRecAppendFlow.chainInApp
            : _SongRecAppendFlow.chainAmbient;
      }
      return _SongRecAppendFlow.finished;
    }
    await SongRecognitionHistoryService.prepend(e);
    await _reloadHistory();
    if (e.mode == SongRecognitionCaptureMode.ambient) {
      _stopAmbient(suppressCancelSnack: true);
    }
    if (!context.mounted) return _SongRecAppendFlow.finished;
    showAppSnackBar(
      context,
      e.title ?? l10n.songRecognizerTitle,
      kind: AppSnackKind.success,
    );
    return _SongRecAppendFlow.finished;
  }

  void _stopAmbient({bool suppressCancelSnack = false}) {
    final wasOn = _ambientOn;
    _ambientTimer?.cancel();
    _ambientTimer = null;
    if (_ambientOn) {
      unawaited(WakelockPlus.disable());
    }
    setState(() {
      _ambientOn = false;
      _pipelineBusy = false;
    });
    if (wasOn && mounted && !suppressCancelSnack) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context).songRecognizerSnackbarCancelled,
        kind: AppSnackKind.neutral,
      );
    }
  }

  void _startAmbient() {
    final l10n = AppLocalizations.of(context);
    if (kIsWeb) {
      showAppSnackBar(
        context,
        l10n.songRecognizerWebUnsupported,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    unawaited(() async {
      if (_provider == SongRecognitionProvider.acrcloud) {
        final acr = await SettingsService.loadAcrCloudRecognitionConfig();
        if (!acr.isComplete) {
          if (mounted) {
            showAppSnackBar(
              context,
              l10n.songRecognizerAcrIncomplete,
              kind: AppSnackKind.error,
            );
          }
          return;
        }
      }
      if (!await _ensureMic()) {
        if (mounted) {
          showAppSnackBar(
            context,
            l10n.songRecognizerMicDenied,
            kind: AppSnackKind.error,
          );
        }
        return;
      }
      if (!mounted) return;
      await WakelockPlus.enable();
      if (!mounted) return;
      setState(() {
        _ambientOn = true;
        _recognitionCancelRequested = false;
      });
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.songRecognizerAmbientActive,
        kind: AppSnackKind.neutral,
      );
      _ambientTimer = Timer.periodic(const Duration(seconds: 22), (_) {
        unawaited(_ambientTick());
      });
      unawaited(_ambientTick());
    }());
  }

  Future<void> _ambientTick() async {
    if (!_ambientOn || _pipelineBusy) return;
    if (kIsWeb) return;
    final ok = await _ensureMic();
    if (!ok || !_ambientOn) return;
    setState(() => _pipelineBusy = true);
    try {
      while (mounted && _ambientOn) {
        final entry = await _captureAndRecognize(
          SongRecognitionCaptureMode.ambient,
          const Duration(seconds: 12),
        );
        if (!mounted || !_ambientOn) return;
        if (entry.errorMessage == _kRecUserCancelled ||
            _recognitionCancelRequested) {
          break;
        }
        final flow = await _appendEntry(context, entry);
        if (!mounted || !_ambientOn) return;
        if (flow != _SongRecAppendFlow.chainAmbient) break;
      }
    } finally {
      _recognitionCancelRequested = false;
      if (mounted) {
        setState(() => _pipelineBusy = false);
      }
    }
  }

  Future<void> _openApiConfigPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const SongRecognitionApiConfigPage(),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final go = await showAppConfirmDialog(
      context: context,
      title: l10n.songRecognizerClearHistory,
      message: l10n.songRecognizerClearHistoryConfirm,
      icon: Icons.delete_outline_rounded,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionDelete,
      confirmIsDestructive: true,
    );
    if (go == true && mounted) {
      await SongRecognitionHistoryService.clear();
      await _reloadHistory();
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final u = Uri.tryParse(url.trim());
    if (u == null) return;
    if (!await canLaunchUrl(u)) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final segStyle = SegmentedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: PopScope(
            canPop: kIsWeb || !_recognitionOccupied,
            onPopInvokedWithResult: (didPop, result) {
              _onPopWhileRecognizingInvoked(didPop);
            },
            child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.songRecognizerTitle,
                style: TextStyle(color: context.gradFg(0.95)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
              actions: [
                IconButton(
                  tooltip: l10n.songRecognizerSectionApiConfig,
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openApiConfigPage,
                ),
                IconButton(
                  tooltip: l10n.songRecognizerClearHistory,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _history.isEmpty ? null : _confirmClear,
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: context.gradFg(0.45),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.songRecognizerAccuracyTip,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.22,
                                color: context.gradFg(0.55),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<SongRecognitionProvider>(
                        style: segStyle,
                        segments: [
                          ButtonSegment(
                            value: SongRecognitionProvider.audd,
                            label: Text(
                              l10n.songRecognizerProviderAudd,
                              style: const TextStyle(fontSize: 13),
                            ),
                            icon: const Icon(Icons.equalizer_rounded, size: 17),
                          ),
                          ButtonSegment(
                            value: SongRecognitionProvider.acrcloud,
                            label: Text(
                              l10n.songRecognizerProviderAcrcloud,
                              style: const TextStyle(fontSize: 13),
                            ),
                            icon: const Icon(Icons.cloud_queue_rounded, size: 17),
                          ),
                        ],
                        selected: {_provider},
                        onSelectionChanged: (s) {
                          if (_ambientOn || _listening || _pipelineBusy) {
                            return;
                          }
                          final next = s.first;
                          setState(() => _provider = next);
                          unawaited(
                            SettingsService.saveSongRecognitionProvider(next),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openApiConfigPage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.vpn_key_rounded,
                                  size: 17,
                                  color: context.gradFg(0.68),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.songRecognizerSectionApiConfig,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.gradFg(0.88),
                                        ),
                                      ),
                                      Text(
                                        l10n.songRecognizerOpenApiConfigSubtitle,
                                        style: TextStyle(
                                          fontSize: 10,
                                          height: 1.2,
                                          color: context.gradFg(0.45),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: context.gradFg(0.38),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SegmentedButton<SongRecognitionCaptureMode>(
                        style: segStyle,
                        segments: [
                          ButtonSegment(
                            value: SongRecognitionCaptureMode.inApp,
                            label: Text(
                              l10n.songRecognizerModeInApp,
                              style: const TextStyle(fontSize: 13),
                            ),
                            icon: const Icon(Icons.graphic_eq_rounded, size: 17),
                          ),
                          ButtonSegment(
                            value: SongRecognitionCaptureMode.ambient,
                            label: Text(
                              l10n.songRecognizerModeAmbient,
                              style: const TextStyle(fontSize: 13),
                            ),
                            icon: const Icon(Icons.hearing_rounded, size: 17),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (s) {
                          if (_ambientOn || _listening || _pipelineBusy) {
                            return;
                          }
                          setState(() => _mode = s.first);
                        },
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _mode == SongRecognitionCaptureMode.inApp
                            ? l10n.songRecognizerModeInAppHelp
                            : l10n.songRecognizerModeAmbientHelp,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.25,
                          color: context.gradFg(0.48),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      if (_mode == SongRecognitionCaptureMode.inApp)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_listening || _recognizing)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          color: context.gradFg(0.9),
                                          strokeWidth: 2.8,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _listening
                                            ? l10n.songRecognizerListening
                                            : l10n.songRecognizerRecognizing,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.gradFg(0.82),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              FilledButton.icon(
                                onPressed:
                                    _pipelineBusy || kIsWeb ? null : _runInAppOnce,
                                icon: const Icon(Icons.mic_rounded),
                                label: Text(l10n.songRecognizerStart),
                              ),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: FilledButton.tonalIcon(
                            onPressed: kIsWeb
                                ? null
                                : (_ambientOn ? _stopAmbient : _startAmbient),
                            icon: Icon(
                              _ambientOn
                                  ? Icons.stop_rounded
                                  : Icons.sensors_rounded,
                            ),
                            label: Text(
                              _ambientOn
                                  ? l10n.songRecognizerStopAmbient
                                  : l10n.songRecognizerModeAmbient,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: context.gradFg(0.1)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.songRecognizerHistory,
                            style: TextStyle(
                              color: context.gradFg(0.92),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_pipelineBusy && _ambientOn)
                            Text(
                              l10n.songRecognizerRecognizing,
                              style: TextStyle(
                                color: context.gradFg(0.5),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<_SongRecHistoryFilter>(
                        style: segStyle,
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: _SongRecHistoryFilter.all,
                            label: Text(
                              l10n.songRecognizerHistoryFilterAll,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: _SongRecHistoryFilter.matchedOnly,
                            label: Text(
                              l10n.songRecognizerHistoryFilterMatched,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: _SongRecHistoryFilter.archived,
                            label: Text(
                              l10n.songRecognizerHistoryFilterArchived,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {_historyFilter},
                        onSelectionChanged: (s) {
                          setState(() => _historyFilter = s.first);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _visibleHistory.isEmpty ? 1 : _visibleHistory.length,
                    itemBuilder: (context, index) {
                      if (_visibleHistory.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              _emptyHistoryHint(l10n),
                              style: TextStyle(
                                color: context.gradFg(0.45),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      final e = _visibleHistory[index];
                      return Dismissible(
                        key: ValueKey('songrec_${e.id}_${e.archived}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                e.archived
                                    ? Icons.star_outline_rounded
                                    : Icons.star_rounded,
                                color: context.gradFg(0.95),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e.archived
                                    ? l10n.songRecognizerSwipeRestore
                                    : l10n.songRecognizerSwipeArchive,
                                style: TextStyle(
                                  color: context.gradFg(0.95),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                l10n.songRecognizerSwipeDelete,
                                style: TextStyle(
                                  color: context.gradFg(0.95),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.delete_outline_rounded,
                                color: context.gradFg(0.95),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          await _handleHistorySwipe(e, direction);
                          return false;
                        },
                        child: _HistoryTile(
                          entry: e,
                          l10n: l10n,
                          timeLabel: _formatSongRecHistoryTime(
                            context,
                            e.createdAt,
                          ),
                          onOpenApple: () => _openUrl(e.appleMusicUrl),
                          onOpenSpotify: () => _openUrl(e.spotifyUrl),
                          onCopy: () => _copyHistoryEntry(e),
                          fg: context.gradFg,
                          fgMuted: context.gradFgMuted,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.l10n,
    required this.timeLabel,
    required this.onOpenApple,
    required this.onOpenSpotify,
    required this.onCopy,
    required this.fg,
    required this.fgMuted,
  });

  final SongRecognitionEntry entry;
  final AppLocalizations l10n;
  final String timeLabel;
  final VoidCallback onOpenApple;
  final VoidCallback onOpenSpotify;
  final VoidCallback onCopy;
  final Color Function([double opacity]) fg;
  final Color Function([double opacity]) fgMuted;

  @override
  Widget build(BuildContext context) {
    final modeLabel = entry.mode == SongRecognitionCaptureMode.inApp
        ? l10n.songRecognizerModeInApp
        : l10n.songRecognizerModeAmbient;
    final copyButton = IconButton(
      tooltip: l10n.songRecognizerCopyEntry,
      onPressed: onCopy,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
      icon: Icon(Icons.copy_rounded, size: 20, color: fg(0.52)),
    );
    final hasArtist =
        entry.artist != null && entry.artist!.trim().isNotEmpty;
    final hasAlbum = entry.album != null && entry.album!.trim().isNotEmpty;
    final hasApple =
        entry.appleMusicUrl != null && entry.appleMusicUrl!.trim().isNotEmpty;
    final hasSpotify =
        entry.spotifyUrl != null && entry.spotifyUrl!.trim().isNotEmpty;
    final hasLinks = hasApple || hasSpotify;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: fg(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    timeLabel,
                    style: TextStyle(color: fgMuted(0.85), fontSize: 12),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (entry.provider != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: fg(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.provider == SongRecognitionProvider.audd
                              ? l10n.songRecognizerProviderAudd
                              : l10n.songRecognizerProviderAcrcloud,
                          style: TextStyle(color: fg(0.72), fontSize: 11),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: fg(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        modeLabel,
                        style: TextStyle(color: fg(0.8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_songRecEntryIsMatchedHit(entry)) ...[
              const SizedBox(height: 8),
              if (!hasArtist && !hasAlbum && !hasLinks)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg(0.95),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    copyButton,
                  ],
                )
              else
                Text(
                  entry.title!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg(0.95),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (hasArtist) ...[
                if (!hasAlbum && !hasLinks)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.artist!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg(0.74), fontSize: 14),
                        ),
                      ),
                      copyButton,
                    ],
                  )
                else
                  Text(
                    entry.artist!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg(0.74), fontSize: 14),
                  ),
              ],
              if (hasAlbum) ...[
                if (!hasLinks)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.album!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fgMuted(0.9), fontSize: 13),
                        ),
                      ),
                      copyButton,
                    ],
                  )
                else
                  Text(
                    entry.album!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fgMuted(0.9), fontSize: 13),
                  ),
              ],
              if (hasLinks) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (hasApple)
                            ActionChip(
                              label: Text(l10n.songRecognizerOpenAppleMusic),
                              onPressed: onOpenApple,
                            ),
                          if (hasSpotify)
                            ActionChip(
                              label: Text(l10n.songRecognizerOpenSpotify),
                              onPressed: onOpenSpotify,
                            ),
                        ],
                      ),
                    ),
                    copyButton,
                  ],
                ),
              ],
            ] else if (entry.status == 'success') ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.songRecognizerNoMatch,
                      style: TextStyle(color: fgMuted(0.9)),
                    ),
                  ),
                  copyButton,
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.songRecognizerError}: ${entry.errorMessage ?? ''}',
                      style: TextStyle(color: fg(0.75)),
                    ),
                  ),
                  copyButton,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
