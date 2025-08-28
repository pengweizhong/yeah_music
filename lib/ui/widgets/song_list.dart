import 'package:flutter/material.dart';

import '../../services/music_service.dart';

@immutable
class SongList extends StatefulWidget {
  MusicService service;

  SongList(this.service);

  @override
  State<StatefulWidget> createState() {
    return _SongListState(this.service);
  }
}

class _SongListState extends State<SongList> {
  MusicService service;

  _SongListState(this.service);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: service.songs.length,
        itemBuilder: (context, index) {
          print(
            "当前播放的歌曲下标：$index，歌曲：${service.songs[index].title}，当前歌曲定位下标：${service.currentIndex},总数量：${service.songs.length}",
          );
          final song = service.songs[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.title),
            selected: index == service.currentIndex,
            onTap: () => service.playSong(index).then((_) => setState(() {})),
          );
        },
      ),
    );
  }
}
