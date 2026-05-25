/// 桌面 DSD 播放时由应用写入、供 [MediaKitPlayer] 覆盖 mpv 错误时长。
class DsdPlaybackHints {
  static final Map<String, Duration> overrideDurationByFileUri = {};

  static void registerFileUri(String fileUri, Duration duration) {
    if (duration <= Duration.zero) return;
    overrideDurationByFileUri[fileUri] = duration;
  }

  static void clearFileUri(String fileUri) {
    overrideDurationByFileUri.remove(fileUri);
  }

  static Duration? durationForFileUri(String fileUri) {
    return overrideDurationByFileUri[fileUri];
  }
}
