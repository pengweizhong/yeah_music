import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/onedrive/onedrive_cloud_playlist_page.dart';

class OneDriveSettingsPage extends StatefulWidget {
  const OneDriveSettingsPage({super.key});

  @override
  State<OneDriveSettingsPage> createState() => _OneDriveSettingsPageState();
}

class _OneDriveSettingsPageState extends State<OneDriveSettingsPage> {
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _rootIdCtrl;

  @override
  void initState() {
    super.initState();
    final c = context.read<OneDriveController>();
    _clientIdCtrl = TextEditingController(text: c.clientId);
    _rootIdCtrl = TextEditingController(text: c.musicRootItemId ?? '');
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _rootIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveFields() async {
    final od = context.read<OneDriveController>();
    await od.saveClientIdText(_clientIdCtrl.text);
    await od.setMusicRootItemId(_rootIdCtrl.text.trim().isEmpty ? null : _rootIdCtrl.text.trim());
  }

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
                left: 20,
                right: 20,
                bottom: 120,
              ),
              children: [
                Text(
                  l10n.oneDriveCacheNote,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.oneDriveAzureRedirectIntro,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: SelectableText(
                            OneDriveConfig.redirectUrl,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 13,
                              height: 1.35,
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
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _clientIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.oneDriveClientIdLabel,
                    hintText: l10n.oneDriveClientIdHint,
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0078D4)),
                    ),
                  ),
                  onSubmitted: (_) => _saveFields(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _rootIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.oneDriveMusicRootIdLabel,
                    hintText: l10n.oneDriveMusicRootHint,
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0078D4)),
                    ),
                  ),
                  onSubmitted: (_) => _saveFields(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveFields,
                  child: Text(l10n.actionSave),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    od.signedIn ? l10n.oneDriveSignedIn : l10n.oneDriveNotSignedIn,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: od.isLinuxUnsupported
                      ? Text(
                          l10n.oneDriveLinuxUnsupported,
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.9),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                if (od.signedIn)
                  FilledButton.tonal(
                    onPressed: () async {
                      await od.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.oneDriveSignOutDone)),
                        );
                      }
                    },
                    child: Text(l10n.oneDriveSignOut),
                  )
                else
                  FilledButton(
                    onPressed: od.isLinuxUnsupported
                        ? null
                        : () async {
                            if (od.effectiveClientId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.oneDriveNeedClientId)),
                              );
                              return;
                            }
                            await _saveFields();
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
                          },
                    child: Text(l10n.oneDriveSignIn),
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
