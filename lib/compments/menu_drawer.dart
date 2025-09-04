import 'package:flutter/material.dart';
import 'package:yeah_music/pages/setting_page.dart';

import '../utils/application_utils.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        //这里放一个Music的Logo
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: DrawerHeader(child: Center(child: Image.asset("assets/icons/icon_512x512@2x.png"))),
          ),

          //主页
          Padding(
            padding: EdgeInsetsGeometry.only(left: 90, right: 90, top: 20),
            child: ListTile(title: Text("主页"), leading: Icon(Icons.home), onTap: () => Navigator.pop(context)),
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
    );
  }
}
