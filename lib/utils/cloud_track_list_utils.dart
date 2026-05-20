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

import 'package:yeah_music/models/onedrive_cloud_track.dart';

/// 与 [OneDriveCloudTrack] 列表展示顺序一致（不修改原列表）。
List<OneDriveCloudTrack> sortCloudTracksCopy(
  List<OneDriveCloudTrack> source,
  CloudTrackSortType type,
  bool ascending,
) {
  final copy = List<OneDriveCloudTrack>.from(source);
  int compare(OneDriveCloudTrack a, OneDriveCloudTrack b) {
    switch (type) {
      case CloudTrackSortType.fileName:
        return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
      case CloudTrackSortType.fullPath:
        return a.displayPath.toLowerCase().compareTo(b.displayPath.toLowerCase());
    }
  }

  copy.sort((a, b) => ascending ? compare(a, b) : compare(b, a));
  return copy;
}

/// 按关键词过滤（文件名或展示路径）。
List<OneDriveCloudTrack> filterCloudTracksByQuery(List<OneDriveCloudTrack> source, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List<OneDriveCloudTrack>.from(source);
  return source
      .where(
        (t) =>
            t.fileName.toLowerCase().contains(q) || t.displayPath.toLowerCase().contains(q),
      )
      .toList();
}
