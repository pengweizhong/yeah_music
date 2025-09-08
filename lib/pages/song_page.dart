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

              // SizedBox(height: 20),
              Container(
                padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                child: NeuBox(
                  padding: EdgeInsets.only(left: 25, right: 25, top: 10),
                  // width: 280,
                  child: Column(
                    children: [
                      //放置歌曲封面图
                      SizedBox(
                        // height: 777,
                        // width: 280,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image(image: ApplicationUtils.getImageCoverProvider(song, size: 512)),
                        ),
                      ),
                      SizedBox(height: 5),
                      //显示歌手和专辑
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            // 占满剩余空间
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                              children: [
                                Container(padding: EdgeInsets.only(left: 10), child: Text(song.album ?? "")),
                                Container(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(song.artist ?? "", style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            ),
                          ),
                          //添加喜爱标识
                          Icon(Icons.favorite, color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 10, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //时间标识
                    Text("0:00"),
                    Icon(Icons.reset_tv_sharp),
                    Text("5:20"),
                  ],
                ),
              ),

              Row(
                children: [
                  //添加时间播放条
                  Padding(
                    padding: EdgeInsets.only(left: 0, right: 0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0)),
                      child: Slider(
                        value: 50,
                        min: 0,
                        max: 100,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          //TODO
                        },
                      ),
                    ),
                  ),
                ],
              ),

              Container(
                padding: EdgeInsets.only(top: 10, left: 20, right: 20),
                child: Row(
                  children: [
                    //上一曲、播放暂停、下一曲
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.skip_previous)),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.play_arrow)),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.skip_next)),
                      ),
                    ),
                  ],
                ),
              ),
              //随机播放、循环播放、定时关闭、歌曲信息
              Container(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.shuffle)),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.repeat)),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.timer)),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          //TODO
                        },
                        child: NeuBox(child: Icon(Icons.more_horiz)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
