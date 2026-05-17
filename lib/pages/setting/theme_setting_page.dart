import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/widgets/app_prompts.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/widgets/image_pick_crop_flow.dart';
import 'package:yeah_music/widgets/rgb_gradient_pickers.dart';

/// 主题主/次色快选：均匀覆盖色相（30 档），饱和与明度足够区分，避免整圈近黑看不出差异。
List<Color> _themeHueAccentSwatches() {
  const count = 30;
  return List<Color>.generate(count, (i) {
    final hue = (i * 360.0 / count) % 360.0;
    return HSLColor.fromAHSL(1.0, hue, 0.73, 0.41).toColor();
  });
}

/// 主题设置页面
class ThemeSettingPage extends StatelessWidget {
  const ThemeSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer2<ThemeConfigProvider, AppThemeModeProvider>(
      builder: (context, themeConfig, appTheme, child) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                l10n.themeSettingsTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: context.gradFg(), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(context, l10n.globalTheme),
                const SizedBox(height: 6),
                Text(
                  l10n.globalThemeDesc,
                  style: TextStyle(
                    color: context.gradFg(0.6),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGlobalThemeSelector(context, l10n, appTheme),
                const SizedBox(height: 24),
                _buildSectionTitle(context, l10n.sectionThemeType),
                const SizedBox(height: 12),
                _buildThemeTypeSelector(context, l10n, themeConfig),
                const SizedBox(height: 24),
                if (themeConfig.themeType == ThemeType.solidColor) ...[
                  _buildSectionTitle(context, l10n.sectionPresetColors),
                  const SizedBox(height: 12),
                  _buildPresetColors(context, themeConfig),
                  const SizedBox(height: 16),
                  _buildThemeGradientFineTune(context, l10n, themeConfig),
                ],
                if (themeConfig.themeType == ThemeType.customColor) ...[
                  _buildSectionTitle(context, l10n.sectionCustomColor),
                  const SizedBox(height: 12),
                  _buildThemeGradientFineTune(context, l10n, themeConfig),
                  const SizedBox(height: 16),
                  _buildCustomColorPicker(context, l10n, themeConfig),
                ],
                if (themeConfig.themeType == ThemeType.backgroundImage) ...[
                  _buildSectionTitle(context, l10n.sectionBackgroundImage),
                  const SizedBox(height: 12),
                  _buildImagePicker(context, l10n, themeConfig),
                  const SizedBox(height: 20),
                  _buildImageEffectSection(l10n, themeConfig),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.gradFg(),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGlobalThemeSelector(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeModeProvider appTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.gradBorder(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradBorder(0.2)),
      ),
      child: Column(
        children: [
          _buildGlobalThemeTile(
            context,
            appTheme,
            ThemeMode.light,
            l10n.themeLight,
            Icons.light_mode_outlined,
          ),
          Divider(height: 1, color: context.gradBorder(0.1)),
          _buildGlobalThemeTile(
            context,
            appTheme,
            ThemeMode.dark,
            l10n.themeDark,
            Icons.dark_mode_outlined,
          ),
          Divider(height: 1, color: context.gradBorder(0.1)),
          _buildGlobalThemeTile(
            context,
            appTheme,
            ThemeMode.system,
            l10n.themeSystem,
            Icons.brightness_auto_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalThemeTile(
    BuildContext context,
    AppThemeModeProvider appTheme,
    ThemeMode value,
    String label,
    IconData icon,
  ) {
    final selected = appTheme.themeMode == value;
    return ListTile(
      leading: Icon(icon, color: context.gradFg(), size: 22),
      title: Text(label, style: TextStyle(color: context.gradFg(), fontSize: 15)),
      trailing: selected
          ? Icon(Icons.check_circle, color: context.gradFg(), size: 22)
          : Icon(Icons.circle_outlined, color: context.gradFg(0.3), size: 22),
      onTap: () => appTheme.setThemeMode(value),
    );
  }

  Widget _buildThemeTypeSelector(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.gradBorder(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradBorder(0.14)),
      ),
      child: Column(
        children: [
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.solidColor,
            l10n.themeTypeSolid,
            Icons.palette,
          ),
          Divider(height: 1, color: context.gradBorder(0.1)),
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.customColor,
            l10n.themeTypeCustom,
            Icons.color_lens,
          ),
          Divider(height: 1, color: context.gradBorder(0.1)),
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.backgroundImage,
            l10n.themeTypeImage,
            Icons.image,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTypeOption(
    BuildContext context,
    ThemeConfigProvider themeConfig,
    ThemeType type,
    String label,
    IconData icon,
  ) {
    final isSelected = themeConfig.themeType == type;
    return ListTile(
      leading: Icon(icon, color: context.gradFg(), size: 22),
      title: Text(label, style: TextStyle(color: context.gradFg(), fontSize: 15)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: context.gradFg(), size: 22)
          : Icon(Icons.circle_outlined, color: context.gradFg(0.3), size: 22),
      onTap: () => themeConfig.setThemeType(type),
    );
  }

  Widget _buildThemeGradientFineTune(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.themeGradientRgbSectionTitle,
            style: TextStyle(
              color: context.gradFg(),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.themeGradientRgbSectionSubtitle,
            style: TextStyle(
              color: context.gradFg(0.6),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: playlistCoverLinearGradient(
                    [
                      themeConfig.primaryColor,
                      themeConfig.secondaryColor,
                    ],
                    direction: themeConfig.gradientDirection,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showThemeGradientRgbDialog(context, l10n, themeConfig),
              icon: Icon(Icons.tune_rounded, color: context.gradFg()),
              label: Text(
                l10n.themeGradientRgbFineTune,
                style: TextStyle(color: context.gradFg()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.gradFg(),
                side: BorderSide(color: context.gradBorder(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeGradientRgbDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    showFrostedDialog<void>(
      context: context,
      maxWidth: 440,
      child: GradientRgbPickDialogContent(
        initialStart: themeConfig.primaryColor,
        initialEnd: themeConfig.secondaryColor,
        initialDirection: themeConfig.gradientDirection,
        l10n: l10n,
        dialogTitle: l10n.themeGradientRgbDialogTitle,
        onPick: (a, b, d) {
          themeConfig.setGradientColorsAndDirection(a, b, d);
        },
      ),
    );
  }

  Widget _buildPresetColors(BuildContext context, ThemeConfigProvider themeConfig) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ThemeConfigProvider.presetColors.map((color) {
          final isSelected = themeConfig.primaryColor.value == color.value;
          return GestureDetector(
            onTap: () {
              themeConfig.setPrimaryColor(color);
              themeConfig.setSecondaryColor(
                ThemeConfigProvider.secondaryFromPresetPrimary(color),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomColorPicker(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.primaryColor,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showColorPicker(context, l10n, themeConfig, true),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: themeConfig.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '#${themeConfig.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => _showColorPicker(context, l10n, themeConfig, true),
                child: Text(
                  l10n.actionSelect,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.secondaryColor,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showColorPicker(context, l10n, themeConfig, false),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: themeConfig.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '#${themeConfig.secondaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => _showColorPicker(context, l10n, themeConfig, false),
                child: Text(
                  l10n.actionSelect,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageEffectSection(
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    final v = themeConfig.backgroundImageEffect;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fogBackground,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.fogBackgroundDesc,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                l10n.fogWeak,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: v,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  label: '${(v * 100).round()}%',
                  onChanged: (nv) {
                    themeConfig.setBackgroundImageEffect(nv);
                  },
                ),
              ),
              Text(
                l10n.fogStrong,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(v * 100).round()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (themeConfig.backgroundImagePath != null &&
              File(themeConfig.backgroundImagePath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(themeConfig.backgroundImagePath!),
                key: ValueKey<int>(themeConfig.themeBackgroundImageGeneration),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 1200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(context, l10n, themeConfig),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: Text(l10n.actionPickImage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (themeConfig.backgroundImagePath != null) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => themeConfig.setBackgroundImage(null),
                  icon: const Icon(Icons.delete, size: 20),
                  label: Text(l10n.actionRemove),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
  ) async {
    final bytes = await pickImageWithCrop(
      context: context,
      l10n: l10n,
      aspectRatio: null,
    );
    if (bytes == null) return;
    if (!context.mounted) return;
    try {
      await themeConfig.setBackgroundImageFromBytes(bytes);
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.themeWallpaperSavedRestartHint,
        kind: AppSnackKind.neutral,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.cannotSaveBackground(e.toString()),
        kind: AppSnackKind.error,
      );
    }
  }

  void _showColorPicker(
    BuildContext context,
    AppLocalizations l10n,
    ThemeConfigProvider themeConfig,
    bool isPrimary,
  ) {
    showFrostedDialog<void>(
      context: context,
      maxWidth: 400,
      child: Builder(
        builder: (ctx) {
          final swatches = _themeHueAccentSwatches();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPrimary
                      ? l10n.colorDialogTitlePrimary
                      : l10n.colorDialogTitleSecondary,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final color in swatches)
                          GestureDetector(
                            onTap: () {
                              if (isPrimary) {
                                themeConfig.setPrimaryColor(color);
                              } else {
                                themeConfig.setSecondaryColor(color);
                              }
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.actionCancel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}








