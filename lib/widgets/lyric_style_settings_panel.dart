import 'package:flutter/material.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/models/lyric_settings.dart';

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
    required this.onUpdate,
    required this.onPersist,
  });

  final LyricSettings settings;
  final BuildContext pageContext;
  final VoidCallback onUpdate;
  final Future<void> Function() onPersist;

  Future<void> _apply(void Function() fn) async {
    fn();
    onUpdate();
    await onPersist();
  }

  static const _on = Colors.white;
  static final _onMuted = Colors.white.withValues(alpha: 0.5);
  static final _onDim = Colors.white.withValues(alpha: 0.38);
  static final _cardFill = Colors.white.withValues(alpha: 0.07);
  static final _cardBorder = Colors.white.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final primary = t.colorScheme.primary;

    return Theme(
      data: t.copyWith(
        sliderTheme: t.sliderTheme.copyWith(
          activeTrackColor: Colors.white.withValues(alpha: 0.5),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
          thumbColor: Colors.white,
          overlayColor: WidgetStateColor.resolveWith(
            (states) => Colors.white.withValues(alpha: 0.1),
          ),
        ),
        switchTheme: t.switchTheme.copyWith(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _on : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.5)
                : Colors.white24,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 6),
            _sectionLabel('显示', '原文与多行译文的开关'),
            const SizedBox(height: 8),
            _frostedCard(
              child: Column(
                children: [
                  _switchRow(
                    icon: Icons.subject_rounded,
                    label: '显示原文',
                    sub: '每个时间戳第 1 行',
                    value: settings.showOriginal,
                    onChanged: (v) => _apply(() {
                      settings.showOriginal = v;
                    }),
                  ),
                  _softDivider(),
                  _switchRow(
                    icon: Icons.translate_rounded,
                    label: '显示翻译/附加行',
                    sub: '第 2 行及以后',
                    value: settings.showTranslations,
                    onChanged: (v) => _apply(() {
                      settings.showTranslations = v;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('字号与行距', '滑条调节后即时生效'),
            const SizedBox(height: 8),
            _frostedCard(
              child: Column(
                children: [
                  _sliderBlock(
                    label: '原文字号',
                    value: settings.originalFontSize,
                    min: LyricSettings.minFontSize,
                    max: LyricSettings.maxFontSize,
                    onChanged: (v) => _apply(() {
                      settings.originalFontSize = v;
                    }),
                  ),
                  _softDivider(),
                  _sliderBlock(
                    label: '翻译字号',
                    value: settings.translationFontSize,
                    min: LyricSettings.minFontSize,
                    max: LyricSettings.maxFontSize,
                    onChanged: (v) => _apply(() {
                      settings.translationFontSize = v;
                    }),
                  ),
                  _softDivider(),
                  _sliderBlock(
                    label: '行间距',
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
            _sectionLabel('行对齐', null),
            const SizedBox(height: 8),
            _frostedCard(
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('左'),
                    icon: Icon(Icons.format_align_left_rounded, size: 18),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('中'),
                    icon: Icon(Icons.format_align_center_rounded, size: 18),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text('右'),
                    icon: Icon(Icons.format_align_right_rounded, size: 18),
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
                    BorderSide(color: _cardBorder),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white.withValues(alpha: 0.18);
                      }
                      return Colors.white.withValues(alpha: 0.04);
                    },
                  ),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('行状态颜色', '正在播放、已播过、未播到'),
            const SizedBox(height: 8),
            _frostedCard(
              child: Column(
                children: [
                  _colorStateBlock(
                    accent: const Color(0xFFFFB74D),
                    title: '正在播放行',
                    icon: Icons.label_important_rounded,
                    c1: Color(settings.activeOriginalColor),
                    c2: Color(settings.activeTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      '正在播放 — 原文',
                      Color(settings.activeOriginalColor),
                      (c) => _apply(
                        () => settings.activeOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      '正在播放 — 译文',
                      Color(settings.activeTranslationColor),
                      (c) => _apply(
                        () =>
                            settings.activeTranslationColor = _argbFromColor(c),
                      ),
                    ),
                  ),
                  _softDivider(),
                  _colorStateBlock(
                    accent: const Color(0xFF81C784),
                    title: '已播过的行',
                    icon: Icons.history_rounded,
                    c1: Color(settings.playedOriginalColor),
                    c2: Color(settings.playedTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      '已播过 — 原文',
                      Color(settings.playedOriginalColor),
                      (c) => _apply(
                        () => settings.playedOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      '已播过 — 译文',
                      Color(settings.playedTranslationColor),
                      (c) => _apply(
                        () => settings.playedTranslationColor =
                            _argbFromColor(c),
                      ),
                    ),
                  ),
                  _softDivider(),
                  _colorStateBlock(
                    accent: const Color(0xFF64B5F6),
                    title: '未播到的行',
                    icon: Icons.schedule_rounded,
                    c1: Color(settings.upcomingOriginalColor),
                    c2: Color(settings.upcomingTranslationColor),
                    onPick1: () => _pickColor(
                      pageContext,
                      '未播到 — 原文',
                      Color(settings.upcomingOriginalColor),
                      (c) => _apply(
                        () => settings.upcomingOriginalColor = _argbFromColor(c),
                      ),
                    ),
                    onPick2: () => _pickColor(
                      pageContext,
                      '未播到 — 译文',
                      Color(settings.upcomingTranslationColor),
                      (c) => _apply(
                        () => settings.upcomingTranslationColor =
                            _argbFromColor(c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '颜色将写入本地设置，切歌后仍保留。',
              style: TextStyle(fontSize: 12, color: _onDim, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '歌词样式',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _on,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '与当前播放页歌词同步',
                style: TextStyle(
                  fontSize: 13,
                  color: _onMuted,
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
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _on,
            letterSpacing: 0.6,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: _onDim, height: 1.2),
          ),
        ],
      ],
    );
  }

  Widget _frostedCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
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

  static Widget _softDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );

  Widget _switchRow({
    required IconData icon,
    required String label,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _on,
                    height: 1.2,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: _onDim,
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

  Widget _sliderBlock({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _on,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _on,
                  fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _colorStateBlock({
    required Color accent,
    required String title,
    required IconData icon,
    required Color c1,
    required Color c2,
    required VoidCallback onPick1,
    required VoidCallback onPick2,
  }) {
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
              Icon(icon, size: 18, color: _onMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _on,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _colorChip(
                  label: '原文',
                  color: c1,
                  onTap: onPick1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _colorChip(
                  label: '译文',
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

  Widget _colorChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _onMuted,
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
                    color: Colors.white.withValues(alpha: 0.35),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '点选色块',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
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
                                      ? Theme.of(dialogContext)
                                          .colorScheme
                                          .primary
                                      : Colors.white30,
                                  width: current == c ? 2.5 : 1,
                                ),
                                boxShadow: [
                                  if (current == c)
                                    BoxShadow(
                                      color: Theme.of(
                                        dialogContext,
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
}
