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

import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/folder_provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/compments/playback_shortcut_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';
import 'package:yeah_music/models/onedrive_cloud_backup_snapshot.dart';
import 'package:yeah_music/models/onedrive_restore_selection.dart';
import 'package:yeah_music/themes/app_locale_provider.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_cloud_playlist_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_download_queue_page.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/utils/android_storage_access.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/onedrive_sync_device.dart';
import 'package:yeah_music/utils/song_library_metadata_hydrator.dart';

enum _RestoreTabKind { thisDevice, otherDevice, legacyFlat }

/// 单个 Tab：同一云端设备文件夹（或旧版平铺）下的备份全局下标，已按时间倒序。
class _RestoreTabSpec {
  const _RestoreTabSpec({
    required this.kind,
    required this.title,
    required this.indices,
  });

  final _RestoreTabKind kind;
  final String title;
  final List<int> indices;
}

/// 按设备分 Tab；各 Tab 内条目按 [OneDriveCloudBackupSnapshot.comparableInstant] 最新在前。
List<_RestoreTabSpec> _buildRestoreDeviceTabs(
  AppLocalizations l10n,
  List<OneDriveCloudBackupSnapshot> snapshots,
  String currentDeviceSanitized,
) {
  final snaps = snapshots;
  final order = List.generate(snaps.length, (i) => i);
  order.sort((a, b) =>
      snaps[b].comparableInstant.compareTo(snaps[a].comparableInstant));

  final thisDevice = <int>[];
  final otherBuckets = <String, List<int>>{};
  final otherTitle = <String, String>{};
  final legacy = <int>[];

  for (final i in order) {
    final s = snaps[i];
    switch (s.kind) {
      case OneDriveCloudBackupSnapshotKind.legacyFlat:
        legacy.add(i);
        break;
      case OneDriveCloudBackupSnapshotKind.deviceSession:
        final raw = (s.deviceFolderLabel ?? '').trim();
        final dl = sanitizeOneDriveSyncFolderSegment(raw);
        final isThis = dl.isNotEmpty &&
            currentDeviceSanitized.isNotEmpty &&
            dl == currentDeviceSanitized;
        if (isThis) {
          thisDevice.add(i);
        } else {
          final key = dl.isEmpty ? '__unnamed_device__' : dl;
          otherBuckets.putIfAbsent(key, () => <int>[]).add(i);
          otherTitle[key] =
              raw.isNotEmpty ? raw : l10n.oneDriveRestoreTabUnknownDevice;
        }
        break;
    }
  }

  DateTime newestInBucket(List<int> idx) {
    var best = snaps[idx.first].comparableInstant;
    for (final i in idx.skip(1)) {
      final t = snaps[i].comparableInstant;
      if (t.isAfter(best)) best = t;
    }
    return best;
  }

  final tabs = <_RestoreTabSpec>[];
  if (thisDevice.isNotEmpty) {
    tabs.add(
      _RestoreTabSpec(
        kind: _RestoreTabKind.thisDevice,
        title: l10n.oneDriveRestoreGroupThisDevice,
        indices: thisDevice,
      ),
    );
  }

  final otherKeys = otherBuckets.keys.toList();
  otherKeys.sort(
    (ka, kb) => newestInBucket(otherBuckets[kb]!)
        .compareTo(newestInBucket(otherBuckets[ka]!)),
  );

  for (final k in otherKeys) {
    tabs.add(
      _RestoreTabSpec(
        kind: _RestoreTabKind.otherDevice,
        title: otherTitle[k] ?? k,
        indices: otherBuckets[k]!,
      ),
    );
  }

  if (legacy.isNotEmpty) {
    tabs.add(
      _RestoreTabSpec(
        kind: _RestoreTabKind.legacyFlat,
        title: l10n.oneDriveRestoreGroupLegacyFlat,
        indices: legacy,
      ),
    );
  }

  return tabs;
}

int _initialRestoreSelectionGlobalIndex(List<_RestoreTabSpec> tabs) {
  if (tabs.isEmpty) return 0;
  for (final t in tabs) {
    if (t.kind == _RestoreTabKind.thisDevice && t.indices.isNotEmpty) {
      return t.indices.first;
    }
  }
  return tabs.first.indices.first;
}

/// 手机用手势面板；平板 / 桌面（较短边 ≥560 或宽度 ≥680）用居中对话框。
Future<OneDriveRestoreSelection?> presentOneDriveRestorePicker({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<OneDriveCloudBackupSnapshot> snapshots,
  required String currentDeviceFolderSanitized,
}) async {
  final media = MediaQuery.of(context);
  final useDialog =
      media.size.shortestSide >= 560 || media.size.width >= 680;

  final sheetChild = _OneDriveRestoreSheet(
    l10n: l10n,
    snapshots: snapshots,
    currentDeviceFolderSanitized: currentDeviceFolderSanitized,
    presentationDialog: useDialog,
  );

  if (!useDialog) {
    return showModalBottomSheet<OneDriveRestoreSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FrostedGlassBottomSheet(
          topRadius: 16,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: sheetChild,
          ),
        );
      },
    );
  }

  return showDialog<OneDriveRestoreSelection>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      final r = BorderRadius.circular(16);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: mq.size.width >= 900 ? 72 : 36,
          vertical: mq.size.height < 520 ? 12 : 32,
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: mq.size.width >= 1200 ? 1024 : 880,
                maxHeight: mq.size.height * 0.92,
              ),
              decoration: BoxDecoration(
                color: FrostedPalette.fill(
                  dialogContext,
                  FrostedSurfaceKind.dialog,
                ),
                borderRadius: r,
                border: Border.all(
                  color: FrostedPalette.edgeLine(dialogContext),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: sheetChild,
            ),
          ),
        ),
      );
    },
  );
}

String _backupSnapshotTitle(AppLocalizations l10n, OneDriveCloudBackupSnapshot s) {
  switch (s.kind) {
    case OneDriveCloudBackupSnapshotKind.legacyFlat:
      return s.sortStamp;
    case OneDriveCloudBackupSnapshotKind.deviceSession:
      return l10n.oneDriveBackupSnapshotDeviceSession(
        s.deviceFolderLabel ?? '',
        s.sortStamp,
      );
  }
}

String _backupSnapshotSubtitle(AppLocalizations l10n, OneDriveCloudBackupSnapshot s) {
  final parts = <String>[];
  if (s.hasPlaylistsJson) parts.add(l10n.oneDriveRestorePlaylistCheckbox);
  if (s.hasLegacyCombinedSettingsJson) {
    parts.add(l10n.oneDriveRestoreLegacySettingsCheckbox);
  }
  if (s.hasHomeGreetingJson) parts.add(l10n.oneDriveRestoreSliceHomeGreeting);
  if (s.hasQuickEntryJson) parts.add(l10n.oneDriveRestoreSliceQuickEntry);
  if (s.hasPlaybackListsJson) parts.add(l10n.oneDriveRestoreSlicePlaybackLists);
  if (s.hasLyricsUiJson) parts.add(l10n.oneDriveRestoreSliceLyricsUi);
  if (s.hasSongRecognitionJson) {
    parts.add(l10n.oneDriveRestoreSliceSongRecognition);
  }
  if (s.hasThemeJson) parts.add(l10n.oneDriveRestoreSliceTheme);
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _backupSnapshotRowTitle(
  AppLocalizations l10n,
  OneDriveCloudBackupSnapshot s,
  _RestoreTabKind tabKind,
) {
  switch (tabKind) {
    case _RestoreTabKind.thisDevice:
    case _RestoreTabKind.otherDevice:
      if (s.kind == OneDriveCloudBackupSnapshotKind.deviceSession) {
        return s.sortStamp;
      }
      return _backupSnapshotTitle(l10n, s);
    case _RestoreTabKind.legacyFlat:
      return _backupSnapshotTitle(l10n, s);
  }
}

class OneDriveSettingsPage extends StatefulWidget {
  const OneDriveSettingsPage({super.key});

  @override
  State<OneDriveSettingsPage> createState() => _OneDriveSettingsPageState();
}

class _OneDriveSettingsPageState extends State<OneDriveSettingsPage> {
  /// 列出备份、弹窗选择、到应用完成前的整段恢复流程（与应用内 [isImmediateRestoreBusy] 叠加）。
  bool _restoreFlowBusy = false;
  bool _signInBusy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, OneDriveController>(
      builder: (context, theme, od, _) {
        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: false,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.oneDriveSettingsTitle,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (od.signedIn)
                  TextButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const OneDriveCloudPlaylistPage(),
                        ),
                      );
                    },
                    child: Text(
                      l10n.oneDriveOpenBrowser,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _SectionLabel(text: l10n.oneDriveSectionAccount),
                  const SizedBox(height: 8),
                  _AccountCard(
                    l10n: l10n,
                    od: od,
                    signingIn: _signInBusy,
                    onSignIn: () => _signIn(context, l10n, od),
                    onSignOut: () => _signOut(context, l10n, od),
                  ),
                  if (od.signedIn) ...[
                    ListTile(
                      leading: const Icon(
                        Icons.download_for_offline_rounded,
                        color: Colors.white70,
                      ),
                      title: Text(
                        l10n.oneDriveTransferQueueTitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        l10n.oneDriveDownloadQueueSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const OneDriveDownloadQueuePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 20),
                  _SectionLabel(text: l10n.oneDriveSectionPaths),
                  const SizedBox(height: 8),
                  _PathsCard(
                    l10n: l10n,
                    od: od,
                    onPickCloudAppFolder: () =>
                        _pickCloudAppFolder(context, l10n, od),
                    onPickMusicUploadFolder: () =>
                        _pickMusicUploadFolder(context, l10n, od),
                    onPickLocalDir: () =>
                        _pickLocalDownloadDir(context, l10n, od),
                    onClearCloudAppFolder: () =>
                        od.setCloudAppDataFolder(null, label: ''),
                    onClearMusicUploadFolder: () =>
                        od.setMusicUploadFolder(null, label: ''),
                    onClearLocalDir: () => od.setLocalDownloadDir(null),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(text: l10n.oneDriveSectionSync),
                  const SizedBox(height: 8),
                  _SyncCard(
                    l10n: l10n,
                    od: od,
                    onSyncNow: () => _handleSyncNow(context, l10n, od),
                    onRestoreFromCloud: () =>
                        _handleRestoreFromCloud(context, l10n, od),
                    operationsLocked:
                        od.isImmediateSyncBusy ||
                        od.isImmediateRestoreBusy ||
                        _restoreFlowBusy,
                    syncShowsProgress: od.isImmediateSyncBusy,
                    restoreShowsProgress:
                        od.isImmediateRestoreBusy || _restoreFlowBusy,
                  ),
                ],
            ),
            bottomNavigationBar: const MiniPlayer(),
          ),
        );
      },
    );
  }

  Future<void> _signIn(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (_signInBusy) return;
    if (od.isLinuxUnsupported) return;
    if (od.effectiveClientId.isEmpty) {
      final configured = await _promptClientIdIfMissing(context);
      if (!context.mounted) return;
      if (!configured || od.effectiveClientId.isEmpty) {
        showAppSnackBar(
          context,
          l10n.oneDriveAppMissingClientConfig,
          kind: AppSnackKind.error,
        );
        return;
      }
    }
    setState(() => _signInBusy = true);
    final ok = await od.signIn(l10n);
    if (mounted) {
      setState(() => _signInBusy = false);
    }
    if (!context.mounted) return;
    if (!ok) {
      showAppSnackBar(
        context,
        od.lastSignInError ?? l10n.oneDriveSignInFailed,
        kind: AppSnackKind.error,
      );
      return;
    }
    showAppSnackBar(
      context,
      l10n.oneDriveSignedIn,
      kind: AppSnackKind.success,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OneDriveCloudPlaylistPage(),
      ),
    );
  }

  Future<bool> _promptClientIdIfMissing(BuildContext context) async {
    final od = context.read<OneDriveController>();
    final c = TextEditingController(text: od.effectiveClientId);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dl10n.oneDriveClientIdDialogTitle),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(
              hintText: dl10n.oneDriveClientIdDialogHint,
              labelText: dl10n.oneDriveClientIdDialogLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dl10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(c.text.trim()),
              child: Text(dl10n.actionSave),
            ),
          ],
        );
      },
    );
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    await od.setLegacyClientId(value.trim());
    return true;
  }

  Future<void> _signOut(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    await od.signOut();
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.oneDriveSignOutDone);
  }

  Future<void> _pickCloudAppFolder(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (!od.signedIn) {
      showAppSnackBar(context, l10n.oneDriveNeedSignInForPicker);
      return;
    }
    final res = await Navigator.of(context).push<OneDriveFolderPickResult>(
      MaterialPageRoute(
        builder: (_) => OneDriveBrowserPage(
          pickFolderForIndex: true,
          folderPickSubtitle: l10n.oneDrivePickFolderForAppData,
        ),
      ),
    );
    if (!context.mounted || res == null) return;
    await od.setCloudAppDataFolder(res.itemId, label: res.name);
  }

  Future<void> _pickMusicUploadFolder(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (!od.signedIn) {
      showAppSnackBar(context, l10n.oneDriveNeedSignInForPicker);
      return;
    }
    final res = await Navigator.of(context).push<OneDriveFolderPickResult>(
      MaterialPageRoute(
        builder: (_) => OneDriveBrowserPage(
          pickFolderForIndex: true,
          folderPickSubtitle: l10n.oneDrivePickFolderForMusicUpload,
        ),
      ),
    );
    if (!context.mounted || res == null) return;
    await od.setMusicUploadFolder(res.itemId, label: res.name);
  }

  Future<void> _pickLocalDownloadDir(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.oneDriveLocalDownloadTitle,
    );
    if (!context.mounted) return;
    if (path != null && path.isNotEmpty) {
      await od.setLocalDownloadDir(path);
    }
  }

  Future<void> _handleSyncNow(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    final sync = od.syncSettings;
    if (!sync.cloudSyncEnabled) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNeedMasterOn,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (!sync.hasConfigurableSlices) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNothingSelected,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (!od.signedIn) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNeedLogin,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    final folder = od.cloudAppDataFolderId;
    if (folder == null || folder.isEmpty) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNeedCloudFolder,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (od.isImmediateSyncBusy ||
        od.isImmediateRestoreBusy ||
        _restoreFlowBusy) {
      return;
    }
    final userPl = context.read<UserPlaylistProvider>();
    if (!userPl.initialized) {
      await userPl.init();
    }
    try {
      await od.performSyncNow(userPlaylistProvider: userPl);
    } on StateError catch (e) {
      if (!context.mounted) return;
      final msg = '$e';
      if (msg.contains('immediate cloud op busy')) return;
      final text = msg.contains('not signed')
          ? l10n.oneDriveSyncNowNeedLogin
          : msg.contains('cloud app folder')
          ? l10n.oneDriveSyncNowNeedCloudFolder
          : msg;
      showAppSnackBar(context, text, kind: AppSnackKind.error);
      return;
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowFailed('$e'),
        kind: AppSnackKind.error,
      );
      return;
    }
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      l10n.oneDriveSyncNowFinished,
      kind: AppSnackKind.success,
    );
  }

  Future<void> _reloadAfterCloudRestore(BuildContext context) async {
    await Future.wait<void>([
      context.read<ThemeConfigProvider>().reloadFromStorage(),
      context.read<AppLocaleProvider>().reloadFromStorage(),
      context.read<AppThemeModeProvider>().reloadFromStorage(),
      context.read<PlaybackShortcutController>().loadFromStorage(),
      context.read<OneDriveController>().loadFromStorage(),
    ]);
  }

  /// 云端备份不含曲目内嵌封面；恢复歌单/设置后会重算合并曲库，播放页 [Song] 可能暂时无 [imageBytes]。
  Future<void> _rehydratePlayingCoverAfterCloudRestore(BuildContext context) async {
    final pl = context.read<PlayListProvider>();
    if (!pl.initialized) return;
    final path = MusicService.tryCurrentPlayingPath()?.trim();
    if (path == null || path.isEmpty) return;

    final libSong = pl.songInLibraryByPath(path);
    var target = pl.currentSong;
    if (target == null || target.path.trim() != path) {
      target = libSong;
    }
    target ??= libSong;
    if (target == null) return;

    if (libSong != null &&
        !identical(libSong, target) &&
        (libSong.imageBytes?.isNotEmpty ?? false)) {
      target.imageBytes = libSong.imageBytes;
      ApplicationUtils.evictSongCoverProvidersForPath(path);
      return;
    }
    if (target.imageBytes != null && target.imageBytes!.isNotEmpty) return;
    await SongLibraryMetadataHydrator.hydrateIfNeeded(target);
    if (target.imageBytes != null && target.imageBytes!.isNotEmpty) {
      ApplicationUtils.evictSongCoverProvidersForPath(path);
    }
  }

  Future<void> _handleRestoreFromCloud(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (!od.signedIn) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNeedLogin,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    final folder = od.cloudAppDataFolderId;
    if (folder == null || folder.isEmpty) {
      showAppSnackBar(
        context,
        l10n.oneDriveSyncNowNeedCloudFolder,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (od.isImmediateSyncBusy ||
        od.isImmediateRestoreBusy ||
        _restoreFlowBusy) {
      return;
    }

    setState(() => _restoreFlowBusy = true);
    try {
      late final List<OneDriveCloudBackupSnapshot> snapshots;
      try {
        snapshots = await od.listCloudBackupSnapshots();
      } catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          l10n.oneDriveRestoreFailed('$e'),
          kind: AppSnackKind.error,
        );
        return;
      }
      if (!context.mounted) return;

      final deviceFolderSanitized =
          sanitizeOneDriveSyncFolderSegment(await resolveOneDriveSyncDeviceFolderLabel());

      if (!context.mounted) return;
      final choice = await presentOneDriveRestorePicker(
        context: context,
        l10n: l10n,
        snapshots: snapshots,
        currentDeviceFolderSanitized: deviceFolderSanitized,
      );
      if (!context.mounted || choice == null) return;

      final userPl = context.read<UserPlaylistProvider>();
      if (!userPl.initialized) {
        await userPl.init();
      }
      if (!context.mounted) return;
      try {
        await od.restoreCloudBackup(
          userPlaylistProvider: userPl,
          sel: choice,
        );
        if (!context.mounted) return;
        if (choice.restorePlaylists) {
          // 与删除/写标签一致：合并曲库与歌单路径重绑会大量 [File] 访问，缺省时共享存储下易 errno 13。
          if (!kIsWeb && Platform.isAndroid) {
            await ensureAndroidManageExternalStorageAccess();
          }
          if (!context.mounted) return;
          final pl = context.read<PlayListProvider>();
          final folder = context.read<FolderProvider>();
          if (!pl.initialized) {
            await pl.init(
              folder,
              oneDrive: od,
              userPlaylists: userPl,
            );
          } else {
            await pl.refreshOneDriveLibraryOverlay(od);
          }
          if (!context.mounted) return;
          await userPl.remapAllPlaylistPathsFromLibrary(pl.libraryMergedSongs);
        }
        if (!context.mounted) return;
        await _reloadAfterCloudRestore(context);
        if (!context.mounted) return;
        await _rehydratePlayingCoverAfterCloudRestore(context);
      } on StateError catch (e) {
        if (!context.mounted) return;
        final m = '$e';
        if (m.contains('immediate cloud op busy')) return;
        final text = m.contains('playlist backup missing')
            ? l10n.oneDriveRestoreMissingPlaylistsFile
            : m.contains('settings backup missing')
            ? l10n.oneDriveRestoreMissingSettingsFile
            : m;
        showAppSnackBar(
          context,
          l10n.oneDriveRestoreFailed(text),
          kind: AppSnackKind.error,
        );
        return;
      } on FormatException catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          l10n.oneDriveRestoreFailed('$e'),
          kind: AppSnackKind.error,
        );
        return;
      } catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          l10n.oneDriveRestoreFailed('$e'),
          kind: AppSnackKind.error,
        );
        return;
      }

      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.oneDriveRestoreFinished,
        kind: AppSnackKind.success,
      );
    } finally {
      if (mounted) {
        setState(() => _restoreFlowBusy = false);
      }
    }
  }
}

class _OneDriveRestoreSheet extends StatefulWidget {
  const _OneDriveRestoreSheet({
    required this.l10n,
    required this.snapshots,
    required this.currentDeviceFolderSanitized,
    required this.presentationDialog,
  });

  final AppLocalizations l10n;
  final List<OneDriveCloudBackupSnapshot> snapshots;
  final String currentDeviceFolderSanitized;
  /// 平板 / 桌面为 `true`（居中对话框）；手机为 `false`（底部面板）。
  final bool presentationDialog;

  @override
  State<_OneDriveRestoreSheet> createState() => _OneDriveRestoreSheetState();
}

class _OneDriveRestoreSheetState extends State<_OneDriveRestoreSheet>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF0078D4);
  static const int _restorePageSize = 15;

  TabController? _tabController;
  late List<_RestoreTabSpec> _tabs;
  final Map<int, int> _visibleCountPerTab = <int, int>{};

  late int _selectedIndex;
  late bool _wantPlaylists;
  late bool _wantLegacySettings;
  late bool _wantHome;
  late bool _wantQuick;
  late bool _wantPlayback;
  late bool _wantLyrics;
  late bool _wantSongRecognition;
  late bool _wantTheme;
  bool _replacePlaylists = false;

  Color _textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  Color _textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  Color _textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
  Color _dividerColor(BuildContext context) =>
      Theme.of(context).dividerColor.withValues(alpha: 0.35);

  @override
  void initState() {
    super.initState();
    _tabs = widget.snapshots.isEmpty
        ? const <_RestoreTabSpec>[]
        : _buildRestoreDeviceTabs(
            widget.l10n,
            widget.snapshots,
            widget.currentDeviceFolderSanitized,
          );

    if (widget.snapshots.isEmpty) {
      _selectedIndex = 0;
      return;
    }

    _selectedIndex = _initialRestoreSelectionGlobalIndex(_tabs);
    if (_tabs.length > 1) {
      _tabController = TabController(length: _tabs.length, vsync: this);
    }
    _syncTogglesForIndex(_selectedIndex);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTogglesForIndex(int i) {
    final s = widget.snapshots[i];
    _wantPlaylists = s.hasPlaylistsJson;
    _wantLegacySettings = s.hasLegacyCombinedSettingsJson;
    _wantHome = s.hasHomeGreetingJson;
    _wantQuick = s.hasQuickEntryJson;
    _wantPlayback = s.hasPlaybackListsJson;
    _wantLyrics = s.hasLyricsUiJson;
    _wantSongRecognition = s.hasSongRecognitionJson;
    _wantTheme = s.hasThemeJson;
    if (s.kind == OneDriveCloudBackupSnapshotKind.legacyFlat) {
      _wantHome = false;
      _wantQuick = false;
      _wantPlayback = false;
      _wantLyrics = false;
      _wantSongRecognition = false;
      _wantTheme = false;
    }
  }

  List<Widget> _buildSliceTiles(
    AppLocalizations l10n,
    OneDriveCloudBackupSnapshot snap,
  ) {
    final textColor = _textPrimary(context);
    return [
      if (snap.kind == OneDriveCloudBackupSnapshotKind.deviceSession) ...[
        CheckboxListTile(
          value: _wantHome,
          onChanged: snap.hasHomeGreetingJson
              ? (v) => setState(() => _wantHome = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSliceHomeGreeting,
            style: TextStyle(color: textColor),
          ),
        ),
        CheckboxListTile(
          value: _wantQuick,
          onChanged: snap.hasQuickEntryJson
              ? (v) => setState(() => _wantQuick = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSliceQuickEntry,
            style: TextStyle(color: textColor),
          ),
        ),
        CheckboxListTile(
          value: _wantPlayback,
          onChanged: snap.hasPlaybackListsJson
              ? (v) => setState(() => _wantPlayback = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSlicePlaybackLists,
            style: TextStyle(color: textColor),
          ),
        ),
        CheckboxListTile(
          value: _wantLyrics,
          onChanged: snap.hasLyricsUiJson
              ? (v) => setState(() => _wantLyrics = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSliceLyricsUi,
            style: TextStyle(color: textColor),
          ),
        ),
        CheckboxListTile(
          value: _wantSongRecognition,
          onChanged: snap.hasSongRecognitionJson
              ? (v) => setState(() => _wantSongRecognition = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSliceSongRecognition,
            style: TextStyle(color: textColor),
          ),
        ),
        CheckboxListTile(
          value: _wantTheme,
          onChanged: snap.hasThemeJson
              ? (v) => setState(() => _wantTheme = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreSliceTheme,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
      if (snap.kind == OneDriveCloudBackupSnapshotKind.legacyFlat)
        CheckboxListTile(
          value: _wantLegacySettings,
          onChanged: snap.hasLegacyCombinedSettingsJson
              ? (v) => setState(() => _wantLegacySettings = v ?? false)
              : null,
          activeColor: _accent,
          title: Text(
            l10n.oneDriveRestoreLegacySettingsCheckbox,
            style: TextStyle(color: textColor),
          ),
        ),
    ];
  }

  Widget _buildBackupRadioTile(
    AppLocalizations l10n,
    int globalIndex,
    _RestoreTabKind tabKind,
  ) {
    final s = widget.snapshots[globalIndex];
    final dense = widget.presentationDialog;
    return RadioListTile<int>(
      visualDensity:
          dense ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      value: globalIndex,
      groupValue: _selectedIndex,
      activeColor: _accent,
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _selectedIndex = v;
          _syncTogglesForIndex(v);
        });
      },
      title: Text(
        _backupSnapshotRowTitle(l10n, s, tabKind),
        style: TextStyle(
          color: _textPrimary(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _backupSnapshotSubtitle(l10n, s),
        style: TextStyle(
          color: _textMuted(context),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPagedBackupListBody(AppLocalizations l10n, int tabIndex) {
    final tab = _tabs[tabIndex];
    final tabKind = tab.kind;
    final total = tab.indices.length;
    final requested = _visibleCountPerTab[tabIndex] ?? _restorePageSize;
    final visible = requested.clamp(1, total);

    final tiles = <Widget>[
      for (var k = 0; k < visible; k++)
        _buildBackupRadioTile(l10n, tab.indices[k], tabKind),
    ];

    if (visible < total) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.oneDriveRestoreListShowing(visible, total),
                style: TextStyle(
                  color: _textMuted(context),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _visibleCountPerTab[tabIndex] =
                        (visible + _restorePageSize).clamp(1, total);
                  });
                },
                child: Text(l10n.oneDriveRestoreLoadMore),
              ),
            ],
          ),
        ),
      );
    } else if (total > _restorePageSize) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Text(
            l10n.oneDriveRestoreListShowing(visible, total),
            style: TextStyle(
              color: _textMuted(context),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: tiles,
    );
  }

  Widget _backupPickerPanel(AppLocalizations l10n) {
    if (_tabs.length <= 1) {
      return _buildPagedBackupListBody(l10n, 0);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController!,
          isScrollable: true,
          labelColor: _textPrimary(context),
          unselectedLabelColor: _textSecondary(context),
          indicatorColor: _accent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: [
            for (final t in _tabs)
              Tab(
                child: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              for (var ti = 0; ti < _tabs.length; ti++)
                _buildPagedBackupListBody(l10n, ti),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRestoreOptionTiles(
    AppLocalizations l10n,
    OneDriveCloudBackupSnapshot snap,
  ) {
    final sliceTiles = _buildSliceTiles(l10n, snap);
    final textColor = _textPrimary(context);
    return [
      CheckboxListTile(
        value: _wantPlaylists,
        onChanged: snap.hasPlaylistsJson
            ? (v) {
                setState(() {
                  _wantPlaylists = v ?? false;
                });
              }
            : null,
        activeColor: _accent,
        title: Text(
          l10n.oneDriveRestorePlaylistCheckbox,
          style: TextStyle(color: textColor),
        ),
      ),
      ...sliceTiles,
      if (_wantPlaylists && snap.hasPlaylistsJson) ...[
        RadioListTile<bool>(
          value: false,
          groupValue: _replacePlaylists,
          activeColor: _accent,
          onChanged: (_) {
            setState(() => _replacePlaylists = false);
          },
          title: Text(
            l10n.oneDriveRestorePlaylistModeMerge,
            style: TextStyle(color: _textSecondary(context)),
          ),
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _replacePlaylists,
          activeColor: _accent,
          onChanged: (_) {
            setState(() => _replacePlaylists = true);
          },
          title: Text(
            l10n.oneDriveRestorePlaylistModeReplace,
            style: TextStyle(color: _textSecondary(context)),
          ),
        ),
      ],
    ];
  }

  void _submitRestore(AppLocalizations l10n, OneDriveCloudBackupSnapshot snap) {
    final sel = OneDriveRestoreSelection(
      snapshot: snap,
      restorePlaylists: _wantPlaylists,
      restoreLegacyCombinedSettings: _wantLegacySettings,
      restoreHomeGreeting: _wantHome,
      restoreQuickEntry: _wantQuick,
      restorePlaybackLists: _wantPlayback,
      restoreLyricsUi: _wantLyrics,
      restoreSongRecognition: _wantSongRecognition,
      restoreTheme: _wantTheme,
      replaceAllPlaylists: _replacePlaylists,
    );
    if (!sel.wantsAnyPayload) {
      showAppSnackBar(
        context,
        l10n.oneDriveRestoreNeedPickContent,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    if (sel.restorePlaylists && !snap.hasPlaylistsJson) {
      showAppSnackBar(
        context,
        l10n.oneDriveRestoreMissingPlaylistsFile,
        kind: AppSnackKind.error,
      );
      return;
    }
    if (sel.restoreLegacyCombinedSettings &&
        !snap.hasLegacyCombinedSettingsJson) {
      showAppSnackBar(
        context,
        l10n.oneDriveRestoreMissingSettingsFile,
        kind: AppSnackKind.error,
      );
      return;
    }
    Navigator.of(context).pop(sel);
  }

  Widget _restoreBar(AppLocalizations l10n, OneDriveCloudBackupSnapshot snap) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        widget.presentationDialog ? 16 : 18,
      ),
      child: FilledButton(
        onPressed: () => _submitRestore(l10n, snap),
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(l10n.oneDriveRestoreAction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (widget.snapshots.isEmpty) {
      return SafeArea(
        top: !widget.presentationDialog,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.oneDriveRestoreSheetTitle,
                        style: TextStyle(
                          color: _textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: _textSecondary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.oneDriveRestoreEmpty,
                  style: TextStyle(
                    color: _textSecondary(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
      );
    }

    final snap = widget.snapshots[_selectedIndex];
    final mq = MediaQuery.of(context);
    final panelMaxHeight =
        mq.size.height * (widget.presentationDialog ? 0.92 : 0.78);

    Widget headerRow() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.oneDriveRestoreSheetTitle,
                style: TextStyle(
                  color: _textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: _textSecondary(context)),
            ),
          ],
        ),
      );
    }

    final subtitle = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l10n.oneDriveRestoreSubtitle,
        style: TextStyle(
          color: _textMuted(context),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );

    return SafeArea(
      top: !widget.presentationDialog,
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
            final splitPane =
                widget.presentationDialog && constraints.maxWidth >= 840;

            if (!splitPane) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: panelMaxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerRow(),
                    subtitle,
                    const SizedBox(height: 8),
                    Flexible(
                      flex: 52,
                      child: Material(
                        color: Colors.transparent,
                        child: _backupPickerPanel(l10n),
                      ),
                    ),
                    Divider(height: 1, color: _dividerColor(context)),
                    Flexible(
                      flex: 48,
                      child: Material(
                        color: Colors.transparent,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: _buildRestoreOptionTiles(l10n, snap),
                        ),
                      ),
                    ),
                    _restoreBar(l10n, snap),
                  ],
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: panelMaxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerRow(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 42,
                          child: Material(
                            color: Colors.transparent,
                            child: _backupPickerPanel(l10n),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: _dividerColor(context),
                        ),
                        Expanded(
                          flex: 58,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.oneDriveRestoreContentSectionTitle,
                                      style: TextStyle(
                                        color: _textPrimary(context),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.oneDriveRestoreSubtitle,
                                      style: TextStyle(
                                        color: _textMuted(context),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    children:
                                        _buildRestoreOptionTiles(l10n, snap),
                                  ),
                                ),
                              ),
                              _restoreBar(l10n, snap),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

String _syncFrequencyLabel(AppLocalizations l10n, OneDriveSyncFrequency f) {
  return switch (f) {
    OneDriveSyncFrequency.manual => l10n.oneDriveSyncFreqManual,
    OneDriveSyncFrequency.hourly1 => l10n.oneDriveSyncFreq1h,
    OneDriveSyncFrequency.hourly6 => l10n.oneDriveSyncFreq6h,
    OneDriveSyncFrequency.hourly12 => l10n.oneDriveSyncFreq12h,
    OneDriveSyncFrequency.hourly24 => l10n.oneDriveSyncFreq24h,
  };
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.l10n,
    required this.od,
    required this.onSyncNow,
    required this.onRestoreFromCloud,
    required this.operationsLocked,
    required this.syncShowsProgress,
    required this.restoreShowsProgress,
  });

  final AppLocalizations l10n;
  final OneDriveController od;
  final VoidCallback onSyncNow;
  final VoidCallback onRestoreFromCloud;

  /// 任一同步 / 恢复 / 列出备份流程进行中时为 true。
  final bool operationsLocked;
  final bool syncShowsProgress;
  final bool restoreShowsProgress;

  static Widget _busyLabelRow({
    required Widget indicator,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20, width: 20, child: indicator),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = od.syncSettings;
    final masterOn = s.cloudSyncEnabled;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: s.cloudSyncEnabled,
            onChanged: (v) {
              od.setSyncSettings(s.copyWith(cloudSyncEnabled: v));
            },
            activeThumbColor: const Color(0xFF0078D4),
            title: Text(
              l10n.oneDriveSyncMasterTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l10n.oneDriveSyncMasterSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          Opacity(
            opacity: masterOn ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !masterOn,
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  SwitchListTile(
                    value: s.syncUserPlaylists,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncUserPlaylists: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemUserPlaylists,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemUserPlaylistsSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncHomeGreeting,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncHomeGreeting: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemHomeGreeting,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemHomeGreetingSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncQuickEntry,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncQuickEntry: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemQuickEntry,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemQuickEntrySubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncPlaybackListsAndStats,
                    onChanged: (v) {
                      od.setSyncSettings(
                        s.copyWith(syncPlaybackListsAndStats: v),
                      );
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemPlaybackListsStats,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemPlaybackListsStatsSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncLyricsUi,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncLyricsUi: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemLyricsUi,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemLyricsUiSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncSongRecognition,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncSongRecognition: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemSongRecognition,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemSongRecognitionSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncThemeAppearance,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncThemeAppearance: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemTheme,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemThemeSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.oneDriveSyncFrequencyLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dropdownMenuTheme: DropdownMenuThemeData(
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  const Color(0xE02C2C2C),
                                ),
                              ),
                            ),
                          ),
                          child: DropdownButton<OneDriveSyncFrequency>(
                            value: s.frequency,
                            underline: const SizedBox.shrink(),
                            dropdownColor: const Color(0xFF2C2C2C),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            iconEnabledColor: Colors.white70,
                            items: OneDriveSyncFrequency.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_syncFrequencyLabel(l10n, e)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                od.setSyncSettings(s.copyWith(frequency: v));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.oneDriveSyncNowDescription,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.oneDriveRestoreSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: operationsLocked ? null : onSyncNow,
                  child: syncShowsProgress
                      ? _busyLabelRow(
                          indicator: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                          label: l10n.oneDriveSyncNowInProgress,
                        )
                      : Text(l10n.oneDriveSyncNow),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: operationsLocked ? null : onRestoreFromCloud,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: restoreShowsProgress
                      ? _busyLabelRow(
                          indicator: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                          label: l10n.oneDriveRestoreInProgress,
                        )
                      : Text(l10n.oneDriveRestoreFromCloud),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.l10n,
    required this.od,
    required this.signingIn,
    required this.onSignIn,
    required this.onSignOut,
  });

  final AppLocalizations l10n;
  final OneDriveController od;
  final bool signingIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  od.signedIn
                      ? Icons.check_circle_outline
                      : Icons.person_outline,
                  color: od.signedIn
                      ? const Color(0xFF81C784)
                      : Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    od.isLinuxUnsupported
                        ? l10n.oneDriveLinuxUnsupported
                        : (od.signedIn
                              ? l10n.oneDriveSignedIn
                              : l10n.oneDriveNotSignedIn),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (!od.isLinuxUnsupported) ...[
              const SizedBox(height: 16),
              if (od.signedIn)
                OutlinedButton(
                  onPressed: onSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(l10n.oneDriveSignOut),
                )
              else
                FilledButton.icon(
                  onPressed: signingIn ? null : onSignIn,
                  icon: signingIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded, size: 20),
                  label: Text(
                    signingIn ? l10n.oneDriveSigningIn : l10n.oneDriveSignIn,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D4),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PathsCard extends StatelessWidget {
  const _PathsCard({
    required this.l10n,
    required this.od,
    required this.onPickCloudAppFolder,
    required this.onPickMusicUploadFolder,
    required this.onPickLocalDir,
    required this.onClearCloudAppFolder,
    required this.onClearMusicUploadFolder,
    required this.onClearLocalDir,
  });

  final AppLocalizations l10n;
  final OneDriveController od;
  final VoidCallback onPickCloudAppFolder;
  final VoidCallback onPickMusicUploadFolder;
  final VoidCallback onPickLocalDir;
  final VoidCallback onClearCloudAppFolder;
  final VoidCallback onClearMusicUploadFolder;
  final VoidCallback onClearLocalDir;

  String _cloudAppSummary() {
    if (od.cloudAppDataFolderId == null || od.cloudAppDataFolderId!.isEmpty) {
      return l10n.oneDriveCloudAppFolderUnset;
    }
    if (od.cloudAppDataFolderLabel.isNotEmpty) {
      return od.cloudAppDataFolderLabel;
    }
    return od.cloudAppDataFolderId!;
  }

  String _musicUploadSummary() {
    if (od.musicUploadFolderId == null || od.musicUploadFolderId!.isEmpty) {
      return l10n.oneDriveMusicUploadFolderFallback;
    }
    if (od.musicUploadFolderLabel.isNotEmpty) {
      return od.musicUploadFolderLabel;
    }
    return od.musicUploadFolderId!;
  }

  Widget _pathBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String valueLine,
    VoidCallback? onTapRow,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? clearLabel,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapRow,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          valueLine,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTapRow != null)
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (primaryLabel != null && onPrimary != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
                if (clearLabel != null && onClear != null)
                  TextButton(onPressed: onClear, child: Text(clearLabel)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _pathBlock(
            icon: Icons.folder_special_outlined,
            iconColor: Colors.lightBlue.shade200,
            title: l10n.oneDriveCloudAppDataTitle,
            subtitle: l10n.oneDriveCloudAppDataSubtitle,
            valueLine: _cloudAppSummary(),
            primaryLabel: l10n.oneDriveChooseCloudFolder,
            onPrimary: od.signedIn ? onPickCloudAppFolder : null,
            clearLabel:
                (od.cloudAppDataFolderId != null &&
                    od.cloudAppDataFolderId!.isNotEmpty)
                ? l10n.oneDriveClear
                : null,
            onClear:
                (od.cloudAppDataFolderId != null &&
                    od.cloudAppDataFolderId!.isNotEmpty)
                ? onClearCloudAppFolder
                : null,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          _pathBlock(
            icon: Icons.cloud_upload_outlined,
            iconColor: Colors.cyan.shade200,
            title: l10n.oneDriveMusicUploadFolderTitle,
            subtitle: l10n.oneDriveMusicUploadFolderSubtitle,
            valueLine: _musicUploadSummary(),
            primaryLabel: l10n.oneDriveChooseCloudFolder,
            onPrimary: od.signedIn ? onPickMusicUploadFolder : null,
            clearLabel:
                (od.musicUploadFolderId != null &&
                    od.musicUploadFolderId!.isNotEmpty)
                ? l10n.oneDriveClear
                : null,
            onClear:
                (od.musicUploadFolderId != null &&
                    od.musicUploadFolderId!.isNotEmpty)
                ? onClearMusicUploadFolder
                : null,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          _pathBlock(
            icon: Icons.download_for_offline_outlined,
            iconColor: Colors.green.shade200,
            title: l10n.oneDriveLocalDownloadTitle,
            subtitle: l10n.oneDriveLocalDownloadSubtitle,
            valueLine: od.localDownloadDir ?? l10n.oneDriveLocalDownloadUnset,
            primaryLabel: l10n.oneDriveChooseLocalFolder,
            onPrimary: onPickLocalDir,
            clearLabel:
                (od.localDownloadDir != null && od.localDownloadDir!.isNotEmpty)
                ? l10n.oneDriveClear
                : null,
            onClear:
                (od.localDownloadDir != null && od.localDownloadDir!.isNotEmpty)
                ? onClearLocalDir
                : null,
          ),
        ],
      ),
    );
  }
}
