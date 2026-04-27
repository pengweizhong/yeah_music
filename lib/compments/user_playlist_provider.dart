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
    if (seen.add(p)) out.add(p);
  }
  return out;
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
}
