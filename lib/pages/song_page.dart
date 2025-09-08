import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/neu_box.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/utils/application_utils.dart';

import '../models/song.dart';

class SongPage extends StatelessWidget {
  int index;

  SongPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayListProvider>(
      builder: (context, playListProvider, childWidget) {
        //拿到当前播放的歌曲
        Song song = playListProvider.playList[index];
        return Scaffold(
          // appBar: AppBar(title: Text("音乐播放页面")),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              //AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //返回按钮
                  IconButton(
                    padding: EdgeInsets.only(left: 5),
                    icon: Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      //返回上一页
                      Navigator.pop(context);
                    },
                  ),
                  Center(
                    child: Text(song.title!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  IconButton(
                    padding: EdgeInsets.only(right: 6),
                    onPressed: () {
                      //TODO  这里计划写播放列表
                    },
                    icon: Icon(Icons.list),
                  ),
                ],
              ),
              //放置歌曲封面图
              SizedBox(height: 15),
              Container(
                width: 280,
                height: 280,
                child: NeuBox(child: Image(image: ApplicationUtils.getImageCoverProvider(song, size: 512))),
              ),
            ],
          ),
        );
      },
    );
  }
}
