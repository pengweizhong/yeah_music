import 'package:flutter/material.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/setting_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';

import '../pages/setting/folder_page_setting.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: FrostedGlassPanel.drawer(
        child: SafeArea(
          child: ListView(
            //这里放一个Music的Logo
            children: [
              Container(
                padding: const EdgeInsets.only(top: 30),
                height: 180,
                width: 180,
                child: DrawerHeader(
                  child: Center(
                    child: Image.asset("assets/icons/icon_512x512@2x.png"),
                  ),
                ),
              ),

              //主页
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 20),
                child: ListTile(
                  title: Text(
                    "主页",
                    style: TextStyle(color: context.gradFg()),
                  ),
                  leading: Icon(Icons.home, color: context.gradFg()),
                  onTap: () => Navigator.pop(context),
                ),
              ),
              //歌曲列表
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 65, top: 5),
                child: ListTile(
                  title: Text(
                    "歌曲列表",
                    style: TextStyle(color: context.gradFg()),
                  ),
                  leading: Icon(Icons.list, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayListPage()),
                    );
                  },
                ),
              ),
              //歌单
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: Text(
                    "歌单",
                    style: TextStyle(color: context.gradFg()),
                  ),
                  leading: Icon(
                    Icons.folder_copy_outlined,
                    color: context.gradFg(),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoragePlayListPage(),
                      ),
                    );
                  },
                ),
              ),
              //音乐源
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: Text(
                    "音乐源",
                    style: TextStyle(color: context.gradFg()),
                  ),
                  leading: Icon(Icons.source, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderPageSettings(),
                      ),
                    );
                  },
                ),
              ),
              //设置
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: Text(
                    "设置",
                    style: TextStyle(color: context.gradFg()),
                  ),
                  leading: Icon(Icons.settings, color: context.gradFg()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
