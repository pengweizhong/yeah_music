import 'package:flutter/material.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/config/app_config.dart';

import '../models/song.dart';

class ApplicationUtils {
  ///弹出软件的"关于信息"
  static void showAboutDialog(BuildContext context) {
    showFrostedDialog<void>(
      context: context,
      maxWidth: 400,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/yeah_music.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppConfig.appTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x332196F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, '作者', 'PengWeiZhong'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.code,
              '仓库',
              'https://github.com/pengweizhong/yeah_music',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.gavel, '许可证', 'GPL-3.0'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.copyright, '版权', '©2026 PengWeiZhong'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建信息行
  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ///自定义提示框
  static void alertDialog(
    BuildContext context,
    String title,
    List<Widget> children,
    List<TextButton> textButtons,
  ) {
    showFrostedDialog<void>(
      context: context,
      maxWidth: 400,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(ctx).copyWith(
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: textButtons,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 按路径与边长复用 [ImageProvider]，避免滑条反复 build 时创建新 [ResizeImage] 导致反复解码。
  static final Map<String, ImageProvider> _coverProviderCache = {};
  static const int _coverProviderMax = 500;

  /// 按需写入 [Song.imageBytes] 后调用，丢弃该曲路径下各尺寸缓存条目，避免继续用占位 [AssetImage]。
  static void evictSongCoverProvidersForPath(String songPath) {
    if (songPath.isEmpty) return;
    final prefix = '$songPath#';
    _coverProviderCache.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// 获取歌曲封面 [ImageProvider]。
  /// 内嵌封面使用 [ResizeImage] 按 [size]×[devicePixelRatio] 降采样解码，避免列表滚动时全尺寸解码进显存。
  static ImageProvider getImageCoverProvider(
    Song song, {
    double size = 32,
    double devicePixelRatio = 2.0,
  }) {
    if (song.imageBytes == null) {
      if (size < 20) {
        return AssetImage("assets/icons/icon_16x16@2x.png");
      }
      if (size < 40) {
        return AssetImage("assets/icons/icon_32x32@2x.png");
      }
      return AssetImage("assets/icons/icon_512x512@2x.png");
    }
    final dim = (size * devicePixelRatio).round().clamp(32, 2048);
    final key = '${song.path}#$dim';
    final existing = _coverProviderCache[key];
    if (existing != null) {
      return existing;
    }
    if (_coverProviderCache.length >= _coverProviderMax) {
      _coverProviderCache.remove(_coverProviderCache.keys.first);
    }
    final base = MemoryImage(song.imageBytes!);
    final created = ResizeImage(
      base,
      width: dim,
      height: dim,
      allowUpscaling: false,
    );
    _coverProviderCache[key] = created;
    return created;
  }
}
