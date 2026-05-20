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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 单条快捷键：启用时可带 [SingleActivator]；关闭时 [activator] 为 null。
class PlaybackShortcutBinding {
  const PlaybackShortcutBinding({
    required this.enabled,
    required this.activator,
  });

  const PlaybackShortcutBinding.disabled()
      : enabled = false,
        activator = null;

  final bool enabled;
  final SingleActivator? activator;

  bool triggers(KeyDownEvent event) {
    if (!enabled || activator == null) return false;
    return activator!.accepts(event, HardwareKeyboard.instance);
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (enabled && activator != null) ..._activatorToJson(activator!),
      };

  static Map<String, dynamic> _activatorToJson(SingleActivator a) => {
        'keyId': a.trigger.keyId,
        'control': a.control,
        'meta': a.meta,
        'alt': a.alt,
        'shift': a.shift,
      };

  factory PlaybackShortcutBinding.fromJson(Map<String, dynamic>? m) {
    if (m == null) return const PlaybackShortcutBinding.disabled();
    final enabled = m['enabled'] as bool? ?? false;
    if (!enabled) return const PlaybackShortcutBinding.disabled();
    final keyId = m['keyId'] as int?;
    if (keyId == null) return const PlaybackShortcutBinding.disabled();
    final trigger =
        LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(keyId);
    return PlaybackShortcutBinding(
      enabled: true,
      activator: SingleActivator(
        trigger,
        control: m['control'] == true,
        meta: m['meta'] == true,
        alt: m['alt'] == true,
        shift: m['shift'] == true,
      ),
    );
  }

  String describeKeys() {
    if (!enabled || activator == null) return '';
    return activator!.debugDescribeKeys();
  }

  static PlaybackShortcutBinding defaultPlayPause() => PlaybackShortcutBinding(
        enabled: true,
        activator: const SingleActivator(LogicalKeyboardKey.mediaPlayPause),
      );

  static PlaybackShortcutBinding defaultNext() => PlaybackShortcutBinding(
        enabled: true,
        activator: const SingleActivator(LogicalKeyboardKey.mediaTrackNext),
      );

  static PlaybackShortcutBinding defaultPrevious() => PlaybackShortcutBinding(
        enabled: true,
        activator: const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious),
      );
}

/// 播放控制全局快捷键（桌面端）。
class PlaybackShortcutConfig {
  const PlaybackShortcutConfig({
    required this.playPause,
    required this.next,
    required this.previous,
  });

  final PlaybackShortcutBinding playPause;
  final PlaybackShortcutBinding next;
  final PlaybackShortcutBinding previous;

  static PlaybackShortcutConfig get defaults => PlaybackShortcutConfig(
        playPause: PlaybackShortcutBinding.defaultPlayPause(),
        next: PlaybackShortcutBinding.defaultNext(),
        previous: PlaybackShortcutBinding.defaultPrevious(),
      );

  PlaybackShortcutConfig copyWith({
    PlaybackShortcutBinding? playPause,
    PlaybackShortcutBinding? next,
    PlaybackShortcutBinding? previous,
  }) {
    return PlaybackShortcutConfig(
      playPause: playPause ?? this.playPause,
      next: next ?? this.next,
      previous: previous ?? this.previous,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'playPause': playPause.toJson(),
        'next': next.toJson(),
        'previous': previous.toJson(),
      };

  factory PlaybackShortcutConfig.fromJson(Map<String, dynamic> m) {
    try {
      return PlaybackShortcutConfig(
        playPause: PlaybackShortcutBinding.fromJson(
          m['playPause'] as Map<String, dynamic>?,
        ),
        next: PlaybackShortcutBinding.fromJson(
          m['next'] as Map<String, dynamic>?,
        ),
        previous: PlaybackShortcutBinding.fromJson(
          m['previous'] as Map<String, dynamic>?,
        ),
      );
    } catch (_) {
      return PlaybackShortcutConfig.defaults;
    }
  }
}

enum PlaybackShortcutKind { playPause, next, previous }
