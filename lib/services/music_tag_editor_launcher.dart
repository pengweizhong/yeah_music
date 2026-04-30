import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/widgets/app_prompts.dart';

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

  /// 打开音乐标签编辑器：失败时 SnackBar；成功时可选 [onLaunchedOk]（例如播放页挂起返回后重载元数据）。
  static Future<void> openMusicTagEditorWithFeedback(
    BuildContext context,
    Song song, {
    void Function(String path)? onLaunchedOk,
  }) async {
    final l10n = AppLocalizations.of(context);
    final path = song.path.trim();
    if (path.isEmpty) return;
    if (!await File(path).exists()) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMusicTagEditorFileNotFound,
        kind: AppSnackKind.error,
      );
      return;
    }
    if (!Platform.isAndroid) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMusicTagEditorUnsupportedPlatform,
        kind: AppSnackKind.neutral,
      );
      return;
    }
    try {
      final status = await openMusicTagEditor(path);
      if (!context.mounted) return;
      final msg = _musicTagStatusSnackMessage(l10n, status);
      if (msg != null) {
        showAppSnackBar(context, msg, kind: AppSnackKind.error);
      } else {
        onLaunchedOk?.call(path);
      }
    } on MissingPluginException {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        l10n.songPageMusicTagEditorLaunchFailed,
        kind: AppSnackKind.error,
      );
    }
  }

  static String? _musicTagStatusSnackMessage(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'ok':
        return null;
      case 'activity_not_found':
        return l10n.songPageMusicTagEditorNotInstalled;
      case 'file_not_found':
        return l10n.songPageMusicTagEditorFileNotFound;
      case 'cannot_share_path':
        return l10n.songPageMusicTagEditorCannotSharePath;
      case 'invalid_args':
      case 'error':
        return l10n.songPageMusicTagEditorLaunchFailed;
      default:
        return l10n.songPageMusicTagEditorLaunchFailed;
    }
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

  /// 从外部标签编辑器返回后通知系统扫描该音频路径（Android），便于 MediaStore 与文件一致。
  static Future<void> scanAudioFileAfterExternalEdit(String absolutePath) async {
    if (!Platform.isAndroid) return;
    final path = absolutePath.trim();
    if (path.isEmpty) return;
    try {
      await _channel.invokeMethod<Object?>('scanAudioFileAfterExternalEdit', <String, Object?>{
        'path': path,
      });
    } on MissingPluginException {
      // ignore
    }
  }
}
