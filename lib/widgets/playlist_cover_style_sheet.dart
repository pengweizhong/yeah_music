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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradients = [
      ...kDefaultPlaylistCoverGradients,
      ...kPlaylistCoverExtendedGradients,
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            Text(
              l10n.playlistCoverSolidSection,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _presetSolidColors.length + 1,
              itemBuilder: (context, i) {
                if (i == _presetSolidColors.length) {
                  return Material(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _pickRgb(context, l10n),
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  );
                }
                final col = _presetSolidColors[i];
                final sel = _draft?.isSolid == true &&
                    _draft!.solidColor.toARGB32() == col.toARGB32();
                return InkWell(
                  onTap: () => setState(() => _draft = UserPlaylistCoverStyle.solid(col)),
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
            ),
            const SizedBox(height: 16),
            Text(
              l10n.playlistCoverGradientSection,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.45,
              ),
              itemCount: gradients.length,
              itemBuilder: (context, i) {
                final g = gradients[i];
                final picked = _draft != null &&
                    _draft!.isSolid != true &&
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
            ),
            const SizedBox(height: 20),
            Row(
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
          ],
        ),
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
            _RgbSlider(
              label: l10n.playlistCoverRgbRed,
              value: _c.r,
              onChanged: (v) => setState(() => _c = _c.withValues(red: v)),
            ),
            _RgbSlider(
              label: l10n.playlistCoverRgbGreen,
              value: _c.g,
              onChanged: (v) => setState(() => _c = _c.withValues(green: v)),
            ),
            _RgbSlider(
              label: l10n.playlistCoverRgbBlue,
              value: _c.b,
              onChanged: (v) => setState(() => _c = _c.withValues(blue: v)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.playlistCoverRgbPreview,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _c,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
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
