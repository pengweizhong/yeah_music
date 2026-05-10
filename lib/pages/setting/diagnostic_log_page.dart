import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/diagnostic_log_store.dart';
import 'package:yeah_music/platform/wire_remote_native.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

class DiagnosticLogPage extends StatefulWidget {
  const DiagnosticLogPage({super.key});

  @override
  State<DiagnosticLogPage> createState() => _DiagnosticLogPageState();
}

class _DiagnosticLogPageState extends State<DiagnosticLogPage> {
  static const _loadTimeout = Duration(seconds: 3);

  bool _loading = true;
  bool _enabled = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    var enabled = _enabled;
    var appLog = '';
    var nativeLog = '';

    try {
      final values = await Future.wait<Object>([
        DiagnosticLogStore.isEnabled().timeout(
          _loadTimeout,
          onTimeout: () => _enabled,
        ),
        DiagnosticLogStore.read().timeout(_loadTimeout, onTimeout: () => ''),
        WireRemoteNative.readDiagnosticsLog().timeout(
          _loadTimeout,
          onTimeout: () => '',
        ),
      ]);
      enabled = values[0] as bool;
      appLog = values[1] as String;
      nativeLog = values[2] as String;
    } catch (_) {
      // 日志页不能因为平台通道或文件读取异常一直停在加载态。
    }

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _log = [
        if (appLog.trim().isNotEmpty) appLog.trimRight(),
        if (nativeLog.trim().isNotEmpty) nativeLog.trimRight(),
      ].join('\n');
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() => _enabled = enabled);
    await DiagnosticLogStore.setEnabled(enabled);
    await WireRemoteNative.setDiagnosticsEnabled(enabled);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _log));
    if (!mounted) return;
    showAppSnackBar(context, l10n.diagnosticLogCopied);
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'yeah_music_diagnostic_log.txt'));
      await file.writeAsString(_log);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: l10n.diagnosticLogTitle),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.diagnosticLogShareFailed('$e'),
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    await DiagnosticLogStore.clear();
    await WireRemoteNative.clearDiagnosticsLog();
    if (!mounted) return;
    setState(() => _log = '');
    showAppSnackBar(context, l10n.diagnosticLogCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
              title: Text(
                l10n.diagnosticLogTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              actions: [
                IconButton(
                  tooltip: l10n.diagnosticLogRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _reload,
                ),
                IconButton(
                  tooltip: l10n.diagnosticLogCopy,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: _log.isEmpty ? null : _copy,
                ),
                IconButton(
                  tooltip: l10n.diagnosticLogShare,
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: _log.isEmpty ? null : _share,
                ),
                IconButton(
                  tooltip: l10n.diagnosticLogClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _log.isEmpty ? null : _clear,
                ),
              ],
            ),
            body: _loading
                ? Center(
                    child: CircularProgressIndicator(color: context.gradFg()),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _enabled,
                        onChanged: _setEnabled,
                        title: Text(
                          l10n.diagnosticLogEnableTitle,
                          style: TextStyle(color: context.gradFg()),
                        ),
                        subtitle: Text(
                          l10n.diagnosticLogEnableSubtitle,
                          style: TextStyle(
                            color: context.gradFg(0.6),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.diagnosticLogDescription,
                        style: TextStyle(
                          color: context.gradFg(0.6),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_log.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            l10n.diagnosticLogEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.gradFg(0.55),
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        SelectableText(
                          _log,
                          style: TextStyle(
                            color: context.gradFg(0.9),
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.35,
                          ),
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
