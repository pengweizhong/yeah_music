import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_auth.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/file_utils.dart';

/// OneDrive 登录、Graph 与本地缓存（应用支持目录下 `onedrive_cache`）。
class OneDriveController extends ChangeNotifier {
  OneDriveController({
    OneDriveAuth? auth,
    OneDriveGraphClient? graph,
  })  : _auth = auth ?? OneDriveAuth(),
        _graph = graph ?? OneDriveGraphClient();

  final OneDriveAuth _auth;
  final OneDriveGraphClient _graph;

  String _clientId = '';
  String? _musicRootItemId;
  bool _signedIn = false;
  String? _accountHint;

  List<OneDriveIndexFolder> _indexFolders = [];
  List<OneDriveCloudTrack> _cloudTracks = [];
  DateTime? _cloudIndexAt;
  bool _cloudIndexBuilding = false;
  String? _cloudIndexError;

  String get clientId => _clientId;
  String? get musicRootItemId => _musicRootItemId;
  bool get signedIn => _signedIn;
  String? get accountHint => _accountHint;
  bool get isLinuxUnsupported => Platform.isLinux;

  List<OneDriveIndexFolder> get indexFolders => List.unmodifiable(_indexFolders);

  List<OneDriveCloudTrack> get cloudTracks => List.unmodifiable(_cloudTracks);

  DateTime? get cloudIndexAt => _cloudIndexAt;

  bool get cloudIndexBuilding => _cloudIndexBuilding;

  String? get cloudIndexError => _cloudIndexError;

  String get effectiveClientId {
    if (_clientId.isNotEmpty) return _clientId;
    return OneDriveConfig.defaultClientIdFromEnv;
  }

  Future<void> loadFromStorage() async {
    _clientId = (await SettingsService.loadOneDriveClientId()) ?? '';
    _musicRootItemId = await SettingsService.loadOneDriveMusicRootId();
    await _loadCloudIndexFromDisk();
    if (effectiveClientId.isEmpty) {
      _signedIn = false;
      notifyListeners();
      return;
    }
    final t = await _auth.getValidAccessToken(effectiveClientId);
    _signedIn = t != null;
    if (_signedIn) {
      _accountHint = 'Microsoft';
    }
    notifyListeners();
  }

  Future<void> _loadCloudIndexFromDisk() async {
    final foldersRaw = await SettingsService.loadOneDriveIndexFolders();
    _indexFolders =
        foldersRaw.map(OneDriveIndexFolder.fromMap).where((e) => e.itemId.isNotEmpty).toList();
    final tracksRaw = await SettingsService.loadOneDriveIndexTracks();
    _cloudTracks =
        tracksRaw.map(OneDriveCloudTrack.fromMap).where((e) => e.itemId.isNotEmpty).toList();
    _cloudTracks.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    _cloudIndexAt = await SettingsService.loadOneDriveIndexCompletedAt();
  }

  Future<void> _persistCloudIndex() async {
    await SettingsService.saveOneDriveIndexFolders(
      _indexFolders.map((e) => e.toMap()).toList(),
    );
    await SettingsService.saveOneDriveIndexTracks(
      _cloudTracks.map((e) => e.toMap()).toList(),
    );
    await SettingsService.saveOneDriveIndexCompletedAt(_cloudIndexAt);
  }

  /// 将 [itemId] 加入索引目录根列表（不会去重扫描，需调用 [rebuildCloudIndex]）。
  Future<void> addIndexFolder(String itemId, String label) async {
    final id = itemId.trim();
    if (id.isEmpty) return;
    if (_indexFolders.any((e) => e.itemId == id)) return;
    final raw = label.trim();
    _indexFolders.add(OneDriveIndexFolder(itemId: id, label: raw.isEmpty ? 'Folder' : raw));
    await SettingsService.saveOneDriveIndexFolders(
      _indexFolders.map((e) => e.toMap()).toList(),
    );
    notifyListeners();
  }

  Future<void> removeIndexFolder(String itemId) async {
    _indexFolders.removeWhere((e) => e.itemId == itemId);
    await SettingsService.saveOneDriveIndexFolders(
      _indexFolders.map((e) => e.toMap()).toList(),
    );
    notifyListeners();
    if (_indexFolders.isEmpty) {
      _cloudTracks = [];
      _cloudIndexAt = null;
      await _persistCloudIndex();
      notifyListeners();
      return;
    }
    await rebuildCloudIndex();
  }

  /// 递归扫描 [indexFolders] 下所有音频，写入 [cloudTracks] 并持久化。
  Future<void> rebuildCloudIndex() async {
    if (_indexFolders.isEmpty) {
      _cloudTracks = [];
      _cloudIndexAt = null;
      _cloudIndexError = null;
      await _persistCloudIndex();
      notifyListeners();
      return;
    }
    final token = await getAccessToken();
    if (token == null) {
      throw StateError('not signed in');
    }
    _cloudIndexBuilding = true;
    _cloudIndexError = null;
    notifyListeners();
    try {
      final dedupe = <String>{};
      final collected = <OneDriveCloudTrack>[];
      for (final root in _indexFolders) {
        await _crawlCollectAudio(
          accessToken: token,
          folderItemId: root.itemId,
          rootLabel: root.label.isEmpty ? 'Music' : root.label,
          pathSegments: const [],
          dedupe: dedupe,
          out: collected,
        );
      }
      collected.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      _cloudTracks = collected;
      _cloudIndexAt = DateTime.now();
      await _persistCloudIndex();
    } catch (e) {
      _cloudIndexError = '$e';
    } finally {
      _cloudIndexBuilding = false;
      notifyListeners();
    }
  }

  Future<void> _crawlCollectAudio({
    required String accessToken,
    required String folderItemId,
    required String rootLabel,
    required List<String> pathSegments,
    required Set<String> dedupe,
    required List<OneDriveCloudTrack> out,
  }) async {
    final children = await _graph.listChildren(
      accessToken: accessToken,
      parentId: folderItemId,
    );
    for (final child in children) {
      if (child.isFolder) {
        await _crawlCollectAudio(
          accessToken: accessToken,
          folderItemId: child.id,
          rootLabel: rootLabel,
          pathSegments: [...pathSegments, child.name],
          dedupe: dedupe,
          out: out,
        );
      } else if (OneDriveConfig.isAudioFileName(child.name)) {
        if (dedupe.add(child.id)) {
          final subs = [...pathSegments, child.name];
          final display = [rootLabel, ...subs].join('/');
          out.add(
            OneDriveCloudTrack(
              itemId: child.id,
              fileName: child.name,
              displayPath: display,
            ),
          );
        }
      }
    }
  }

  /// 由索引条目还原为可下载的 Graph 占位项。
  OneDriveGraphItem graphItemForCloudTrack(OneDriveCloudTrack t) {
    return OneDriveGraphItem(
      id: t.itemId,
      name: t.fileName,
      isFolder: false,
      downloadUrl: null,
    );
  }

  /// 点播云端曲目：按需下载，`songForPlayableItem` 内已按 item id 缓存。
  Future<Song> songForCloudTrack(OneDriveCloudTrack t) {
    return songForPlayableItem(graphItemForCloudTrack(t));
  }

  Future<List<Song>> buildQueueForCloudTracks(List<OneDriveCloudTrack> slice) async {
    final out = <Song>[];
    for (final t in slice) {
      out.add(await songForCloudTrack(t));
    }
    return out;
  }

  Future<void> setMusicRootItemId(String? id) async {
    _musicRootItemId = id;
    await SettingsService.saveOneDriveMusicRootId(id);
    notifyListeners();
  }

  /// 将 [clientId] 一并写入设置（可来自输入框或编译默认）。
  Future<void> saveClientIdText(String text) async {
    final v = text.trim();
    _clientId = v;
    await SettingsService.saveOneDriveClientId(v.isEmpty ? null : v);
    notifyListeners();
  }

  Future<String?> getAccessToken() {
    if (effectiveClientId.isEmpty) return Future.value(null);
    return _auth.getValidAccessToken(effectiveClientId);
  }

  Future<bool> signIn() async {
    if (isLinuxUnsupported) {
      return false;
    }
    if (effectiveClientId.isEmpty) {
      return false;
    }
    try {
      final res = await _auth.signIn(effectiveClientId);
      if (res == null) {
        return false;
      }
      _signedIn = true;
      _accountHint = 'Microsoft';
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _signedIn = false;
    _accountHint = null;
    notifyListeners();
  }

  Future<List<OneDriveGraphItem>> listChildren(String? parentItemId) async {
    final t = await getAccessToken();
    if (t == null) {
      throw StateError('not signed in');
    }
    if (parentItemId == null && _musicRootItemId != null) {
      return _graph.listChildren(
        accessToken: t,
        parentId: _musicRootItemId,
      );
    }
    return _graph.listChildren(accessToken: t, parentId: parentItemId);
  }

  /// 将云端文件拉取到本地并生成 [Song]；已存在同 id 缓存则跳过网络。
  Future<Song> songForPlayableItem(OneDriveGraphItem item) async {
    if (item.isFolder) {
      throw StateError('not a file');
    }
    if (!OneDriveConfig.isAudioFileName(item.name)) {
      throw StateError('not audio');
    }
    final t = await getAccessToken();
    if (t == null) {
      throw StateError('not signed in');
    }
    final OneDriveGraphItem use = item.downloadUrl == null
        ? (await _graph.getItem(accessToken: t, itemId: item.id)) ?? item
        : item;
    final target = await _cacheFilePath(item.id, item.name);
    if (!await target.exists() || await target.length() == 0) {
      await _graph.downloadToFile(
        downloadUrl: use.downloadUrl,
        itemId: item.id,
        accessToken: t,
        file: target,
      );
    }
    final s = Song(target.path);
    await FileUtils.loadSongMeta(s);
    return s;
  }

  Future<File> _cacheFilePath(String itemId, String filename) async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'onedrive_cache'));
    await root.create(recursive: true);
    final safe = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return File(p.join(root.path, '${itemId}_$safe'));
  }

  /// 为当前目录中所有音频建播放队列；已缓存的跳过网络，其余串行下载。
  Future<List<Song>> buildQueueForAudioItems(List<OneDriveGraphItem> items) async {
    final files = items
        .where(
          (e) => !e.isFolder && OneDriveConfig.isAudioFileName(e.name),
        )
        .toList();
    final out = <Song>[];
    for (final f in files) {
      out.add(await songForPlayableItem(f));
    }
    return out;
  }

  @override
  void dispose() {
    _graph.close();
    super.dispose();
  }
}
