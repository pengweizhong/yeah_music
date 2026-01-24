import 'package:flutter/material.dart';
import 'package:yeah_music/compments/animated_gradient_background.dart';
import 'package:yeah_music/compments/mini_player.dart';

///歌单
class StoragePlayListPage extends StatelessWidget {
  final List<Map<String, dynamic>> folders = [
    {"name": "我的最爱", "songCount": 23, "path": "/storage/emulated/0/Music/Favorites", "created": "2024-09-01"},
    {"name": "流行歌曲", "songCount": 57, "path": "/storage/emulated/0/Music/Pop", "created": "2024-09-05"},
  ];

  StoragePlayListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('歌单', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedGradientBackground(
        colors: GradientColorExtractor.getDefaultColors(),
        child: ListView.builder(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return ExpansionTile(
              title: Text(folder["name"], style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                "共 ${folder["songCount"]} 首歌",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                ListTile(
                  title: Text(
                    "路径: ${folder["path"]}",
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                ListTile(
                  title: Text(
                    "添加时间: ${folder["created"]}",
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
