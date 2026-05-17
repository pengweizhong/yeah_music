import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/image_pick_crop_flow.dart';
import 'package:yeah_music/widgets/rgb_gradient_pickers.dart';

/// 底部抽屉：编辑歌单单色 / 渐变 / 自定义图片封面或恢复默认轮换配色。
Future<void> showPlaylistCoverStyleSheet(
  BuildContext context,
  UserPlaylist playlist,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: FrostedGlassBottomSheet(
        showTopHandle: false,
        child: _PlaylistCoverStyleBody(playlist: playlist),
      ),
    ),
  );
}

const List<Color> _presetSolidColors = [
  Color(0xFF3949AB),
  Color(0xFF00897B),
  Color(0xFF7B1FA2),
  Color(0xFFE65100),
  Color(0xFFC62828),
  Color(0xFF5E35B1),
  Color(0xFF0277BD),
  Color(0xFF33691E),
  Color(0xFF37474F),
  Color(0xFFAD1457),
  Color(0xFF00695C),
  Color(0xFFF57F17),
];

class _PlaylistCoverStyleBody extends StatefulWidget {
  const _PlaylistCoverStyleBody({required this.playlist});

  final UserPlaylist playlist;

  @override
  State<_PlaylistCoverStyleBody> createState() =>
      _PlaylistCoverStyleBodyState();
}

class _PlaylistCoverStyleBodyState extends State<_PlaylistCoverStyleBody> {
  UserPlaylistCoverStyle? _draft;

  List<List<Color>> get _allPresetGradientPairs => [
        ...kDefaultPlaylistCoverGradients,
        ...kPlaylistCoverExtendedGradients,
      ];

  static String _hex6(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  bool _matchesPresetGradient(UserPlaylistCoverStyle d) {
    if (d.isCustomImage || d.isSolid) return false;
    if (d.gradientDirection != PlaylistCoverGradientDirection.horizontalLtr) {
      return false;
    }
    final ca = d.gradientColors;
    for (final g in _allPresetGradientPairs) {
      if (ca[0].toARGB32() == g[0].toARGB32() &&
          ca[1].toARGB32() == g[1].toARGB32()) {
        return true;
      }
    }
    return false;
  }

  bool _isCustomGradient(UserPlaylistCoverStyle? d) {
    if (d == null || d.isSolid || d.isCustomImage) return false;
    return !_matchesPresetGradient(d);
  }

  @override
  void initState() {
    super.initState();
    _draft = widget.playlist.coverStyle;
  }

  bool _sameAs(UserPlaylistCoverStyle? a, UserPlaylistCoverStyle? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a == b;
  }

  Future<void> _apply(BuildContext context) async {
    final user = context.read<UserPlaylistProvider>();
    if (_sameAs(_draft, widget.playlist.coverStyle)) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    if (widget.playlist.id == UserPlaylistProvider.homeCarouselLibrarySentinel) {
      await user.setHomeLibraryCoverStyle(_draft);
    } else {
      await user.setPlaylistCoverStyle(widget.playlist.id, _draft);
    }
    if (context.mounted) Navigator.pop(context);
  }

  void _pickGradientRgb(BuildContext outerContext, AppLocalizations l10n) {
    final pair = _draft != null && _draft!.isGradient
        ? _draft!.gradientColors
        : <Color>[const Color(0xFF283593), const Color(0xFFFF7043)];
    final dir = _draft != null && _draft!.isGradient
        ? _draft!.gradientDirection
        : PlaylistCoverGradientDirection.horizontalLtr;
    showFrostedDialog<void>(
      context: outerContext,
      maxWidth: 440,
      child: GradientRgbPickDialogContent(
        initialStart: pair[0],
        initialEnd: pair[1],
        initialDirection: dir,
        l10n: l10n,
        onPick: (a, b, d) {
          setState(
            () => _draft =
                UserPlaylistCoverStyle.gradient(a, b, direction: d),
          );
        },
      ),
    );
  }

  void _pickRgb(BuildContext outerContext, AppLocalizations l10n) {
    final initial =
        _draft?.isSolid == true ? _draft!.solidColor : Colors.blueGrey.shade400;
    showFrostedDialog<void>(
      context: outerContext,
      maxWidth: 420,
      child: RgbPickDialogContent(
        initial: initial,
        l10n: l10n,
        onPick: (color) {
          setState(() => _draft = UserPlaylistCoverStyle.solid(color));
        },
      ),
    );
  }

  int _fallbackIndex() =>
      widget.playlist.id.hashCode.abs() %
      kDefaultPlaylistCoverGradients.length;

  bool _isCustomRgbSolid(UserPlaylistCoverStyle? d) {
    if (d == null || !d.isSolid) return false;
    final argb = d.solidColor.toARGB32();
    for (final c in _presetSolidColors) {
      if (c.toARGB32() == argb) return false;
    }
    return true;
  }

  String _previewSubtitle(AppLocalizations l10n) {
    final d = _draft;
    if (d == null) return l10n.playlistCoverUseDefaultPalette;
    if (d.isCustomImage) {
      final name = p.basename(d.imagePath);
      return '${l10n.playlistCoverPictureSection} · $name';
    }
    if (d.isSolid) {
      final c = d.solidColor;
      final r = (c.r * 255.0).round().clamp(0, 255);
      final g = (c.g * 255.0).round().clamp(0, 255);
      final b = (c.b * 255.0).round().clamp(0, 255);
      final hex =
          (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
      final customRgb = _isCustomRgbSolid(d);
      if (customRgb) {
        return '${l10n.playlistCoverRgbTitle} · #$hex · RGB($r,$g,$b)';
      }
      return '${l10n.playlistCoverSolidSection} · #$hex · RGB($r,$g,$b)';
    }
    if (_isCustomGradient(d)) {
      final gc = d.gradientColors;
      final dir = d.gradientDirection;
      final dirSuffix = dir == PlaylistCoverGradientDirection.horizontalLtr
          ? ''
          : ' · ${linearGradientDirectionLabel(l10n, dir)}';
      return '${l10n.playlistCoverCustomGradientTitle} · '
          '#${_hex6(gc[0])} → #${_hex6(gc[1])}$dirSuffix';
    }
    return l10n.playlistCoverGradientSection;
  }

  Future<void> _pickCoverImage(
    BuildContext outerContext,
    AppLocalizations l10n,
  ) async {
    final bytes = await pickImageWithCrop(
      context: outerContext,
      l10n: l10n,
      aspectRatio: kPlaylistCoverCropAspectRatio,
    );
    if (bytes == null || !mounted) return;
    final dir = await getTemporaryDirectory();
    // 固定文件名覆盖写入，避免多次选图未保存时 temp 里堆积带时间戳的 PNG。
    final tmp = File(
      p.join(dir.path, 'ym_playlist_cover_${widget.playlist.id.hashCode}.png'),
    );
    await tmp.writeAsBytes(bytes);
    setState(() => _draft = UserPlaylistCoverStyle.customImage(tmp.path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final gradients = _allPresetGradientPairs;
    final fb = _fallbackIndex();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    // Column(mainAxisSize: min) 子级里，无界 CustomScrollView 会算成零高；给视口一个有限高度。
    final sheetHeight = (screenH * 0.72).clamp(280.0, screenH * 0.92);

    return SizedBox(
      height: sheetHeight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.playlistCoverStyleTitle,
                  style: TextStyle(
                    color: context.gradFg(),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.playlistCoverStyleSubtitle,
                  style: TextStyle(
                    color: context.gradFg(0.55),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: kPlaylistCoverCropAspectRatio,
                    child: DecoratedBox(
                      decoration: playlistCoverCardDecoration(
                        coverStyle: _draft,
                        fallbackGradientIndex: fb,
                        radius: 14,
                      ).copyWith(boxShadow: const []),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 9),
                          child: Text(
                            l10n.playlistCoverPreviewLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(blurRadius: 8, color: Color(0x99000000)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _previewSubtitle(l10n),
                  style: TextStyle(
                    color: context.gradFg(0.72),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _draft = null),
                    icon: Icon(
                      Icons.palette_outlined,
                      color: _draft == null
                          ? scheme.primary
                          : context.gradFg(0.54),
                      size: 20,
                    ),
                    label: Text(l10n.playlistCoverUseDefaultPalette),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.playlistCoverSolidSection,
              style: TextStyle(
                color: context.gradFg(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final presetLen = _presetSolidColors.length;
                if (i == presetLen) {
                  final sel = _isCustomRgbSolid(_draft);
                  final borderAccent = context.gradFg();
                  final borderSubtle = context.gradBorder(0.35);
                  return InkWell(
                    onTap: () => _pickRgb(context, l10n),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: sel && _draft?.isSolid == true
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _draft!.solidColor.withValues(alpha: 0.92),
                                  _draft!.solidColor.withValues(alpha: 0.38),
                                ],
                              )
                            : null,
                        color: sel
                            ? null
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.65),
                        border: Border.all(
                          color: sel ? borderAccent : borderSubtle,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        sel ? Icons.check_rounded : Icons.tune_rounded,
                        color: context.gradFg(sel ? 1 : 0.85),
                        size: sel ? 22 : 24,
                      ),
                    ),
                  );
                }
                final col = _presetSolidColors[i];
                final sel = _draft?.isSolid == true &&
                    _draft!.solidColor.toARGB32() == col.toARGB32();
                final swatchBorder = sel ? Colors.white : Colors.white38;
                return InkWell(
                  onTap: () =>
                      setState(() => _draft = UserPlaylistCoverStyle.solid(col)),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: swatchBorder,
                        width: sel ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              },
              childCount: _presetSolidColors.length + 1,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.playlistCoverGradientSection,
              style: TextStyle(
                color: context.gradFg(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.45,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final presetLen = gradients.length;
                if (i == presetLen) {
                  final sel = _isCustomGradient(_draft);
                  return InkWell(
                    onTap: () => _pickGradientRgb(context, l10n),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: sel && _draft != null && _draft!.isGradient
                            ? playlistCoverLinearGradient(
                                _draft!.gradientColors,
                                direction: _draft!.gradientDirection,
                              )
                            : null,
                        color: sel
                            ? null
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.65),
                        border: Border.all(
                          color:
                              sel ? context.gradFg() : context.gradBorder(0.35),
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        sel ? Icons.check_rounded : Icons.gradient_rounded,
                        color: context.gradFg(sel ? 1 : 0.88),
                        size: sel ? 26 : 28,
                      ),
                    ),
                  );
                }
                final g = gradients[i];
                final picked = _draft != null &&
                    _draft!.isGradient &&
                    _draft!.gradientDirection ==
                        PlaylistCoverGradientDirection.horizontalLtr &&
                    _draft!.gradientColors[0].toARGB32() == g[0].toARGB32() &&
                    _draft!.gradientColors[1].toARGB32() == g[1].toARGB32();
                final gradSwatchBorder =
                    picked ? Colors.white : Colors.white38;
                return InkWell(
                  onTap: () => setState(
                    () => _draft = UserPlaylistCoverStyle.gradient(g[0], g[1]),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: playlistCoverLinearGradient(g),
                      border: Border.all(
                        color: gradSwatchBorder,
                        width: picked ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              },
              childCount: gradients.length + 1,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.playlistCoverPictureSection,
              style: TextStyle(
                color: context.gradFg(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickCoverImage(context, l10n),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.gradFg(),
                      side: BorderSide(color: context.gradBorder(0.38)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.playlistCoverPickImage),
                  ),
                ),
                if (_draft?.isCustomImage == true) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.playlistCoverRemoveImage,
                    onPressed: () => setState(() => _draft = null),
                    icon: Icon(
                      Icons.delete_outline,
                      color: context.gradFg(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12 + bottomPad),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionCancel),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _apply(context),
                    child: Text(l10n.actionSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
