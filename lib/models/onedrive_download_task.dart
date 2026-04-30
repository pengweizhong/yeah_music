import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/services/onedrive/onedrive_graph_client.dart';

enum OneDriveDownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

/// 批量点播队列中的一条任务（OneDrive **下载**或**上传**）。
class OneDriveDownloadTask {
  OneDriveDownloadTask({
    required this.graphItem,
    required this.title,
    required this.subtitle,
    DateTime? enqueuedAt,
    this.startedDownloadingAt,
    this.uploadLocalPath,
    this.uploadParentItemId,
    this.uploadRemoteFileName,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  /// 下载：远端文件；上传：可为占位（真实父目录见 [uploadParentItemId]）。
  final OneDriveGraphItem graphItem;
  final String title;
  final String subtitle;

  /// 非 null 表示上传到 [uploadParentItemId]，云端文件名为 [uploadRemoteFileName]。
  final String? uploadLocalPath;
  final String? uploadParentItemId;
  final String? uploadRemoteFileName;

  bool get isUpload =>
      uploadLocalPath != null &&
      uploadLocalPath!.isNotEmpty &&
      uploadParentItemId != null &&
      uploadParentItemId!.isNotEmpty;

  /// 加入队列时刻（界面排序：同优先级内倒序）。
  final DateTime enqueuedAt;

  /// 本次进入进行中状态的时刻（可选，用于排序）。
  DateTime? startedDownloadingAt;

  OneDriveDownloadStatus status = OneDriveDownloadStatus.pending;

  int receivedBytes = 0;

  /// 总字节（未知时为 null）。
  int? totalBytes;

  Song? song;

  Object? error;

  double get progress {
    if (status == OneDriveDownloadStatus.completed) {
      return 1;
    }
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
