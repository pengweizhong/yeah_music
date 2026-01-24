import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/animated_gradient_background.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/pages/setting/music_theme_settings.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/utils/application_utils.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return Container(
          decoration: themeConfig.getBackgroundDecoration(),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("设置", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              children: [
                // 设置项分组
                ListTile(
                  title: const Text("背景主题", style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    "纯色、自定义颜色、背景图片",
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  leading: const Icon(Icons.color_lens, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingPage()));
                  },
                ),
                ListTile(
                  title: const Text("音乐主题", style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    "颜色、字体、夜间模式",
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  leading: const Icon(Icons.title, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MusicThemeSettings()));
                  },
                ),
            ExpansionTile(
              title: const Text("系统信息", style: TextStyle(color: Colors.white)),
              subtitle: Text(
                "资源使用情况",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              leading: const Icon(Icons.system_security_update_good_outlined, color: Colors.white),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [DiskSpaceView()],
            ),
            ListTile(
              title: const Text("关于", style: TextStyle(color: Colors.white)),
              subtitle: Text(
                "应用信息、版本、作者等",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              leading: const Icon(Icons.info, color: Colors.white),
              onTap: () {
                ApplicationUtils.showAboutDialog(context);
              },
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
