import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yeah_music/config/onedrive_config.dart';
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

  String get clientId => _clientId;
  String? get musicRootItemId => _musicRootItemId;
  bool get signedIn => _signedIn;
  String? get accountHint => _accountHint;
  bool get isLinuxUnsupported => Platform.isLinux;

  String get effectiveClientId {
    if (_clientId.isNotEmpty) return _clientId;
    return OneDriveConfig.defaultClientIdFromEnv;
  }

  Future<void> loadFromStorage() async {
    _clientId = (await SettingsService.loadOneDriveClientId()) ?? '';
    _musicRootItemId = await SettingsService.loadOneDriveMusicRootId();
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
