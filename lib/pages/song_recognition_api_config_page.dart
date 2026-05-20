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
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/acr_cloud_recognition_config.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

/// 听歌识曲：AudD / ACRCloud 接口凭证（与主页面解耦）。
class SongRecognitionApiConfigPage extends StatefulWidget {
  const SongRecognitionApiConfigPage({super.key});

  @override
  State<SongRecognitionApiConfigPage> createState() =>
      _SongRecognitionApiConfigPageState();
}

class _SongRecognitionApiConfigPageState
    extends State<SongRecognitionApiConfigPage> {
  late final TextEditingController _auddCtrl;
  late final TextEditingController _acrHostCtrl;
  late final TextEditingController _acrKeyCtrl;
  late final TextEditingController _acrSecretCtrl;

  @override
  void initState() {
    super.initState();
    _auddCtrl = TextEditingController();
    _acrHostCtrl = TextEditingController();
    _acrKeyCtrl = TextEditingController();
    _acrSecretCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final t = await SettingsService.loadAuddApiToken();
      final ac = await SettingsService.loadAcrCloudRecognitionConfig();
      if (!mounted) return;
      _auddCtrl.text = t;
      _acrHostCtrl.text = ac.host;
      _acrKeyCtrl.text = ac.accessKey;
      _acrSecretCtrl.text = ac.accessSecret;
    });
  }

  @override
  void dispose() {
    _auddCtrl.dispose();
    _acrHostCtrl.dispose();
    _acrKeyCtrl.dispose();
    _acrSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAudd() async {
    final l10n = AppLocalizations.of(context);
    await SettingsService.saveAuddApiToken(_auddCtrl.text);
    if (!mounted) return;
    showAppSnackBar(
      context,
      l10n.songRecognizerConfigSaved,
      kind: AppSnackKind.success,
    );
  }

  Future<void> _saveAcr() async {
    final l10n = AppLocalizations.of(context);
    final next = AcrCloudRecognitionConfig(
      host: _acrHostCtrl.text.trim(),
      accessKey: _acrKeyCtrl.text.trim(),
      accessSecret: _acrSecretCtrl.text.trim(),
    );
    await SettingsService.saveAcrCloudRecognitionConfig(next);
    if (!mounted) return;
    showAppSnackBar(
      context,
      l10n.songRecognizerConfigSaved,
      kind: AppSnackKind.success,
    );
  }

  InputDecoration _apiFieldDec(BuildContext context, String label,
      [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: context.gradFg(0.55)),
      hintStyle: TextStyle(color: context.gradFg(0.38)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.gradFg(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.gradFg(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.gradFg(0.42)),
      ),
    );
  }

  Widget _configCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradFg(0.13)),
        color: Colors.white.withValues(alpha: 0.055),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.gradFg(0.94),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: context.gradFg(0.52),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.songRecognizerSectionApiConfig,
                style: TextStyle(color: context.gradFg(0.95)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                Text(
                  l10n.songRecognizerConfigHint,
                  style: TextStyle(
                    color: context.gradFg(0.55),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _configCard(
                  context: context,
                  title: l10n.songRecognizerProviderAudd,
                  subtitle: l10n.songRecognizerAuddCardSubtitle,
                  icon: Icons.graphic_eq_rounded,
                  accent: const Color(0xFFB388FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.songRecognizerApiKeyHelp,
                        style: TextStyle(
                          color: context.gradFg(0.55),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _auddCtrl,
                        maxLines: 2,
                        style: TextStyle(
                          color: context.gradFg(0.92),
                          fontSize: 14,
                        ),
                        decoration: _apiFieldDec(
                          context,
                          l10n.songRecognizerApiKey,
                          'api_token',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: _saveAudd,
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: Text(l10n.songRecognizerSave),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _configCard(
                  context: context,
                  title: l10n.songRecognizerAcrCardTitle,
                  subtitle: l10n.songRecognizerAcrCardSubtitle,
                  icon: Icons.hub_outlined,
                  accent: const Color(0xFFFFB74D),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.songRecognizerAcrHelp,
                        style: TextStyle(
                          color: context.gradFg(0.55),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _acrHostCtrl,
                        style: TextStyle(
                          color: context.gradFg(0.92),
                          fontSize: 14,
                        ),
                        decoration: _apiFieldDec(
                          context,
                          l10n.songRecognizerAcrHost,
                          l10n.songRecognizerAcrHostHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _acrKeyCtrl,
                        style: TextStyle(
                          color: context.gradFg(0.92),
                          fontSize: 14,
                        ),
                        decoration: _apiFieldDec(
                          context,
                          l10n.songRecognizerAcrAccessKey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _acrSecretCtrl,
                        obscureText: true,
                        style: TextStyle(
                          color: context.gradFg(0.92),
                          fontSize: 14,
                        ),
                        decoration: _apiFieldDec(
                          context,
                          l10n.songRecognizerAcrSecret,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: _saveAcr,
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: Text(l10n.songRecognizerSave),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }
}
