import 'package:flutter/material.dart';

///歌单提供者
class PlayListProvider extends StatelessWidget {
  final List<Map<String, dynamic>> folders = [
    {"name": "我的最爱", "songCount": 23, "path": "/storage/emulated/0/Music/Favorites", "created": "2024-09-01"},
    {"name": "流行歌曲", "songCount": 57, "path": "/storage/emulated/0/Music/Pop", "created": "2024-09-05"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歌单')),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return ExpansionTile(
            title: Text(folder["name"]),
            subtitle: Text("共 ${folder["songCount"]} 首歌"),
            children: [
              ListTile(title: Text("路径: ${folder["path"]}")),
              ListTile(title: Text("添加时间: ${folder["created"]}")),
            ],
          );
        },
      ),
    );
  }
}
