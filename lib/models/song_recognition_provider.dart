/// 听歌识曲云端引擎（策略实现）。
enum SongRecognitionProvider {
  audd,
  acrcloud,
}

SongRecognitionProvider songRecognitionProviderFromStorage(String? raw) {
  for (final v in SongRecognitionProvider.values) {
    if (v.name == raw) return v;
  }
  return SongRecognitionProvider.audd;
}
