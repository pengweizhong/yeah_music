import 'package:flutter/material.dart';
import 'package:yeah_music/pages/setting/music_theme_settings.dart';
import 'package:yeah_music/utils/application_utils.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("设置")),
      body: ListView(
        children: [
          // 设置项分组
          ListTile(
            title: Text("主题"),
            subtitle: Text("颜色、字体、夜间模式"),
            leading: Icon(Icons.title),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MusicThemeSettings()));
            },
          ),
          ListTile(
            title: Text("关于"),
            subtitle: Text("应用信息、版本、作者等"),
            leading: Icon(Icons.info),
            onTap: () {
              ApplicationUtils.showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
