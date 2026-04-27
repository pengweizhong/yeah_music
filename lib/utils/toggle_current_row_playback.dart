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
