import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/pages/setting/language_settings_page.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.settingsTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              children: [
                ListTile(
                  title: Text(
                    l10n.settingsLanguage,
                    style: TextStyle(color: context.gradFg()),
                  ),
                  subtitle: Text(
                    l10n.settingsLanguageDesc,
                    style: TextStyle(color: context.gradFg(0.6)),
                  ),
                  leading: Icon(Icons.language, color: context.gradFg()),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const LanguageSettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    l10n.settingsBackgroundTheme,
                    style: TextStyle(color: context.gradFg()),
                  ),
                  subtitle: Text(
                    l10n.settingsBackgroundThemeDesc,
                    style: TextStyle(color: context.gradFg(0.6)),
                  ),
                  leading: Icon(Icons.color_lens, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingPage(),
                      ),
                    );
                  },
                ),
                ExpansionTile(
                  title: Text(
                    l10n.settingsSystemInfo,
                    style: TextStyle(color: context.gradFg()),
                  ),
                  subtitle: Text(
                    l10n.settingsSystemInfoDesc,
                    style: TextStyle(color: context.gradFg(0.6)),
                  ),
                  leading: Icon(Icons.info_outline, color: context.gradFg()),
                  iconColor: context.gradFg(),
                  collapsedIconColor: context.gradFg(),
                  children: const [DiskSpaceView()],
                ),
                ListTile(
                  title: Text(
                    l10n.settingsAbout,
                    style: TextStyle(color: context.gradFg()),
                  ),
                  subtitle: Text(
                    l10n.settingsAboutDesc,
                    style: TextStyle(color: context.gradFg(0.6)),
                  ),
                  leading: Icon(Icons.favorite, color: context.gradFg()),
                  onTap: () {
                    ApplicationUtils.showAboutDialog(context);
                  },
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
