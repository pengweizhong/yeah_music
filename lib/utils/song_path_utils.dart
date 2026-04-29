import 'package:path/path.dart' as p;

/// 与全库/播放状态匹配路径时一致
String normSongPath(String path) {
  final t = path.trim();
  if (t.isEmpty) return '';
  return p.normalize(t).replaceAll(r'\', '/').toLowerCase();
}

/// [MediaItem.id] 可能为 `file:///...`
String filePathFromMediaItemId(String mediaId) {
  final t = mediaId.trim();
  if (t.startsWith('file://')) {
    try {
      return Uri.parse(t).toFilePath();
    } catch (_) {
      return t;
    }
  }
  return t;
}

bool mediaItemIdMatchesSongPath(String mediaId, String songPath) {
  return normSongPath(filePathFromMediaItemId(mediaId)) ==
      normSongPath(songPath);
}

bool songPathsEqual(String a, String b) => normSongPath(a) == normSongPath(b);
