import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/themes/theme_provider.dart';

class MusicThemeSettings extends StatefulWidget {
  const MusicThemeSettings({super.key});

  @override
  State<MusicThemeSettings> createState() => _ThemeSettingsState();
}

class _ThemeSettingsState extends State<MusicThemeSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("主题设置")),
      body: Container(
        //装饰切换
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //夜晚模式
            const Text("夜晚模式", style: TextStyle(fontWeight: FontWeight.bold)),
            //切换模式
            CupertinoSwitch(
              value: Provider.of<ThemeProvider>(context, listen: false).isDarkTheme,
              onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}
