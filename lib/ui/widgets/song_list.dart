import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../models/song.dart';
import '../../services/music_service.dart';

var log = Logger(printer: SimplePrinter());

@immutable
class SongList extends StatefulWidget {
  MusicService service;

  SongList(this.service, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _SongListState();
  }
}

class _SongListState extends State<SongList> {
  MusicService get service => widget.service;

  @override
  Widget build(BuildContext context) {
    // 整个列表只监听一次 currentSong
    return ValueListenableBuilder<Song?>(
      valueListenable: service.currentSong,
      builder: (context, current, _) {
        return ListView.builder(
          itemCount: service.songs.length,
          itemBuilder: (context, index) {
            final song = service.songs[index];
            return ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(song.title),
              selected: current == song, // 根据 current 高亮
              onTap: () {
                log.d("点击播放歌曲，下标：$index, current: $current");
                service.playSong(index); // 直接调用
                // 不需要 setState，因为 ValueListenableBuilder 会自动 rebuild
              },
            );
          },
        );
      },
    );
  }
}
