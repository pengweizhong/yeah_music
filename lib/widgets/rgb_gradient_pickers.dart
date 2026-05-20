// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';

/// 线性渐变方向在设置、歌单封面等处共用的图标（与 [PlaylistCoverGradientDirection] 一致）。
IconData linearGradientDirectionIcon(PlaylistCoverGradientDirection d) {
  switch (d) {
    case PlaylistCoverGradientDirection.horizontalLtr:
      return Icons.arrow_right_alt_rounded;
    case PlaylistCoverGradientDirection.horizontalRtl:
      return Icons.arrow_back_rounded;
    case PlaylistCoverGradientDirection.verticalTtb:
      return Icons.arrow_downward_rounded;
    case PlaylistCoverGradientDirection.verticalBtt:
      return Icons.arrow_upward_rounded;
    case PlaylistCoverGradientDirection.diagonalTlBr:
      return Icons.south_east_rounded;
    case PlaylistCoverGradientDirection.diagonalTrBl:
      return Icons.south_west_rounded;
    case PlaylistCoverGradientDirection.diagonalBrTl:
      return Icons.north_west_rounded;
    case PlaylistCoverGradientDirection.diagonalBlTr:
      return Icons.north_east_rounded;
  }
}

/// 线性渐变方向的可见标签（文案与歌单封面一致，避免重复维护）。
String linearGradientDirectionLabel(
  AppLocalizations l10n,
  PlaylistCoverGradientDirection d,
) {
  switch (d) {
    case PlaylistCoverGradientDirection.horizontalLtr:
      return l10n.playlistCoverGradientDirHorizontalLR;
    case PlaylistCoverGradientDirection.horizontalRtl:
      return l10n.playlistCoverGradientDirHorizontalRL;
    case PlaylistCoverGradientDirection.verticalTtb:
      return l10n.playlistCoverGradientDirVerticalTB;
    case PlaylistCoverGradientDirection.verticalBtt:
      return l10n.playlistCoverGradientDirVerticalBT;
    case PlaylistCoverGradientDirection.diagonalTlBr:
      return l10n.playlistCoverGradientDirDiagonalTLBR;
    case PlaylistCoverGradientDirection.diagonalTrBl:
      return l10n.playlistCoverGradientDirDiagonalTRBL;
    case PlaylistCoverGradientDirection.diagonalBrTl:
      return l10n.playlistCoverGradientDirDiagonalBRTL;
    case PlaylistCoverGradientDirection.diagonalBlTr:
      return l10n.playlistCoverGradientDirDiagonalBLTR;
  }
}

Color contrastingSurfaceLabelColor(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.55 ? const Color(0xFF111418) : Colors.white;
}

/// 双色 RGB 滑块 + 渐变方向；用于歌单封面、设置主题背景等。
class GradientRgbPickDialogContent extends StatefulWidget {
  const GradientRgbPickDialogContent({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.initialDirection,
    required this.l10n,
    required this.onPick,
    this.dialogTitle,
  });

  final Color initialStart;
  final Color initialEnd;
  final PlaylistCoverGradientDirection initialDirection;
  final AppLocalizations l10n;
  final void Function(Color a, Color b, PlaylistCoverGradientDirection dir)
      onPick;

  /// 为 `null` 时使用 [AppLocalizations.playlistCoverCustomGradientTitle]。
  final String? dialogTitle;

  @override
  State<GradientRgbPickDialogContent> createState() =>
      _GradientRgbPickDialogContentState();
}

class _GradientRgbPickDialogContentState
    extends State<GradientRgbPickDialogContent> {
  late Color _start;
  late Color _end;
  late PlaylistCoverGradientDirection _dir;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _dir = widget.initialDirection;
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
    final midBlend = Color.lerp(_start, _end, 0.5)!;
    final viewPad = MediaQuery.paddingOf(context);
    final maxScrollH =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(180.0, 420.0);
    final title = widget.dialogTitle ?? l10n.playlistCoverCustomGradientTitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 12 + viewPad.bottom * 0.02),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxScrollH),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: playlistCoverLinearGradient(
                            [_start, _end],
                            direction: _dir,
                          ),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            l10n.playlistCoverRgbPreview,
                            style: TextStyle(
                              color: contrastingSurfaceLabelColor(midBlend),
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                  blurRadius: 6,
                                  color: Color(0x99000000),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        final t = _start;
                        _start = _end;
                        _end = t;
                      }),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      label: Text(l10n.playlistCoverGradientSwapColors),
                    ),
                  ),
                  Text(
                    l10n.playlistCoverGradientDirectionTitle,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in PlaylistCoverGradientDirection.values)
                        Tooltip(
                          message: linearGradientDirectionLabel(l10n, d),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () => setState(() => _dir = d),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _dir == d
                                        ? scheme.primary
                                        : scheme.outline
                                            .withValues(alpha: 0.38),
                                    width: _dir == d ? 2.2 : 1,
                                  ),
                                  color: _dir == d
                                      ? scheme.primary.withValues(alpha: 0.14)
                                      : scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.28),
                                ),
                                child: Icon(
                                  linearGradientDirectionIcon(d),
                                  size: 22,
                                  color: scheme.onSurface.withValues(
                                    alpha: _dir == d ? 1 : 0.82,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.playlistCoverGradientStartColor,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: sliderTheme,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbRed,
                          value: _start.r,
                          onChanged: (v) => setState(
                            () => _start = _start.withValues(red: v),
                          ),
                        ),
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbGreen,
                          value: _start.g,
                          onChanged: (v) => setState(
                            () => _start = _start.withValues(green: v),
                          ),
                        ),
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbBlue,
                          value: _start.b,
                          onChanged: (v) => setState(
                            () => _start = _start.withValues(blue: v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.playlistCoverGradientEndColor,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: sliderTheme,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbRed,
                          value: _end.r,
                          onChanged: (v) =>
                              setState(() => _end = _end.withValues(red: v)),
                        ),
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbGreen,
                          value: _end.g,
                          onChanged: (v) =>
                              setState(() => _end = _end.withValues(green: v)),
                        ),
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbBlue,
                          value: _end.b,
                          onChanged: (v) =>
                              setState(() => _end = _end.withValues(blue: v)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8 + viewPad.bottom * 0.15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  widget.onPick(_start, _end, _dir);
                  Navigator.pop(context);
                },
                child: Text(l10n.actionOK),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单色 RGB 滑块对话框（歌单封面自定义实色等）。
class RgbPickDialogContent extends StatefulWidget {
  const RgbPickDialogContent({
    super.key,
    required this.initial,
    required this.l10n,
    required this.onPick,
    this.dialogTitle,
  });

  final Color initial;
  final AppLocalizations l10n;
  final ValueChanged<Color> onPick;

  /// 为 `null` 时使用 [AppLocalizations.playlistCoverRgbTitle]。
  final String? dialogTitle;

  @override
  State<RgbPickDialogContent> createState() => _RgbPickDialogContentState();
}

class _RgbPickDialogContentState extends State<RgbPickDialogContent> {
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
    final viewPad = MediaQuery.paddingOf(context);
    final maxScrollH =
        (MediaQuery.sizeOf(context).height * 0.38).clamp(160.0, 320.0);
    final title = widget.dialogTitle ?? l10n.playlistCoverRgbTitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 12 + viewPad.bottom * 0.02),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxScrollH),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              l10n.playlistCoverRgbPreview,
                              style: TextStyle(
                                color: contrastingSurfaceLabelColor(_c),
                                fontWeight: FontWeight.w700,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Color(0x66000000),
                                  ),
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
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbRed,
                          value: _c.r,
                          onChanged: (v) =>
                              setState(() => _c = _c.withValues(red: v)),
                        ),
                        RgbChannelSlider(
                          label: l10n.playlistCoverRgbGreen,
                          value: _c.g,
                          onChanged: (v) =>
                              setState(() => _c = _c.withValues(green: v)),
                        ),
                        RgbChannelSlider(
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
          ),
          SizedBox(height: 8 + viewPad.bottom * 0.15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  widget.onPick(_c);
                  Navigator.pop(context);
                },
                child: Text(l10n.actionOK),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RgbChannelSlider extends StatelessWidget {
  const RgbChannelSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final fg =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${(value * 255).round()})',
          style: TextStyle(color: fg, fontSize: 13),
        ),
        Slider(
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
