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
import 'package:yeah_music/widgets/playback_sound_custom_eq_sheet.dart';

const List<PlaybackSoundPreset> kPlaybackSoundPresetOrder = [
  PlaybackSoundPreset.standard,
  PlaybackSoundPreset.pureVocals,
  PlaybackSoundPreset.podcastVoice,
  PlaybackSoundPreset.spatialWide,
  PlaybackSoundPreset.rock,
  PlaybackSoundPreset.metal,
  PlaybackSoundPreset.pop,
  PlaybackSoundPreset.hipHop,
  PlaybackSoundPreset.electronic,
  PlaybackSoundPreset.classical,
  PlaybackSoundPreset.jazz,
  PlaybackSoundPreset.liveStage,
  PlaybackSoundPreset.cozyRoom,
  PlaybackSoundPreset.loFi,
  PlaybackSoundPreset.nightComfort,
  PlaybackSoundPreset.bassBoost,
  PlaybackSoundPreset.custom,
];

String playbackSoundPresetTitle(
  PlaybackSoundPreset preset,
  AppLocalizations l10n,
) {
  switch (preset) {
    case PlaybackSoundPreset.standard:
      return l10n.playbackSoundPresetStandard;
    case PlaybackSoundPreset.pureVocals:
      return l10n.playbackSoundPresetPureVocals;
    case PlaybackSoundPreset.podcastVoice:
      return l10n.playbackSoundPresetPodcast;
    case PlaybackSoundPreset.spatialWide:
      return l10n.playbackSoundPresetSpatialWide;
    case PlaybackSoundPreset.rock:
      return l10n.playbackSoundPresetRock;
    case PlaybackSoundPreset.metal:
      return l10n.playbackSoundPresetMetal;
    case PlaybackSoundPreset.pop:
      return l10n.playbackSoundPresetPop;
    case PlaybackSoundPreset.hipHop:
      return l10n.playbackSoundPresetHipHop;
    case PlaybackSoundPreset.electronic:
      return l10n.playbackSoundPresetElectronic;
    case PlaybackSoundPreset.classical:
      return l10n.playbackSoundPresetClassical;
    case PlaybackSoundPreset.jazz:
      return l10n.playbackSoundPresetJazz;
    case PlaybackSoundPreset.liveStage:
      return l10n.playbackSoundPresetLiveStage;
    case PlaybackSoundPreset.cozyRoom:
      return l10n.playbackSoundPresetCozyRoom;
    case PlaybackSoundPreset.loFi:
      return l10n.playbackSoundPresetLoFi;
    case PlaybackSoundPreset.nightComfort:
      return l10n.playbackSoundPresetNight;
    case PlaybackSoundPreset.bassBoost:
      return l10n.playbackSoundPresetBassBoost;
    case PlaybackSoundPreset.custom:
      return l10n.playbackSoundPresetCustom;
  }
}

/// 播放页「更多」内打开的音效预设底部面板。
Future<void> showPlaybackSoundPresetSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FrostedGlassBottomSheet(
          child: SafeArea(
            top: false,
            child: const _PlaybackSoundPresetBody(),
          ),
        ),
      );
    },
  );
}

class _PlaybackSoundPresetBody extends StatefulWidget {
  const _PlaybackSoundPresetBody();

  @override
  State<_PlaybackSoundPresetBody> createState() =>
      _PlaybackSoundPresetBodyState();
}

class _PlaybackSoundPresetBodyState extends State<_PlaybackSoundPresetBody> {
  late Future<PlaybackSoundPreset> _load;

  @override
  void initState() {
    super.initState();
    _load = SettingsService.loadPlaybackSoundPreset();
  }

  Future<void> _select(PlaybackSoundPreset preset) async {
    await SettingsService.savePlaybackSoundPreset(preset);
    await PlaybackSoundEffectService.applyPreset(
      preset,
      equalizer: MusicService.androidEqualizer,
      loudness: MusicService.androidLoudnessEnhancer,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openCustomEditor() async {
    await showPlaybackSoundCustomEqSheet(context);
    if (mounted) {
      setState(() {
        _load = SettingsService.loadPlaybackSoundPreset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxSheetH = MediaQuery.sizeOf(context).height * 0.88;
    return FutureBuilder<PlaybackSoundPreset>(
      future: _load,
      builder: (context, snap) {
        final current = snap.data;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  l10n.playbackSoundPresetSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.playbackSoundPresetUnsupportedBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.gradFg(0.62),
                        ),
                  ),
                ),
              if (current == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: kPlaybackSoundPresetOrder.length,
                    itemBuilder: (context, index) {
                      final p = kPlaybackSoundPresetOrder[index];
                      if (p == PlaybackSoundPreset.custom) {
                        return ListTile(
                          leading: const Icon(Icons.tune_rounded),
                          title: Text(playbackSoundPresetTitle(p, l10n)),
                          subtitle: Text(
                            l10n.playbackSoundCustomTileSubtitle,
                          ),
                          trailing: current == p
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: _openCustomEditor,
                        );
                      }
                      return ListTile(
                        leading: Icon(
                          p == PlaybackSoundPreset.standard
                              ? Icons.graphic_eq_outlined
                              : Icons.equalizer_rounded,
                        ),
                        title: Text(playbackSoundPresetTitle(p, l10n)),
                        trailing: current == p
                            ? Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => _select(p),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
