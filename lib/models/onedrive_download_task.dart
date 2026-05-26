// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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
    this.localDownloadPath,
    this.localDownloadRootPath,
    this.uploadCloudPath,
    this.uploadLocalPath,
    this.uploadParentItemId,
    this.uploadRemoteFileName,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  /// 下载：远端文件；上传：可为占位（真实父目录见 [uploadParentItemId]）。
  final OneDriveGraphItem graphItem;
  final String title;
  final String subtitle;

  /// 下载落地完整路径（入队时按点播缓存规则推算；完成后与 [song.path] 一致）。
  final String? localDownloadPath;

  /// 当前生效的本地下载根目录（设置项或默认 `onedrive_cache`）。
  final String? localDownloadRootPath;

  /// 上传目标云端展示路径（Graph 解析的 `文件夹路径/文件名`）。
  final String? uploadCloudPath;

  /// 非 null 表示上传到 [uploadParentItemId]，云端文件名为 [uploadRemoteFileName]。
  final String? uploadLocalPath;
  final String? uploadParentItemId;
  final String? uploadRemoteFileName;

  bool get isUpload =>
      uploadLocalPath != null &&
      uploadLocalPath!.isNotEmpty &&
      uploadParentItemId != null &&
      uploadParentItemId!.isNotEmpty;

  /// 列表展示用：已完成时优先 [song.path]。
  String? get displayLocalDownloadPath {
    final done = song?.path.trim();
    if (done != null && done.isNotEmpty) return done;
    final planned = localDownloadPath?.trim();
    if (planned != null && planned.isNotEmpty) return planned;
    return null;
  }

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
