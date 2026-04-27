import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/hive_utils.dart';

/// 排序维度。全库列表仅使用前三种（持久化键：`sort_type` / `sort_ascending`）；
/// [addedToPlaylist] 仅用于用户歌单（持久化键：`user_playlist_sort_type` 等）。
enum SongListSortType {
  name,
  createTime,
  modifyTime,

  /// 按加入当前歌单的先后顺序（需传入 [sortSongsCopy] 的 `pathAddIndex`）
  addedToPlaylist,
}

class SongSortPreferences {
  const SongSortPreferences({required this.type, required this.ascending});

  final SongListSortType type;
  final bool ascending;
}

List<Song> sortSongsCopy(
  List<Song> songs,
  SongListSortType type,
  bool ascending, {
  Map<String, int>? pathAddIndex,
}) {
  final out = List<Song>.from(songs);
  int rankAdded(String path) => pathAddIndex?[path] ?? 1 << 30;

  out.sort((a, b) {
    int result = 0;
    switch (type) {
      case SongListSortType.name:
        result = (a.title ?? '').compareTo(b.title ?? '');
        break;
      case SongListSortType.createTime:
        final aTime = a.createDateTime ?? a.updateDateTime ?? DateTime(1970);
        final bTime = b.createDateTime ?? b.updateDateTime ?? DateTime(1970);
        result = aTime.compareTo(bTime);
        break;
      case SongListSortType.modifyTime:
        final aTime = a.updateDateTime ?? DateTime(1970);
        final bTime = b.updateDateTime ?? DateTime(1970);
        result = aTime.compareTo(bTime);
        break;
      case SongListSortType.addedToPlaylist:
        if (pathAddIndex == null || pathAddIndex.isEmpty) {
          result = (a.title ?? '').compareTo(b.title ?? '');
        } else {
          result = rankAdded(a.path).compareTo(rankAdded(b.path));
        }
        break;
    }
    return ascending ? result : -result;
  });
  return out;
}

Future<SongSortPreferences> loadSongSortPreferences() async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  final raw = box.get('sort_type', defaultValue: 0) as int?;
  final asc = box.get('sort_ascending', defaultValue: true) as bool?;
  var idx = raw ?? 0;
  if (idx < 0) idx = 0;
  final max = SongListSortType.modifyTime.index;
  if (idx > max) idx = max;
  return SongSortPreferences(
    type: SongListSortType.values[idx],
    ascending: asc ?? true,
  );
}

/// 用户歌单页排序偏好（含「加入歌单时间」）
Future<SongSortPreferences> loadUserPlaylistSortPreferences() async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  final rawUser = box.get('user_playlist_sort_type') as int?;
  if (rawUser == null) {
    return loadSongSortPreferences();
  }
  final asc = box.get('user_playlist_sort_ascending', defaultValue: true) as bool?;
  var idx = rawUser;
  if (idx < 0) idx = 0;
  final max = SongListSortType.values.length - 1;
  if (idx > max) idx = max;
  return SongSortPreferences(
    type: SongListSortType.values[idx],
    ascending: asc ?? true,
  );
}

Future<void> saveUserPlaylistSortPreferences(SongListSortType type, bool ascending) async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  await box.put('user_playlist_sort_type', type.index);
  await box.put('user_playlist_sort_ascending', ascending);
}

Future<void> saveSongSortPreferences(SongListSortType type, bool ascending) async {
  final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
  await box.put('sort_type', type.index);
  await box.put('sort_ascending', ascending);
}
