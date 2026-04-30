import 'dart:io';

import 'package:flutter/material.dart';

/// 封面双色线性渐变的方向（与存储中的 `dir` 序号一致）。
enum PlaylistCoverGradientDirection {
  /// 左 → 右（默认，与早期版本一致）
  horizontalLtr,

  /// 右 → 左
  horizontalRtl,

  /// 上 → 下
  verticalTtb,

  /// 下 → 上
  verticalBtt,

  /// 左上 → 右下
  diagonalTlBr,

  /// 右上 → 左下
  diagonalTrBl,

  /// 右下 → 左上（与 [diagonalTlBr] 同轴反向）
  diagonalBrTl,

  /// 左下 → 右上（与 [diagonalTrBl] 同轴反向）
  diagonalBlTr;

  (Alignment, Alignment) get beginEnd => switch (this) {
        PlaylistCoverGradientDirection.horizontalLtr => (
            Alignment.centerLeft,
            Alignment.centerRight,
          ),
        PlaylistCoverGradientDirection.horizontalRtl => (
            Alignment.centerRight,
            Alignment.centerLeft,
          ),
        PlaylistCoverGradientDirection.verticalTtb => (
            Alignment.topCenter,
            Alignment.bottomCenter,
          ),
        PlaylistCoverGradientDirection.verticalBtt => (
            Alignment.bottomCenter,
            Alignment.topCenter,
          ),
        PlaylistCoverGradientDirection.diagonalTlBr => (
            Alignment.topLeft,
            Alignment.bottomRight,
          ),
        PlaylistCoverGradientDirection.diagonalTrBl => (
            Alignment.topRight,
            Alignment.bottomLeft,
          ),
        PlaylistCoverGradientDirection.diagonalBrTl => (
            Alignment.bottomRight,
            Alignment.topLeft,
          ),
        PlaylistCoverGradientDirection.diagonalBlTr => (
            Alignment.bottomLeft,
            Alignment.topRight,
          ),
      };

  static PlaylistCoverGradientDirection fromStorage(int? code) {
    if (code == null) return PlaylistCoverGradientDirection.horizontalLtr;
    if (code < 0 || code >= PlaylistCoverGradientDirection.values.length) {
      return PlaylistCoverGradientDirection.horizontalLtr;
    }
    return PlaylistCoverGradientDirection.values[code];
  }
}

/// 首页 / 编辑面板共用的预设渐变（未自定义时使用列表序号循环）。
/// 双色对比更明显，便于在小卡片上看出渐变走向。
const List<List<Color>> kDefaultPlaylistCoverGradients = [
  [Color(0xFF0D47A1), Color(0xFF64B5F6)],
  [Color(0xFF004D40), Color(0xFF4DD0E1)],
  [Color(0xFF311B92), Color(0xFFE040FB)],
  [Color(0xFFBF360C), Color(0xFFFFCC80)],
];

/// 编辑面板可选的额外渐变预设。
const List<List<Color>> kPlaylistCoverExtendedGradients = [
  [Color(0xFF263238), Color(0xFF90CAF9)],
  [Color(0xFF880E4F), Color(0xFFFF80AB)],
  [Color(0xFF006064), Color(0xFFB2DFDB)],
  [Color(0xFFE65100), Color(0xFFFFEB3B)],
  [Color(0xFF01579B), Color(0xFF80D8FF)],
  [Color(0xFF33691E), Color(0xFFCCFF90)],
  [Color(0xFF4E342E), Color(0xFFFFAB91)],
  [Color(0xFF1A237E), Color(0xFF82B1FF)],
];

/// 封面渐变绘制：沿 [direction] 三色停靠 + 中段插值，让小卡片上的渐变更清晰。
LinearGradient playlistCoverLinearGradient(
  List<Color> pair, {
  PlaylistCoverGradientDirection direction =
      PlaylistCoverGradientDirection.horizontalLtr,
}) {
  final a = pair[0];
  final b = pair[1];
  final mid = Color.lerp(a, b, 0.48)!;
  final be = direction.beginEnd;
  return LinearGradient(
    begin: be.$1,
    end: be.$2,
    colors: [a, mid, b],
    stops: const [0.0, 0.52, 1.0],
  );
}

/// 歌单封面（纯色、双色渐变或本地图片路径），持久化于 Hive；`null` 表示沿用首页默认轮换渐变。
@immutable
class UserPlaylistCoverStyle {
  const UserPlaylistCoverStyle._(
    this._c1,
    this._c2,
    this._gradientDirCode,
    this._imagePath,
  );

  /// 单色填充。
  factory UserPlaylistCoverStyle.solid(Color c) =>
      UserPlaylistCoverStyle._(c.toARGB32(), null, null, null);

  /// 线性渐变；[direction] 默认左→右，与旧备份兼容。
  factory UserPlaylistCoverStyle.gradient(
    Color a,
    Color b, {
    PlaylistCoverGradientDirection direction =
        PlaylistCoverGradientDirection.horizontalLtr,
  }) =>
      UserPlaylistCoverStyle._(a.toARGB32(), b.toARGB32(), direction.index, null);

  /// 自定义封面图（本地绝对路径，建议使用应用支持目录下的缓存文件）。
  factory UserPlaylistCoverStyle.customImage(String absolutePath) =>
      UserPlaylistCoverStyle._(0, null, null, absolutePath.trim());

  final int _c1;
  final int? _c2;

  /// 仅 `gradient` 有效；`null` 视为 [PlaylistCoverGradientDirection.horizontalLtr]。
  final int? _gradientDirCode;

  final String? _imagePath;

  bool get isCustomImage {
    final p = _imagePath;
    return p != null && p.trim().isNotEmpty;
  }

  bool get isSolid => !isCustomImage && _c2 == null;

  bool get isGradient => !isCustomImage && _c2 != null;

  Color get solidColor => Color(_c1);

  List<Color> get gradientColors {
    final c = _c2;
    if (c == null) {
      throw StateError('gradientColors only defined for gradient covers');
    }
    return [Color(_c1), Color(c)];
  }

  PlaylistCoverGradientDirection get gradientDirection {
    if (!isGradient) return PlaylistCoverGradientDirection.horizontalLtr;
    return PlaylistCoverGradientDirection.fromStorage(_gradientDirCode);
  }

  String get imagePath {
    assert(isCustomImage);
    return _imagePath!;
  }

  /// 自存储 map 解析；非法或缺失返回 `null`（表示使用默认轮换色）。
  static UserPlaylistCoverStyle? tryParse(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final t = m['t'] as String?;
    if (t == 'sol') {
      final c = m['c'];
      if (c is int) {
        return UserPlaylistCoverStyle._(c, null, null, null);
      }
    }
    if (t == 'grad') {
      final c1 = m['c1'];
      final c2 = m['c2'];
      if (c1 is int && c2 is int) {
        final rawDir = m['dir'];
        int? dirCode;
        if (rawDir is int) {
          dirCode = rawDir;
        }
        return UserPlaylistCoverStyle._(c1, c2, dirCode, null);
      }
    }
    if (t == 'img') {
      final pth = m['p'];
      if (pth is String && pth.trim().isNotEmpty) {
        return UserPlaylistCoverStyle._(0, null, null, pth.trim());
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    if (isCustomImage) {
      return {'t': 'img', 'p': _imagePath!};
    }
    if (_c2 == null) {
      return {'t': 'sol', 'c': _c1};
    }
    return {
      't': 'grad',
      'c1': _c1,
      'c2': _c2,
      'dir': gradientDirection.index,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is UserPlaylistCoverStyle &&
      other._c1 == _c1 &&
      other._c2 == _c2 &&
      other._gradientDirCode == _gradientDirCode &&
      other._imagePath == _imagePath;

  @override
  int get hashCode => Object.hash(_c1, _c2, _gradientDirCode, _imagePath);
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
      gradient: playlistCoverLinearGradient(
        fallback,
        direction: PlaylistCoverGradientDirection.horizontalLtr,
      ),
      boxShadow: playlistCoverCardShadows(),
    );
  }
  if (coverStyle.isCustomImage) {
    final file = File(coverStyle.imagePath);
    if (file.existsSync()) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
        ),
        boxShadow: playlistCoverCardShadows(),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: playlistCoverLinearGradient(
        fallback,
        direction: PlaylistCoverGradientDirection.horizontalLtr,
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
    gradient: playlistCoverLinearGradient(
      g,
      direction: coverStyle.gradientDirection,
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
