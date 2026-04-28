import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yeah_music/compments/onedrive_controller.dart';
import 'package:yeah_music/compments/play_list_provider.dart';
import 'package:yeah_music/models/onedrive_cloud_track.dart';
import 'package:yeah_music/models/onedrive_download_task.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';
import 'package:yeah_music/services/settings_service.dart';
import 'package:yeah_music/utils/file_utils.dart';

/// OneDrive 下载队列：批量 / 单曲追加；暂停 / 继续 / 停止；持久化记录。
class OneDriveDownloadQueueController extends ChangeNotifier {
  OneDriveDownloadQueueController({
    required OneDriveController oneDrive,
    PlayListProvider? playListRef,
  })  : _od = oneDrive,
        _playListRef = playListRef;

  final OneDriveController _od;

  final PlayListProvider? _playListRef;

  List<OneDriveDownloadTask> _tasks = [];

  bool _sessionPaused = false;

  bool _stopRequested = false;

  bool _workerRunning = false;

  Timer? _persistTimer;

  static const int _maxPersistRows = 200;

  List<OneDriveDownloadTask> get tasks => List.unmodifiable(_tasks);

  /// 下载队列界面：「下载中」置顶，其余按入队时间从新到旧。
  List<OneDriveDownloadTask> get tasksSortedForDisplay {
    int tier(OneDriveDownloadTask t) {
      switch (t.status) {
        case OneDriveDownloadStatus.downloading:
          return 0;
        case OneDriveDownloadStatus.pending:
          return 1;
        case OneDriveDownloadStatus.completed:
        case OneDriveDownloadStatus.failed:
        case OneDriveDownloadStatus.cancelled:
          return 2;
      }
    }

    final list = List<OneDriveDownloadTask>.from(_tasks);
    list.sort((a, b) {
      final ta = tier(a);
      final tb = tier(b);
      if (ta != tb) return ta.compareTo(tb);
      if (ta == 0) {
        final sa = a.startedDownloadingAt ?? a.enqueuedAt;
        final sb = b.startedDownloadingAt ?? b.enqueuedAt;
        return sb.compareTo(sa);
      }
      return b.enqueuedAt.compareTo(a.enqueuedAt);
    });
    return list;
  }

  bool get sessionPaused => _sessionPaused;

  bool get workerRunning => _workerRunning;

  bool get stopRequested => _stopRequested;

  bool get canPauseDownloads =>
      !_stopRequested &&
      workerRunning &&
      !sessionPaused &&
      _tasks.any(
        (t) =>
            t.status == OneDriveDownloadStatus.pending ||
            t.status == OneDriveDownloadStatus.downloading,
      );

  bool get canResumeDownloads => !_stopRequested && workerRunning && sessionPaused;

  /// 「全部停止」后队列处于中止状态：可点此恢复将已取消任务重新排队下载。
  bool get canContinueAfterStop =>
      !_workerRunning &&
      _stopRequested &&
      _tasks.any((t) => t.status == OneDriveDownloadStatus.cancelled);

  bool get canStopDownloads =>
      workerRunning ||
      _tasks.any(
        (t) =>
            t.status == OneDriveDownloadStatus.pending ||
            t.status == OneDriveDownloadStatus.downloading,
      );

  List<Song> get completedSongs {
    final out = <Song>[];
    for (final t in _tasks) {
      if (t.status == OneDriveDownloadStatus.completed && t.song != null) {
        out.add(t.song!);
      }
    }
    return out;
  }

  bool get hasCompletedSongs => completedSongs.isNotEmpty;

  bool get hasRecordedTasks => _tasks.isNotEmpty;

  void pause() {
    _sessionPaused = true;
    notifyListeners();
  }

  void resume() {
    _sessionPaused = false;
    notifyListeners();
  }

  /// 在「全部停止」之后重新开始队列（仅当 worker 已退出且仍有已取消任务）。
  void resumeStoppedBatch() {
    if (_workerRunning || !_stopRequested) return;
    var changed = false;
    for (final t in _tasks) {
      if (t.status == OneDriveDownloadStatus.cancelled) {
        t.status = OneDriveDownloadStatus.pending;
        t.error = null;
        changed = true;
      }
    }
    _stopRequested = false;
    notifyListeners();
    if (changed) {
      _schedulePersist();
    }
    _ensureWorkerRunning();
  }

  void requestStop() {
    _stopRequested = true;
    _sessionPaused = false;
    notifyListeners();
  }

  void resetStopFlags() {
    _stopRequested = false;
    _sessionPaused = false;
  }

  Future<void> _waitWhilePausedInSession() async {
    while (_sessionPaused && !_stopRequested) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      notifyListeners();
    }
  }

  Future<void> _abortRunningWorkerIfNeeded() async {
    if (!_workerRunning) return;
    requestStop();
    var n = 0;
    while (_workerRunning && n < 600) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      n++;
    }
  }

  bool _hasActiveWorkForItemId(String itemId) {
    return _tasks.any(
      (t) =>
          t.graphItem.id == itemId &&
          (t.status == OneDriveDownloadStatus.pending ||
              t.status == OneDriveDownloadStatus.downloading),
    );
  }

  /// 启动时从 Hive 恢复队列记录（含已完成路径）。
  Future<void> restorePersistedTasks() async {
    try {
      final rows = await SettingsService.loadOneDriveDownloadQueueHistory();
      if (rows.isEmpty) return;
      final restored = <OneDriveDownloadTask>[];
      for (final m in rows) {
        final id = m['id'] as String?;
        final name = m['name'] as String?;
        if (id == null || name == null || id.isEmpty) continue;
        final title = (m['title'] as String?) ?? name;
        final subtitle = (m['subtitle'] as String?) ?? '';
        final gi = OneDriveGraphItem(id: id, name: name, isFolder: false);
        final eqMillis = m['enqueuedAt'];
        final sdMillis = m['startedDownloadingAt'];
        final task = OneDriveDownloadTask(
          graphItem: gi,
          title: title,
          subtitle: subtitle,
          enqueuedAt: eqMillis is num
              ? DateTime.fromMillisecondsSinceEpoch((eqMillis as num).toInt())
              : null,
          startedDownloadingAt: sdMillis is num
              ? DateTime.fromMillisecondsSinceEpoch((sdMillis as num).toInt())
              : null,
        );
        final st = m['status'] as String?;
        task.status = OneDriveDownloadStatus.values.firstWhere(
          (e) => e.name == st,
          orElse: () => OneDriveDownloadStatus.pending,
        );
        task.receivedBytes = (m['receivedBytes'] as num?)?.toInt() ?? 0;
        task.totalBytes = (m['totalBytes'] as num?)?.toInt();
        final path = m['localPath'] as String?;
        if (path != null && path.trim().isNotEmpty) {
          final f = File(path.trim());
          if (await f.exists() && await f.length() > 0) {
            final s = Song(f.path);
            await FileUtils.loadSongMeta(s, loadEmbeddedAlbumArt: false);
            task.song = s;
            if (task.status == OneDriveDownloadStatus.downloading ||
                task.status == OneDriveDownloadStatus.pending) {
              task.status = OneDriveDownloadStatus.completed;
            }
          } else if (task.status == OneDriveDownloadStatus.completed) {
            task.status = OneDriveDownloadStatus.failed;
            task.error = 'missing local file';
            task.song = null;
          }
        }
        if (task.status == OneDriveDownloadStatus.downloading) {
          task.status = OneDriveDownloadStatus.pending;
        }
        final err = m['error'] as String?;
        if (err != null && err.isNotEmpty && task.status == OneDriveDownloadStatus.failed) {
          task.error = err;
        }
        restored.add(task);
      }
      _tasks = restored;
      notifyListeners();
      _ensureWorkerRunning();
    } catch (e, st) {
      assert(() {
        debugPrint('restore download queue failed: $e\n$st');
        return true;
      }());
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        await SettingsService.saveOneDriveDownloadQueueHistory(_tasksToPersistMaps());
      } catch (_) {}
    });
  }

  List<Map<String, dynamic>> _tasksToPersistMaps() {
    final list = _tasks.length > _maxPersistRows
        ? _tasks.sublist(_tasks.length - _maxPersistRows)
        : List<OneDriveDownloadTask>.from(_tasks);
    return list.map(_taskToMap).toList();
  }

  Map<String, dynamic> _taskToMap(OneDriveDownloadTask t) {
    return {
      'id': t.graphItem.id,
      'name': t.graphItem.name,
      'title': t.title,
      'subtitle': t.subtitle,
      'status': t.status.name,
      'receivedBytes': t.receivedBytes,
      'totalBytes': t.totalBytes,
      'localPath': t.song?.path,
      'error': t.error?.toString(),
      'enqueuedAt': t.enqueuedAt.millisecondsSinceEpoch,
      'startedDownloadingAt': t.startedDownloadingAt?.millisecondsSinceEpoch,
    };
  }

  /// 清空记录并中止进行中的下载。
  Future<void> clearDownloadHistory() async {
    await _abortRunningWorkerIfNeeded();
    resetStopFlags();
    _tasks.clear();
    notifyListeners();
    await SettingsService.saveOneDriveDownloadQueueHistory([]);
  }

  /// 后台追加云端曲目。
  Future<void> enqueueCloudTracks(List<OneDriveCloudTrack> tracks) async {
    if (tracks.isEmpty) return;
    _stopRequested = false;
    var changed = false;
    for (final t in tracks) {
      final gi = _od.graphItemForCloudTrack(t);
      if (_hasActiveWorkForItemId(gi.id)) continue;
      final cached = await _od.songFromLocalCacheIfExists(gi);
      if (cached != null) {
        final len = await File(cached.path).length();
        final task = OneDriveDownloadTask(
          graphItem: gi,
          title: t.fileName,
          subtitle: t.displayPath,
        );
        task.status = OneDriveDownloadStatus.completed;
        task.song = cached;
        task.receivedBytes = len;
        task.totalBytes = len;
        _tasks.add(task);
        changed = true;
        continue;
      }
      _tasks.add(
        OneDriveDownloadTask(
          graphItem: gi,
          title: t.fileName,
          subtitle: t.displayPath,
        ),
      );
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _schedulePersist();
    _ensureWorkerRunning();
  }

  Future<void> enqueueGraphItems(
    List<({OneDriveGraphItem item, String title, String subtitle})> entries,
  ) async {
    if (entries.isEmpty) return;
    _stopRequested = false;
    var changed = false;
    for (final e in entries) {
      if (_hasActiveWorkForItemId(e.item.id)) continue;
      final cached = await _od.songFromLocalCacheIfExists(e.item);
      if (cached != null) {
        final len = await File(cached.path).length();
        final task = OneDriveDownloadTask(
          graphItem: e.item,
          title: e.title,
          subtitle: e.subtitle,
        );
        task.status = OneDriveDownloadStatus.completed;
        task.song = cached;
        task.receivedBytes = len;
        task.totalBytes = len;
        _tasks.add(task);
        changed = true;
        continue;
      }
      _tasks.add(
        OneDriveDownloadTask(
          graphItem: e.item,
          title: e.title,
          subtitle: e.subtitle,
        ),
      );
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _schedulePersist();
    _ensureWorkerRunning();
  }

  Future<List<Song>> runBatchFromCloudTracks(List<OneDriveCloudTrack> tracks) async {
    await _abortRunningWorkerIfNeeded();
    final batchTasks = <OneDriveDownloadTask>[];
    for (final t in tracks) {
      final gi = _od.graphItemForCloudTrack(t);
      final cached = await _od.songFromLocalCacheIfExists(gi);
      if (cached != null) {
        final len = await File(cached.path).length();
        final task = OneDriveDownloadTask(
          graphItem: gi,
          title: t.fileName,
          subtitle: t.displayPath,
        );
        task.status = OneDriveDownloadStatus.completed;
        task.song = cached;
        task.receivedBytes = len;
        task.totalBytes = len;
        batchTasks.add(task);
      } else {
        batchTasks.add(
          OneDriveDownloadTask(
            graphItem: gi,
            title: t.fileName,
            subtitle: t.displayPath,
          ),
        );
      }
    }
    _tasks = batchTasks;
    resetStopFlags();
    notifyListeners();
    _schedulePersist();
    _ensureWorkerRunning();
    await _waitForTasksTerminal(batchTasks);
    return _songsFromTasks(batchTasks);
  }

  Future<List<Song>> runBatchFromGraphItems(
    List<({OneDriveGraphItem item, String title, String subtitle})> entries,
  ) async {
    await _abortRunningWorkerIfNeeded();
    final batchTasks = <OneDriveDownloadTask>[];
    for (final e in entries) {
      final cached = await _od.songFromLocalCacheIfExists(e.item);
      if (cached != null) {
        final len = await File(cached.path).length();
        final task = OneDriveDownloadTask(
          graphItem: e.item,
          title: e.title,
          subtitle: e.subtitle,
        );
        task.status = OneDriveDownloadStatus.completed;
        task.song = cached;
        task.receivedBytes = len;
        task.totalBytes = len;
        batchTasks.add(task);
      } else {
        batchTasks.add(
          OneDriveDownloadTask(
            graphItem: e.item,
            title: e.title,
            subtitle: e.subtitle,
          ),
        );
      }
    }
    _tasks = batchTasks;
    resetStopFlags();
    notifyListeners();
    _schedulePersist();
    _ensureWorkerRunning();
    await _waitForTasksTerminal(batchTasks);
    return _songsFromTasks(batchTasks);
  }

  Future<void> _waitForTasksTerminal(List<OneDriveDownloadTask> batchTasks) async {
    while (batchTasks.any((t) => !t.isTerminal) && !_stopRequested) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  List<Song> _songsFromTasks(List<OneDriveDownloadTask> batchTasks) {
    return batchTasks
        .where(
          (t) => t.status == OneDriveDownloadStatus.completed && t.song != null,
        )
        .map((t) => t.song!)
        .toList();
  }

  void _ensureWorkerRunning() {
    if (_workerRunning) return;
    unawaited(_workerLoop());
  }

  Future<void> _workerLoop() async {
    if (_workerRunning) return;
    _workerRunning = true;
    notifyListeners();
    try {
      while (!_stopRequested) {
        await _waitWhilePausedInSession();
        if (_stopRequested) break;
        final idx = _tasks.indexWhere(
          (t) => t.status == OneDriveDownloadStatus.pending,
        );
        if (idx < 0) {
          break;
        }
        await _downloadOne(idx);
      }
    } finally {
      _workerRunning = false;
      notifyListeners();
    }
  }

  Future<void> _downloadOne(int i) async {
    if (i < 0 || i >= _tasks.length) return;
    await _waitWhilePausedInSession();
    if (_stopRequested) {
      _markCancelledFrom(i);
      return;
    }

    final task = _tasks[i];
    if (task.status == OneDriveDownloadStatus.completed && task.song != null) {
      return;
    }

    final cached = await _od.songFromLocalCacheIfExists(task.graphItem);
    if (cached != null) {
      final len = await File(cached.path).length();
      task.song = cached;
      task.status = OneDriveDownloadStatus.completed;
      task.receivedBytes = len;
      task.totalBytes = len;
      task.error = null;
      notifyListeners();
      _schedulePersist();
      _maybeNotifyLibraryOdOverlay();
      return;
    }

    task.status = OneDriveDownloadStatus.downloading;
    task.startedDownloadingAt = DateTime.now();
    notifyListeners();

    try {
      final song = await _od.songForPlayableItemWithProgress(
        task.graphItem,
        onProgress: (received, total) {
          task.receivedBytes = received;
          task.totalBytes = total;
          notifyListeners();
        },
        waitWhilePaused: _waitWhilePausedInSession,
        isCancelled: () => _stopRequested,
      );
      task.song = song;
      task.status = OneDriveDownloadStatus.completed;
      task.error = null;
    } on OneDriveDownloadCancelledException {
      _markCancelledFrom(i);
    } catch (e, st) {
      task.status = OneDriveDownloadStatus.failed;
      task.error = e;
      assert(() {
        debugPrint('OneDrive download failed: $e\n$st');
        return true;
      }());
      notifyListeners();
    }
    notifyListeners();
    _schedulePersist();
    if (task.status == OneDriveDownloadStatus.completed && task.song != null) {
      _maybeNotifyLibraryOdOverlay();
    }
  }

  void _maybeNotifyLibraryOdOverlay() {
    final pl = _playListRef;
    if (pl != null && pl.initialized) {
      unawaited(pl.refreshOneDriveLibraryOverlay(_od));
    }
  }

  void _markCancelledFrom(int from) {
    for (var j = from; j < _tasks.length; j++) {
      final t = _tasks[j];
      if (t.status == OneDriveDownloadStatus.completed) {
        continue;
      }
      t.status = OneDriveDownloadStatus.cancelled;
    }
    notifyListeners();
    _schedulePersist();
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}
