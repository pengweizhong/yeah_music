/// 统一识曲结果（各后端映射到此结构，供 UI / 历史写入）。
class MusicRecognitionOutcome {
  const MusicRecognitionOutcome({
    required this.rawStatus,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
    this.appleMusicUrl,
    this.spotifyUrl,
    this.errorMessage,
  });

  /// `success`：请求成功（可能无标题即无匹配）；`error`：调用或协议错误。
  final String rawStatus;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
  final String? appleMusicUrl;
  final String? spotifyUrl;
  final String? errorMessage;

  bool get hasMatch => title != null && title!.trim().isNotEmpty;

  bool get isSuccess => rawStatus == 'success' && hasMatch;

  bool get isNoMatch => rawStatus == 'success' && !hasMatch;
}
