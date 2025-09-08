import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/play_list_provider.dart';

class SongPage extends StatelessWidget {
  int index;

  SongPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayListProvider>(
      builder: (context, value, child) => Scaffold(
        // appBar: AppBar(title: Text("音乐播放页面")),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            //AppBar
            Row(
              children: [
                //返回按钮
                IconButton(onPressed: () {
                  //返回上一页
                  Navigator.pop(context);
                }, icon: Icon(Icons.arrow_back_ios_new)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
