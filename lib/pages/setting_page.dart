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
import 'package:yeah_music/widgets/desktop_floating_lyrics_host.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static bool get _showDesktopLyricsSection =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

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
                if (_showDesktopLyricsSection) const _DesktopLyricsSettingsSection(),
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

/// 桌面歌词：悬浮窗（各桌面平台）+ 菜单栏（仅 macOS）。
class _DesktopLyricsSettingsSection extends StatefulWidget {
  const _DesktopLyricsSettingsSection();

  @override
  State<_DesktopLyricsSettingsSection> createState() =>
      _DesktopLyricsSettingsSectionState();
}

class _DesktopLyricsSettingsSectionState extends State<_DesktopLyricsSettingsSection> {
  static const double _kBgOpacityMin = 0.0;
  static const double _kBgOpacityMax = 0.92;
  static const int _kLinesMax = 20;

  bool _floating = false;
  bool _menuBar = false;
  bool _loaded = false;
  double _bgOpacity = SettingsService.desktopFloatingLyricsBgOpacityDefault;
  int _linesBefore = SettingsService.desktopFloatingLyricsLinesBeforeDefault;
  int _linesAfter = SettingsService.desktopFloatingLyricsLinesAfterDefault;
  bool _dragLocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await SettingsService.loadDesktopFloatingLyricsEnabled();
    final m = await SettingsService.loadMacosMenuBarLyricsEnabled();
    final bg = await SettingsService.loadDesktopFloatingLyricsBgOpacity();
    final lb = await SettingsService.loadDesktopFloatingLyricsLinesBefore();
    final la = await SettingsService.loadDesktopFloatingLyricsLinesAfter();
    final lk = await SettingsService.loadDesktopFloatingLyricsDragLocked();
    if (!mounted) return;
    setState(() {
      _floating = f;
      _menuBar = m;
      _bgOpacity = bg;
      _linesBefore = lb;
      _linesAfter = la;
      _dragLocked = lk;
      _loaded = true;
    });
  }

  Future<void> _onFloatingChanged(bool v) async {
    setState(() => _floating = v);
    await SettingsService.saveDesktopFloatingLyricsEnabled(v);
    await DesktopFloatingLyricsGlue.reloadFromHive();
  }

  Future<void> _onMenuBarChanged(bool v) async {
    setState(() => _menuBar = v);
    await SettingsService.saveMacosMenuBarLyricsEnabled(v);
    await MacosMenuBarLyricsGlue.reloadFromHive();
  }

  Future<void> _onDragLockedChanged(bool v) async {
    setState(() => _dragLocked = v);
    await SettingsService.saveDesktopFloatingLyricsDragLocked(v);
    await DesktopFloatingLyricsGlue.reloadFromHive();
  }

  Widget _floatingSliderBlock({
    required BuildContext context,
    required AppLocalizations l10n,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    String Function(double v)? labelFor,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final fg = context.gradFg();
    final fgMuted = context.gradFg(0.6);
    final label = labelFor?.call(value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            label != null ? '$subtitle · $label' : subtitle,
            style: TextStyle(color: fgMuted, fontSize: 13),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_loaded) {
      return ListTile(
        leading: Icon(Icons.lyrics_outlined, color: context.gradFg()),
        title: Text(l10n.settingsDesktopLyricsGroupTitle, style: TextStyle(color: context.gradFg())),
        subtitle: Text(l10n.settingsDesktopLyricsGroupSubtitle, style: TextStyle(color: context.gradFg(0.6))),
      );
    }

    return ExpansionTile(
      leading: Icon(Icons.lyrics_outlined, color: context.gradFg()),
      title: Text(l10n.settingsDesktopLyricsGroupTitle, style: TextStyle(color: context.gradFg())),
      subtitle: Text(l10n.settingsDesktopLyricsGroupSubtitle, style: TextStyle(color: context.gradFg(0.6))),
      iconColor: context.gradFg(),
      collapsedIconColor: context.gradFg(),
      children: [
        SwitchListTile(
          secondary: Icon(Icons.picture_in_picture_alt_outlined, color: context.gradFg()),
          title: Text(l10n.settingsDesktopFloatingLyrics, style: TextStyle(color: context.gradFg())),
          subtitle: Text(l10n.settingsDesktopFloatingLyricsDesc, style: TextStyle(color: context.gradFg(0.6))),
          value: _floating,
          onChanged: desktopFloatingLyricsSupported ? _onFloatingChanged : null,
          activeThumbColor: context.gradFg(0.95),
          activeTrackColor: context.gradFg(0.35),
        ),
        if (desktopFloatingLyricsSupported && _floating) ...[
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: context.gradFg()),
            title: Text(l10n.settingsDesktopFloatingDragLock, style: TextStyle(color: context.gradFg())),
            subtitle: Text(l10n.settingsDesktopFloatingDragLockDesc, style: TextStyle(color: context.gradFg(0.6))),
            value: _dragLocked,
            onChanged: _onDragLockedChanged,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
          _floatingSliderBlock(
            context: context,
            l10n: l10n,
            title: l10n.settingsDesktopFloatingBgOpacity,
            subtitle: l10n.settingsDesktopFloatingBgOpacityDesc,
            value: _bgOpacity,
            min: _kBgOpacityMin,
            max: _kBgOpacityMax,
            labelFor: (v) => '${(v * 100).round()}%',
            onChanged: (v) => setState(() => _bgOpacity = v),
            onChangeEnd: (v) async {
              await SettingsService.saveDesktopFloatingLyricsBgOpacity(v);
              await DesktopFloatingLyricsGlue.reloadFromHive();
            },
          ),
          _floatingSliderBlock(
            context: context,
            l10n: l10n,
            title: l10n.settingsDesktopFloatingLinesBefore,
            subtitle: l10n.settingsDesktopFloatingLinesBeforeDesc,
            value: _linesBefore.toDouble(),
            min: 0,
            max: _kLinesMax.toDouble(),
            divisions: _kLinesMax,
            labelFor: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _linesBefore = v.round()),
            onChangeEnd: (v) async {
              await SettingsService.saveDesktopFloatingLyricsLinesBefore(v.round());
              await DesktopFloatingLyricsGlue.reloadFromHive();
            },
          ),
          _floatingSliderBlock(
            context: context,
            l10n: l10n,
            title: l10n.settingsDesktopFloatingLinesAfter,
            subtitle: l10n.settingsDesktopFloatingLinesAfterDesc,
            value: _linesAfter.toDouble(),
            min: 0,
            max: _kLinesMax.toDouble(),
            divisions: _kLinesMax,
            labelFor: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _linesAfter = v.round()),
            onChangeEnd: (v) async {
              await SettingsService.saveDesktopFloatingLyricsLinesAfter(v.round());
              await DesktopFloatingLyricsGlue.reloadFromHive();
            },
          ),
        ],
        if (Platform.isMacOS)
          SwitchListTile(
            secondary: Icon(Icons.podcasts_rounded, color: context.gradFg()),
            title: Text(l10n.settingsMacosMenuBarLyrics, style: TextStyle(color: context.gradFg())),
            subtitle: Text(l10n.settingsMacosMenuBarLyricsDesc, style: TextStyle(color: context.gradFg(0.6))),
            value: _menuBar,
            onChanged: MacosMenuBarLyrics.supported ? _onMenuBarChanged : null,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
      ],
    );
  }
}
