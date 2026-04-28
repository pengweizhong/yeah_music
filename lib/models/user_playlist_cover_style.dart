import 'package:flutter/material.dart';

/// 首页 / 编辑面板共用的预设渐变（未自定义时使用列表序号循环）。
const List<List<Color>> kDefaultPlaylistCoverGradients = [
  [Color(0xFF1A237E), Color(0xFF3949AB)],
  [Color(0xFF004D40), Color(0xFF00695C)],
  [Color(0xFF4A148C), Color(0xFF6A1B9A)],
  [Color(0xFFBF360C), Color(0xFFE64A19)],
];

/// 编辑面板可选的额外渐变预设。
const List<List<Color>> kPlaylistCoverExtendedGradients = [
  [Color(0xFF263238), Color(0xFF455A64)],
  [Color(0xFF880E4F), Color(0xFFC2185B)],
  [Color(0xFF004D40), Color(0xFF00897B)],
  [Color(0xFFE65100), Color(0xFFFF9800)],
  [Color(0xFF01579B), Color(0xFF039BE5)],
  [Color(0xFF33691E), Color(0xFF689F38)],
];

/// 歌单封面（纯色或双色渐变），持久化于 Hive；`null` 表示沿用首页默认轮换渐变。
@immutable
class UserPlaylistCoverStyle {
  const UserPlaylistCoverStyle._(this._c1, this._c2);

  /// 单色填充。
  factory UserPlaylistCoverStyle.solid(Color c) =>
      UserPlaylistCoverStyle._(c.toARGB32(), null);

  /// 左上→右下线性渐变。
  factory UserPlaylistCoverStyle.gradient(Color a, Color b) =>
      UserPlaylistCoverStyle._(a.toARGB32(), b.toARGB32());

  final int _c1;
  final int? _c2;

  bool get isSolid => _c2 == null;

  Color get solidColor => Color(_c1);

  List<Color> get gradientColors =>
      [Color(_c1), Color(_c2!)];

  /// 自存储 map 解析；非法或缺失返回 `null`（表示使用默认轮换色）。
  static UserPlaylistCoverStyle? tryParse(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final t = m['t'] as String?;
    if (t == 'sol') {
      final c = m['c'];
      if (c is int) {
        return UserPlaylistCoverStyle._(c, null);
      }
    }
    if (t == 'grad') {
      final c1 = m['c1'];
      final c2 = m['c2'];
      if (c1 is int && c2 is int) {
        return UserPlaylistCoverStyle._(c1, c2);
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    if (_c2 == null) {
      return {'t': 'sol', 'c': _c1};
    }
    return {'t': 'grad', 'c1': _c1, 'c2': _c2};
  }

  @override
  bool operator ==(Object other) =>
      other is UserPlaylistCoverStyle &&
      other._c1 == _c1 &&
      other._c2 == _c2;

  @override
  int get hashCode => Object.hash(_c1, _c2);
}

List<BoxShadow> playlistCoverCardShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

/// [coverStyle] 为 `null` 时使用 [fallbackGradientIndex] 对应预设渐变。
BoxDecoration playlistCoverCardDecoration({
  required UserPlaylistCoverStyle? coverStyle,
  required int fallbackGradientIndex,
  double radius = 16,
}) {
  final gradients = kDefaultPlaylistCoverGradients;
  final i = fallbackGradientIndex % gradients.length;
  final fallback = gradients[i];

  if (coverStyle == null) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: fallback,
      ),
      boxShadow: playlistCoverCardShadows(),
    );
  }
  if (coverStyle.isSolid) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: coverStyle.solidColor,
      boxShadow: playlistCoverCardShadows(),
    );
  }
  final g = coverStyle.gradientColors;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: g,
    ),
    boxShadow: playlistCoverCardShadows(),
  );
}

BoxDecoration playlistCoverPreviewDecoration({
  required UserPlaylistCoverStyle? coverStyle,
  required int fallbackGradientIndex,
  double radius = 12,
}) =>
    playlistCoverCardDecoration(
      coverStyle: coverStyle,
      fallbackGradientIndex: fallbackGradientIndex,
      radius: radius,
    );
