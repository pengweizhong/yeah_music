// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/services/music_service.dart';

/// 列表行当前曲目：正在播则暂停，否则恢复/重播（与首页条、迷你播放器一致）
Future<void> toggleCurrentRowPlayback(PlayListProvider play) async {
  if (MusicService.isPlaying) {
    await MusicService().pause();
  } else if (!MusicService.canUseResumeToPlay) {
    await play.playAt(play.currentIndex);
  } else {
    MusicService().resume();
  }
}
