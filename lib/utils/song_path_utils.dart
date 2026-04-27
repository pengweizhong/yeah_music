import 'package:path/path.dart' as p;

/// 与全库/播放状态匹配路径时一致
String normSongPath(String path) {
  final t = path.trim();
  if (t.isEmpty) return '';
  return p.normalize(t).replaceAll(r'\', '/').toLowerCase();
}

bool songPathsEqual(String a, String b) => normSongPath(a) == normSongPath(b);
