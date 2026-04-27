import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';

/// 主题设置页面
class ThemeSettingPage extends StatelessWidget {
  const ThemeSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return themeConfig.buildThemedBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('主题设置', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 主题类型选择
                _buildSectionTitle('主题类型'),
                const SizedBox(height: 12),
                _buildThemeTypeSelector(context, themeConfig),
                
                const SizedBox(height: 24),
                
                // 预设颜色
                if (themeConfig.themeType == ThemeType.solidColor) ...[
                  _buildSectionTitle('预设颜色'),
                  const SizedBox(height: 12),
                  _buildPresetColors(context, themeConfig),
                ],
                
                // 自定义颜色
                if (themeConfig.themeType == ThemeType.customColor) ...[
                  _buildSectionTitle('自定义颜色'),
                  const SizedBox(height: 12),
                  _buildCustomColorPicker(context, themeConfig),
                ],
                
                // 背景图片
                if (themeConfig.themeType == ThemeType.backgroundImage) ...[
                  _buildSectionTitle('背景图片'),
                  const SizedBox(height: 12),
                  _buildImagePicker(context, themeConfig),
                  const SizedBox(height: 20),
                  _buildImageEffectSection(themeConfig),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeTypeSelector(BuildContext context, ThemeConfigProvider themeConfig) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.solidColor,
            '预设颜色',
            Icons.palette,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.customColor,
            '自定义颜色',
            Icons.color_lens,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          _buildThemeTypeOption(
            context,
            themeConfig,
            ThemeType.backgroundImage,
            '背景图片',
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
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
          : Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.3), size: 22),
      onTap: () => themeConfig.setThemeType(type),
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
              // 自动设置次色调为稍微亮一点的颜色
              final hsl = HSLColor.fromColor(color);
              final secondaryColor = hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor();
              themeConfig.setSecondaryColor(secondaryColor);
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

  Widget _buildCustomColorPicker(BuildContext context, ThemeConfigProvider themeConfig) {
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
          const Text(
            '主色调',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showColorPicker(context, themeConfig, true),
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
                onPressed: () => _showColorPicker(context, themeConfig, true),
                child: const Text('选择', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '次色调',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showColorPicker(context, themeConfig, false),
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
                onPressed: () => _showColorPicker(context, themeConfig, false),
                child: const Text('选择', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageEffectSection(ThemeConfigProvider themeConfig) {
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
          const Text(
            '背景雾化',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '虚化并压暗背景图，减轻对文字、图标的干扰。默认 45%，可按需调节。',
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
                '弱',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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
                '强',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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

  Widget _buildImagePicker(BuildContext context, ThemeConfigProvider themeConfig) {
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
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(context, themeConfig),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text('选择图片'),
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
                  label: const Text('移除'),
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

  Future<void> _pickImage(BuildContext context, ThemeConfigProvider themeConfig) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;
    if (!context.mounted) return;
    try {
      await themeConfig.setBackgroundImage(pickedFile.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法保存背景图（请重试或换一张）：$e'),
        ),
      );
    }
  }

  void _showColorPicker(BuildContext context, ThemeConfigProvider themeConfig, bool isPrimary) {
    showFrostedDialog<void>(
      context: context,
      maxWidth: 360,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPrimary ? '选择主色调' : '选择次色调',
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
                      children: List.generate(360, (index) {
                        final hue = index.toDouble();
                        final color =
                            HSLColor.fromAHSL(1.0, hue, 0.5, 0.1).toColor();
                        return GestureDetector(
                          onTap: () {
                            if (isPrimary) {
                              themeConfig.setPrimaryColor(color);
                            } else {
                              themeConfig.setSecondaryColor(color);
                            }
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}








