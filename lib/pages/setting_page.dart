import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/disk_space.dart';
import 'package:yeah_music/compments/mini_player.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/pages/setting/theme_setting_page.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, child) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text("设置", style: TextStyle(color: context.gradFg())),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              children: [
                // 设置项分组
                ListTile(
                  title: Text("背景主题", style: TextStyle(color: context.gradFg())),
                  subtitle: Text(
                    "纯色、自定义颜色、背景图片",
                    style: TextStyle(color: context.gradFg(0.6)),
                  ),
                  leading: Icon(Icons.color_lens, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingPage()));
                  },
                ),
            ExpansionTile(
              title: Text("系统信息", style: TextStyle(color: context.gradFg())),
              subtitle: Text(
                "设备信息、存储空间",
                style: TextStyle(color: context.gradFg(0.6)),
              ),
              leading: Icon(Icons.info_outline, color: context.gradFg()),
              iconColor: context.gradFg(),
              collapsedIconColor: context.gradFg(),
              children: [DiskSpaceView()],
            ),
            ListTile(
              title: Text("关于", style: TextStyle(color: context.gradFg())),
              subtitle: Text(
                "应用信息、版本、开源协议",
                style: TextStyle(color: context.gradFg(0.6)),
              ),
              leading: Icon(Icons.favorite, color: context.gradFg()),
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
