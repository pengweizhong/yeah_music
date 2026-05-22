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
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/themes/platform_typography.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

/// 首页问候：自定义句子列表与顺序 / 随机轮播。
class HomeGreetingSettingsPage extends StatefulWidget {
  const HomeGreetingSettingsPage({super.key});

  @override
  State<HomeGreetingSettingsPage> createState() =>
      _HomeGreetingSettingsPageState();
}

class _HomeGreetingSettingsPageState extends State<HomeGreetingSettingsPage> {
  final List<TextEditingController> _controllers = [];
  bool _rotationRandom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lines = await SettingsService.loadHomeGreetingCustomSubtitles();
    final rnd = await SettingsService.loadHomeGreetingRotationRandom();
    if (!mounted) return;
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers
      ..clear()
      ..addAll(lines.map((s) => TextEditingController(text: s)));
    setState(() => _rotationRandom = rnd);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeAt(int i) {
    setState(() => _controllers.removeAt(i).dispose());
  }

  Future<void> _save() async {
    final texts = _controllers.map((c) => c.text).toList();
    await SettingsService.saveHomeGreetingCustomSubtitles(texts);
    await SettingsService.saveHomeGreetingRotationRandom(_rotationRandom);
    if (!mounted) return;
    showAppSnackBar(
      context,
      AppLocalizations.of(context).settingsHomeGreetingSaved,
      kind: AppSnackKind.success,
    );
  }

  Widget _rotationButtons(AppLocalizations l10n, ThemeData theme) {
    final scheme = theme.colorScheme;
    ButtonStyle sel(bool on) => OutlinedButton.styleFrom(
          foregroundColor: on ? scheme.onPrimary : context.gradFg(),
          backgroundColor: on ? scheme.primary : Colors.transparent,
          side: BorderSide(
            color: on ? scheme.primary : context.gradBorder(0.22),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: sel(!_rotationRandom),
            onPressed: () => setState(() => _rotationRandom = false),
            child: Text(l10n.settingsHomeGreetingRotationSequential),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: sel(_rotationRandom),
            onPressed: () => setState(() => _rotationRandom = true),
            child: Text(l10n.settingsHomeGreetingRotationRandom),
          ),
        ),
      ],
    );
  }

  Widget _lineRow(AppLocalizations l10n, int rowIndex) {
    final c = _controllers[rowIndex];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SizedBox(
            width: 28,
            child: Text(
              '${rowIndex + 1}.',
              style: context.gradTextStyle(
                color: context.gradFg(0.42),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: c,
            minLines: 1,
            maxLines: 4,
            style: context.gradTextStyle(height: 1.35),
            decoration: InputDecoration(
              hintText: l10n.settingsHomeGreetingLineHint,
              hintStyle: context.gradTextStyle(color: context.gradFg(0.38)),
              filled: true,
              fillColor: context.gradBorder(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.gradBorder(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.gradBorder(0.12)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          icon:
              Icon(Icons.delete_outline_rounded, color: context.gradFg(0.55)),
          onPressed: () => _removeAt(rowIndex),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: PlatformTypography.desktopFontScope(
            context: context,
            defaultColor: context.gradFg(),
            child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                l10n.settingsHomeGreetingTitle,
                style: context.gradAppBarTitleStyle(fontSize: 18),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: context.gradFg(),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton(
                  onPressed: _save,
                  child: Text(
                    l10n.settingsHomeGreetingSave,
                    style: context.gradTextStyle(color: context.gradFg(0.95)),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  l10n.settingsHomeGreetingHelp,
                  style: context.gradTextStyle(
                    color: context.gradFg(0.6),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.settingsHomeGreetingRotationTitle,
                  style: context.gradTextStyle(
                    color: context.gradFg(0.88),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _rotationButtons(l10n, theme),
                const SizedBox(height: 24),
                if (_controllers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.settingsHomeGreetingEmptyHint,
                      style: context.gradTextStyle(
                        color: context.gradFg(0.48),
                        fontSize: 14,
                      ),
                    ),
                  ),
                for (var i = 0; i < _controllers.length; i++) ...[
                  _lineRow(l10n, i),
                  const SizedBox(height: 12),
                ],
                TextButton.icon(
                  onPressed: _addLine,
                  icon: Icon(Icons.add_rounded, color: context.gradFg(0.85)),
                  label: Text(
                    l10n.settingsHomeGreetingAddLine,
                    style: context.gradTextStyle(color: context.gradFg(0.9)),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}
