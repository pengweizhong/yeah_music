import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/config/sponsor_links.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

/// 接近 GitHub Star 图标的金色（ Material `Icons.star_outline`）
const Color _kRepoStarTint = Color(0xFFE3B341);

class SponsorSupportPage extends StatelessWidget {
  const SponsorSupportPage({super.key});

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context).settingsSponsorLaunchFailed,
        kind: AppSnackKind.error,
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!ok) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context).settingsSponsorLaunchFailed,
          kind: AppSnackKind.error,
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        AppLocalizations.of(context).settingsSponsorLaunchFailed,
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      AppLocalizations.of(context).settingsSponsorLinkCopied,
    );
  }

  void _showTipEasterEgg(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showAppScrollMessageDialog(
      context: context,
      title: l10n.settingsSponsorEasterEggDialogTitle,
      body: l10n.settingsSponsorEasterEggDialogBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        final l10n = AppLocalizations.of(context);
        final fgMuted = TextStyle(
          color: context.gradFgMuted(0.82),
          fontSize: 14,
          height: 1.45,
        );
        final fgSmall = TextStyle(
          color: context.gradFgMuted(0.68),
          fontSize: 12.5,
          height: 1.42,
        );

        Widget sectionTitle(String text) => Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 10),
              child: Text(
                text,
                style: TextStyle(
                  color: context.gradFg(0.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            );

        Widget repoTile({
          required String title,
          required String subtitle,
          required String url,
        }) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  size: 22,
                  color: _kRepoStarTint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: context.gradFg(), fontSize: 16),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(color: context.gradFg(0.62), fontSize: 13),
              ),
            ),
            trailing: IconButton(
              tooltip: l10n.settingsSponsorCopyLink,
              icon: Icon(Icons.copy_rounded, color: context.gradFg(0.65)),
              onPressed: () => _copy(context, url),
            ),
            onTap: () => _launch(context, url),
          );
        }

        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                l10n.settingsSponsorTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: context.gradFg(), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                sectionTitle(l10n.settingsSponsorSectionFreeTitle),
                Text(l10n.settingsSponsorSectionFreeBody, style: fgMuted),
                sectionTitle(l10n.settingsSponsorSectionStarTitle),
                Text(l10n.settingsSponsorSectionStarHint, style: fgMuted),
                const SizedBox(height: 8),
                repoTile(
                  title: l10n.settingsSponsorRepoYeahMusicTitle,
                  subtitle: l10n.settingsSponsorRepoYeahMusicSubtitle,
                  url: SponsorLinks.yeahMusicGitHub,
                ),
                Divider(height: 24, color: context.gradBorder(0.35)),
                repoTile(
                  title: l10n.settingsSponsorRepoDynamicSql2Title,
                  subtitle: l10n.settingsSponsorRepoDynamicSql2Subtitle,
                  url: SponsorLinks.dynamicSql2GitHub,
                ),
                Divider(height: 28, color: context.gradBorder(0.35)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    Icons.sentiment_satisfied_alt_outlined,
                    color: context.gradFg(0.85),
                  ),
                  title: Text(
                    l10n.settingsSponsorEasterEggTriggerLine,
                    style: TextStyle(color: context.gradFg(), fontSize: 16),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: context.gradFg(0.45),
                  ),
                  onTap: () => _showTipEasterEgg(context),
                ),
                const SizedBox(height: 20),
                Text(l10n.settingsSponsorExternalHint, style: fgSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
