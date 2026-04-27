import 'package:flutter/material.dart';

/// 历史上曾用于在快速滚动时抑制列表封面解码；现已不再卸图，避免与 [ImageCache] 已缓存
/// 的封面在「灰色占位 ↔ 真图」之间反复切换造成闪动。保持该包裹器仅透传 [child]。
class ScrollAwareListFrame extends StatelessWidget {
  const ScrollAwareListFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
