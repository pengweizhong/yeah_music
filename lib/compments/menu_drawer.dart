import 'package:flutter/material.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/pages/setting_page.dart';

import '../pages/setting/folder_page_setting.dart';
import '../utils/application_utils.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          //这里放一个Music的Logo
          children: [
            Container(
              padding: EdgeInsetsGeometry.only(top: 30),
              height: 180,
              width: 180,
              child: DrawerHeader(child: Center(child: Image.asset("assets/icons/icon_512x512@2x.png"))),
            ),

            //主页
            Padding(
              padding: EdgeInsetsGeometry.only(left: 90, right: 90, top: 20),
              child: ListTile(title: Text("主页"), leading: Icon(Icons.home), onTap: () => Navigator.pop(context)),
            ),
            //歌单
            Padding(
              padding: EdgeInsetsGeometry.only(left: 90, right: 80, top: 5),
              child: ListTile(
                title: Text("歌单"),
                leading: Icon(Icons.featured_play_list_outlined),
                onTap: () {
                  //关闭当前页面 / 弹窗
                  Navigator.pop(context);
                  //导航到新的页面
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PlayListProvider()));
                  //这种方式不保留当前页面栈 替换当前页面
                  // MaterialPageRoute(builder: (context) => ThemeSettings()),
                },
              ),
            ),
            //音乐源
            Padding(
              padding: EdgeInsetsGeometry.only(left: 90, right: 80, top: 5),
              child: ListTile(
                title: Text("音乐源"),
                leading: Icon(Icons.source),
                onTap: () {
                  //关闭当前页面 / 弹窗
                  Navigator.pop(context);
                  //导航到新的页面
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FolderPageSettings()));
                  //这种方式不保留当前页面栈 替换当前页面
                  // MaterialPageRoute(builder: (context) => FolderPageSettings());
                },
              ),
            ),
            //设置
            Padding(
              padding: EdgeInsetsGeometry.only(left: 90, right: 90, top: 5),
              child: ListTile(
                title: Text("设置"),
                leading: Icon(Icons.settings),
                onTap: () {
                  //关闭当前页面 / 弹窗
                  Navigator.pop(context);
                  //导航到新的页面
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingPage()));
                  //这种方式不保留当前页面栈 替换当前页面
                  // MaterialPageRoute(builder: (context) => ThemeSettings()),
                },
              ),
            ),
            //关于
            Padding(
              padding: EdgeInsetsGeometry.only(left: 90, right: 90, top: 5),
              child: ListTile(
                title: Text("关于"),
                leading: Icon(Icons.music_note),
                onTap: () {
                  ApplicationUtils.showAboutDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
