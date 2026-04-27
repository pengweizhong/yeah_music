import 'package:flutter/material.dart';

/// 在快速滚动会话内请求 [SongListCover] 不挂载真实 [Image]（不触发解码/上传纹理），
/// 由 [ScrollAwareListFrame] 在竖向列表滚动起止时更新。
class ListCoverImagePolicy extends InheritedWidget {
  const ListCoverImagePolicy({
    super.key,
    required this.suppressDecode,
    required super.child,
  });

  /// true：仅显示与列表行一致的占位，不做封面解码
  final bool suppressDecode;

  /// 在 [ListCoverImagePolicy] 下则随策略重建；无祖先时恒为 false（如 [MiniPlayer]）
  static bool shouldSuppressDecode(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ListCoverImagePolicy>()
            ?.suppressDecode ??
        false;
  }

  @override
  bool updateShouldNotify(covariant ListCoverImagePolicy oldWidget) {
    return oldWidget.suppressDecode != suppressDecode;
  }
}
