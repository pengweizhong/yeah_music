/// 有线耳机 / 媒体键连击对应的动作（Android 前台线控）。
enum WireRemoteControlAction {
  playPause,
  next,
  previous,
  none,
}

WireRemoteControlAction wireRemoteActionParse(
  String? raw, {
  required WireRemoteControlAction orElse,
}) {
  if (raw == null || raw.isEmpty) return orElse;
  for (final v in WireRemoteControlAction.values) {
    if (v.name == raw) return v;
  }
  return orElse;
}

/// 单击 / 双击 / 三击 各自映射的动作（常见线控约定）。
class WireRemoteControlConfig {
  const WireRemoteControlConfig({
    required this.enabled,
    required this.singleClick,
    required this.doubleClick,
    required this.tripleClick,
  });

  final bool enabled;
  final WireRemoteControlAction singleClick;
  final WireRemoteControlAction doubleClick;
  final WireRemoteControlAction tripleClick;

  static WireRemoteControlConfig get defaults => const WireRemoteControlConfig(
        enabled: true,
        singleClick: WireRemoteControlAction.playPause,
        doubleClick: WireRemoteControlAction.next,
        tripleClick: WireRemoteControlAction.previous,
      );

  WireRemoteControlConfig copyWith({
    bool? enabled,
    WireRemoteControlAction? singleClick,
    WireRemoteControlAction? doubleClick,
    WireRemoteControlAction? tripleClick,
  }) {
    return WireRemoteControlConfig(
      enabled: enabled ?? this.enabled,
      singleClick: singleClick ?? this.singleClick,
      doubleClick: doubleClick ?? this.doubleClick,
      tripleClick: tripleClick ?? this.tripleClick,
    );
  }

  WireRemoteControlAction actionForClickCount(int n) {
    final c = n.clamp(1, 3);
    return switch (c) {
      1 => singleClick,
      2 => doubleClick,
      _ => tripleClick,
    };
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'singleClick': singleClick.name,
        'doubleClick': doubleClick.name,
        'tripleClick': tripleClick.name,
      };

  factory WireRemoteControlConfig.fromJson(Map<String, dynamic> m) {
    try {
      return WireRemoteControlConfig(
        enabled: m['enabled'] as bool? ?? true,
        singleClick: wireRemoteActionParse(
          m['singleClick'] as String?,
          orElse: WireRemoteControlAction.playPause,
        ),
        doubleClick: wireRemoteActionParse(
          m['doubleClick'] as String?,
          orElse: WireRemoteControlAction.next,
        ),
        tripleClick: wireRemoteActionParse(
          m['tripleClick'] as String?,
          orElse: WireRemoteControlAction.previous,
        ),
      );
    } catch (_) {
      return WireRemoteControlConfig.defaults;
    }
  }

  /// 传给 Android MethodChannel
  Map<String, dynamic> toNativeMap() => {
        'enabled': enabled,
        'singleClick': singleClick.name,
        'doubleClick': doubleClick.name,
        'tripleClick': tripleClick.name,
      };
}
