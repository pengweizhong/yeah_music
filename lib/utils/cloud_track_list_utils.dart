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
