import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/pages/song_page.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 迷你播放器组件 - 显示在底部的正在播放栏
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  /// 与 [MiniPlayer] 竖向占位一致，供主页等在 `extendBody` 下为列表预留底部边距
  static const double barHeight = 80;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayListProvider>(
      builder: (context, playListProvider, child) {
        // 安全检查：如果 provider 未初始化或没有歌曲，不显示
        if (!playListProvider.initialized) {
          return const SizedBox.shrink();
        }

        final currentSong = playListProvider.currentSong;

        // 如果没有歌曲，不显示
        if (currentSong == null || playListProvider.playList.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<bool>(
          stream: MusicService.playingStream,
          initialData: MusicService.isPlaying,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;

            return FrostedGlassPanel.bottomBar(
              height: barHeight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final box = await HiveUtils.openBox<dynamic>(
                      Constant.hiveRootPath,
                    );
                    final savedPage =
                        box.get('last_song_page', defaultValue: 0) as int? ?? 0;
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongPage(
                          index: playListProvider.currentIndex,
                          initialPage: savedPage.clamp(0, 1),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // 封面
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image(
                              fit: BoxFit.cover,
                              image: ApplicationUtils.getImageCoverProvider(
                                currentSong,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 歌曲信息
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title ?? '未知标题',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong.artist ?? '未知艺术家',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // 上一曲按钮
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 24),
                          color: Colors.white,
                          onPressed: () async {
                            await playListProvider.playPrev();
                          },
                        ),
                        // 播放/暂停按钮（与继续播放卡一致：冷启动/播完后 idle 时 resume 无声，应 [playAt] 换源）
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 28,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (isPlaying) {
                              await MusicService().pause();
                            } else {
                              if (!MusicService.canUseResumeToPlay) {
                                await playListProvider
                                    .playAt(playListProvider.currentIndex);
                              } else {
                                MusicService().resume();
                              }
                            }
                          },
                        ),
                        // 下一曲按钮
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 24),
                          color: Colors.white,
                          onPressed: () async {
                            await playListProvider.playNext();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
