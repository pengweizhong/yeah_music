import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';
import 'package:yeah_music/pages/onedrive/onedrive_cloud_playlist_page.dart';

class OneDriveSettingsPage extends StatefulWidget {
  const OneDriveSettingsPage({super.key});

  @override
  State<OneDriveSettingsPage> createState() => _OneDriveSettingsPageState();
}

class _OneDriveSettingsPageState extends State<OneDriveSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, OneDriveController>(
      builder: (context, theme, od, _) {
        return theme.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
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
                          builder: (context) => const OneDriveCloudPlaylistPage(),
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
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                left: 16,
                right: 16,
                bottom: 120,
              ),
              children: [
                _SectionLabel(text: l10n.oneDriveSectionAccount),
                const SizedBox(height: 8),
                _AccountCard(
                  l10n: l10n,
                  od: od,
                  onSignIn: () => _signIn(context, l10n, od),
                  onSignOut: () => _signOut(context, l10n, od),
                ),
                const SizedBox(height: 8),
                _TroubleshootExpansion(l10n: l10n),
                const SizedBox(height: 20),
                _SectionLabel(text: l10n.oneDriveSectionPaths),
                const SizedBox(height: 8),
                _PathsCard(
                  l10n: l10n,
                  od: od,
                  onPickCloudAppFolder: () => _pickCloudAppFolder(context, l10n, od),
                  onEditMusicRoot: () => _editMusicRootId(context, l10n, od),
                  onPickLocalDir: () => _pickLocalDownloadDir(context, l10n, od),
                  onClearCloudAppFolder: () => od.setCloudAppDataFolder(null, label: ''),
                  onClearLocalDir: () => od.setLocalDownloadDir(null),
                ),
                const SizedBox(height: 20),
                _SectionLabel(text: l10n.oneDriveSectionSync),
                const SizedBox(height: 8),
                _SyncCard(
                  l10n: l10n,
                  od: od,
                  onSyncNow: () => _handleSyncNow(context, l10n, od),
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
    if (od.isLinuxUnsupported) return;
    if (od.effectiveClientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oneDriveAppMissingClientConfig)),
      );
      return;
    }
    final ok = await od.signIn();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oneDriveSignInFailed)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.oneDriveSignedIn)),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OneDriveCloudPlaylistPage(),
      ),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    await od.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.oneDriveSignOutDone)),
    );
  }

  Future<void> _pickCloudAppFolder(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (!od.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oneDriveNeedSignInForPicker)),
      );
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

  Future<void> _editMusicRootId(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    final ctrl = TextEditingController(text: od.musicRootItemId ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.oneDriveMusicRootIdLabel),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: l10n.oneDriveMusicRootHint,
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (!context.mounted || ok != true) {
      ctrl.dispose();
      return;
    }
    final v = ctrl.text.trim();
    ctrl.dispose();
    await od.setMusicRootItemId(v.isEmpty ? null : v);
  }

  Future<void> _handleSyncNow(
    BuildContext context,
    AppLocalizations l10n,
    OneDriveController od,
  ) async {
    if (!od.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oneDriveSyncNowNeedLogin)),
      );
      return;
    }
    final folder = od.cloudAppDataFolderId;
    if (folder == null || folder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oneDriveSyncNowNeedCloudFolder)),
      );
      return;
    }
    await od.performSyncNow();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.oneDriveSyncNowFinished)),
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
  });

  final AppLocalizations l10n;
  final OneDriveController od;
  final VoidCallback onSyncNow;

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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              l10n.oneDriveSyncMasterSubtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
          ),
          Opacity(
            opacity: masterOn ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !masterOn,
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  SwitchListTile(
                    value: s.syncPlaylists,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncPlaylists: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemPlaylists,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemPlaylistsSubtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                  SwitchListTile(
                    value: s.syncAppSettings,
                    onChanged: (v) {
                      od.setSyncSettings(s.copyWith(syncAppSettings: v));
                    },
                    activeThumbColor: const Color(0xFF0078D4),
                    title: Text(
                      l10n.oneDriveSyncItemSettings,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      l10n.oneDriveSyncItemSettingsSubtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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
                            style: const TextStyle(color: Colors.white, fontSize: 14),
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
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onSyncNow,
                  child: Text(l10n.oneDriveSyncNow),
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
    required this.onSignIn,
    required this.onSignOut,
  });

  final AppLocalizations l10n;
  final OneDriveController od;
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
                  od.signedIn ? Icons.check_circle_outline : Icons.person_outline,
                  color: od.signedIn
                      ? const Color(0xFF81C784)
                      : Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    od.isLinuxUnsupported
                        ? l10n.oneDriveLinuxUnsupported
                        : (od.signedIn ? l10n.oneDriveSignedIn : l10n.oneDriveNotSignedIn),
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
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(l10n.oneDriveSignOut),
                )
              else
                FilledButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(l10n.oneDriveSignIn),
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

class _TroubleshootExpansion extends StatelessWidget {
  const _TroubleshootExpansion({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          title: Text(
            l10n.oneDriveTroubleshootTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          children: [
            Text(
              l10n.oneDriveAzureRedirectIntro,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.oneDriveAzureRedirectUriCaption,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: SelectableText(
                        OneDriveConfig.redirectUrl,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.oneDriveRedirectCopyTooltip,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: OneDriveConfig.redirectUrl),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.oneDriveRedirectCopied)),
                    );
                  },
                  icon: Icon(
                    Icons.copy_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
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
    required this.onEditMusicRoot,
    required this.onPickLocalDir,
    required this.onClearCloudAppFolder,
    required this.onClearLocalDir,
  });

  final AppLocalizations l10n;
  final OneDriveController od;
  final VoidCallback onPickCloudAppFolder;
  final VoidCallback onEditMusicRoot;
  final VoidCallback onPickLocalDir;
  final VoidCallback onClearCloudAppFolder;
  final VoidCallback onClearLocalDir;

  String _musicRootSummary() {
    final id = od.musicRootItemId;
    if (id == null || id.isEmpty) {
      return l10n.oneDriveMusicRootSummaryRoot;
    }
    return id.length > 36 ? '${id.substring(0, 18)}…' : id;
  }

  String _cloudAppSummary() {
    if (od.cloudAppDataFolderId == null || od.cloudAppDataFolderId!.isEmpty) {
      return l10n.oneDriveCloudAppFolderUnset;
    }
    if (od.cloudAppDataFolderLabel.isNotEmpty) {
      return od.cloudAppDataFolderLabel;
    }
    return od.cloudAppDataFolderId!;
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
                    Icon(Icons.edit_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
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
                  TextButton(
                    onPressed: onClear,
                    child: Text(clearLabel),
                  ),
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
            icon: Icons.library_music_outlined,
            iconColor: Colors.amber.shade200,
            title: l10n.oneDriveMusicRootTileTitle,
            subtitle: l10n.oneDriveMusicRootTileSubtitle,
            valueLine: _musicRootSummary(),
            onTapRow: onEditMusicRoot,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          _pathBlock(
            icon: Icons.folder_special_outlined,
            iconColor: Colors.lightBlue.shade200,
            title: l10n.oneDriveCloudAppDataTitle,
            subtitle: l10n.oneDriveCloudAppDataSubtitle,
            valueLine: _cloudAppSummary(),
            primaryLabel: l10n.oneDriveChooseCloudFolder,
            onPrimary: od.signedIn ? onPickCloudAppFolder : null,
            clearLabel:
                (od.cloudAppDataFolderId != null && od.cloudAppDataFolderId!.isNotEmpty)
                    ? l10n.oneDriveClear
                    : null,
            onClear:
                (od.cloudAppDataFolderId != null && od.cloudAppDataFolderId!.isNotEmpty)
                    ? onClearCloudAppFolder
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
