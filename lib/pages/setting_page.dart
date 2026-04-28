import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/setting/language_settings_page.dart';
import 'package:yeah_music/pages/setting/onedrive_settings_page.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/application_utils.dart';

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
              title: Text(l10n.settingsTitle, style: TextStyle(color: context.gradFg())),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              children: [
                ListTile(
                  title: Text(l10n.settingsBackgroundTheme, style: TextStyle(color: context.gradFg())),
                  subtitle: Text(l10n.settingsBackgroundThemeDesc, style: TextStyle(color: context.gradFg(0.6))),
                  leading: Icon(Icons.color_lens, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingPage()));
                  },
                ),
                ListTile(
                  title: Text(l10n.settingsLanguage, style: TextStyle(color: context.gradFg())),
                  subtitle: Text(l10n.settingsLanguageDesc, style: TextStyle(color: context.gradFg(0.6))),
                  leading: Icon(Icons.language, color: context.gradFg()),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (context) => const LanguageSettingsPage()),
                    );
                  },
                ),
                ListTile(
                  title: Text(l10n.settingsOneDrive, style: TextStyle(color: context.gradFg())),
                  subtitle: Text(l10n.settingsOneDriveDesc, style: TextStyle(color: context.gradFg(0.6))),
                  leading: Icon(Icons.cloud_outlined, color: context.gradFg()),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (context) => const OneDriveSettingsPage()),
                    );
                  },
                ),
                if (!kIsWeb && Platform.isMacOS) const _MacosMenuBarLyricsSettingTile(),
                ListTile(
                  title: Text(l10n.settingsAbout, style: TextStyle(color: context.gradFg())),
                  subtitle: Text(l10n.settingsAboutDesc, style: TextStyle(color: context.gradFg(0.6))),
                  leading: Icon(Icons.favorite, color: context.gradFg()),
                  onTap: () {
                    ApplicationUtils.showAboutDialog(context);
                  },
                ),
                ExpansionTile(
                  title: Text(l10n.settingsSystemInfo, style: TextStyle(color: context.gradFg())),
                  subtitle: Text(l10n.settingsSystemInfoDesc, style: TextStyle(color: context.gradFg(0.6))),
                  leading: Icon(Icons.info_outline, color: context.gradFg()),
                  iconColor: context.gradFg(),
                  collapsedIconColor: context.gradFg(),
                  children: const [DiskSpaceView()],
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

class _MacosMenuBarLyricsSettingTile extends StatefulWidget {
  const _MacosMenuBarLyricsSettingTile();

  @override
  State<_MacosMenuBarLyricsSettingTile> createState() => _MacosMenuBarLyricsSettingTileState();
}

class _MacosMenuBarLyricsSettingTileState extends State<_MacosMenuBarLyricsSettingTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await SettingsService.loadMacosMenuBarLyricsEnabled();
    if (!mounted) return;
    setState(() {
      _value = v;
      _loaded = true;
    });
  }

  Future<void> _onChanged(bool v) async {
    setState(() => _value = v);
    await SettingsService.saveMacosMenuBarLyricsEnabled(v);
    await MacosMenuBarLyricsGlue.reloadFromHive();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_loaded) {
      return ListTile(
        leading: Icon(Icons.more_horiz, color: context.gradFg()),
        title: Text(l10n.settingsMacosMenuBarLyrics, style: TextStyle(color: context.gradFg())),
        subtitle: Text(l10n.settingsMacosMenuBarLyricsDesc, style: TextStyle(color: context.gradFg(0.6))),
      );
    }
    return SwitchListTile(
      secondary: Icon(Icons.podcasts_rounded, color: context.gradFg()),
      title: Text(l10n.settingsMacosMenuBarLyrics, style: TextStyle(color: context.gradFg())),
      subtitle: Text(l10n.settingsMacosMenuBarLyricsDesc, style: TextStyle(color: context.gradFg(0.6))),
      value: _value,
      onChanged: MacosMenuBarLyrics.supported ? _onChanged : null,
      activeThumbColor: context.gradFg(0.95),
      activeTrackColor: context.gradFg(0.35),
    );
  }
}
