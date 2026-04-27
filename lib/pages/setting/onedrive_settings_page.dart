import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/onedrive/onedrive_browser_page.dart';

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
                          builder: (context) => const OneDriveBrowserPage(),
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
                                SnackBar(
                                  content: Text(l10n.oneDriveError('sign in failed')),
                                ),
                              );
                            }
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
