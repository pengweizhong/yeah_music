import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android：主线程直推 MediaSession 展示文案（绕过 audio_service setMediaItem 单线程池排队）。
abstract final class AndroidMediaSessionLyricsChannel {
  AndroidMediaSessionLyricsChannel._();

  static const MethodChannel _channel =
      MethodChannel('yeah_music/media_session_lyrics');

  static Future<void> setCarNotificationEnabled(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setCarNotificationEnabled', <String, bool>{
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('MediaSessionLyricsChannel.setCarNotificationEnabled failed: $e');
    }
  }

  static Future<void> setLyricsDisplayManaged(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setLyricsManaged', <String, bool>{
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('MediaSessionLyricsChannel.setLyricsManaged failed: $e');
    }
  }

  static void updateDisplay({
    required String displayTitle,
    String? displaySubtitle,
  }) {
    if (kIsWeb || !Platform.isAndroid) return;
    final args = <String, String>{'displayTitle': displayTitle};
    if (displaySubtitle != null) {
      args['displaySubtitle'] = displaySubtitle;
    }
    _channel
        .invokeMethod<void>('updateDisplay', args)
        .catchError((Object e, StackTrace st) {
          debugPrint('MediaSessionLyricsChannel.updateDisplay failed: $e');
        });
  }
}
