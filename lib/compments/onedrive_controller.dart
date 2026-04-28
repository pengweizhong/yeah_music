import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_auth.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart'
    show OneDriveGraphClient, OneDriveGraphItem;
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/file_utils.dart';

/// OneDrive 登录、Graph 与本地缓存。
///
/// 点播时落地路径：若设置里指定了「本地下载目录」且该路径存在且为文件夹，则下载到该目录；
/// 否则（未指定、路径不存在或为文件）使用应用支持目录下的 `onedrive_cache`。
class OneDriveController extends ChangeNotifier {
  OneDriveController({
    OneDriveAuth? auth,
    OneDriveGraphClient? graph,
  })  : _auth = auth ?? OneDriveAuth(),
        _graph = graph ?? OneDriveGraphClient();

  final OneDriveAuth _auth;
  final OneDriveGraphClient _graph;

  /// 旧版在设置中保存的 Client ID；仅当 [OneDriveConfig.applicationClientId] 为空时作为回退。
  String _legacyClientId = '';
  String? _musicRootItemId;
  String? _cloudAppDataFolderId;
  String _cloudAppDataFolderLabel = '';
  String? _localDownloadDir;
  bool _signedIn = false;
  String? _accountHint;

  List<OneDriveIndexFolder> _indexFolders = [];
  List<OneDriveCloudTrack> _cloudTracks = [];
  DateTime? _cloudIndexAt;
  bool _cloudIndexBuilding = false;
  String? _cloudIndexError;

  OneDriveSyncSettings _syncSettings = OneDriveSyncSettings.defaults;

  String? get musicRootItemId => _musicRootItemId;

  /// 云端「应用数据」目录（设置/歌单备份等预留），Graph driveItem id。
  String? get cloudAppDataFolderId => _cloudAppDataFolderId;

  String get cloudAppDataFolderLabel => _cloudAppDataFolderLabel;

  /// 本地下载目录（预留：整曲下载到设备）。
  String? get localDownloadDir => _localDownloadDir;
  bool get signedIn => _signedIn;
  String? get accountHint => _accountHint;
  bool get isLinuxUnsupported => Platform.isLinux;

  List<OneDriveIndexFolder> get indexFolders => List.unmodifiable(_indexFolders);

  List<OneDriveCloudTrack> get cloudTracks => List.unmodifiable(_cloudTracks);

  DateTime? get cloudIndexAt => _cloudIndexAt;

  bool get cloudIndexBuilding => _cloudIndexBuilding;

  String? get cloudIndexError => _cloudIndexError;

  OneDriveSyncSettings get syncSettings => _syncSettings;

  String get effectiveClientId {
    final builtIn = OneDriveConfig.applicationClientId;
    if (builtIn.isNotEmpty) return builtIn;
    if (_legacyClientId.isNotEmpty) return _legacyClientId;
    return '';
  }

  Future<void> loadFromStorage() async {
    _legacyClientId = (await SettingsService.loadOneDriveClientId()) ?? '';
    _musicRootItemId = await SettingsService.loadOneDriveMusicRootId();
    final appFolder = await SettingsService.loadOneDriveCloudAppFolder();
    _cloudAppDataFolderId = appFolder.$1;
    _cloudAppDataFolderLabel = appFolder.$2;
    _localDownloadDir = await SettingsService.loadOneDriveLocalDownloadDir();
    _syncSettings = await SettingsService.loadOneDriveSyncSettings();
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

  /// 若点播缓存文件已存在且非空则装载元数据并返回，否则返回 null（不发起网络）。
  Future<Song?> songFromLocalCacheIfExists(OneDriveGraphItem item) async {
    if (item.isFolder) return null;
    if (!OneDriveConfig.isAudioFileName(item.name)) return null;
    final target = await _localFileForPlayback(item.id, item.name);
    if (!await target.exists()) return null;
    final len = await target.length();
    if (len <= 0) return null;
    final s = Song(target.path);
    await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
    return s;
  }

  /// 点播云端曲目：按需下载，`songForPlayableItem` 内已按 item id 缓存。
  Future<Song> songForCloudTrack(OneDriveCloudTrack t) {
    return songForPlayableItem(graphItemForCloudTrack(t));
  }

  /// 点播：支持进度与暂停/取消（批量队列）；已缓存则跳过网络。
  Future<Song> songForPlayableItemWithProgress(
    OneDriveGraphItem item, {
    required void Function(int received, int? total) onProgress,
    required Future<void> Function() waitWhilePaused,
    required bool Function() isCancelled,
  }) async {
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
    final target = await _localFileForPlayback(item.id, item.name);
    if (await target.exists()) {
      final len = await target.length();
      if (len > 0) {
        onProgress(len, len);
        final s = Song(target.path);
        await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
        return s;
      }
    }
    await _graph.downloadToFileStreaming(
      downloadUrl: use.downloadUrl,
      itemId: item.id,
      accessToken: t,
      file: target,
      onProgress: onProgress,
      waitWhilePaused: waitWhilePaused,
      isCancelled: isCancelled,
    );
    final s = Song(target.path);
    await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
    return s;
  }

  Future<Song> songForCloudTrackWithProgress(
    OneDriveCloudTrack t, {
    required void Function(int received, int? total) onProgress,
    required Future<void> Function() waitWhilePaused,
    required bool Function() isCancelled,
  }) {
    return songForPlayableItemWithProgress(
      graphItemForCloudTrack(t),
      onProgress: onProgress,
      waitWhilePaused: waitWhilePaused,
      isCancelled: isCancelled,
    );
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

  Future<void> setCloudAppDataFolder(String? itemId, {String label = ''}) async {
    _cloudAppDataFolderId = itemId;
    _cloudAppDataFolderLabel = label;
    await SettingsService.saveOneDriveCloudAppFolder(itemId, label);
    notifyListeners();
  }

  Future<void> setLocalDownloadDir(String? path) async {
    final v = path?.trim();
    _localDownloadDir = (v == null || v.isEmpty) ? null : v;
    await SettingsService.saveOneDriveLocalDownloadDir(_localDownloadDir);
    notifyListeners();
  }

  Future<void> setSyncSettings(OneDriveSyncSettings value) async {
    _syncSettings = value;
    await SettingsService.saveOneDriveSyncSettings(_syncSettings);
    notifyListeners();
  }

  /// 立即同步占位：后续在此调用实际上传/下载。
  Future<void> performSyncNow() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
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
    final target = await _localFileForPlayback(item.id, item.name);
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

  /// 默认：`ApplicationSupportDirectory/onedrive_cache`
  Future<Directory> _defaultPlaybackStorageDirectory() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'onedrive_cache'));
    await root.create(recursive: true);
    return root;
  }

  /// 解析点播落地目录：有效自定义目录存在则用自定义；否则用 [_defaultPlaybackStorageDirectory]。
  Future<Directory> _playbackStorageDirectory() async {
    final defaultRoot = await _defaultPlaybackStorageDirectory();
    final configured = _localDownloadDir?.trim();
    if (configured == null || configured.isEmpty) {
      return defaultRoot;
    }
    final userDir = Directory(p.normalize(configured));
    if (!await userDir.exists()) {
      return defaultRoot;
    }
    try {
      final stat = await userDir.stat();
      if (stat.type != FileSystemEntityType.directory) {
        return defaultRoot;
      }
    } catch (_) {
      return defaultRoot;
    }
    return userDir;
  }

  Future<File> _localFileForPlayback(String itemId, String filename) async {
    final root = await _playbackStorageDirectory();
    await root.create(recursive: true);
    final safe = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return File(p.join(root.path, '${itemId}_$safe'));
  }

  /// 扫描点播落地目录（默认 `onedrive_cache` + 互不重叠的用户目录）：列出其中的音频文件并装载元数据。
  ///
  /// 不要求当前已登录 OneDrive；仅读本地磁盘。
  Future<List<Song>> loadLocallyCachedOneDriveSongs() async {
    final roots = await _onedriveLocalPlaybackRoots();
    final seenPaths = <String>{};
    final files = <File>[];
    for (final root in roots) {
      await root.create(recursive: true);
      if (!await root.exists()) continue;
      await for (final entity in root.list(recursive: false, followLinks: false)) {
        if (entity is! File) continue;
        if (!OneDriveConfig.isAudioFileName(entity.path)) continue;
        final norm = p.normalize(entity.path);
        if (seenPaths.add(norm)) {
          files.add(entity);
        }
      }
    }
    files.sort(
      (a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()),
    );
    final songs = <Song>[];
    for (final f in files) {
      final s = Song(f.path);
      await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
      songs.add(s);
    }
    return songs;
  }

  /// 默认缓存目录以及（若配置且存在）用户下载目录；路径相同时只保留一处。
  Future<List<Directory>> _onedriveLocalPlaybackRoots() async {
    final support = await getApplicationSupportDirectory();
    final def = Directory(p.join(support.path, 'onedrive_cache'));
    final roots = <Directory>[def];
    final configured = _localDownloadDir?.trim();
    if (configured != null && configured.isNotEmpty) {
      final user = Directory(p.normalize(configured));
      if (await user.exists()) {
        try {
          final st = await user.stat();
          if (st.type == FileSystemEntityType.directory) {
            final defPath = p.normalize(def.path);
            final userPath = p.normalize(user.path);
            if (userPath != defPath) {
              roots.add(user);
            }
          }
        } catch (_) {}
      }
    }
    return roots;
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
