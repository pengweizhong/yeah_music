import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';

enum OneDriveDownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

/// 批量点播队列中的一条下载任务。
class OneDriveDownloadTask {
  OneDriveDownloadTask({
    required this.graphItem,
    required this.title,
    required this.subtitle,
    DateTime? enqueuedAt,
    this.startedDownloadingAt,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  final OneDriveGraphItem graphItem;
  final String title;
  final String subtitle;

  /// 加入队列时刻（界面排序：同优先级内倒序）。
  final DateTime enqueuedAt;

  /// 本次进入 [OneDriveDownloadStatus.downloading] 的时刻（可选，用于排序）。
  DateTime? startedDownloadingAt;

  OneDriveDownloadStatus status = OneDriveDownloadStatus.pending;

  int receivedBytes = 0;

  /// Graph 响应给出的总字节（未知时为 null）。
  int? totalBytes;

  Song? song;

  Object? error;

  double get progress {
    final t = totalBytes;
    if (t != null && t > 0) {
      return (receivedBytes.clamp(0, t)) / t;
    }
    return 0;
  }

  bool get isTerminal =>
      status == OneDriveDownloadStatus.completed ||
      status == OneDriveDownloadStatus.failed ||
      status == OneDriveDownloadStatus.cancelled;
}
