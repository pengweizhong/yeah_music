import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
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

String _normPlaylistMatchToken(String s) {
  return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _effectiveSongTitleForPlaylistMatch(Song song) {
  final t = song.title?.trim();
  if (t != null && t.isNotEmpty) return t;
  return p.basenameWithoutExtension(song.path);
}

String _titleArtistMatchKey(String title, String artist) {
  return '${_normPlaylistMatchToken(title)}\x1f${_normPlaylistMatchToken(artist)}';
}

/// 从「无扩展名文件名」猜测 (title, artist) 的两种键：常见 `艺人 - 歌名` 与 `歌名 - 艺人`。
List<String> _stemTitleArtistMatchKeys(String storedPath) {
  final stem = p.basenameWithoutExtension(storedPath);
  final out = <String>[];
  void addKey(String title, String artist) {
    final k = _titleArtistMatchKey(title, artist);
    if (!out.contains(k)) out.add(k);
  }

  const seps = [' — ', ' – ', ' - '];
  for (final sep in seps) {
    final i = stem.indexOf(sep);
    if (i <= 0 || i + sep.length >= stem.length) continue;
    final left = stem.substring(0, i).trim();
    final right = stem.substring(i + sep.length).trim();
    if (left.isEmpty || right.isEmpty) continue;
    addKey(right, left);
    addKey(left, right);
    return out;
  }

  addKey(stem, '');
  return out;
}

Song? _pickUniqueByTitleArtistKeysInPool(
  Iterable<Song> pool,
  List<String> keys,
) {
  Song? hit;
  for (final s in pool) {
    final k = _titleArtistMatchKey(
      _effectiveSongTitleForPlaylistMatch(s),
      s.artist?.trim() ?? '',
    );
    if (!keys.contains(k)) continue;
    if (hit != null) return null;
    hit = s;
  }
  return hit;
}

Song? _pickUniqueByStemAgainstBasenamePool(List<Song> pool, String storedPath) {
  final keys = _stemTitleArtistMatchKeys(storedPath);
  return _pickUniqueByTitleArtistKeysInPool(pool, keys);
}

Song? _pickUniqueByTitleNormAgainstLibrary(String storedPath, List<Song> all) {
  final stem = p.basenameWithoutExtension(storedPath);
  final want = _normPlaylistMatchToken(stem);
  if (want.isEmpty) return null;
  Song? hit;
  for (final s in all) {
    if (_normPlaylistMatchToken(_effectiveSongTitleForPlaylistMatch(s)) != want) {
      continue;
    }
    if (hit != null) return null;
    hit = s;
  }
  return hit;
}

/// 歌单内已失效路径 → 在 [librarySongs] 中重绑：先文件名（含 OneDrive 点播 `{id}_远端名.ext` 的远端名别名），再曲库内嵌标题+艺人（含从文件名拆分的两种顺序）。
Song? _remapStalePlaylistPathToLibrarySong(
  String storedPath,
  _PlaylistPathRemapIndexes idx,
) {
  final base = p.basename(storedPath).toLowerCase();
  if (base.isEmpty) return null;

  var byBase = idx.byBasenameLower[base];
  if (byBase == null || byBase.isEmpty) {
    final fromOd = OneDriveConfig.cacheBasenameRemoteSuffixLower(base);
    if (fromOd != null) {
      byBase = idx.byBasenameLower[fromOd];
    }
  }
  if (byBase != null && byBase.isNotEmpty) {
    if (byBase.length == 1) return byBase.single;
    final narrowed = _pickUniqueByStemAgainstBasenamePool(byBase, storedPath);
    if (narrowed != null) return narrowed;
    return null;
  }

  final stemKeys = _stemTitleArtistMatchKeys(storedPath);
  for (final key in stemKeys) {
    final xs = idx.byTitleArtistKey[key];
    if (xs != null && xs.length == 1) return xs.single;
  }

  return _pickUniqueByTitleNormAgainstLibrary(storedPath, idx.allSongs);
}

class _PlaylistPathRemapIndexes {
  _PlaylistPathRemapIndexes({
    required this.byNormPath,
    required this.byBasenameLower,
    required this.byTitleArtistKey,
    required this.allSongs,
  });

  final Map<String, Song> byNormPath;
  final Map<String, List<Song>> byBasenameLower;
  final Map<String, List<Song>> byTitleArtistKey;
  final List<Song> allSongs;

  static _PlaylistPathRemapIndexes build(List<Song> librarySongs) {
    final byNormPath = <String, Song>{};
    final byBasenameLower = <String, List<Song>>{};
    final byTitleArtistKey = <String, List<Song>>{};
    void addBasenameKey(String key, Song song) {
      if (key.isEmpty) return;
      final list = byBasenameLower.putIfAbsent(key, () => []);
      final nk = normSongPath(song.path);
      for (final e in list) {
        if (normSongPath(e.path) == nk) return;
      }
      list.add(song);
    }

    for (final s in librarySongs) {
      final nk = normSongPath(s.path);
      if (nk.isEmpty) continue;
      byNormPath.putIfAbsent(nk, () => s);
      final b = p.basename(s.path).toLowerCase();
      addBasenameKey(b, s);
      final od = OneDriveConfig.cacheBasenameRemoteSuffixLower(b);
      if (od != null) {
        addBasenameKey(od, s);
      }
      final tk = _titleArtistMatchKey(
        _effectiveSongTitleForPlaylistMatch(s),
        s.artist?.trim() ?? '',
      );
      byTitleArtistKey.putIfAbsent(tk, () => []).add(s);
    }
    return _PlaylistPathRemapIndexes(
      byNormPath: byNormPath,
      byBasenameLower: byBasenameLower,
      byTitleArtistKey: byTitleArtistKey,
      allSongs: librarySongs,
    );
  }
}

/// 歌单路径不在曲库且本机无文件时，仍用于列表展示以便用户辨认并「从歌单移除」；[Song.title] 为路径上的文件名。
Song _userPlaylistMissingFileStubSong(String storedPath) {
  final pStr = storedPath.trim();
  final s = Song(pStr);
  s.title = p.basename(pStr);
  s.playlistEntryMissingOnDevice = true;
  return s;
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

/// 可选：`歌单 id` → 自定义封面原始字节的标准 Base64（单文件导出便携用）。
///
/// 与 [UserPlaylist.toMap] 里 `coverStyle` 类型 `img` 的路径字段配套：云端备份路径指向本机无效，
/// 实际像素数据以此字段为准。
const String userPlaylistExportCoverImagesKey = 'playlistCoverImages';

/// OneDrive 等同目录侧车文件：`歌单 id` → 文件名（与 `yeah_music_playlists.json` 同一文件夹）。
const String userPlaylistExportCoverAssetNamesKey = 'playlistCoverAssetNames';

/// 首页「我的歌单」横滑顺序：含 [UserPlaylistProvider.homeCarouselLibrarySentinel] 与歌单 id。
const String userPlaylistExportCarouselOrderKey = 'homePlaylistCarouselOrder';

/// 备份中「全部歌曲」横滑卡片的封面样式（与 [UserPlaylist.toMap] 内 `coverStyle` 结构相同）。
const String userPlaylistExportHomeLibraryCoverStyleKey = 'homeLibraryCoverStyle';

/// 自定义「全部歌曲」标题；缺省或由导入方回退为本地化默认文案。
const String userPlaylistExportHomeLibraryDisplayNameKey = 'homeLibraryDisplayName';

/// 自备份文档读取封面侧车文件名表。
Map<String, String> playlistCoverAssetNamesFromDoc(Map<String, dynamic> doc) {
  final raw = doc[userPlaylistExportCoverAssetNamesKey];
  if (raw is! Map) return {};
  final out = <String, String>{};
  for (final e in raw.entries) {
    final k = '${e.key}'.trim();
    final v = e.value;
    if (k.isEmpty || v is! String || v.trim().isEmpty) continue;
    out[k] = v.trim();
  }
  return out;
}

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
  static const String _carouselOrderKey = 'home_playlist_carousel_order';
  static const String _homeLibraryCoverStyleKey = 'home_library_carousel_cover_style';
  static const String _homeLibraryDisplayNameKey = 'home_library_carousel_display_name';

  /// 首页与管理页横滑顺序中表示「本地全部歌曲」的占位键（非用户歌单 id）。
  static const String homeCarouselLibrarySentinel = '__ym_home_library__';

  final List<UserPlaylist> _playlists = [];
  List<String> _homeCarouselOrderKeys = [];
  UserPlaylistCoverStyle? _homeLibraryCoverStyle;
  String? _homeLibraryDisplayName;
  bool _initialized = false;

  /// 歌单详情 [songsForPlaylistWithDiskFallback] 跨路由缓存；键含 [PlayListProvider.libraryMergeEpoch]，
  /// 合并曲库失效后会自动换 key 重算。
  final Map<String, Future<List<Song>>> _playlistDetailResolveFutures = {};

  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);

  bool get initialized => _initialized;

  /// 「全部歌曲」卡片的自定义封面 / 配色；`null` 时界面使用内置默认色。
  UserPlaylistCoverStyle? get homeLibraryCoverStyle => _homeLibraryCoverStyle;

  /// 非空时使用自定义标题；否则传入 [defaultTitle]（一般为 `l10n.homeAllSongs`）。
  String resolvedHomeLibraryTitle(String defaultTitle) {
    final c = _homeLibraryDisplayName?.trim();
    if (c == null || c.isEmpty) return defaultTitle;
    return c;
  }

  void _loadHomeLibrarySlotFromBox(dynamic box) {
    final covRaw = box.get(_homeLibraryCoverStyleKey);
    _homeLibraryCoverStyle = UserPlaylistCoverStyle.tryParse(covRaw);
    final nameRaw = box.get(_homeLibraryDisplayNameKey);
    if (nameRaw is String) {
      final t = nameRaw.trim();
      _homeLibraryDisplayName = t.isEmpty ? null : t;
    } else {
      _homeLibraryDisplayName = null;
    }
  }

  Future<void> _persistHomeLibrarySlot(dynamic box) async {
    if (_homeLibraryCoverStyle != null) {
      await box.put(_homeLibraryCoverStyleKey, _homeLibraryCoverStyle!.toMap());
    } else {
      await box.delete(_homeLibraryCoverStyleKey);
    }
    if (_homeLibraryDisplayName != null && _homeLibraryDisplayName!.trim().isNotEmpty) {
      await box.put(_homeLibraryDisplayNameKey, _homeLibraryDisplayName!.trim());
    } else {
      await box.delete(_homeLibraryDisplayNameKey);
    }
  }

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
    _homeCarouselOrderKeys = _parseCarouselOrderRaw(box.get(_carouselOrderKey));
    _loadHomeLibrarySlotFromBox(box);
    _initialized = true;
    notifyListeners();
  }

  /// 使 [resolvedPlaylistSongsForDetailCached] 缓存失效；[playlistId] 为 null 时清空全部。
  void evictPlaylistDetailResolveCache([String? playlistId]) {
    if (playlistId == null) {
      _playlistDetailResolveFutures.clear();
      return;
    }
    final prefix = '$playlistId\x1e';
    _playlistDetailResolveFutures.removeWhere((k, _) => k.startsWith(prefix));
  }

  void _pruneStalePlaylistDetailResolveFutures(
    String playlistId,
    int mergeEpoch,
    String pathSig,
  ) {
    _playlistDetailResolveFutures.removeWhere((k, _) {
      if (!k.startsWith('$playlistId\x1e')) return false;
      final parts = k.split('\x1e');
      if (parts.length < 3) return false;
      final ep = int.tryParse(parts[1]) ?? -1;
      final sig = parts.sublist(2).join('\x1e');
      return sig == pathSig && ep != mergeEpoch;
    });
  }

  /// 从 Hive 重新载入用户歌单与首页横滑顺序（下拉刷新与其它持久化同步）。
  Future<void> reloadFromHive() async {
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    final rawList =
        box.get(_storageKey, defaultValue: <dynamic>[]) as List<dynamic>;
    _playlists
      ..clear()
      ..addAll(
        rawList
            .whereType<Map<dynamic, dynamic>>()
            .map(UserPlaylist.fromMap)
            .where((playlist) => playlist.id.isNotEmpty),
      );
    _homeCarouselOrderKeys = _parseCarouselOrderRaw(box.get(_carouselOrderKey));
    _loadHomeLibrarySlotFromBox(box);
    _initialized = true;
    _playlistDetailResolveFutures.clear();
    notifyListeners();
  }

  List<String> _parseCarouselOrderRaw(Object? raw) {
    if (raw is! List<dynamic>) return [];
    final out = <String>[];
    final seen = <String>{};
    for (final e in raw) {
      if (e is! String) continue;
      final t = e.trim();
      if (t.isEmpty) continue;
      if (!seen.add(t)) continue;
      out.add(t);
    }
    return out;
  }

  Future<void> _persistCarouselOrderKeys() async {
    final box = await HiveUtils.openBox<dynamic>(Constant.hiveRootPath);
    await box.put(_carouselOrderKey, List<String>.from(_homeCarouselOrderKeys));
  }

  /// 首页与管理页共用的横滑顺序键（含 [homeCarouselLibrarySentinel] 表示「全部歌曲」）。
  List<String> resolvedHomeCarouselOrder() {
    final idOrder = _playlists.map((p) => p.id).toList();
    final idSet = idOrder.toSet();
    final seen = <String>{};
    final out = <String>[];

    for (final key in _homeCarouselOrderKeys) {
      if (key == homeCarouselLibrarySentinel) {
        if (seen.add(key)) out.add(key);
      } else if (idSet.contains(key) && seen.add(key)) {
        out.add(key);
      }
    }
    if (!seen.contains(homeCarouselLibrarySentinel)) {
      out.insert(0, homeCarouselLibrarySentinel);
      seen.add(homeCarouselLibrarySentinel);
    }
    for (final id in idOrder) {
      if (!seen.contains(id)) {
        out.add(id);
        seen.add(id);
      }
    }
    return out;
  }

  UserPlaylist? playlistById(String playlistId) => _playlistById(playlistId);

  /// [ReorderableListView.onReorder] 约定（向下拖时框架会先修正 [newIndex]）
  Future<void> reorderHomeCarousel(int oldIndex, int newIndex) async {
    final order = List<String>.from(resolvedHomeCarouselOrder());
    if (oldIndex < 0 || oldIndex >= order.length) return;
    if (newIndex < 0) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;
    if (newIndex < 0 || newIndex >= order.length) return;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    _homeCarouselOrderKeys = order;
    _syncPlaylistsOrderFromCarouselKeys(order);
    await _persistCarouselOrderKeys();
    await _save();
    notifyListeners();
  }

  /// 覆盖导入：以备份中的横滑顺序为准；缺字段或项无效时回退为「全部歌曲」在前 + 当前 [_playlists] 顺序。
  void _restoreHomeCarouselOrderFromBackup(List<String>? backupKeys) {
    final idOrder = _playlists.map((p) => p.id).toList();
    final idSet = idOrder.toSet();
    final seen = <String>{};
    final out = <String>[];

    if (backupKeys != null) {
      for (final key in backupKeys) {
        final t = key.trim();
        if (t.isEmpty) continue;
        if (t == homeCarouselLibrarySentinel) {
          if (seen.add(t)) out.add(t);
        } else if (idSet.contains(t) && seen.add(t)) {
          out.add(t);
        }
      }
    }
    if (!seen.contains(homeCarouselLibrarySentinel)) {
      out.insert(0, homeCarouselLibrarySentinel);
      seen.add(homeCarouselLibrarySentinel);
    }
    for (final id in idOrder) {
      if (!seen.contains(id)) {
        out.add(id);
        seen.add(id);
      }
    }
    _homeCarouselOrderKeys = out;
  }

  /// 写入导出 JSON：与当前首页横滑一致；[playlistIdsLimit] 非空时只保留其中的歌单 id（子集导出）。
  List<String> _homeCarouselOrderForExport({Set<String>? playlistIdsLimit}) {
    final full = resolvedHomeCarouselOrder();
    if (playlistIdsLimit == null) {
      return List<String>.from(full);
    }
    final out = <String>[];
    final seen = <String>{};
    for (final k in full) {
      if (k == homeCarouselLibrarySentinel) {
        if (seen.add(k)) out.add(k);
      } else if (playlistIdsLimit.contains(k) && seen.add(k)) {
        out.add(k);
      }
    }
    if (!seen.contains(homeCarouselLibrarySentinel)) {
      out.insert(0, homeCarouselLibrarySentinel);
      seen.add(homeCarouselLibrarySentinel);
    }
    return out;
  }

  void _syncPlaylistsOrderFromCarouselKeys(List<String> orderKeys) {
    final idsInOrder = orderKeys
        .where((k) => k != homeCarouselLibrarySentinel)
        .toList();
    final byId = {for (final p in _playlists) p.id: p};
    final next = <UserPlaylist>[];
    for (final id in idsInOrder) {
      final p = byId[id];
      if (p != null) next.add(p);
    }
    for (final p in _playlists) {
      if (!next.any((x) => x.id == p.id)) next.add(p);
    }
    _playlists
      ..clear()
      ..addAll(next);
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

  void _evictCoverImageCache(String absolutePath) {
    try {
      final f = File(absolutePath);
      if (f.existsSync()) {
        PaintingBinding.instance.imageCache.evict(FileImage(f));
      }
    } catch (_) {}
  }

  void _deleteCoverImageFileIfAny(UserPlaylistCoverStyle? style) {
    if (style == null || !style.isCustomImage) return;
    try {
      final path = style.imagePath;
      _evictCoverImageCache(path);
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  String _safePlaylistCoverFileId(String playlistId) =>
      playlistId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<String> _playlistCoverSupportPath(String playlistId) async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'playlist_covers'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return p.join(dir.path, 'cover_${_safePlaylistCoverFileId(playlistId)}.png');
  }

  Future<UserPlaylistCoverStyle?> _canonicalizeCoverImageStyle(
    String playlistId,
    UserPlaylistCoverStyle style,
  ) async {
    if (!style.isCustomImage) return style;
    final rawPath = style.imagePath;
    final destPath = await _playlistCoverSupportPath(playlistId);
    if (p.normalize(rawPath) == p.normalize(destPath)) {
      final f = File(destPath);
      if (f.existsSync()) return style;
      return null;
    }
    final src = File(rawPath);
    if (!await src.exists()) return null;
    await src.copy(destPath);
    _evictCoverImageCache(destPath);
    try {
      final tmpRoot = (await getTemporaryDirectory()).path;
      final normSrc = p.normalize(rawPath);
      final normTmp = p.normalize(tmpRoot);
      if (normSrc.startsWith('$normTmp${p.separator}')) {
        await src.delete();
      }
    } catch (_) {}
    return UserPlaylistCoverStyle.customImage(destPath);
  }

  Future<void> setPlaylistCoverStyle(
    String playlistId,
    UserPlaylistCoverStyle? style,
  ) async {
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;

    final prev = playlist.coverStyle;
    UserPlaylistCoverStyle? next = style;

    if (next?.isCustomImage == true) {
      next = await _canonicalizeCoverImageStyle(playlistId, next!);
      if (next == null) {
        notifyListeners();
        return;
      }
    }

    final prevImg =
        prev?.isCustomImage == true ? prev!.imagePath : null;
    final nextImg =
        next?.isCustomImage == true ? next!.imagePath : null;

    if (prevImg != null &&
        (nextImg == null || p.normalize(prevImg) != p.normalize(nextImg))) {
      _deleteCoverImageFileIfAny(prev);
    }

    playlist.coverStyle = next;
    await _save();
    notifyListeners();
  }

  Future<void> setHomeLibraryCoverStyle(UserPlaylistCoverStyle? style) async {
    final prev = _homeLibraryCoverStyle;
    UserPlaylistCoverStyle? next = style;
    if (next?.isCustomImage == true) {
      next = await _canonicalizeCoverImageStyle(homeCarouselLibrarySentinel, next!);
      if (next == null) {
        notifyListeners();
        return;
      }
    }
    final prevImg = prev?.isCustomImage == true ? prev!.imagePath : null;
    final nextImg = next?.isCustomImage == true ? next!.imagePath : null;
    if (prevImg != null &&
        (nextImg == null || p.normalize(prevImg) != p.normalize(nextImg))) {
      _deleteCoverImageFileIfAny(prev);
    }
    _homeLibraryCoverStyle = next;
    await _save();
    notifyListeners();
  }

  /// 置空或仅空白则恢复为本地化默认「全部歌曲」标题。
  Future<void> setHomeLibraryDisplayName(String? name) async {
    final t = name?.trim();
    _homeLibraryDisplayName = (t == null || t.isEmpty) ? null : t;
    await _save();
    notifyListeners();
  }

  /// 供封面样式底sheet使用；[titleForPreview] 为 [resolvedHomeLibraryTitle] 传入的展示名。
  UserPlaylist homeLibraryPlaylistStubForCoverUi(String titleForPreview) {
    return UserPlaylist(
      id: homeCarouselLibrarySentinel,
      name: titleForPreview,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      songPaths: const [],
      coverStyle: _homeLibraryCoverStyle,
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlist = _playlistById(playlistId);
    if (playlist != null) {
      _deleteCoverImageFileIfAny(playlist.coverStyle);
    }
    evictPlaylistDetailResolveCache(playlistId);
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    _homeCarouselOrderKeys.removeWhere((k) => k == playlistId);
    await _save();
    await _persistCarouselOrderKeys();
    notifyListeners();
  }

  /// 批量删除歌单（仅移除歌单与路径引用，不删本地音乐文件）
  Future<void> deletePlaylists(Iterable<String> playlistIds) async {
    final idSet = playlistIds.toSet();
    if (idSet.isEmpty) return;
    evictPlaylistDetailResolveCache();
    for (final playlist in _playlists) {
      if (idSet.contains(playlist.id)) {
        _deleteCoverImageFileIfAny(playlist.coverStyle);
      }
    }
    _playlists.removeWhere((playlist) => idSet.contains(playlist.id));
    _homeCarouselOrderKeys.removeWhere(idSet.contains);
    await _save();
    await _persistCarouselOrderKeys();
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
    evictPlaylistDetailResolveCache();
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
    for (final id in playlistIds) {
      evictPlaylistDetailResolveCache(id);
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
    evictPlaylistDetailResolveCache();
    await _save();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlistById(playlistId);
    if (playlist == null) return;
    final n = normSongPath(song.path);
    playlist.songPaths.removeWhere((p) => normSongPath(p) == n);
    evictPlaylistDetailResolveCache(playlistId);
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
    evictPlaylistDetailResolveCache();
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
    evictPlaylistDetailResolveCache();
    await _save();
    notifyListeners();
  }

  /// 与 [songsForPlaylistWithDiskFallback] 相同解析，但在「歌单 id + 路径签名 + 合并曲库世代」不变时
  /// 复用同一 [Future]，避免每次进入详情页重复全量读盘校验（例如 70 首歌本机均存在仍每次 await 70 次）。
  Future<List<Song>> resolvedPlaylistSongsForDetailCached({
    required UserPlaylist playlist,
    required int libraryMergeEpoch,
    required List<Song> libraryMergedSongs,
  }) {
    final pathSig = playlist.songPaths.join('\x1e');
    _pruneStalePlaylistDetailResolveFutures(
      playlist.id,
      libraryMergeEpoch,
      pathSig,
    );
    final key = '${playlist.id}\x1e$libraryMergeEpoch\x1e$pathSig';
    return _playlistDetailResolveFutures.putIfAbsent(
      key,
      () => songsForPlaylistWithDiskFallback(playlist, libraryMergedSongs),
    );
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
  ///
  /// 不在此做「失效路径 → 曲库重绑」：避免每次进入歌单详情都扫描、写 Hive。批量重绑仅在
  /// OneDrive 云端恢复歌单后由 [remapAllPlaylistPathsFromLibrary] 触发。
  ///
  /// 曲库与本机均无有效文件时仍追加占位 [Song]（标题为路径文件名），与 [songPaths] 条数一致，便于用户手动从歌单移除。
  ///
  /// 合并曲库命中时仍会校验 [Song.path] 在本机是否存在：恢复歌单后曲库索引可能仍指向已删文件，此时与未命中一样
  /// 使用 [playlistEntryMissingOnDevice] 占位行（列表标题呈 error 色）。
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
        if (!kIsWeb) {
          try {
            if (!await File(fromLib.path).exists()) {
              out.add(_userPlaylistMissingFileStubSong(trimmed));
              continue;
            }
          } catch (_) {
            out.add(_userPlaylistMissingFileStubSong(trimmed));
            continue;
          }
        }
        out.add(fromLib);
        continue;
      }
      if (kIsWeb) {
        out.add(_userPlaylistMissingFileStubSong(trimmed));
        continue;
      }
      try {
        final f = File(trimmed);
        if (await f.exists()) {
          final s = Song(trimmed);
          await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
          out.add(s);
        } else {
          out.add(_userPlaylistMissingFileStubSong(trimmed));
        }
      } catch (_) {
        out.add(_userPlaylistMissingFileStubSong(trimmed));
      }
    }
    return out;
  }

  /// 批量修正歌单内「路径失效但曲库仍有同一首歌」的条目并持久化（便于导出/本机路径迁移）。
  ///
  /// 仅在 **OneDrive 从云端恢复歌单** 后由设置页在刷新合并曲库后调用；不在冷启动或进入歌单详情时触发。
  /// 匹配规则见 [_remapStalePlaylistPathToLibrarySong]。
  Future<void> remapAllPlaylistPathsFromLibrary(List<Song> librarySongs) async {
    if (kIsWeb || !_initialized || librarySongs.isEmpty) return;
    final idx = _PlaylistPathRemapIndexes.build(librarySongs);
    var changed = false;
    for (final pl in _playlists) {
      for (var i = 0; i < pl.songPaths.length; i++) {
        final trimmed = pl.songPaths[i].trim();
        if (trimmed.isEmpty) continue;
        if (idx.byNormPath.containsKey(normSongPath(trimmed))) continue;
        var existsOk = false;
        try {
          existsOk = await File(trimmed).exists();
        } catch (_) {
          existsOk = false;
        }
        if (existsOk) continue;
        final hit = _remapStalePlaylistPathToLibrarySong(trimmed, idx);
        if (hit == null) continue;
        final newPath = hit.path.trim();
        if (newPath.isEmpty || normSongPath(newPath) == normSongPath(trimmed)) {
          continue;
        }
        pl.songPaths[i] = newPath;
        changed = true;
      }
    }
    if (changed) {
      evictPlaylistDetailResolveCache();
      await _save();
      notifyListeners();
    }
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
    await _persistHomeLibrarySlot(box);
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
      userPlaylistExportCarouselOrderKey: _homeCarouselOrderForExport(),
      if (_homeLibraryCoverStyle != null)
        userPlaylistExportHomeLibraryCoverStyleKey: _homeLibraryCoverStyle!.toMap(),
      if (_homeLibraryDisplayName != null && _homeLibraryDisplayName!.trim().isNotEmpty)
        userPlaylistExportHomeLibraryDisplayNameKey: _homeLibraryDisplayName!.trim(),
    };
  }

  /// 将本次导出中包含「自定义封面图」的歌单文件读入并写入 [map]\[[userPlaylistExportCoverImagesKey]\]。
  ///
  /// 适用于「单个 JSON 文件」导出（便携）；OneDrive 同步请使用 [preparePlaylistCoverSidecarsForOneDrive]。
  Future<void> attachPlaylistCoverImagesToExportMap(Map<String, dynamic> map) async {
    map.remove(userPlaylistExportCoverAssetNamesKey);
    final rawList = map['playlists'];
    final ids = <String>{};
    if (rawList is List<dynamic>) {
      for (final e in rawList) {
        if (e is Map && e['id'] is String) {
          final id = (e['id'] as String).trim();
          if (id.isNotEmpty) ids.add(id);
        }
      }
    }

    final assets = <String, String>{};
    const maxBytes = 8 * 1024 * 1024;

    Future<void> tryEncodeCustomCover(String id, UserPlaylistCoverStyle? cs) async {
      if (cs == null || !cs.isCustomImage) return;
      try {
        final file = File(cs.imagePath);
        if (!await file.exists()) return;
        final len = await file.length();
        if (len <= 0 || len > maxBytes) return;
        final bytes = await file.readAsBytes();
        if (bytes.length > maxBytes) return;
        assets[id] = base64Encode(bytes);
      } catch (_) {}
    }

    for (final id in ids) {
      final pl = _playlistById(id);
      if (pl != null) {
        await tryEncodeCustomCover(id, pl.coverStyle);
      } else if (id == '__ym_export_library_all__') {
        await tryEncodeCustomCover(id, _homeLibraryCoverStyle);
      }
    }

    if (map.containsKey(userPlaylistExportHomeLibraryCoverStyleKey) &&
        _homeLibraryCoverStyle != null &&
        _homeLibraryCoverStyle!.isCustomImage) {
      await tryEncodeCustomCover(homeCarouselLibrarySentinel, _homeLibraryCoverStyle);
    }

    if (assets.isNotEmpty) {
      map[userPlaylistExportCoverImagesKey] = assets;
    }
  }

  /// OneDrive：去掉 Base64，写入 [userPlaylistExportCoverAssetNamesKey]，并返回待上传的本地文件。
  ///
  /// 调用前请先 [buildExportMap] / [buildExportMapForPlaylists]。上传顺序：先 JSON，再各侧车文件（同文件夹）。
  Future<Map<String, File>> preparePlaylistCoverSidecarsForOneDrive(
    Map<String, dynamic> map,
  ) async {
    map.remove(userPlaylistExportCoverImagesKey);
    final rawList = map['playlists'];
    final idsInExport = <String>{};
    if (rawList is List<dynamic>) {
      for (final e in rawList) {
        if (e is Map && e['id'] is String) {
          final id = (e['id'] as String).trim();
          if (id.isNotEmpty) idsInExport.add(id);
        }
      }
    }

    final hasHomeLibraryCoverDoc =
        map.containsKey(userPlaylistExportHomeLibraryCoverStyleKey) &&
            _homeLibraryCoverStyle != null &&
            _homeLibraryCoverStyle!.isCustomImage;

    if (idsInExport.isEmpty && !hasHomeLibraryCoverDoc) {
      return {};
    }

    map.remove(userPlaylistExportCoverAssetNamesKey);
    final manifest = <String, String>{};
    final files = <String, File>{};
    const maxBytes = 8 * 1024 * 1024;

    Future<void> tryAddSidecar(String id, UserPlaylistCoverStyle? cs) async {
      if (cs == null || !cs.isCustomImage) return;
      try {
        final file = File(cs.imagePath);
        if (!await file.exists()) return;
        final len = await file.length();
        if (len <= 0 || len > maxBytes) return;
        final ext = _playlistCoverSidecarExtension(cs.imagePath);
        final remoteName =
            'yeah_music_pl_cover_${_safePlaylistCoverFileId(id)}$ext';
        manifest[id] = remoteName;
        files[id] = file;
      } catch (_) {}
    }

    for (final id in idsInExport) {
      final pl = _playlistById(id);
      if (pl != null) {
        await tryAddSidecar(id, pl.coverStyle);
      } else if (id == '__ym_export_library_all__') {
        await tryAddSidecar(id, _homeLibraryCoverStyle);
      }
    }

    if (hasHomeLibraryCoverDoc) {
      await tryAddSidecar(homeCarouselLibrarySentinel, _homeLibraryCoverStyle);
    }

    if (manifest.isNotEmpty) {
      map[userPlaylistExportCoverAssetNamesKey] = manifest;
    }
    return files;
  }

  static const Set<String> _coverSidecarAllowedExt = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  };

  String _playlistCoverSidecarExtension(String imagePath) {
    final ext = p.extension(imagePath).toLowerCase();
    if (_coverSidecarAllowedExt.contains(ext)) return ext;
    return '.png';
  }

  Map<String, String> _playlistCoverImagesFromBackupDoc(Map<String, dynamic> doc) {
    final raw = doc[userPlaylistExportCoverImagesKey];
    if (raw is! Map) return {};
    final out = <String, String>{};
    for (final e in raw.entries) {
      final k = '${e.key}'.trim();
      final v = e.value;
      if (k.isEmpty || v is! String || v.trim().isEmpty) continue;
      out[k] = v.trim();
    }
    return out;
  }

  Future<UserPlaylist> _playlistWithoutBrokenCoverImage(UserPlaylist p) async {
    final cs = p.coverStyle;
    if (cs == null || !cs.isCustomImage) return p;
    try {
      if (await File(cs.imagePath).exists()) return p;
    } catch (_) {}
    return UserPlaylist(
      id: p.id,
      name: p.name,
      createdAt: p.createdAt,
      songPaths: p.songPaths,
      coverStyle: null,
    );
  }

  Future<List<UserPlaylist>> _hydrateImportedPlaylistCovers(
    List<UserPlaylist> playlists,
    Map<String, String> coverFileAbsoluteByPlaylistId,
    Map<String, String> assetsBase64,
  ) async {
    final out = <UserPlaylist>[];
    for (final p in playlists) {
      final abs = coverFileAbsoluteByPlaylistId[p.id]?.trim();
      if (abs != null && abs.isNotEmpty) {
        try {
          final src = File(abs);
          if (!await src.exists()) throw StateError('cover sidecar missing');
          final destPath = await _playlistCoverSupportPath(p.id);
          await src.copy(destPath);
          _evictCoverImageCache(destPath);
          out.add(
            UserPlaylist(
              id: p.id,
              name: p.name,
              createdAt: p.createdAt,
              songPaths: p.songPaths,
              coverStyle: UserPlaylistCoverStyle.customImage(destPath),
            ),
          );
        } catch (_) {
          out.add(await _playlistWithoutBrokenCoverImage(p));
        }
        continue;
      }

      final b64 = assetsBase64[p.id];
      if (b64 != null && b64.isNotEmpty) {
        try {
          final bytes = base64Decode(b64);
          if (bytes.isEmpty) throw StateError('empty cover bytes');
          final destPath = await _playlistCoverSupportPath(p.id);
          await File(destPath).writeAsBytes(bytes, flush: true);
          _evictCoverImageCache(destPath);
          out.add(
            UserPlaylist(
              id: p.id,
              name: p.name,
              createdAt: p.createdAt,
              songPaths: p.songPaths,
              coverStyle: UserPlaylistCoverStyle.customImage(destPath),
            ),
          );
        } catch (_) {
          out.add(await _playlistWithoutBrokenCoverImage(p));
        }
        continue;
      }
      out.add(await _playlistWithoutBrokenCoverImage(p));
    }
    return out;
  }

  /// 将全部曲库曲目导出为「单歌单」JSON（格式与普通导出一致，导入后可变为自建歌单）。
  Map<String, dynamic> buildExportMapForLibraryAllSongs({
    required String playlistName,
    required List<String> songPaths,
  }) {
    final pl = UserPlaylist(
      id: '__ym_export_library_all__',
      name: playlistName,
      createdAt: DateTime.now(),
      songPaths: songPaths,
      coverStyle: _homeLibraryCoverStyle,
    );
    return {
      'format': userPlaylistExportFormatId,
      'version': userPlaylistExportVersion,
      'app': AppProductInfo.exportMetadataBlock,
      'exportedAt': DateTime.now().toIso8601String(),
      'songIdentity':
          'Each entry in songPaths is a full file path; duplicates by title/artist are distinct files.',
      'playlists': [pl.toMap()],
      userPlaylistExportCarouselOrderKey: <String>[homeCarouselLibrarySentinel],
      if (_homeLibraryCoverStyle != null)
        userPlaylistExportHomeLibraryCoverStyleKey: _homeLibraryCoverStyle!.toMap(),
      if (_homeLibraryDisplayName != null && _homeLibraryDisplayName!.trim().isNotEmpty)
        userPlaylistExportHomeLibraryDisplayNameKey: _homeLibraryDisplayName!.trim(),
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
      userPlaylistExportCarouselOrderKey:
          _homeCarouselOrderForExport(playlistIdsLimit: want),
      if (_homeLibraryCoverStyle != null)
        userPlaylistExportHomeLibraryCoverStyleKey: _homeLibraryCoverStyle!.toMap(),
      if (_homeLibraryDisplayName != null && _homeLibraryDisplayName!.trim().isNotEmpty)
        userPlaylistExportHomeLibraryDisplayNameKey: _homeLibraryDisplayName!.trim(),
    };
  }

  Future<void> _applyHomeLibrarySlotFromImportDoc(
    Map<String, dynamic> doc, {
    required bool replaceAll,
    required Map<String, String> coverFilesAbsolute,
    required Map<String, String> coverAssetsBase64,
  }) async {
    final libKey = homeCarouselLibrarySentinel;

    Future<void> hydrateFromRaw(dynamic raw) async {
      UserPlaylistCoverStyle? st;
      if (raw is Map) {
        st = UserPlaylistCoverStyle.tryParse(Map<dynamic, dynamic>.from(raw));
      }
      if (st == null) {
        _deleteCoverImageFileIfAny(_homeLibraryCoverStyle);
        _homeLibraryCoverStyle = null;
        return;
      }
      final stub = UserPlaylist(
        id: libKey,
        name: '',
        createdAt: DateTime.now(),
        songPaths: const [],
        coverStyle: st,
      );
      final hyd = await _hydrateImportedPlaylistCovers(
        [stub],
        coverFilesAbsolute,
        coverAssetsBase64,
      );
      _homeLibraryCoverStyle = hyd.isEmpty ? null : hyd.first.coverStyle;
    }

    if (replaceAll) {
      if (doc.containsKey(userPlaylistExportHomeLibraryCoverStyleKey)) {
        await hydrateFromRaw(doc[userPlaylistExportHomeLibraryCoverStyleKey]);
      } else {
        _deleteCoverImageFileIfAny(_homeLibraryCoverStyle);
        _homeLibraryCoverStyle = null;
      }
      if (doc.containsKey(userPlaylistExportHomeLibraryDisplayNameKey)) {
        final n = doc[userPlaylistExportHomeLibraryDisplayNameKey];
        if (n is String) {
          final t = n.trim();
          _homeLibraryDisplayName = t.isEmpty ? null : t;
        } else {
          _homeLibraryDisplayName = null;
        }
      } else {
        _homeLibraryDisplayName = null;
      }
    } else {
      if (doc.containsKey(userPlaylistExportHomeLibraryCoverStyleKey)) {
        await hydrateFromRaw(doc[userPlaylistExportHomeLibraryCoverStyleKey]);
      }
      if (doc.containsKey(userPlaylistExportHomeLibraryDisplayNameKey)) {
        final n = doc[userPlaylistExportHomeLibraryDisplayNameKey];
        if (n is String && n.trim().isNotEmpty) {
          _homeLibraryDisplayName = n.trim();
        }
      }
    }
  }

  /// [playlistCoverFilesAbsolute]：从 OneDrive 等拉取到临时目录的封面文件 `歌单 id → 绝对路径`（优先于 Base64）。
  Future<void> applyImportedDocument(
    Map<String, dynamic> doc, {
    required bool replaceAll,
    Map<String, String>? playlistCoverFilesAbsolute,
  }) async {
    evictPlaylistDetailResolveCache();
    final rawList = doc['playlists'] as List<dynamic>;
    final coverAssets = _playlistCoverImagesFromBackupDoc(doc);
    final parsed = <UserPlaylist>[];
    for (final e in rawList) {
      if (e is! Map) continue;
      try {
        parsed.add(UserPlaylist.fromMap(Map<dynamic, dynamic>.from(e)));
      } catch (_) {}
    }
    final hydrated = await _hydrateImportedPlaylistCovers(
      parsed,
      playlistCoverFilesAbsolute ?? const {},
      coverAssets,
    );
    final imported = _coalesceImportedPlaylists(hydrated);

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
      final carouselRaw = doc[userPlaylistExportCarouselOrderKey];
      List<String>? carouselParsed;
      if (carouselRaw is List<dynamic>) {
        carouselParsed = carouselRaw
            .map((e) => '$e')
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
      _restoreHomeCarouselOrderFromBackup(carouselParsed);
      _syncPlaylistsOrderFromCarouselKeys(_homeCarouselOrderKeys);
      await _persistCarouselOrderKeys();
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
    await _applyHomeLibrarySlotFromImportDoc(
      doc,
      replaceAll: replaceAll,
      coverFilesAbsolute: playlistCoverFilesAbsolute ?? const {},
      coverAssetsBase64: coverAssets,
    );
    await _save();
    notifyListeners();
  }
}
