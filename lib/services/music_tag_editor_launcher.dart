import 'package:flutter/services.dart';

/// Android：通过同一 MethodChannel 调起外部音频编辑器（Music Tag Editor / SyncedLyric Editor）。
class MusicTagEditorLauncher {
  MusicTagEditorLauncher._();

  static const MethodChannel _channel = MethodChannel('yeah_music/music_tag_editor');

  /// 与 Kotlin [MusicTagEditorBridge] 中 `openWithMusicTagEditor` 默认值一致。
  static const String androidMusicTagPackageName = 'com.xjcheng.musictageditor';

  /// SyncedLyric Editor（嵌入歌词等），与 Kotlin 中 `openWithSyncedLyricEditor` 默认值一致。
  static const String androidSyncedLyricEditorPackageName =
      'lyriceditor.lyricsearch.embedlyrictomp3.syncedlyriceditor';

  /// 返回原生状态：`ok`、`activity_not_found`、`file_not_found`、`cannot_share_path`、`invalid_args`、`error`，失败或未实现时为 null。
  static Future<String?> openMusicTagEditor(
    String absolutePath, {
    String packageName = androidMusicTagPackageName,
  }) async {
    return _invoke('openWithMusicTagEditor', absolutePath, packageName);
  }

  static Future<String?> openSyncedLyricEditor(
    String absolutePath, {
    String packageName = androidSyncedLyricEditorPackageName,
  }) async {
    return _invoke('openWithSyncedLyricEditor', absolutePath, packageName);
  }

  static Future<String?> _invoke(String method, String absolutePath, String packageName) async {
    final Object? raw = await _channel.invokeMethod<Object?>(method, <String, Object?>{
      'path': absolutePath,
      'package': packageName,
    });
    if (raw is Map) {
      final status = raw['status'];
      if (status is String) return status;
    }
    return null;
  }
}
