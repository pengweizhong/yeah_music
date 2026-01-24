import 'package:flutter/material.dart';
import 'package:yeah_music/config/app_config.dart';

import '../models/song.dart';

class ApplicationUtils {
  ///弹出软件的"关于信息"
  static void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 应用图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                
                // 应用名称
                const Text(
                  AppConfig.appTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 版本号
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "v1.0.0",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 分隔线
                Divider(color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                
                // 作者信息
                _buildInfoRow(Icons.person_outline, "作者", "PengWeiZhong"),
                const SizedBox(height: 12),
                
                // 仓库地址
                _buildInfoRow(Icons.code, "仓库", "github.com/pengweizhong/yeah_music"),
                const SizedBox(height: 12),
                
                // 许可证
                _buildInfoRow(Icons.gavel, "许可证", "GPL-3.0"),
                const SizedBox(height: 12),
                
                // 版权信息
                _buildInfoRow(Icons.copyright, "版权", "©2025 pengweizhong"),
                const SizedBox(height: 24),
                
                // 关闭按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "关闭",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建信息行
  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ///自定义提示框
  static void alertDialog(BuildContext context, String title, List<Widget> children, List<TextButton> textButtons) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 内容自适应，不撑满屏幕
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            children: children, //弹出内容
          ),
          actions: textButtons,
        );
      },
    );
  }

  //获取歌曲封面图
  static ImageProvider getImageCoverProvider(Song song, {double size = 32}) {
    if (song.imageBytes == null) {
      if (size < 20) {
        return AssetImage("assets/icons/icon_16x16@2x.png");
      }
      if (size < 40) {
        return AssetImage("assets/icons/icon_32x32@2x.png");
      }
      return AssetImage("assets/icons/icon_512x512@2x.png");
    }
    return MemoryImage(song.imageBytes!);
  }
}
