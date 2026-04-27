import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/playback_mode.dart';

String playbackModeLabel(PlaybackMode mode, AppLocalizations l10n) {
  switch (mode) {
    case PlaybackMode.sequential:
      return l10n.playbackSequential;
    case PlaybackMode.shuffle:
      return l10n.playbackShuffle;
    case PlaybackMode.singleLoop:
      return l10n.playbackSingleLoop;
    case PlaybackMode.playOnce:
      return l10n.playbackOnce;
    case PlaybackMode.timerShutdown:
      return l10n.playbackTimer;
  }
}
