import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/setting/language_settings_page.dart';
import 'package:yeah_music/pages/setting/onedrive_settings_page.dart';
import 'package:yeah_music/pages/setting/playback_shortcuts_section.dart';
import 'package:yeah_music/pages/setting/wire_remote_control_section.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/widgets/desktop_floating_lyrics_host.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

void _showSettingHelp(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showAppScrollMessageDialog(context: context, title: title, body: body);
}

Widget _settingHelpButton(
  BuildContext context, {
  required AppLocalizations l10n,
  required String dialogTitle,
  required String dialogBody,
}) {
  return IconButton(
    tooltip: l10n.settingsRowHelpTooltip,
    icon: Icon(Icons.info_outline, size: 22, color: context.gradFg(0.55)),
    onPressed: () =>
        _showSettingHelp(context, title: dialogTitle, body: dialogBody),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
  );
}

/// Android：车载 / 锁屏媒体会话（封面、歌词行、切歌）。
class _AndroidCarLyricsSettingsSection extends StatefulWidget {
  const _AndroidCarLyricsSettingsSection();

  @override
  State<_AndroidCarLyricsSettingsSection> createState() =>
      _AndroidCarLyricsSettingsSectionState();
}

class _AndroidCarLyricsSettingsSectionState
    extends State<_AndroidCarLyricsSettingsSection> {
  bool _enabled = false;
  bool _showCover = true;
  bool _syncLyrics = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await SettingsService.loadAndroidCarLyricsEnabled();
    final c = await SettingsService.loadAndroidCarLyricsShowCover();
    final s = await SettingsService.loadAndroidCarLyricsSyncLyrics();
    if (!mounted) return;
    setState(() {
      _enabled = e;
      _showCover = c;
      _syncLyrics = s;
      _loaded = true;
    });
  }

  Future<void> _onEnabled(bool v) async {
    setState(() => _enabled = v);
    await SettingsService.saveAndroidCarLyricsEnabled(v);
  }

  Future<void> _onCover(bool v) async {
    setState(() => _showCover = v);
    await SettingsService.saveAndroidCarLyricsShowCover(v);
  }

  Future<void> _onSync(bool v) async {
    setState(() => _syncLyrics = v);
    await SettingsService.saveAndroidCarLyricsSyncLyrics(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final interactive =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final detailBody = interactive
        ? l10n.settingsCarLyricsGroupDetail
        : '${l10n.settingsCarLyricsGroupDetail}\n\n${l10n.settingsCarLyricsOnlyAndroidHint}';
    final subStyle = TextStyle(color: context.gradFg(0.6), fontSize: 13);
    if (!_loaded) {
      return ListTile(
        leading: Icon(Icons.directions_car_outlined, color: context.gradFg()),
        title: Text(
          l10n.settingsCarLyricsGroupTitle,
          style: TextStyle(color: context.gradFg()),
        ),
        subtitle: Text(l10n.settingsCarLyricsGroupSubtitle, style: subStyle),
        trailing: _settingHelpButton(
          context,
          l10n: l10n,
          dialogTitle: l10n.settingsCarLyricsGroupTitle,
          dialogBody: detailBody,
        ),
      );
    }
    final showDetailSwitches = !interactive || _enabled;
    return ExpansionTile(
      leading: Icon(Icons.directions_car_outlined, color: context.gradFg()),
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.settingsCarLyricsGroupTitle,
              style: TextStyle(color: context.gradFg()),
            ),
          ),
          _settingHelpButton(
            context,
            l10n: l10n,
            dialogTitle: l10n.settingsCarLyricsGroupTitle,
            dialogBody: detailBody,
          ),
        ],
      ),
      subtitle: Text(l10n.settingsCarLyricsGroupSubtitle, style: subStyle),
      iconColor: context.gradFg(),
      collapsedIconColor: context.gradFg(),
      children: [
        SwitchListTile(
          secondary: Icon(Icons.play_circle_outline, color: context.gradFg()),
          title: Text(
            l10n.settingsCarLyricsEnabled,
            style: TextStyle(color: context.gradFg()),
          ),
          subtitle: Text(
            l10n.settingsCarLyricsEnabledSubtitle,
            style: subStyle,
          ),
          value: _enabled,
          onChanged: interactive ? _onEnabled : null,
          activeThumbColor: context.gradFg(0.95),
          activeTrackColor: context.gradFg(0.35),
        ),
        if (showDetailSwitches) ...[
          SwitchListTile(
            secondary: Icon(Icons.album_outlined, color: context.gradFg()),
            title: Text(
              l10n.settingsCarLyricsShowCover,
              style: TextStyle(color: context.gradFg()),
            ),
            subtitle: Text(
              l10n.settingsCarLyricsShowCoverSubtitle,
              style: subStyle,
            ),
            value: _showCover,
            onChanged: interactive ? _onCover : null,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
          SwitchListTile(
            secondary: Icon(Icons.subtitles_outlined, color: context.gradFg()),
            title: Text(
              l10n.settingsCarLyricsSyncLyrics,
              style: TextStyle(color: context.gradFg()),
            ),
            subtitle: Text(
              l10n.settingsCarLyricsSyncLyricsSubtitle,
              style: subStyle,
            ),
            value: _syncLyrics,
            onChanged: interactive ? _onSync : null,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
        ],
      ],
    );
  }
}

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
            extendBodyBehindAppBar: false,
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
            body: Consumer<PlayListProvider>(
              builder: (context, play, _) {
                final showMini =
                    play.initialized &&
                    play.currentSong != null &&
                    play.playList.isNotEmpty;
                final bottomPad =
                    MediaQuery.paddingOf(context).bottom +
                    8 +
                    (showMini ? MiniPlayer.barHeight : 0.0);
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomPad),
                  children: [
                    ListTile(
                      title: Text(
                        l10n.settingsBackgroundTheme,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsBackgroundThemeSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
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
                    ListTile(
                      title: Text(
                        l10n.settingsLanguage,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsLanguageSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(Icons.language, color: context.gradFg()),
                      trailing: _settingHelpButton(
                        context,
                        l10n: l10n,
                        dialogTitle: l10n.settingsLanguage,
                        dialogBody: l10n.settingsLanguageDesc,
                      ),
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
                        l10n.settingsOneDrive,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsOneDriveSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(
                        Icons.cloud_outlined,
                        color: context.gradFg(),
                      ),
                      trailing: _settingHelpButton(
                        context,
                        l10n: l10n,
                        dialogTitle: l10n.settingsOneDrive,
                        dialogBody: l10n.settingsOneDriveDesc,
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const OneDriveSettingsPage(),
                          ),
                        );
                      },
                    ),
                    if (!kIsWeb &&
                        (Platform.isMacOS ||
                            Platform.isWindows ||
                            Platform.isLinux))
                      const PlaybackShortcutsSettingsSection(),
                    const _AndroidCarLyricsSettingsSection(),
                    if (!kIsWeb) const WireRemoteControlSection(),
                    if (_showDesktopLyricsSection)
                      const _DesktopLyricsSettingsSection(),
                    ListTile(
                      title: Text(
                        l10n.settingsAbout,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsAboutSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(Icons.favorite, color: context.gradFg()),
                      onTap: () {
                        ApplicationUtils.showAboutDialog(context);
                      },
                    ),
                    ExpansionTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: context.gradFg(),
                      ),
                      title: Text(
                        l10n.settingsSystemInfo,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsSystemInfoSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      iconColor: context.gradFg(),
                      collapsedIconColor: context.gradFg(),
                      children: const [DiskSpaceView()],
                    ),
                  ],
                );
              },
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

class _DesktopLyricsSettingsSectionState
    extends State<_DesktopLyricsSettingsSection> {
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
          Text(
            title,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: fgMuted, fontSize: 13)),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                label,
                style: TextStyle(color: fgMuted, fontSize: 13),
              ),
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
    final subStyle = TextStyle(color: context.gradFg(0.6), fontSize: 13);
    if (!_loaded) {
      return ListTile(
        leading: Icon(Icons.lyrics_outlined, color: context.gradFg()),
        title: Text(
          l10n.settingsDesktopLyricsGroupTitle,
          style: TextStyle(color: context.gradFg()),
        ),
        subtitle: Text(
          l10n.settingsDesktopLyricsGroupSubtitle,
          style: subStyle,
        ),
        trailing: _settingHelpButton(
          context,
          l10n: l10n,
          dialogTitle: l10n.settingsDesktopLyricsGroupTitle,
          dialogBody: l10n.settingsDesktopLyricsGroupDetail,
        ),
      );
    }

    return ExpansionTile(
      leading: Icon(Icons.lyrics_outlined, color: context.gradFg()),
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.settingsDesktopLyricsGroupTitle,
              style: TextStyle(color: context.gradFg()),
            ),
          ),
          _settingHelpButton(
            context,
            l10n: l10n,
            dialogTitle: l10n.settingsDesktopLyricsGroupTitle,
            dialogBody: l10n.settingsDesktopLyricsGroupDetail,
          ),
        ],
      ),
      subtitle: Text(l10n.settingsDesktopLyricsGroupSubtitle, style: subStyle),
      iconColor: context.gradFg(),
      collapsedIconColor: context.gradFg(),
      children: [
        SwitchListTile(
          secondary: Icon(
            Icons.picture_in_picture_alt_outlined,
            color: context.gradFg(),
          ),
          title: Text(
            l10n.settingsDesktopFloatingLyrics,
            style: TextStyle(color: context.gradFg()),
          ),
          subtitle: Text(
            l10n.settingsDesktopFloatingLyricsSubtitle,
            style: subStyle,
          ),
          value: _floating,
          onChanged: desktopFloatingLyricsSupported ? _onFloatingChanged : null,
          activeThumbColor: context.gradFg(0.95),
          activeTrackColor: context.gradFg(0.35),
        ),
        if (desktopFloatingLyricsSupported && _floating) ...[
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: context.gradFg()),
            title: Text(
              l10n.settingsDesktopFloatingDragLock,
              style: TextStyle(color: context.gradFg()),
            ),
            subtitle: Text(
              l10n.settingsDesktopFloatingDragLockSubtitle,
              style: subStyle,
            ),
            value: _dragLocked,
            onChanged: _onDragLockedChanged,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
          _floatingSliderBlock(
            context: context,
            title: l10n.settingsDesktopFloatingBgOpacity,
            subtitle: l10n.settingsDesktopFloatingBgOpacitySubtitle,
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
            title: l10n.settingsDesktopFloatingLinesBefore,
            subtitle: l10n.settingsDesktopFloatingLinesBeforeSubtitle,
            value: _linesBefore.toDouble(),
            min: 0,
            max: _kLinesMax.toDouble(),
            divisions: _kLinesMax,
            labelFor: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _linesBefore = v.round()),
            onChangeEnd: (v) async {
              await SettingsService.saveDesktopFloatingLyricsLinesBefore(
                v.round(),
              );
              await DesktopFloatingLyricsGlue.reloadFromHive();
            },
          ),
          _floatingSliderBlock(
            context: context,
            title: l10n.settingsDesktopFloatingLinesAfter,
            subtitle: l10n.settingsDesktopFloatingLinesAfterSubtitle,
            value: _linesAfter.toDouble(),
            min: 0,
            max: _kLinesMax.toDouble(),
            divisions: _kLinesMax,
            labelFor: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _linesAfter = v.round()),
            onChangeEnd: (v) async {
              await SettingsService.saveDesktopFloatingLyricsLinesAfter(
                v.round(),
              );
              await DesktopFloatingLyricsGlue.reloadFromHive();
            },
          ),
        ],
        if (Platform.isMacOS)
          SwitchListTile(
            secondary: Icon(Icons.podcasts_rounded, color: context.gradFg()),
            title: Text(
              l10n.settingsMacosMenuBarLyrics,
              style: TextStyle(color: context.gradFg()),
            ),
            subtitle: Text(
              l10n.settingsMacosMenuBarLyricsSubtitle,
              style: subStyle,
            ),
            value: _menuBar,
            onChanged: MacosMenuBarLyrics.supported ? _onMenuBarChanged : null,
            activeThumbColor: context.gradFg(0.95),
            activeTrackColor: context.gradFg(0.35),
          ),
      ],
    );
  }
}
