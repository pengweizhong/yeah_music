import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/rgb_gradient_pickers.dart';

int _argbFromColor(Color c) {
  // ARGB 32 位，与 [LyricSettings] 存 Hive 的 int 一致
  return c.toARGB32();
}

/// 播放页「歌词样式」底栏内文：毛玻璃上的分组与控件
class LyricStyleSettingsPanel extends StatelessWidget {
  const LyricStyleSettingsPanel({
    super.key,
    required this.settings,
    required this.pageContext,
    required this.keepScreenAwake,
    required this.onKeepScreenAwakeChanged,
    required this.onUpdate,
    required this.onPersist,
  });

  final LyricSettings settings;
  final BuildContext pageContext;
  /// 播放页屏幕常亮（与 Hive [SettingsService.loadSongPageKeepScreenAwake] 同步）
  final bool keepScreenAwake;
  final ValueChanged<bool> onKeepScreenAwakeChanged;
  final VoidCallback onUpdate;
  final Future<void> Function() onPersist;

  Future<void> _apply(void Function() fn) async {
    fn();
    onUpdate();
    await onPersist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context);
    final primary = t.colorScheme.primary;
    final fg = context.gradFg();

    return Theme(
      data: t.copyWith(
        sliderTheme: t.sliderTheme.copyWith(
          activeTrackColor: fg.withValues(alpha: 0.5),
          inactiveTrackColor: fg.withValues(alpha: 0.12),
          thumbColor: fg,
          overlayColor: WidgetStateColor.resolveWith(
            (states) => fg.withValues(alpha: 0.1),
          ),
        ),
        switchTheme: t.switchTheme.copyWith(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? fg : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.5)
                : fg.withValues(alpha: 0.24),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, l10n),
            const SizedBox(height: 6),
            _sectionLabel(context, l10n.lyricStyleSectionDisplay, l10n.lyricStyleSectionDisplaySub),
            const SizedBox(height: 8),
            _frostedCard(
              context,
              child: Column(
                children: [
                  _switchRow(
                    context,
                    icon: Icons.subject_rounded,
                    label: l10n.lyricStyleShowOriginal,
                    sub: l10n.lyricStyleShowOriginalSub,
                    value: settings.showOriginal,
                    onChanged: (v) => _apply(() {
                      settings.showOriginal = v;
                    }),
                  ),
                  _softDivider(context),
                  _switchRow(
                    context,
                    icon: Icons.translate_rounded,
                    label: l10n.lyricStyleShowTranslation,
                    sub: l10n.lyricStyleShowTranslationSub,
                    value: settings.showTranslations,
                    onChanged: (v) => _apply(() {
                      settings.showTranslations = v;
                    }),
                  ),
                  _softDivider(context),
                  _switchRow(
                    context,
                    icon: Icons.light_mode_rounded,
                    label: l10n.songPageKeepScreenAwake,
                    sub: l10n.lyricStyleKeepScreenAwakeSub,
                    value: keepScreenAwake,
                    onChanged: onKeepScreenAwakeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, l10n.lyricStyleSectionTypography, l10n.lyricStyleSectionTypographySub),
            const SizedBox(height: 8),
            _frostedCard(
              context,
              child: Column(
                children: [
                  _sliderBlock(
                    context,
                    label: l10n.lyricStyleFontOriginal,
                    value: settings.originalFontSize,
                    min: LyricSettings.minFontSize,
                    max: LyricSettings.maxFontSize,
                    onChanged: (v) => _apply(() {
                      settings.originalFontSize = v;
                    }),
                  ),
                  _softDivider(context),
                  _sliderBlock(
                    context,
                    label: l10n.lyricStyleFontTranslation,
                    value: settings.translationFontSize,
                    min: LyricSettings.minFontSize,
                    max: LyricSettings.maxFontSize,
                    onChanged: (v) => _apply(() {
                      settings.translationFontSize = v;
                    }),
                  ),
                  _softDivider(context),
                  _sliderBlock(
                    context,
                    label: l10n.lyricStyleLineSpacing,
                    value: settings.lyricLineSpacing,
                    min: LyricSettings.minLineSpacing,
                    max: LyricSettings.maxLineSpacing,
                    onChanged: (v) => _apply(() {
                      settings.lyricLineSpacing = v;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, l10n.lyricStyleSectionLineAlign, null),
            const SizedBox(height: 8),
            _frostedCard(
              context,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(l10n.lyricAlignLeft),
                    icon: Icon(Icons.format_align_left_rounded, size: 18, color: fg),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(l10n.lyricAlignCenter),
                    icon: Icon(Icons.format_align_center_rounded, size: 18, color: fg),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text(l10n.lyricAlignRight),
                    icon: Icon(Icons.format_align_right_rounded, size: 18, color: fg),
                  ),
                ],
                selected: {settings.lyricTextAlignIndex},
                onSelectionChanged: (next) {
                  _apply(() {
                    settings.lyricTextAlignIndex = next.first;
                  });
                },
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(color: context.gradBorder(0.12)),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return fg.withValues(alpha: 0.18);
                      }
                      return fg.withValues(alpha: 0.04);
                    },
                  ),
                  foregroundColor: WidgetStateProperty.all(fg),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, l10n.lyricStyleSectionStateColors, l10n.lyricStyleSectionStateColorsSub),
            const SizedBox(height: 8),
            _frostedCard(
              context,
              child: Column(
                children: [
                  _colorStateBlock(
                    context,
                    accent: const Color(0xFFFFB74D),
                    title: l10n.lyricStyleStateNowPlaying,
                    labelOriginal: l10n.lyricLabelOriginal,
                    labelTranslation: l10n.lyricLabelTranslation,
                    icon: Icons.label_important_rounded,
                    c1: Color(settings.activeOriginalColor),
                    c2: Color(settings.activeTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorNowOriginal,
                      Color(settings.activeOriginalColor),
                      (c) => _apply(
                        () => settings.activeOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorNowTranslation,
                      Color(settings.activeTranslationColor),
                      (c) => _apply(
                        () =>
                            settings.activeTranslationColor = _argbFromColor(c),
                      ),
                    ),
                  ),
                  _softDivider(context),
                  _stateGradientControls(
                    context,
                    l10n: l10n,
                    title: l10n.lyricStyleActiveGradientTitle,
                    useGradient: settings.activeLyricUseGradient,
                    onToggle: (v) =>
                        _apply(() => settings.activeLyricUseGradient = v),
                    startArgb: settings.activeLyricGradientStart,
                    endArgb: settings.activeLyricGradientEnd,
                    dirIndex: settings.activeLyricGradientDirectionIndex,
                    dialogTitle: l10n.lyricStyleActiveGradientDialogTitle,
                    onGradientSaved: (a, b, d) {
                      settings.activeLyricGradientStart = a;
                      settings.activeLyricGradientEnd = b;
                      settings.activeLyricGradientDirectionIndex = d;
                    },
                  ),
                  _softDivider(context),
                  _colorStateBlock(
                    context,
                    accent: const Color(0xFF81C784),
                    title: l10n.lyricStyleStatePlayed,
                    labelOriginal: l10n.lyricLabelOriginal,
                    labelTranslation: l10n.lyricLabelTranslation,
                    icon: Icons.history_rounded,
                    c1: Color(settings.playedOriginalColor),
                    c2: Color(settings.playedTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorPlayedOriginal,
                      Color(settings.playedOriginalColor),
                      (c) => _apply(
                        () => settings.playedOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorPlayedTranslation,
                      Color(settings.playedTranslationColor),
                      (c) => _apply(
                        () => settings.playedTranslationColor =
                            _argbFromColor(c),
                      ),
                    ),
                  ),
                  _softDivider(context),
                  _stateGradientControls(
                    context,
                    l10n: l10n,
                    title: l10n.lyricStylePlayedGradientTitle,
                    useGradient: settings.playedLyricUseGradient,
                    onToggle: (v) =>
                        _apply(() => settings.playedLyricUseGradient = v),
                    startArgb: settings.playedLyricGradientStart,
                    endArgb: settings.playedLyricGradientEnd,
                    dirIndex: settings.playedLyricGradientDirectionIndex,
                    dialogTitle: l10n.lyricStylePlayedGradientDialogTitle,
                    onGradientSaved: (a, b, d) {
                      settings.playedLyricGradientStart = a;
                      settings.playedLyricGradientEnd = b;
                      settings.playedLyricGradientDirectionIndex = d;
                    },
                  ),
                  _softDivider(context),
                  _colorStateBlock(
                    context,
                    accent: const Color(0xFF64B5F6),
                    title: l10n.lyricStyleStateUpcoming,
                    labelOriginal: l10n.lyricLabelOriginal,
                    labelTranslation: l10n.lyricLabelTranslation,
                    icon: Icons.schedule_rounded,
                    c1: Color(settings.upcomingOriginalColor),
                    c2: Color(settings.upcomingTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorUpcomingOriginal,
                      Color(settings.upcomingOriginalColor),
                      (c) => _apply(
                        () => settings.upcomingOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      l10n.lyricStyleColorUpcomingTranslation,
                      Color(settings.upcomingTranslationColor),
                      (c) => _apply(
                        () => settings.upcomingTranslationColor =
                            _argbFromColor(c),
                      ),
                    ),
                  ),
                  _softDivider(context),
                  _stateGradientControls(
                    context,
                    l10n: l10n,
                    title: l10n.lyricStyleUpcomingGradientTitle,
                    useGradient: settings.upcomingLyricUseGradient,
                    onToggle: (v) =>
                        _apply(() => settings.upcomingLyricUseGradient = v),
                    startArgb: settings.upcomingLyricGradientStart,
                    endArgb: settings.upcomingLyricGradientEnd,
                    dirIndex: settings.upcomingLyricGradientDirectionIndex,
                    dialogTitle: l10n.lyricStyleUpcomingGradientDialogTitle,
                    onGradientSaved: (a, b, d) {
                      settings.upcomingLyricGradientStart = a;
                      settings.upcomingLyricGradientEnd = b;
                      settings.upcomingLyricGradientDirectionIndex = d;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lyricStyleColorPersistNote,
              style: TextStyle(fontSize: 12, color: context.gradFg(0.38), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final on = context.gradFg();
    final onMuted = context.gradFgMuted();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tooltipLyricStyle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: on,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.lyricStyleSyncSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: onMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 24,
                color: on.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String title, String? subtitle) {
    final on = context.gradFg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on,
            letterSpacing: 0.6,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: context.gradFg(0.38), height: 1.2),
          ),
        ],
      ],
    );
  }

  Widget _frostedCard(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final cardFill = Theme.of(context).brightness == Brightness.light
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.07);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradBorder(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _softDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(
          height: 1,
          thickness: 1,
          color: context.gradBorder(0.08),
        ),
      );

  Widget _switchRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final on = context.gradFg();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: context.gradFg(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: on,
                    height: 1.2,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.gradFg(0.38),
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => onChanged(v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _stateGradientControls(
    BuildContext sheetContext, {
    required AppLocalizations l10n,
    required String title,
    required bool useGradient,
    required ValueChanged<bool> onToggle,
    required int startArgb,
    required int endArgb,
    required int dirIndex,
    required String dialogTitle,
    required void Function(int start, int end, int dirIdx) onGradientSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _switchRow(
          sheetContext,
          icon: Icons.gradient_rounded,
          label: title,
          sub: l10n.lyricStyleStateGradientSub,
          value: useGradient,
          onChanged: onToggle,
        ),
        if (useGradient) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: playlistCoverLinearGradient(
                    [
                      Color(startArgb),
                      Color(endArgb),
                    ],
                    direction:
                        PlaylistCoverGradientDirection.fromStorage(dirIndex),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showStateGradientPicker(
                pageContext,
                l10n,
                dialogTitle: dialogTitle,
                startArgb: startArgb,
                endArgb: endArgb,
                directionIndex: dirIndex,
                apply: onGradientSaved,
              ),
              icon: Icon(
                Icons.tune_rounded,
                color: sheetContext.gradFg(0.9),
              ),
              label: Text(
                l10n.lyricStyleActiveGradientTune,
                style: TextStyle(
                  color: sheetContext.gradFg(0.9),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: sheetContext.gradBorder(0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sliderBlock(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final fg = context.gradFg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.gradBorder(0.12)),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (v) => onChanged(v),
        ),
      ],
    );
  }

  Widget _colorStateBlock(
    BuildContext context, {
    required Color accent,
    required String title,
    required String labelOriginal,
    required String labelTranslation,
    required IconData icon,
    required Color c1,
    required Color c2,
    required VoidCallback onPick1,
    required VoidCallback onPick2,
  }) {
    final fg = context.gradFg();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: context.gradFgMuted()),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _colorChip(
                  context,
                  label: labelOriginal,
                  color: c1,
                  onTap: onPick1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _colorChip(
                  context,
                  label: labelTranslation,
                  color: c2,
                  onTap: onPick2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorChip(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final ink = context.gradFg();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.gradBorder(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: context.gradFgMuted(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(
                    color: context.gradBorder(0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(
    BuildContext context,
    String title,
    Color current,
    void Function(Color) onPick,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        final colors = <Color>[
          Colors.white,
          const Color(0xFFD0D0D0),
          const Color(0xFFB0B0B0),
          const Color(0xFF909090),
          const Color(0xFF7A7A7A),
          const Color(0xFF6A6A6A),
          Colors.lightBlue.shade200,
          Colors.lightGreen.shade200,
          Colors.amber.shade200,
          Colors.purple.shade200,
        ];
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Theme(
            data: frostedDialogContentTheme(dialogContext),
            child: FrostedGlassDialog(
              child: Builder(
                builder: (inner) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: inner.gradFg(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.lyricColorPickerHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: inner.gradFgMuted(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final c in colors)
                              GestureDetector(
                                onTap: () => Navigator.of(dialogContext).pop(c),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: current == c
                                          ? Theme.of(inner)
                                              .colorScheme
                                              .primary
                                          : inner.gradBorder(0.3),
                                      width: current == c ? 2.5 : 1,
                                    ),
                                    boxShadow: [
                                      if (current == c)
                                        BoxShadow(
                                          color: Theme.of(
                                            inner,
                                          ).colorScheme.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      onPick(result);
    }
  }

  Future<void> _showStateGradientPicker(
    BuildContext context,
    AppLocalizations l10n, {
    required String dialogTitle,
    required int startArgb,
    required int endArgb,
    required int directionIndex,
    required void Function(int start, int end, int dirIdx) apply,
  }) async {
    await showFrostedDialog<void>(
      context: context,
      maxWidth: 440,
      child: GradientRgbPickDialogContent(
        initialStart: Color(startArgb),
        initialEnd: Color(endArgb),
        initialDirection:
            PlaylistCoverGradientDirection.fromStorage(directionIndex),
        l10n: l10n,
        dialogTitle: dialogTitle,
        onPick: (a, b, d) {
          _apply(() {
            apply(_argbFromColor(a), _argbFromColor(b), d.index);
          });
        },
      ),
    );
  }
}
