import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/hive_utils.dart';

class UserPlaylist {
  final String id;
  String name;
  final DateTime createdAt;
  final List<String> songPaths;

  UserPlaylist({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? songPaths,
  }) : songPaths = songPaths ?? [];

  factory UserPlaylist.fromMap(Map<dynamic, dynamic> map) {
    return UserPlaylist(
      id: map['id'] as String,
      name: map['name'] as String? ?? '未命名歌单',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      songPaths: _uniquePathsInOrder(
        (map['songPaths'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'songPaths': _uniquePathsInOrder(songPaths),
    };
  }

  bool containsSong(Song song) => songPaths.contains(song.path);
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
      );
    } else {
      final merged = _mergePathsExistingFirst(existing.songPaths, p.songPaths);
      map[id] = UserPlaylist(
        id: id,
        name: existing.name,
        createdAt: existing.createdAt,
        songPaths: merged,
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

  Future<UserPlaylist> createPlaylist(String name) async {
    final trimmedName = name.trim();
    final playlist = UserPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName.isEmpty ? '新建歌单' : trimmedName,
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    await _save();
    notifyListeners();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
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
    for (final playlist in _playlists) {
      if (selectedPlaylistIds.contains(playlist.id)) {
        if (!playlist.songPaths.contains(song.path)) {
          playlist.songPaths.add(song.path);
        }
      } else {
        playlist.songPaths.remove(song.path);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> addSongToPlaylists(Song song, Set<String> playlistIds) async {
    for (final playlist in _playlists.where((playlist) => playlistIds.contains(playlist.id))) {
      if (!playlist.songPaths.contains(song.path)) {
        playlist.songPaths.add(song.path);
      }
    }
    await _save();
    notifyListeners();
  }

  /// 包含该歌曲（按文件路径）的歌单 id 集合
  Set<String> playlistIdsContainingSong(Song song) {
    final path = song.path;
    return {
      for (final p in _playlists)
        if (p.songPaths.contains(path)) p.id,
    };
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;
    playlist.songPaths.remove(song.path);
    await _save();
    notifyListeners();
  }

  List<Song> songsForPlaylist(UserPlaylist playlist, List<Song> allSongs) {
    final byPath = {for (final song in allSongs) song.path: song};
    return playlist.songPaths.map((path) => byPath[path]).whereType<Song>().toList();
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
      'exportedAt': DateTime.now().toIso8601String(),
      'songIdentity': 'Each entry in songPaths is a full file path; duplicates by title/artist are distinct files.',
      'playlists': _playlists.map((e) => e.toMap()).toList(),
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
        } else {
          _playlists.add(
            UserPlaylist(
              id: imp.id,
              name: imp.name,
              createdAt: imp.createdAt,
              songPaths: _uniquePathsInOrder(imp.songPaths),
            ),
          );
        }
      }
    }
    await _save();
    notifyListeners();
  }
}
