import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/lyric_settings.dart';
import 'package:yeah_music/services/music_service.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/external_lyric_line_formatter.dart';

/// 将当前歌词行写入系统媒体项副标题（锁屏 / 部分车机），依赖 [JustAudioBackground]。
class AndroidCarLyricsSync {
  AndroidCarLyricsSync._();

  static PlayListProvider? _playlist;
  static Timer? _timer;
  static ExternalLyricLineFormatter? _formatter;

  static void attach(PlayListProvider playlist) {
    if (kIsWeb || !Platform.isAndroid) return;
    _playlist = playlist;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      unawaited(_tick());
    });
  }

  static void detach() {
    _timer?.cancel();
    _timer = null;
    _playlist = null;
    _formatter = null;
  }

  static Future<void> _tick() async {
    if (_playlist == null) return;
    if (!MusicService.isPlaying) return;
    if (!await SettingsService.loadAndroidCarLyricsEnabled()) return;
    if (!await SettingsService.loadAndroidCarLyricsSyncLyrics()) return;

    final raw = await SettingsService.loadLyricSettings();
    final style = raw ?? LyricSettings();
    style.normalizeLayoutFields();
    _formatter ??= ExternalLyricLineFormatter(lyricStyle: style);
    _formatter!.lyricStyle = style;

    final song = _playlist!.currentSong;
    if (song == null) return;

    final line = _formatter!.formatLine(
      song: song,
      position: MusicService.lastPosition,
      l10n: null,
    );
    if (line.isEmpty) return;

    final item = AudioService.currentMediaItem;
    if (item == null || item.id != song.path) return;
    if (item.displaySubtitle == line) return;

    try {
      await AudioService.updateMediaItem(item.copyWith(displaySubtitle: line));
    } catch (_) {}
  }
}
