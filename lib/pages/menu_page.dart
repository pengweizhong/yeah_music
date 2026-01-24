import 'package:flutter/material.dart';
import 'package:yeah_music/compments/animated_gradient_background.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/setting_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';

import '../pages/setting/folder_page_setting.dart';

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
      child: AnimatedGradientBackground(
        colors: GradientColorExtractor.getDefaultColors(),
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
                  title: const Text("主页", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.home, color: Colors.white),
                  onTap: () => Navigator.pop(context),
                ),
              ),
              //歌曲列表
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 65, top: 5),
                child: ListTile(
                  title: const Text("歌曲列表", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.list, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayListPage()));
                  },
                ),
              ),
              //歌单
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: const Text("歌单", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.folder_copy_outlined, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoragePlayListPage()));
                  },
                ),
              ),
              //音乐源
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: const Text("音乐源", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.source, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FolderPageSettings()));
                  },
                ),
              ),
              //设置
              Padding(
                padding: const EdgeInsets.only(left: 80, right: 80, top: 5),
                child: ListTile(
                  title: const Text("设置", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.settings, color: Colors.white),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingPage()));
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

