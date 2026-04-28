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

/// 有线 / 蓝牙耳机的媒体键映射。
///
/// - [singleClick]、[doubleClick]、[tripleClick]：同一颗「播放/暂停」或线控键的**连击**（部分蓝牙会改为发独立 NEXT 键，见下）。
/// - [mediaNextKeyAction]、[mediaPreviousKeyAction]：系统上报的**独立**「下一曲」「上一曲」（蓝牙耳机常见）。
class WireRemoteControlConfig {
  const WireRemoteControlConfig({
    required this.enabled,
    required this.singleClick,
    required this.doubleClick,
    required this.tripleClick,
    required this.mediaNextKeyAction,
    required this.mediaPreviousKeyAction,
  });

  final bool enabled;
  final WireRemoteControlAction singleClick;
  final WireRemoteControlAction doubleClick;
  final WireRemoteControlAction tripleClick;

  /// 蓝牙等发送的 [KeyEvent.KEYCODE_MEDIA_NEXT] / 快进 等。
  final WireRemoteControlAction mediaNextKeyAction;

  /// 蓝牙等发送的 [KeyEvent.KEYCODE_MEDIA_PREVIOUS] / 快退 等。
  final WireRemoteControlAction mediaPreviousKeyAction;

  static WireRemoteControlConfig get defaults => const WireRemoteControlConfig(
        enabled: true,
        singleClick: WireRemoteControlAction.playPause,
        doubleClick: WireRemoteControlAction.next,
        tripleClick: WireRemoteControlAction.previous,
        mediaNextKeyAction: WireRemoteControlAction.next,
        mediaPreviousKeyAction: WireRemoteControlAction.previous,
      );

  WireRemoteControlConfig copyWith({
    bool? enabled,
    WireRemoteControlAction? singleClick,
    WireRemoteControlAction? doubleClick,
    WireRemoteControlAction? tripleClick,
    WireRemoteControlAction? mediaNextKeyAction,
    WireRemoteControlAction? mediaPreviousKeyAction,
  }) {
    return WireRemoteControlConfig(
      enabled: enabled ?? this.enabled,
      singleClick: singleClick ?? this.singleClick,
      doubleClick: doubleClick ?? this.doubleClick,
      tripleClick: tripleClick ?? this.tripleClick,
      mediaNextKeyAction: mediaNextKeyAction ?? this.mediaNextKeyAction,
      mediaPreviousKeyAction:
          mediaPreviousKeyAction ?? this.mediaPreviousKeyAction,
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
        'mediaNextKeyAction': mediaNextKeyAction.name,
        'mediaPreviousKeyAction': mediaPreviousKeyAction.name,
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
        mediaNextKeyAction: wireRemoteActionParse(
          m['mediaNextKeyAction'] as String?,
          orElse: WireRemoteControlAction.next,
        ),
        mediaPreviousKeyAction: wireRemoteActionParse(
          m['mediaPreviousKeyAction'] as String?,
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
        'mediaNextKeyAction': mediaNextKeyAction.name,
        'mediaPreviousKeyAction': mediaPreviousKeyAction.name,
      };
}
