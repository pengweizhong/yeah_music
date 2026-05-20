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

/// 云端曲库列表排序方式（与 [sortCloudTracksCopy] 一致）。
enum CloudTrackSortType {
  /// 仅比较文件名
  fileName,

  /// 比较展示路径（根标签/子路径/文件名）
  fullPath,
}

/// 云端索引中的一条曲目（仅存 Graph item id 与路径展示，不包含音频字节）。
class OneDriveIndexFolder {
  OneDriveIndexFolder({required this.itemId, required this.label});

  final String itemId;
  final String label;

  factory OneDriveIndexFolder.fromMap(Map<dynamic, dynamic> m) {
    return OneDriveIndexFolder(
      itemId: (m['itemId'] as String? ?? '').trim(),
      label: (m['label'] as String? ?? 'Folder').trim(),
    );
  }

  Map<String, dynamic> toMap() => {'itemId': itemId, 'label': label};
}

class OneDriveCloudTrack {
  OneDriveCloudTrack({
    required this.itemId,
    required this.fileName,
    required this.displayPath,
  });

  /// OneDrive driveItem id
  final String itemId;

  /// 文件名（含扩展名）
  final String fileName;

  /// 便于列表展示：`根标签/子路径/文件名`
  final String displayPath;

  String get sortKey => displayPath.toLowerCase();

  factory OneDriveCloudTrack.fromMap(Map<dynamic, dynamic> m) {
    return OneDriveCloudTrack(
      itemId: (m['itemId'] as String? ?? '').trim(),
      fileName: (m['fileName'] as String? ?? '').trim(),
      displayPath: (m['displayPath'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'fileName': fileName,
        'displayPath': displayPath,
      };
}
