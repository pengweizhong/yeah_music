import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/song_path_utils.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/config/app_product_info.dart';
import 'package:yeah_music/utils/hive_utils.dart';

class UserPlaylist {
  final String id;
  String name;
  final DateTime createdAt;
  final List<String> songPaths;

  /// `null`：首页「我的歌单」按序号轮换预设渐变；非空则为自定义纯色或渐变。
  UserPlaylistCoverStyle? coverStyle;

  UserPlaylist({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? songPaths,
    this.coverStyle,
  }) : songPaths = songPaths ?? [];

  factory UserPlaylist.fromMap(Map<dynamic, dynamic> map) {
    return UserPlaylist(
      id: map['id'] as String,
      name: map['name'] as String? ?? '未命名歌单',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      songPaths: _uniquePathsInOrder(
        (map['songPaths'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(),
      ),
      coverStyle: UserPlaylistCoverStyle.tryParse(map['coverStyle']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'songPaths': _uniquePathsInOrder(songPaths),
      if (coverStyle != null) 'coverStyle': coverStyle!.toMap(),
    };
  }

  bool containsSong(Song song) =>
      songPaths.any((p) => normSongPath(p) == normSongPath(song.path));
}

/// 同一歌单内路径去重且保持顺序（加载旧数据时兜底）
List<String> _uniquePathsInOrder(List<String> paths) {
  final seen = <String>{};
  final out = <String>[];
  for (final p in paths) {
    final t = p.trim();
    if (t.isEmpty) continue;
    if (seen.add(t)) out.add(t);
  }
  return out;
}

/// 先保留 [existing] 顺序，再追加 [incoming] 中尚未出现的路径（导入合并用）
List<String> _mergePathsExistingFirst(List<String> existing, List<String> incoming) {
  final seen = <String>{};
  final out = <String>[];
  for (final p in existing) {
    final t = p.trim();
    if (t.isEmpty) continue;
    if (seen.add(t)) out.add(t);
  }
  for (final p in incoming) {
    final t = p.trim();
    if (t.isEmpty) continue;
    if (seen.add(t)) out.add(t);
  }
  return out;
}

/// 导入文件中若多条记录 id 相同则合并路径
List<UserPlaylist> _coalesceImportedPlaylists(List<UserPlaylist> items) {
  final map = <String, UserPlaylist>{};
  for (final p in items) {
    var id = p.id.trim();
    if (id.isEmpty) {
      id = DateTime.now().microsecondsSinceEpoch.toString();
    }
    final existing = map[id];
    if (existing == null) {
      map[id] = UserPlaylist(
        id: id,
        name: p.name,
        createdAt: p.createdAt,
        songPaths: List<String>.from(p.songPaths),
        coverStyle: p.coverStyle,
      );
    } else {
      final merged = _mergePathsExistingFirst(existing.songPaths, p.songPaths);
      map[id] = UserPlaylist(
        id: id,
        name: existing.name,
        createdAt: existing.createdAt,
        songPaths: merged,
        coverStyle: existing.coverStyle ?? p.coverStyle,
      );
    }
  }
  return map.values.toList();
}

const String userPlaylistExportFormatId = 'yeah_music_user_playlists';
const int userPlaylistExportVersion = 1;

/// 解析导出的 JSON 字符串，失败抛出 [FormatException]
Map<String, dynamic> parseUserPlaylistExportJson(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is! Map) {
    throw const FormatException('JSON 根须为对象');
  }
  final m = Map<String, dynamic>.from(decoded);
  if (m['format'] != userPlaylistExportFormatId) {
    throw const FormatException('不是 Yeah Music 歌单备份（format 不匹配）');
  }
  if (m['version'] != userPlaylistExportVersion) {
    throw FormatException('不支持的备份版本: ${m['version']}');
  }
  if (m['playlists'] is! List) {
    throw const FormatException('缺少 playlists 数组');
  }
  return m;
}

class UserPlaylistProvider extends ChangeNotifier {
  static const String _storageKey = 'user_playlists';

  final List<UserPlaylist> _playlists = [];
  bool _initialized = false;

  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final rawList = box.get(_storageKey, defaultValue: <dynamic>[]) as List<dynamic>;
    _playlists
      ..clear()
      ..addAll(
        rawList
            .whereType<Map<dynamic, dynamic>>()
            .map(UserPlaylist.fromMap)
            .where((playlist) => playlist.id.isNotEmpty),
      );
    _initialized = true;
    notifyListeners();
  }

  Future<UserPlaylist> createPlaylist(
    String name, {
    UserPlaylistCoverStyle? coverStyle,
  }) async {
    final trimmedName = name.trim();
    final playlist = UserPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName.isEmpty ? '新建歌单' : trimmedName,
      createdAt: DateTime.now(),
      coverStyle: coverStyle,
    );
    _playlists.add(playlist);
    await _save();
    notifyListeners();
    return playlist;
  }

  Future<void> setPlaylistCoverStyle(
    String playlistId,
    UserPlaylistCoverStyle? style,
  ) async {
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;
    playlist.coverStyle = style;
    await _save();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    await _save();
    notifyListeners();
  }

  /// 批量删除歌单（仅移除歌单与路径引用，不删本地音乐文件）
  Future<void> deletePlaylists(Iterable<String> playlistIds) async {
    final idSet = playlistIds.toSet();
    if (idSet.isEmpty) return;
    _playlists.removeWhere((playlist) => idSet.contains(playlist.id));
    await _save();
    notifyListeners();
  }

  /// 调整歌单在列表中的顺序（与本地存储数组一致，[首页-我的歌单]横滑取前几位同序）
  /// [onReorder] 的约定与 [ReorderableListView] 相同（向下拖时 [newIndex] 需由调用方在框架侧先或此处统一修正）
  Future<void> reorderPlaylists(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _playlists.length) return;
    if (newIndex < 0) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;
    if (newIndex < 0 || newIndex >= _playlists.length) return;
    final item = _playlists.removeAt(oldIndex);
    _playlists.insert(newIndex, item);
    await _save();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;
    playlist.name = trimmedName;
    await _save();
    notifyListeners();
  }

  Future<void> setSongInPlaylists(Song song, Set<String> selectedPlaylistIds) async {
    final sn = normSongPath(song.path);
    for (final playlist in _playlists) {
      if (selectedPlaylistIds.contains(playlist.id)) {
        final has = playlist.songPaths.any((sp) => normSongPath(sp) == sn);
        if (!has) {
          playlist.songPaths.add(song.path);
        }
      } else {
        playlist.songPaths.removeWhere((p) => normSongPath(p) == sn);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> addSongToPlaylists(Song song, Set<String> playlistIds) async {
    final sn = normSongPath(song.path);
    for (final playlist in _playlists.where((playlist) => playlistIds.contains(playlist.id))) {
      final has = playlist.songPaths.any((sp) => normSongPath(sp) == sn);
      if (!has) {
        playlist.songPaths.add(song.path);
      }
    }
    await _save();
    notifyListeners();
  }

  /// 包含该歌曲（按文件路径）的歌单 id 集合
  Set<String> playlistIdsContainingSong(Song song) {
    final n = normSongPath(song.path);
    return {
      for (final p in _playlists)
        if (p.songPaths.any((sp) => normSongPath(sp) == n)) p.id,
    };
  }

  /// 同时包含 [songs] 中每一首的用户歌单 id 交集（批量「添加到歌单」初始勾选）。
  Set<String> playlistIdsContainingAllSongs(List<Song> songs) {
    if (songs.isEmpty) return {};
    var intersection = playlistIdsContainingSong(songs.first);
    for (var i = 1; i < songs.length; i++) {
      intersection =
          intersection.intersection(playlistIdsContainingSong(songs[i]));
    }
    return intersection;
  }

  /// 与 [setSongInPlaylists] 语义一致，但对多首曲目批量生效。
  Future<void> setSongsMembershipInPlaylists(
    List<Song> songs,
    Set<String> selectedPlaylistIds,
  ) async {
    if (songs.isEmpty) return;
    final norms = {for (final s in songs) normSongPath(s.path)};
    for (final playlist in _playlists) {
      if (selectedPlaylistIds.contains(playlist.id)) {
        for (final song in songs) {
          final sn = normSongPath(song.path);
          final has = playlist.songPaths.any((sp) => normSongPath(sp) == sn);
          if (!has) playlist.songPaths.add(song.path);
        }
      } else {
        playlist.songPaths.removeWhere((p) => norms.contains(normSongPath(p)));
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;
    final n = normSongPath(song.path);
    playlist.songPaths.removeWhere((p) => normSongPath(p) == n);
    await _save();
    notifyListeners();
  }

  /// 从所有用户歌单中移除路径（文件已删除等）。
  Future<void> removePathsFromAllPlaylists(Iterable<String> rawPaths) async {
    final norms = <String>{
      for (final p in rawPaths)
        if (p.trim().isNotEmpty) normSongPath(p),
    };
    if (norms.isEmpty) return;
    var changed = false;
    for (final playlist in _playlists) {
      final before = playlist.songPaths.length;
      playlist.songPaths.removeWhere((p) => norms.contains(normSongPath(p)));
      if (playlist.songPaths.length != before) changed = true;
    }
    if (!changed) return;
    await _save();
    notifyListeners();
  }

  /// 所有歌单内将路径 [oldPath] 替换为 [newPath]（文件重命名后）。
  Future<void> replaceSongPathInAllPlaylists(String oldPath, String newPath) async {
    final o = normSongPath(oldPath);
    final n = newPath.trim();
    if (o.isEmpty || n.isEmpty) return;
    var changed = false;
    for (final playlist in _playlists) {
      for (var i = 0; i < playlist.songPaths.length; i++) {
        if (normSongPath(playlist.songPaths[i]) == o) {
          playlist.songPaths[i] = n;
          changed = true;
        }
      }
    }
    if (!changed) return;
    await _save();
    notifyListeners();
  }

  Map<String, Song> _indexLibraryByNormPath(List<Song> allSongs) {
    final byNormPath = <String, Song>{};
    for (final song in allSongs) {
      final k = normSongPath(song.path);
      if (k.isEmpty) continue;
      byNormPath.putIfAbsent(k, () => song);
    }
    return byNormPath;
  }

  /// 仅从已加载曲库解析（同步）。未命中路径将被忽略。
  List<Song> songsForPlaylist(UserPlaylist playlist, List<Song> allSongs) {
    final byNormPath = _indexLibraryByNormPath(allSongs);
    return playlist.songPaths
        .map((path) => byNormPath[normSongPath(path)])
        .whereType<Song>()
        .toList();
  }

  /// 与 [songsForPlaylist] 相同顺序；先匹配 [librarySongs]，未命中且路径在本机仍存在时读盘加载（覆盖 OneDrive
  /// 缓存未及时并入 [PlayListProvider]、仅首页等处以 [UserPlaylist.songPaths] 计数等情形）。
  Future<List<Song>> songsForPlaylistWithDiskFallback(
    UserPlaylist playlist,
    List<Song> librarySongs,
  ) async {
    final byNormPath = _indexLibraryByNormPath(librarySongs);
    final out = <Song>[];
    for (final path in playlist.songPaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      final k = normSongPath(trimmed);
      final fromLib = byNormPath[k];
      if (fromLib != null) {
        out.add(fromLib);
        continue;
      }
      if (kIsWeb) continue;
      try {
        final f = File(trimmed);
        if (await f.exists()) {
          final s = Song(trimmed);
          await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
          out.add(s);
        }
      } catch (_) {}
    }
    return out;
  }

  UserPlaylist? _playlistById(String playlistId) {
    for (final playlist in _playlists) {
      if (playlist.id == playlistId) return playlist;
    }
    return null;
  }

  Future<void> _save() async {
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    await box.put(_storageKey, _playlists.map((playlist) => playlist.toMap()).toList());
  }

  /// 导出用 JSON 对象（歌曲仅以完整文件路径标识，同名/不同音质为不同路径）
  Map<String, dynamic> buildExportMap() {
    return {
      'format': userPlaylistExportFormatId,
      'version': userPlaylistExportVersion,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'songIdentity': 'Each entry in songPaths is a full file path; duplicates by title/artist are distinct files.',
      'playlists': _playlists.map((e) => e.toMap()).toList(),
    };
  }

  /// 仅导出指定 [playlistIds] 中的歌单（按本地列表顺序，忽略未知 id）
  Map<String, dynamic> buildExportMapForPlaylists(Iterable<String> playlistIds) {
    final want = playlistIds.toSet();
    final out = <Map<String, dynamic>>[];
    for (final p in _playlists) {
      if (want.contains(p.id)) {
        out.add(p.toMap());
      }
    }
    return {
      'format': userPlaylistExportFormatId,
      'version': userPlaylistExportVersion,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'songIdentity': 'Each entry in songPaths is a full file path; duplicates by title/artist are distinct files.',
      'playlists': out,
    };
  }

  /// [replaceAll] 为 true：清空本地歌单后导入；为 false：按歌单 id 合并路径（无则新建）
  Future<void> applyImportedDocument(Map<String, dynamic> doc, {required bool replaceAll}) async {
    final rawList = doc['playlists'] as List<dynamic>;
    final parsed = <UserPlaylist>[];
    for (final e in rawList) {
      if (e is! Map) continue;
      try {
        parsed.add(UserPlaylist.fromMap(Map<dynamic, dynamic>.from(e)));
      } catch (_) {}
    }
    final imported = _coalesceImportedPlaylists(parsed);

    if (replaceAll) {
      _playlists
        ..clear()
        ..addAll(
          imported.map(
            (p) => UserPlaylist(
              id: p.id,
              name: p.name,
              createdAt: p.createdAt,
              songPaths: _uniquePathsInOrder(p.songPaths),
              coverStyle: p.coverStyle,
            ),
          ),
        );
    } else {
      for (final imp in imported) {
        final existing = _playlistById(imp.id);
        if (existing != null) {
          final merged = _mergePathsExistingFirst(existing.songPaths, imp.songPaths);
          existing.songPaths
            ..clear()
            ..addAll(merged);
          if (imp.coverStyle != null) {
            existing.coverStyle = imp.coverStyle;
          }
        } else {
          _playlists.add(
            UserPlaylist(
              id: imp.id,
              name: imp.name,
              createdAt: imp.createdAt,
              songPaths: _uniquePathsInOrder(imp.songPaths),
              coverStyle: imp.coverStyle,
            ),
          );
        }
      }
    }
    await _save();
    notifyListeners();
  }
}
