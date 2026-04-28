import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';

/// 底部抽屉：编辑歌单单色 / 渐变封面或恢复默认轮换配色。
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
    await user.setPlaylistCoverStyle(widget.playlist.id, _draft);
    if (context.mounted) Navigator.pop(context);
  }

  void _pickRgb(BuildContext outerContext, AppLocalizations l10n) {
    final initial =
        _draft?.isSolid == true ? _draft!.solidColor : Colors.blueGrey.shade400;
    showDialog<void>(
      context: outerContext,
      builder: (dialogCtx) => _RgbPickDialogContent(
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

  String _previewSubtitle(AppLocalizations l10n, bool customRgb) {
    final d = _draft;
    if (d == null) return l10n.playlistCoverUseDefaultPalette;
    if (d.isSolid) {
      final c = d.solidColor;
      final r = (c.r * 255.0).round().clamp(0, 255);
      final g = (c.g * 255.0).round().clamp(0, 255);
      final b = (c.b * 255.0).round().clamp(0, 255);
      final hex =
          (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
      if (customRgb) {
        return '${l10n.playlistCoverRgbTitle} · #$hex · RGB($r,$g,$b)';
      }
      return '${l10n.playlistCoverSolidSection} · #$hex · RGB($r,$g,$b)';
    }
    return l10n.playlistCoverGradientSection;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradients = [
      ...kDefaultPlaylistCoverGradients,
      ...kPlaylistCoverExtendedGradients,
    ];
    final fb = _fallbackIndex();
    final customRgb = _isCustomRgbSolid(_draft);
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.playlistCoverStyleSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 2.55,
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
                  _previewSubtitle(l10n, customRgb),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
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
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white54,
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
                color: Colors.white.withValues(alpha: 0.72),
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
                  final sel = customRgb;
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
                        color: sel ? null : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: sel ? Colors.white : Colors.white24,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        sel ? Icons.check_rounded : Icons.tune_rounded,
                        color: Colors.white.withValues(alpha: sel ? 1 : 0.85),
                        size: sel ? 22 : 24,
                      ),
                    ),
                  );
                }
                final col = _presetSolidColors[i];
                final sel = _draft?.isSolid == true &&
                    _draft!.solidColor.toARGB32() == col.toARGB32();
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
                        color: sel ? Colors.white : Colors.white24,
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
                color: Colors.white.withValues(alpha: 0.72),
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
                final g = gradients[i];
                final picked = _draft != null &&
                    !_draft!.isSolid &&
                    _draft!.gradientColors[0].toARGB32() == g[0].toARGB32() &&
                    _draft!.gradientColors[1].toARGB32() == g[1].toARGB32();
                return InkWell(
                  onTap: () => setState(
                    () => _draft = UserPlaylistCoverStyle.gradient(g[0], g[1]),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: g,
                      ),
                      border: Border.all(
                        color: picked ? Colors.white : Colors.white24,
                        width: picked ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              },
              childCount: gradients.length,
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

class _RgbPickDialogContent extends StatefulWidget {
  const _RgbPickDialogContent({
    required this.initial,
    required this.l10n,
    required this.onPick,
  });

  final Color initial;
  final AppLocalizations l10n;
  final ValueChanged<Color> onPick;

  @override
  State<_RgbPickDialogContent> createState() => _RgbPickDialogContentState();
}

class _RgbPickDialogContentState extends State<_RgbPickDialogContent> {
  late Color _c;

  @override
  void initState() {
    super.initState();
    _c = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: scheme.primary.withValues(alpha: 0.95),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
      thumbColor: Colors.white,
      trackHeight: 4,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF2C3138),
      title: Text(
        l10n.playlistCoverRgbTitle,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _c,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        l10n.playlistCoverRgbPreview,
                        style: TextStyle(
                          color: _contrastingLabel(_c),
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Color(0x66000000)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SliderTheme(
              data: sliderTheme,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RgbSlider(
                    label: l10n.playlistCoverRgbRed,
                    value: _c.r,
                    onChanged: (v) => setState(() => _c = _c.withValues(red: v)),
                  ),
                  _RgbSlider(
                    label: l10n.playlistCoverRgbGreen,
                    value: _c.g,
                    onChanged: (v) =>
                        setState(() => _c = _c.withValues(green: v)),
                  ),
                  _RgbSlider(
                    label: l10n.playlistCoverRgbBlue,
                    value: _c.b,
                    onChanged: (v) =>
                        setState(() => _c = _c.withValues(blue: v)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onPick(_c);
            Navigator.pop(context);
          },
          child: Text(l10n.actionOK),
        ),
      ],
    );
  }

  Color _contrastingLabel(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.55 ? const Color(0xFF111418) : Colors.white;
  }
}

class _RgbSlider extends StatelessWidget {
  const _RgbSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${(value * 255).round()})',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        ),
        Slider(
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
