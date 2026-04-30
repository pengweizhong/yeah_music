import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart'
    show
        UserPlaylistProvider,
        parseUserPlaylistExportJson,
        playlistCoverAssetNamesFromDoc;
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/onedrive_cloud_backup_snapshot.dart';
import 'package:yeah_music/models/onedrive_restore_selection.dart';
import 'package:yeah_music/models/onedrive_sync_constants.dart';
import 'package:yeah_music/models/onedrive_sync_settings.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_auth.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart'
    show OneDriveGraphClient, OneDriveGraphItem;
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/onedrive_backup_stamp.dart';
import 'package:yeah_music/utils/onedrive_sync_device.dart';

class _PlaylistCoverDownloadScratch {
  _PlaylistCoverDownloadScratch({
    required this.pathsByPlaylistId,
    required this.directory,
  });

  final Map<String, String> pathsByPlaylistId;
  final Directory directory;
}

/// OneDrive 登录、Graph 与本地缓存。
///
/// 点播时落地路径：若设置里指定了「本地下载目录」且该路径存在且为文件夹，则下载到该目录；
/// 否则（未指定、路径不存在或为文件）使用应用支持目录下的 `onedrive_cache`。
class OneDriveController extends ChangeNotifier {
  OneDriveController({OneDriveAuth? auth, OneDriveGraphClient? graph})
    : _auth = auth ?? OneDriveAuth(),
      _graph = graph ?? OneDriveGraphClient();

  final OneDriveAuth _auth;
  final OneDriveGraphClient _graph;

  /// 旧版在设置中保存的 Client ID；仅当 [OneDriveConfig.applicationClientId] 为空时作为回退。
  String _legacyClientId = '';
  String? _cloudAppDataFolderId;
  String _cloudAppDataFolderLabel = '';
  String? _musicUploadFolderId;
  String _musicUploadFolderLabel = '';
  String? _localDownloadDir;
  bool _signedIn = false;
  String? _accountHint;

  /// 每进程内去重，配合 [SettingsService.appendOneDriveDownloadScanRootIfNew] 持久化点播目录。
  final Set<String> _playbackScanRootsTouched = {};

  List<OneDriveIndexFolder> _indexFolders = [];
  List<OneDriveCloudTrack> _cloudTracks = [];
  DateTime? _cloudIndexAt;
  bool _cloudIndexBuilding = false;
  String? _cloudIndexError;

  OneDriveSyncSettings _syncSettings = OneDriveSyncSettings.defaults;

  /// 「立即同步」上传进行中；与 [restoreCloudBackup] 互斥，避免并行写云端/本地 Hive。
  bool _immediateSyncBusy = false;

  /// 云端恢复（下载并应用）进行中。
  bool _immediateRestoreBusy = false;

  bool get isImmediateSyncBusy => _immediateSyncBusy;

  bool get isImmediateRestoreBusy => _immediateRestoreBusy;

  /// 云端「应用数据」目录（设置/歌单备份等预留），Graph driveItem id。
  String? get cloudAppDataFolderId => _cloudAppDataFolderId;

  String get cloudAppDataFolderLabel => _cloudAppDataFolderLabel;

  /// 本地上传音乐的默认目标文件夹（Graph driveItem id）；未设置时上传可退回 [cloudAppDataFolderId]。
  String? get musicUploadFolderId => _musicUploadFolderId;

  String get musicUploadFolderLabel => _musicUploadFolderLabel;

  /// 本地下载目录（预留：整曲下载到设备）。
  String? get localDownloadDir => _localDownloadDir;
  bool get signedIn => _signedIn;
  String? get accountHint => _accountHint;
  bool get isLinuxUnsupported => Platform.isLinux;

  List<OneDriveIndexFolder> get indexFolders =>
      List.unmodifiable(_indexFolders);

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
    await SettingsService.migrateRemoveOneDriveMusicRootSetting();
    final appFolder = await SettingsService.loadOneDriveCloudAppFolder();
    _cloudAppDataFolderId = appFolder.$1;
    _cloudAppDataFolderLabel = appFolder.$2;
    final musicUp = await SettingsService.loadOneDriveMusicUploadFolder();
    _musicUploadFolderId = musicUp.$1;
    _musicUploadFolderLabel = musicUp.$2;
    _localDownloadDir = await SettingsService.loadOneDriveLocalDownloadDir();
    await SettingsService.ensureOneDriveDownloadScanRootsIncludesActiveDir();
    _syncSettings = await SettingsService.loadOneDriveSyncSettings();
    await _loadCloudIndexFromDisk();
    if (effectiveClientId.isEmpty) {
      _signedIn = false;
      notifyListeners();
      return;
    }
    var t = await _auth.getValidAccessToken(effectiveClientId);
    if (t == null && Platform.isMacOS) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      t = await _auth.getValidAccessToken(effectiveClientId);
    }
    _signedIn = t != null;
    if (_signedIn) {
      _accountHint = 'Microsoft';
    }
    notifyListeners();
  }

  Future<void> _loadCloudIndexFromDisk() async {
    final foldersRaw = await SettingsService.loadOneDriveIndexFolders();
    _indexFolders = foldersRaw
        .map(OneDriveIndexFolder.fromMap)
        .where((e) => e.itemId.isNotEmpty)
        .toList();
    final tracksRaw = await SettingsService.loadOneDriveIndexTracks();
    _cloudTracks = tracksRaw
        .map(OneDriveCloudTrack.fromMap)
        .where((e) => e.itemId.isNotEmpty)
        .toList();
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
    _indexFolders.add(
      OneDriveIndexFolder(itemId: id, label: raw.isEmpty ? 'Folder' : raw),
    );
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

  Future<void> _touchPlaybackRootForScanHistory() async {
    try {
      final dir = await _playbackStorageDirectory();
      final norm = p.normalize(dir.path);
      if (_playbackScanRootsTouched.add(norm)) {
        await SettingsService.appendOneDriveDownloadScanRootIfNew(norm);
      }
    } catch (_) {}
  }

  /// 若点播缓存文件已存在且非空则装载元数据并返回，否则返回 null（不发起网络）。
  Future<Song?> songFromLocalCacheIfExists(OneDriveGraphItem item) async {
    if (item.isFolder) return null;
    if (!OneDriveConfig.isAudioFileName(item.name)) return null;
    await _touchPlaybackRootForScanHistory();
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
    await _touchPlaybackRootForScanHistory();
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

  Future<List<Song>> buildQueueForCloudTracks(
    List<OneDriveCloudTrack> slice,
  ) async {
    final out = <Song>[];
    for (final t in slice) {
      out.add(await songForCloudTrack(t));
    }
    return out;
  }

  /// 上传目标未手动配置到 [musicUploadFolderId] / [cloudAppDataFolderId] 时，
  /// 在云盘「我的文件」根下查找或新建 [defaultMusicUploadFolderName]，并设为 [musicUploadFolderId]。
  static const String defaultMusicUploadFolderName = 'Yeah Music Uploads';

  Future<String?> ensureDefaultMusicUploadFolder() async {
    final existing = (_musicUploadFolderId ?? _cloudAppDataFolderId)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final token = await getAccessToken();
    if (token == null) {
      return null;
    }
    try {
      var folder = await _graph.findChildFolderNamed(
        accessToken: token,
        parentId: null,
        folderName: defaultMusicUploadFolderName,
      );
      folder ??= await _graph.createFolderChild(
        accessToken: token,
        parentId: null,
        folderName: defaultMusicUploadFolderName,
      );
      if (folder == null) {
        return null;
      }
      await setMusicUploadFolder(folder.id, label: folder.name);
      return folder.id.trim();
    } catch (e, st) {
      assert(() {
        debugPrint('ensureDefaultMusicUploadFolder: $e\n$st');
        return true;
      }());
      return null;
    }
  }

  Future<void> setCloudAppDataFolder(
    String? itemId, {
    String label = '',
  }) async {
    _cloudAppDataFolderId = itemId;
    _cloudAppDataFolderLabel = label;
    await SettingsService.saveOneDriveCloudAppFolder(itemId, label);
    notifyListeners();
  }

  Future<void> setMusicUploadFolder(String? itemId, {String label = ''}) async {
    _musicUploadFolderId = itemId;
    _musicUploadFolderLabel = label;
    await SettingsService.saveOneDriveMusicUploadFolder(itemId, label);
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

  Future<String?> _ensureFolderNamed({
    required String token,
    required String parentId,
    required String folderName,
  }) async {
    final found = await _graph.findChildFolderNamed(
      accessToken: token,
      parentId: parentId,
      folderName: folderName,
    );
    if (found != null) return found.id.trim();
    final created = await _graph.createFolderChild(
      accessToken: token,
      parentId: parentId,
      folderName: folderName,
    );
    return created?.id.trim();
  }

  Future<void> _uploadUtf8JsonToFolder({
    required String token,
    required String folderItemId,
    required String remoteFileName,
    required String utf8Payload,
  }) async {
    final tmpRoot = await getTemporaryDirectory();
    final safeScratch = File(
      p.join(
        tmpRoot.path,
        'yeah_sync_${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    );
    await safeScratch.writeAsString(utf8Payload, flush: true);
    try {
      await uploadLocalFileWithProgress(
        parentFolderItemId: folderItemId,
        remoteFileName: remoteFileName,
        file: safeScratch,
        onProgress: (int sent, int? total) {},
        waitWhilePaused: () async {},
        isCancelled: () => false,
      );
    } finally {
      try {
        if (await safeScratch.exists()) {
          await safeScratch.delete();
        }
      } catch (_) {}
    }
  }

  /// 将勾选的配置切片上传到 `{同步根}/{设备}/{YYYYMMDDTHHmmss}/`。
  Future<void> performSyncNow({
    required UserPlaylistProvider userPlaylistProvider,
  }) async {
    final sync = _syncSettings;
    if (!sync.hasConfigurableSlices) {
      return;
    }
    if (_immediateSyncBusy || _immediateRestoreBusy) {
      throw StateError('immediate cloud op busy');
    }
    if (effectiveClientId.isEmpty || !_signedIn) {
      throw StateError('not signed in');
    }
    final token = await getAccessToken();
    if (token == null) {
      throw StateError('not signed in');
    }
    final parent = _cloudAppDataFolderId?.trim();
    if (parent == null || parent.isEmpty) {
      throw StateError('cloud app folder unset');
    }
    _immediateSyncBusy = true;
    notifyListeners();
    try {
      await userPlaylistProvider.init();

      const encoder = JsonEncoder.withIndent('  ');
      final sessionStamp = formatOneDriveSyncSessionFolderStamp(DateTime.now());

      final uploadIntoSession =
          sync.syncHomeGreeting ||
              sync.syncQuickEntry ||
              sync.syncPlaybackListsAndStats ||
              sync.syncLyricsUi ||
              sync.syncThemeAppearance ||
              sync.syncUserPlaylists;

      if (uploadIntoSession) {
        final deviceRaw =
            sanitizeOneDriveSyncFolderSegment(await resolveOneDriveSyncDeviceFolderLabel());
        final deviceFolderId =
            await _ensureFolderNamed(token: token, parentId: parent, folderName: deviceRaw);
        if (deviceFolderId == null || deviceFolderId.isEmpty) {
          throw StateError('onedrive folder create failed');
        }
        final leafId = await _ensureFolderNamed(
          token: token,
          parentId: deviceFolderId,
          folderName: sessionStamp,
        );
        if (leafId == null || leafId.isEmpty) {
          throw StateError('onedrive folder create failed');
        }

        if (sync.syncUserPlaylists) {
          final map = userPlaylistProvider.buildExportMap();
          final sidecars =
              await userPlaylistProvider.preparePlaylistCoverSidecarsForOneDrive(
                map,
              );
          final manifest = playlistCoverAssetNamesFromDoc(map);
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.playlistsBlobFileName,
            utf8Payload: encoder.convert(map),
          );
          for (final e in sidecars.entries) {
            final remoteName = manifest[e.key]?.trim();
            if (remoteName == null || remoteName.isEmpty) continue;
            await uploadLocalFileWithProgress(
              parentFolderItemId: leafId,
              remoteFileName: remoteName,
              file: e.value,
              onProgress: (int sent, int? total) {},
              waitWhilePaused: () async {},
              isCancelled: () => false,
            );
          }
        }
        if (sync.syncHomeGreeting) {
          final m = await SettingsService.buildCloudBackupHiveSubsetMap(
            SettingsService.hiveKeysCloudSliceHomeGreeting(),
          );
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.sliceHomeGreetingFileName,
            utf8Payload: encoder.convert(m),
          );
        }
        if (sync.syncQuickEntry) {
          final map = await SettingsService.buildCloudBackupQuickEntrySliceMap();
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.sliceQuickEntryFileName,
            utf8Payload: encoder.convert(map),
          );
        }
        if (sync.syncPlaybackListsAndStats) {
          final m = await SettingsService.buildCloudBackupHiveSubsetMap(
            SettingsService.hiveKeysCloudSlicePlaybackLists(),
          );
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.slicePlaybackListsFileName,
            utf8Payload: encoder.convert(m),
          );
        }
        if (sync.syncLyricsUi) {
          final m = await SettingsService.buildCloudBackupLyricsUiSliceMap();
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.sliceLyricsUiFileName,
            utf8Payload: encoder.convert(m),
          );
        }
        if (sync.syncThemeAppearance) {
          final m = await SettingsService.buildCloudBackupThemeSliceMap();
          final bgFile =
              await SettingsService.prepareThemeBackgroundSidecarForOneDrive(m);
          final themeBgRemote =
              SettingsService.themeBackgroundAssetNameFromDoc(m);
          await _uploadUtf8JsonToFolder(
            token: token,
            folderItemId: leafId,
            remoteFileName: OneDriveSyncConstants.sliceThemeFileName,
            utf8Payload: encoder.convert(m),
          );
          if (bgFile != null &&
              themeBgRemote != null &&
              themeBgRemote.isNotEmpty) {
            await uploadLocalFileWithProgress(
              parentFolderItemId: leafId,
              remoteFileName: themeBgRemote,
              file: bgFile,
              onProgress: (int sent, int? total) {},
              waitWhilePaused: () async {},
              isCancelled: () => false,
            );
          }
        }
      }

      await SettingsService.saveOneDriveLastConfigSyncAt(DateTime.now());
      notifyListeners();
    } finally {
      _immediateSyncBusy = false;
      notifyListeners();
    }
  }

  static final RegExp _cloudBackupPlaylistFileName = RegExp(
    r'^yeah_music_playlists_(.+)\.json$',
  );
  static final RegExp _cloudBackupSettingsFileName = RegExp(
    r'^yeah_music_settings_(.+)\.json$',
  );

  /// 列举云端备份：旧版平铺、`设备型号/时间戳/` 会话目录。
  Future<List<OneDriveCloudBackupSnapshot>> listCloudBackupSnapshots() async {
    final folder = _cloudAppDataFolderId?.trim();
    if (folder == null || folder.isEmpty) {
      throw StateError('cloud app folder unset');
    }
    final token = await getAccessToken();
    if (token == null) {
      throw StateError('not signed in');
    }
    final children = await _graph.listChildren(
      accessToken: token,
      parentId: folder,
    );

    final out = <OneDriveCloudBackupSnapshot>[];

    final playlistIdsByStamp = <String, String>{};
    final settingsIdsByStamp = <String, String>{};

    for (final it in children) {
      if (it.isFolder) {
        continue;
      }
      final mpl = _cloudBackupPlaylistFileName.firstMatch(it.name);
      if (mpl != null) {
        playlistIdsByStamp[mpl.group(1)!] = it.id;
        continue;
      }
      final mst = _cloudBackupSettingsFileName.firstMatch(it.name);
      if (mst != null) {
        settingsIdsByStamp[mst.group(1)!] = it.id;
      }
    }

    final legacyStamps = <String>{
      ...playlistIdsByStamp.keys,
      ...settingsIdsByStamp.keys,
    };
    for (final stamp in legacyStamps) {
      out.add(
        OneDriveCloudBackupSnapshot(
          kind: OneDriveCloudBackupSnapshotKind.legacyFlat,
          sortStamp: stamp,
          playlistsItemId: playlistIdsByStamp[stamp],
          settingsItemId: settingsIdsByStamp[stamp],
        ),
      );
    }

    for (final deviceNode in children) {
      if (!deviceNode.isFolder) continue;
      if (deviceNode.name == OneDriveSyncConstants.legacyCrossDeviceFolderName) {
        continue;
      }
      final tsKids = await _graph.listChildren(
        accessToken: token,
        parentId: deviceNode.id,
      );
      for (final ts in tsKids) {
        if (!ts.isFolder) continue;
        if (!OneDriveSyncConstants.isSessionFolderName(ts.name)) continue;
        final files = await _graph.listChildren(
          accessToken: token,
          parentId: ts.id,
        );
        final blobs = <String, String>{};
        for (final fi in files) {
          if (fi.isFolder) continue;
          if (OneDriveSyncConstants.sessionBlobFileNames.contains(fi.name)) {
            blobs[fi.name] = fi.id;
          }
        }
        if (blobs.isEmpty) continue;
        out.add(
          OneDriveCloudBackupSnapshot(
            kind: OneDriveCloudBackupSnapshotKind.deviceSession,
            sortStamp: ts.name,
            deviceFolderLabel: deviceNode.name,
            leafFolderItemId: ts.id,
            blobItemIds: blobs,
          ),
        );
      }
    }

    out.sort();
    return out;
  }

  String? _playlistBackupItemId(OneDriveCloudBackupSnapshot snapshot) {
    final blob =
        snapshot.blobItemIds[OneDriveSyncConstants.playlistsBlobFileName]?.trim();
    if (blob != null && blob.isNotEmpty) return blob;
    return snapshot.playlistsItemId?.trim();
  }

  Future<void> _applySettingsBlob({
    required String token,
    required String itemId,
  }) async {
    final raw = await _graph.downloadDriveItemUtf8(
      accessToken: token,
      itemId: itemId,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('settings backup root must be object');
    }
    await SettingsService.applyCloudBackupMap(decoded);
  }

  Future<void> _applyThemeSliceBlob({
    required String token,
    required String itemId,
  }) async {
    final raw = await _graph.downloadDriveItemUtf8(
      accessToken: token,
      itemId: itemId,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('theme slice backup root must be object');
    }
    File? sidecar;
    try {
      sidecar = await _downloadThemeBackgroundSidecarAdjacent(
        token: token,
        themeSliceItemId: itemId,
        doc: decoded,
      );
      await SettingsService.applyCloudBackupMap(
        decoded,
        themeBackgroundSidecarAbsolute: sidecar?.path,
      );
    } finally {
      if (sidecar != null && await sidecar.exists()) {
        try {
          await sidecar.delete();
        } catch (_) {}
      }
    }
  }

  Future<File?> _downloadThemeBackgroundSidecarAdjacent({
    required String token,
    required String themeSliceItemId,
    required Map<String, dynamic> doc,
  }) async {
    final name =
        SettingsService.themeBackgroundAssetNameFromDoc(doc)?.trim();
    if (name == null || name.isEmpty) return null;

    final parentId = await _graph.driveItemParentFolderId(
      accessToken: token,
      itemId: themeSliceItemId,
    );
    if (parentId == null || parentId.isEmpty) return null;

    final children = await _graph.listChildren(
      accessToken: token,
      parentId: parentId,
    );
    OneDriveGraphItem? hit;
    for (final it in children) {
      if (it.isFolder) continue;
      if (it.name == name) {
        hit = it;
        break;
      }
    }
    if (hit == null) return null;

    final OneDriveGraphItem use = hit.downloadUrl == null
        ? (await _graph.getItem(accessToken: token, itemId: hit.id)) ?? hit
        : hit;

    final tmpRoot = await getTemporaryDirectory();
    final out = File(
      p.join(
        tmpRoot.path,
        'yeah_theme_bg_${DateTime.now().microsecondsSinceEpoch}_$name',
      ),
    );

    await _graph.downloadToFile(
      downloadUrl: use.downloadUrl,
      itemId: hit.id,
      accessToken: token,
      file: out,
    );
    return out;
  }

  /// 与同目录 JSON 配套的封面侧车：`playlistCoverAssetNames` → 按文件名在父文件夹中查找并下载。
  Future<_PlaylistCoverDownloadScratch?> _downloadPlaylistCoverSidecarsAdjacent({
    required String token,
    required String playlistsDriveItemId,
    required Map<String, dynamic> doc,
  }) async {
    final manifest = playlistCoverAssetNamesFromDoc(doc);
    if (manifest.isEmpty) return null;

    final parentId = await _graph.driveItemParentFolderId(
      accessToken: token,
      itemId: playlistsDriveItemId,
    );
    if (parentId == null || parentId.isEmpty) return null;

    final children = await _graph.listChildren(
      accessToken: token,
      parentId: parentId,
    );
    final byName = <String, OneDriveGraphItem>{};
    for (final it in children) {
      if (it.isFolder) continue;
      byName[it.name] = it;
    }

    final tmpRoot = await getTemporaryDirectory();
    final scratch = Directory(
      p.join(
        tmpRoot.path,
        'yeah_pl_cov_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await scratch.create(recursive: true);

    final pathsByPlaylistId = <String, String>{};
    try {
      for (final e in manifest.entries) {
        final playlistId = e.key.trim();
        final remoteName = e.value.trim();
        if (playlistId.isEmpty || remoteName.isEmpty) continue;
        final item = byName[remoteName];
        if (item == null) continue;

        final OneDriveGraphItem use = item.downloadUrl == null
            ? (await _graph.getItem(accessToken: token, itemId: item.id)) ??
                item
            : item;

        final dest = File(p.join(scratch.path, remoteName));
        await _graph.downloadToFile(
          downloadUrl: use.downloadUrl,
          itemId: item.id,
          accessToken: token,
          file: dest,
        );
        pathsByPlaylistId[playlistId] = dest.path;
      }
    } catch (_) {
      try {
        if (await scratch.exists()) {
          await scratch.delete(recursive: true);
        }
      } catch (_) {}
      rethrow;
    }

    return _PlaylistCoverDownloadScratch(
      pathsByPlaylistId: pathsByPlaylistId,
      directory: scratch,
    );
  }

  Future<void> restoreCloudBackup({
    required UserPlaylistProvider userPlaylistProvider,
    required OneDriveRestoreSelection sel,
  }) async {
    if (!sel.wantsAnyPayload) {
      return;
    }
    if (_immediateSyncBusy || _immediateRestoreBusy) {
      throw StateError('immediate cloud op busy');
    }
    final token = await getAccessToken();
    if (token == null) {
      throw StateError('not signed in');
    }

    _immediateRestoreBusy = true;
    notifyListeners();
    try {
      await userPlaylistProvider.init();

      Future<void> applySlice(String fileName, bool want) async {
        if (!want) return;
        final id = sel.snapshot.blobItemIds[fileName]?.trim();
        if (id == null || id.isEmpty) return;
        if (fileName == OneDriveSyncConstants.sliceThemeFileName) {
          await _applyThemeSliceBlob(token: token, itemId: id);
        } else {
          await _applySettingsBlob(token: token, itemId: id);
        }
      }

      if (sel.restorePlaylists) {
        final id = _playlistBackupItemId(sel.snapshot);
        if (id == null || id.isEmpty) {
          throw StateError('playlist backup missing');
        }
        final raw = await _graph.downloadDriveItemUtf8(
          accessToken: token,
          itemId: id,
        );
        final doc = parseUserPlaylistExportJson(raw);
        _PlaylistCoverDownloadScratch? cov;
        try {
          cov = await _downloadPlaylistCoverSidecarsAdjacent(
            token: token,
            playlistsDriveItemId: id,
            doc: doc,
          );
          await userPlaylistProvider.applyImportedDocument(
            doc,
            replaceAll: sel.replaceAllPlaylists,
            playlistCoverFilesAbsolute: cov?.pathsByPlaylistId,
          );
        } finally {
          if (cov != null && await cov.directory.exists()) {
            try {
              await cov.directory.delete(recursive: true);
            } catch (_) {}
          }
        }
      }

      await applySlice(
        OneDriveSyncConstants.sliceHomeGreetingFileName,
        sel.restoreHomeGreeting,
      );
      await applySlice(
        OneDriveSyncConstants.sliceQuickEntryFileName,
        sel.restoreQuickEntry,
      );
      await applySlice(
        OneDriveSyncConstants.slicePlaybackListsFileName,
        sel.restorePlaybackLists,
      );
      await applySlice(
        OneDriveSyncConstants.sliceLyricsUiFileName,
        sel.restoreLyricsUi,
      );
      await applySlice(
        OneDriveSyncConstants.sliceThemeFileName,
        sel.restoreTheme,
      );

      if (sel.restoreLegacyCombinedSettings) {
        final settingsId = sel.snapshot.settingsItemId?.trim();
        if (settingsId == null || settingsId.isEmpty) {
          throw StateError('settings backup missing');
        }
        await _applySettingsBlob(token: token, itemId: settingsId);
      }

      notifyListeners();
    } finally {
      _immediateRestoreBusy = false;
      notifyListeners();
    }
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
      await loadFromStorage();
      return _signedIn;
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
    await _touchPlaybackRootForScanHistory();
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
  ///
  /// 从 Hive 读取路径，与 [_onedriveLocalPlaybackRoots] 一致，避免 [_localDownloadDir] 尚未注入时使用默认目录。
  Future<Directory> _playbackStorageDirectory() async {
    final defaultRoot = await _defaultPlaybackStorageDirectory();
    final configuredRaw = await SettingsService.loadOneDriveLocalDownloadDir();
    final configured = configuredRaw?.trim();
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
  /// 使用 [recursive: true] 以包含子目录中的文件（例如用户整理的下载目录结构）。
  Future<List<Song>> loadLocallyCachedOneDriveSongs() async {
    final roots = await _onedriveLocalPlaybackRoots();
    final seenPaths = <String>{};
    final files = <File>[];
    for (final root in roots) {
      await root.create(recursive: true);
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(
          recursive: true,
          followLinks: true,
        )) {
          if (entity is! File) continue;
          if (!OneDriveConfig.isAudioOrOneDriveCachedFileName(
            p.basename(entity.path),
          )) {
            continue;
          }
          final norm = p.normalize(entity.path);
          if (seenPaths.add(norm)) {
            files.add(entity);
          }
        }
      } on FileSystemException catch (e, st) {
        assert(() {
          debugPrint('loadLocallyCachedOneDriveSongs list failed: $e\n$st');
          return true;
        }());
      }
    }
    files.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    final songs = <Song>[];
    for (final f in files) {
      try {
        final s = Song(f.path);
        await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
        songs.add(s);
      } catch (e, st) {
        assert(() {
          debugPrint(
            'loadLocallyCachedOneDriveSongs skip ${f.path}: $e\n$st',
          );
          return true;
        }());
      }
    }
    return songs;
  }

  /// 默认缓存目录以及（若配置且存在）用户下载目录，加上 [SettingsService.loadOneDriveDownloadScanRoots]
  /// 中仍存在的路径（避免清空「当前下载目录」后只扫默认目录、历史点播文件「消失」）。
  ///
  /// 另尝试 [getApplicationDocumentsDirectory]/onedrive_cache 作为遗留位置。
  Future<List<Directory>> _onedriveLocalPlaybackRoots() async {
    final support = await getApplicationSupportDirectory();
    final def = Directory(p.join(support.path, 'onedrive_cache'));

    final roots = <Directory>[def];
    final seenNorm = <String>{p.normalize(def.path)};

    Future<void> addRoot(Directory dir) async {
      final n = p.normalize(dir.path);
      if (seenNorm.contains(n)) return;
      if (!await dir.exists()) return;
      try {
        final st = await dir.stat();
        if (st.type != FileSystemEntityType.directory) return;
      } catch (_) {
        return;
      }
      seenNorm.add(n);
      roots.add(dir);
    }

    final configuredRaw = await SettingsService.loadOneDriveLocalDownloadDir();
    final configured = configuredRaw?.trim();
    if (configured != null && configured.isNotEmpty) {
      await addRoot(Directory(p.normalize(configured)));
    }

    for (final path in await SettingsService.loadOneDriveDownloadScanRoots()) {
      if (path.isEmpty) continue;
      await addRoot(Directory(path));
    }

    try {
      final docs = await getApplicationDocumentsDirectory();
      await addRoot(Directory(p.join(docs.path, 'onedrive_cache')));
    } catch (_) {}

    try {
      final cacheRoot = await getApplicationCacheDirectory();
      await addRoot(Directory(p.join(cacheRoot.path, 'onedrive_cache')));
    } catch (_) {}

    try {
      final tmp = await getTemporaryDirectory();
      await addRoot(Directory(p.join(tmp.path, 'onedrive_cache')));
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final externalCaches = await getExternalCacheDirectories();
        if (externalCaches != null) {
          for (final d in externalCaches) {
            await addRoot(Directory(p.join(d.path, 'onedrive_cache')));
          }
        }
      } catch (_) {}
    }

    return roots;
  }

  /// 将本地文件上传到 OneDrive 指定 **文件夹**（Graph driveItem id）。
  Future<void> uploadLocalFileWithProgress({
    required String parentFolderItemId,
    required String remoteFileName,
    required File file,
    required void Function(int sent, int? total) onProgress,
    required Future<void> Function() waitWhilePaused,
    required bool Function() isCancelled,
  }) async {
    final t = await getAccessToken();
    if (t == null) {
      throw StateError('not signed in');
    }
    final parentMeta = await _graph.getItem(
      accessToken: t,
      itemId: parentFolderItemId,
    );
    if (parentMeta == null || !parentMeta.isFolder) {
      throw StateError('upload parent is not a folder');
    }
    await _graph.uploadLocalFileWithProgress(
      accessToken: t,
      parentItemId: parentFolderItemId,
      remoteFileName: remoteFileName,
      file: file,
      onProgress: (sent, total) => onProgress(sent, total),
      waitWhilePaused: waitWhilePaused,
      isCancelled: isCancelled,
    );
  }

  /// 为当前目录中所有音频建播放队列；已缓存的跳过网络，其余串行下载。
  Future<List<Song>> buildQueueForAudioItems(
    List<OneDriveGraphItem> items,
  ) async {
    final files = items
        .where((e) => !e.isFolder && OneDriveConfig.isAudioFileName(e.name))
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
