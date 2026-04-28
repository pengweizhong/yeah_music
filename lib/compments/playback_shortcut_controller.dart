import 'package:flutter/foundation.dart';
import 'package:yeah_music/models/playback_shortcut_config.dart';
import 'package:yeah_music/models/wire_remote_control_config.dart';
import 'package:yeah_music/platform/wire_remote_native.dart';
import 'package:yeah_music/services/settings_service.dart';

class PlaybackShortcutController extends ChangeNotifier {
  PlaybackShortcutConfig _config = PlaybackShortcutConfig.defaults;
  WireRemoteControlConfig _wireRemote = WireRemoteControlConfig.defaults;

  PlaybackShortcutConfig get config => _config;

  WireRemoteControlConfig get wireRemote => _wireRemote;

  Future<void> loadFromStorage() async {
    _config = await SettingsService.loadPlaybackShortcutConfig();
    _wireRemote = await SettingsService.loadWireRemoteControlConfig();
    notifyListeners();
    await WireRemoteNative.configure(_wireRemote);
  }

  Future<void> syncWireRemoteToNative() =>
      WireRemoteNative.configure(_wireRemote);

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

  Future<void> setWireRemote(WireRemoteControlConfig value) async {
    _wireRemote = value;
    await SettingsService.saveWireRemoteControlConfig(_wireRemote);
    notifyListeners();
    await WireRemoteNative.configure(_wireRemote);
  }
}
