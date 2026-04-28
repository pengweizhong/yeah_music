import 'package:flutter/foundation.dart';
import 'package:yeah_music/models/playback_shortcut_config.dart';
import 'package:yeah_music/services/settings_service.dart';

class PlaybackShortcutController extends ChangeNotifier {
  PlaybackShortcutConfig _config = PlaybackShortcutConfig.defaults;

  PlaybackShortcutConfig get config => _config;

  Future<void> loadFromStorage() async {
    _config = await SettingsService.loadPlaybackShortcutConfig();
    notifyListeners();
  }

  Future<void> setBinding(
    PlaybackShortcutKind kind,
    PlaybackShortcutBinding binding,
  ) async {
    _config = switch (kind) {
      PlaybackShortcutKind.playPause => _config.copyWith(playPause: binding),
      PlaybackShortcutKind.next => _config.copyWith(next: binding),
      PlaybackShortcutKind.previous =>
        _config.copyWith(previous: binding),
    };
    await SettingsService.savePlaybackShortcutConfig(_config);
    notifyListeners();
  }
}
