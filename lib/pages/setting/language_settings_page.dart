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
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/themes/app_locale_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeConfigProvider, AppLocaleProvider>(
      builder: (context, themeConfig, locale, _) {
        final l10n = AppLocalizations.of(context);
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                l10n.languageSettingsTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: context.gradFg(), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                Text(
                  l10n.languageSettingsDescription,
                  style: TextStyle(
                    color: context.gradFg(0.6),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.languageRestartNotice,
                  style: TextStyle(
                    color: context.gradFg(0.6),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _optionTile(
                  context,
                  title: l10n.langFollowSystem,
                  selected: locale.option == AppLanguageOption.system,
                  onTap: () => locale.setOption(AppLanguageOption.system),
                ),
                _optionTile(
                  context,
                  title: l10n.langEnglish,
                  selected: locale.option == AppLanguageOption.en,
                  onTap: () => locale.setOption(AppLanguageOption.en),
                ),
                _optionTile(
                  context,
                  title: l10n.langJapanese,
                  selected: locale.option == AppLanguageOption.ja,
                  onTap: () => locale.setOption(AppLanguageOption.ja),
                ),
                _optionTile(
                  context,
                  title: l10n.langSimplifiedChinese,
                  selected: locale.option == AppLanguageOption.zhHans,
                  onTap: () => locale.setOption(AppLanguageOption.zhHans),
                ),
                _optionTile(
                  context,
                  title: l10n.langTraditionalChinese,
                  selected: locale.option == AppLanguageOption.zhHant,
                  onTap: () => locale.setOption(AppLanguageOption.zhHant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      title: Text(
        title,
        style: TextStyle(color: context.gradFg(), fontSize: 16),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: context.gradFg(), size: 24)
          : Icon(Icons.circle_outlined, color: context.gradFg(0.25), size: 24),
      onTap: onTap,
    );
  }
}
