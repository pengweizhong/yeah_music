// Copyright (c) 2025 Yeah Music
//
// 桌面 DSD 播放路径：优先 FFmpeg→FLAC，其次 DFF→DSF。

import 'package:yeah_music/utils/dff_dsf_transmux.dart';
import 'package:yeah_music/utils/dsd_ffmpeg_transcode.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

/// 返回可供 mpv 稳定解码的本地路径（可能是原路径、.dsf 或 .flac）。
Future<String?> ensureDesktopDsdPlaybackPath(String songPath) async {
  final lower = songPath.toLowerCase();
  if (!lower.endsWith('.dsf') && !lower.endsWith('.dff')) {
    return songPath;
  }

  if (lower.endsWith('.dff')) {
    showAppSnackBarGlobal(
      'DFF 正在准备播放（首次约 30～90 秒）…',
      kind: AppSnackKind.neutral,
      duration: const Duration(seconds: 5),
    );
  }
  final flac = await ensureFfmpegFlacPlaybackPath(songPath);
  if (flac != null) {
    return flac;
  }

  if (lower.endsWith('.dff')) {
    return ensureDsfPlaybackPathForDff(songPath);
  }

  return songPath;
}
