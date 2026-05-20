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

import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/pages/setting/diagnostic_log_page.dart';
import 'package:yeah_music/pages/setting/language_settings_page.dart';
import 'package:yeah_music/pages/setting/audio_quality_settings_page.dart';
import 'package:yeah_music/pages/setting/home_greeting_settings_page.dart';
import 'package:yeah_music/pages/setting/onedrive_settings_page.dart';
import 'package:yeah_music/pages/setting/playback_shortcuts_section.dart';
import 'package:yeah_music/pages/setting/sponsor_support_page.dart';
import 'package:yeah_music/pages/setting/wire_remote_control_section.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/services/android_car_lyrics_sync.dart';
import 'package:yeah_music/services/android_media_session_lyrics_channel.dart';
import 'package:yeah_music/services/macos_menu_bar_lyrics.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';
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

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final fixed = size >= 100 ? 0 : 1;
  return '${size.toStringAsFixed(fixed)} ${units[unit]}';
}

Future<int> _directoryBytes(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    try {
      total += await entity.length();
    } catch (_) {}
  }
  return total;
}

Future<List<Directory>> _managedCacheDirectories() async {
  final dirs = <Directory>[];
  final seen = <String>{};
  Future<void> addDir(Directory dir) async {
    final norm = p.normalize(dir.path);
    if (seen.add(norm)) dirs.add(dir);
  }

  final appCache = await getApplicationCacheDirectory();
  await addDir(appCache);

  final support = await getApplicationSupportDirectory();
  await addDir(Directory(p.join(support.path, 'onedrive_cache')));
  return dirs;
}

Future<int> _loadManagedCacheBytes() async {
  final dirs = await _managedCacheDirectories();
  var total = 0;
  for (final d in dirs) {
    total += await _directoryBytes(d);
  }
  total += await _loadHiveCacheFilesBytes();
  return total;
}

Future<int> _loadHiveCacheFilesBytes() async {
  final docs = await getApplicationDocumentsDirectory();
  final boxes = <String>[
    'settings',
    Constant.hiveRootPath,
    Constant.hiveFolderBox,
  ];
  const suffixes = <String>['.hive', '.hivec', '.lock'];
  var total = 0;
  for (final name in boxes) {
    final base = name.trim().toLowerCase();
    if (base.isEmpty) continue;
    for (final suffix in suffixes) {
      final file = File(p.join(docs.path, '$base$suffix'));
      if (!await file.exists()) continue;
      try {
        total += await file.length();
      } catch (_) {}
    }
  }
  return total;
}

Future<void> _clearManagedCacheDirectories() async {
  final dirs = await _managedCacheDirectories();
  for (final d in dirs) {
    if (!await d.exists()) continue;
    await for (final entity in d.list(recursive: false, followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {}
    }
  }

  // 按现有初始化逻辑清掉 Hive 缓存数据（用户已明确要求）。
  final boxes = <String>[
    'settings',
    Constant.hiveRootPath,
    Constant.hiveFolderBox,
  ];
  for (final boxName in boxes) {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    } catch (_) {}
    await HiveUtils.deleteHiveBoxDiskFilesBestEffort(boxName);
  }
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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final pl = context.read<PlayListProvider>();
    var ok = true;
    if (!v) {
      await AndroidMediaSessionLyricsChannel.setCarNotificationEnabled(false);
      ok = await pl.ensureAndroidSingleSourceBeforeCarNotifyOff();
    }
    if (v) {
      await AndroidCarLyricsSync.attachIfNeeded(pl);
    } else {
      await AndroidCarLyricsSync.detach();
    }
    await AndroidCarLyricsSync.applySettingsFromStorage();
    if (v) {
      ok = await pl.applyAndroidCarLyricsSettingsChange();
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCarLyricsApplyRestartHint)),
      );
    }
  }

  Future<void> _onCover(bool v) async {
    setState(() => _showCover = v);
    await SettingsService.saveAndroidCarLyricsShowCover(v);
    if (!mounted || !_enabled) return;
    await AndroidCarLyricsSync.republishCurrentTrackMediaItem();
  }

  Future<void> _onSync(bool v) async {
    setState(() => _syncLyrics = v);
    await SettingsService.saveAndroidCarLyricsSyncLyrics(v);
    await AndroidCarLyricsSync.applySettingsFromStorage();
    await AndroidCarLyricsSync.republishCurrentTrackMediaItem();
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
      final tile = ListTile(
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
      return Opacity(opacity: interactive ? 1.0 : 0.48, child: tile);
    }
    final showDetailSwitches = !interactive || _enabled;
    final expansion = ExpansionTile(
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
          ),
        ],
      ],
    );
    return Opacity(opacity: interactive ? 1.0 : 0.48, child: expansion);
  }
}

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
                    // 背景主题：进入主题、颜色、壁纸相关设置。
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
                    // OneDrive：账号、云端曲库、同步和下载目录设置。
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
                    // 播放快捷键：桌面快捷键与 Android 线控设置分组。
                    const PlaybackShortcutsSettingsSection(),
                    // Android 媒体会话：锁屏、蓝牙、车机与歌词同步设置。
                    const _AndroidCarLyricsSettingsSection(),
                    // 桌面歌词：Linux / macOS / Windows 悬浮歌词与菜单栏歌词设置。
                    const _DesktopLyricsSettingsSection(),
                    const _PlaybackFadeOutSettingsSection(),
                    // 耳机线控：Android 单击、双击、三击和媒体键映射。
                    const WireRemoteControlSection(),
                    // 首页问候：编辑首页问候副标题轮播内容。
                    ListTile(
                      title: Text(
                        l10n.settingsHomeGreetingTitle,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsHomeGreetingListSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: context.gradFg(),
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                            const HomeGreetingSettingsPage(),
                          ),
                        );
                      },
                    ),
                    // 音质：曲库列表标识分级说明（从低到高）。
                    ListTile(
                      title: Text(
                        l10n.settingsAudioQualityTitle,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsAudioQualityListSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(
                        Icons.high_quality_outlined,
                        color: context.gradFg(),
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const AudioQualitySettingsPage(),
                          ),
                        );
                      },
                    ),
                    // 语言：切换应用界面语言。
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
                    // 缓存管理：清理应用缓存与部分 Hive 缓存（暂未在设置页展示）。
                    // const _CacheManagementSection(),
                    // 诊断日志：查看、复制、分享和清空本机诊断日志。
                    ListTile(
                      title: Text(
                        l10n.diagnosticLogTitle,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.diagnosticLogSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(
                        Icons.bug_report_outlined,
                        color: context.gradFg(),
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const DiagnosticLogPage(),
                          ),
                        );
                      },
                    ),
                    // 赞助与支持：GitHub Star、项目链接和支持说明。
                    ListTile(
                      title: Text(
                        l10n.settingsSponsorTitle,
                        style: TextStyle(color: context.gradFg()),
                      ),
                      subtitle: Text(
                        l10n.settingsSponsorSubtitle,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                        ),
                      ),
                      leading: Icon(
                        Icons.volunteer_activism_outlined,
                        color: context.gradFg(),
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const SponsorSupportPage(),
                          ),
                        );
                      },
                    ),
                    // 关于：应用信息、版本和更新检查。
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
                    // 系统信息：设备信息、磁盘空间和目录占用。
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

class _CacheManagementSection extends StatefulWidget {
  const _CacheManagementSection();

  @override
  State<_CacheManagementSection> createState() =>
      _CacheManagementSectionState();
}

class _CacheManagementSectionState extends State<_CacheManagementSection> {
  bool _loadingSize = true;
  bool _clearing = false;
  int _cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    _reloadSize();
  }

  Future<void> _reloadSize() async {
    setState(() => _loadingSize = true);
    final bytes = await _loadManagedCacheBytes();
    if (!mounted) return;
    setState(() {
      _cacheBytes = bytes;
      _loadingSize = false;
    });
  }

  Future<void> _confirmAndClear() async {
    if (_clearing) return;
    final t = _CacheTexts.of(context);
    final ok = await showAppConfirmDialog(
      context: context,
      title: t.dialogTitle,
      message: t.dialogBody(_formatBytes(_cacheBytes)),
      icon: Icons.cleaning_services_outlined,
      cancelLabel: t.cancel,
      confirmLabel: t.clearAction,
    );
    if (ok != true) return;

    setState(() => _clearing = true);
    try {
      await _clearManagedCacheDirectories();
      context.read<OneDriveController>().clearBrowseChildrenCache();
      if (!mounted) return;
      await _reloadSize();
      if (!mounted) return;
      showAppSnackBar(context, t.clearDone, kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, t.clearFailed('$e'), kind: AppSnackKind.error);
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = context.gradFg();
    final fgMuted = context.gradFg(0.6);
    final t = _CacheTexts.of(context);
    final subtitle = _loadingSize
        ? t.measuring
        : t.currentSize(_formatBytes(_cacheBytes));
    return ListTile(
      title: Text(t.title, style: TextStyle(color: fg)),
      subtitle: Text(subtitle, style: TextStyle(color: fgMuted, fontSize: 13)),
      leading: Icon(Icons.cleaning_services_outlined, color: fg),
      trailing: _clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _confirmAndClear,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(t.clearAction),
            ),
      onTap: _clearing ? null : _confirmAndClear,
    );
  }
}

class _CacheTexts {
  const _CacheTexts._({
    required this.title,
    required this.measuring,
    required this.dialogTitle,
    required this.cancel,
    required this.clearAction,
    required this.clearDone,
    required this.currentSize,
    required this.dialogBody,
    required this.clearFailed,
  });

  final String title;
  final String measuring;
  final String dialogTitle;
  final String cancel;
  final String clearAction;
  final String clearDone;
  final String Function(String size) currentSize;
  final String Function(String size) dialogBody;
  final String Function(String err) clearFailed;

  static _CacheTexts of(BuildContext context) {
    final tag = Localizations.localeOf(context).toLanguageTag();
    if (tag.startsWith('ja')) {
      return _CacheTexts._(
        title: 'キャッシュ管理',
        measuring: 'キャッシュを集計中…',
        dialogTitle: 'キャッシュを削除',
        cancel: 'キャンセル',
        clearAction: '削除',
        clearDone: 'キャッシュを削除しました（完全反映には再起動が必要な場合があります）',
        currentSize: (size) => '削除可能なキャッシュ: $size',
        dialogBody: (size) =>
            '削除可能なキャッシュは約 $size です。今すぐ削除しますか？\n\n※ 端末内の設定とキャッシュデータも削除されます。',
        clearFailed: (err) => 'キャッシュ削除に失敗しました: $err',
      );
    }
    if (tag.startsWith('zh-Hant')) {
      return _CacheTexts._(
        title: '快取管理',
        measuring: '正在統計快取…',
        dialogTitle: '清理快取',
        cancel: '取消',
        clearAction: '清理',
        clearDone: '快取已清理（部分設定需重新啟動後才會完全生效）',
        currentSize: (size) => '目前可清理快取：$size',
        dialogBody: (size) => '目前可清理快取約 $size，確定立即清理嗎？\n\n注意：這會清空本機設定與快取資料。',
        clearFailed: (err) => '快取清理失敗：$err',
      );
    }
    if (tag.startsWith('en')) {
      return _CacheTexts._(
        title: 'Cache management',
        measuring: 'Measuring cache size…',
        dialogTitle: 'Clear cache',
        cancel: 'Cancel',
        clearAction: 'Clear',
        clearDone:
            'Cache cleared (some settings may require app restart to fully apply)',
        currentSize: (size) => 'Clearable cache: $size',
        dialogBody: (size) =>
            'About $size can be cleared. Clear now?\n\nNote: this will remove local settings and cached data.',
        clearFailed: (err) => 'Failed to clear cache: $err',
      );
    }
    return _CacheTexts._(
      title: '缓存管理',
      measuring: '正在统计缓存...',
      dialogTitle: '清理缓存',
      cancel: '取消',
      clearAction: '清理',
      clearDone: '缓存清理完成（部分配置需重启后完全生效）',
      currentSize: (size) => '当前可清理缓存：$size',
      dialogBody: (size) => '当前可清理缓存约 $size，确认立即清理吗？\n\n注意：这会清空本地设置与缓存数据。',
      clearFailed: (err) => '缓存清理失败：$err',
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
    final desktopApplicable =
        !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

    if (!_loaded) {
      final tile = ListTile(
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
      return Opacity(opacity: desktopApplicable ? 1.0 : 0.48, child: tile);
    }

    final expansion = ExpansionTile(
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
          onChanged: desktopApplicable && desktopFloatingLyricsSupported
              ? _onFloatingChanged
              : null,
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
        ),
      ],
    );
    return Opacity(opacity: desktopApplicable ? 1.0 : 0.48, child: expansion);
  }
}

/// 暂停 / 切歌 / 通知栏控制前的音量线性淡出时长（0–1000 ms，0 为关闭）。
class _PlaybackFadeOutSettingsSection extends StatefulWidget {
  const _PlaybackFadeOutSettingsSection();

  @override
  State<_PlaybackFadeOutSettingsSection> createState() =>
      _PlaybackFadeOutSettingsSectionState();
}

class _PlaybackFadeOutSettingsSectionState
    extends State<_PlaybackFadeOutSettingsSection> {
  static const int _kFadeMsMin = SettingsService.playbackFadeOutDurationMsMin;
  static const int _kFadeMsMax = SettingsService.playbackFadeOutDurationMsMax;
  static const int _kFadeSliderDivisions = 100;

  bool _loaded = false;
  double _fadeMs = SettingsService.playbackFadeOutDurationMsDefault.toDouble();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ms = await SettingsService.loadPlaybackFadeOutDurationMs();
    if (!mounted) return;
    setState(() {
      _fadeMs = ms.toDouble();
      _loaded = true;
    });
  }

  String _valueLabel(AppLocalizations l10n, int ms) {
    if (ms <= 0) return l10n.settingsPlaybackFadeOutOff;
    return l10n.settingsPlaybackFadeOutMillis(ms);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subStyle = TextStyle(color: context.gradFg(0.6), fontSize: 13);
    final fg = context.gradFg();

    if (!_loaded) {
      return ListTile(
        leading: Icon(Icons.volume_down_rounded, color: fg),
        title: Text(
          l10n.settingsPlaybackFadeOutTitle,
          style: TextStyle(color: fg),
        ),
        subtitle: Text(l10n.settingsPlaybackFadeOutSubtitle, style: subStyle),
      );
    }

    final ms = _fadeMs.round();
    final valueText = _valueLabel(l10n, ms);

    return ExpansionTile(
      leading: Icon(Icons.volume_down_rounded, color: fg),
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.settingsPlaybackFadeOutTitle,
              style: TextStyle(color: fg),
            ),
          ),
          _settingHelpButton(
            context,
            l10n: l10n,
            dialogTitle: l10n.settingsPlaybackFadeOutTitle,
            dialogBody: l10n.settingsPlaybackFadeOutDesc,
          ),
        ],
      ),
      subtitle: Text(
        '${l10n.settingsPlaybackFadeOutSubtitle} · $valueText',
        style: subStyle,
      ),
      iconColor: fg,
      collapsedIconColor: fg,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                valueText,
                style: subStyle,
              ),
              Slider(
                value: _fadeMs.clamp(
                  _kFadeMsMin.toDouble(),
                  _kFadeMsMax.toDouble(),
                ),
                min: _kFadeMsMin.toDouble(),
                max: _kFadeMsMax.toDouble(),
                divisions: _kFadeSliderDivisions,
                label: valueText,
                onChanged: (v) => setState(() => _fadeMs = v),
                onChangeEnd: (v) async {
                  final rounded = v.round();
                  await SettingsService.savePlaybackFadeOutDurationMs(rounded);
                  if (!mounted) return;
                  setState(() => _fadeMs = rounded.toDouble());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
