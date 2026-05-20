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

/// 首页「快捷入口」显示顺序与显隐
class QuickEntryConfig {
  QuickEntryConfig({required this.order, required this.hidden}) {
    normalizeInPlace();
  }

  static const idLibrary = 'library';
  static const idPlaylists = 'playlists';
  static const idRecent = 'recent';
  static const idMostPlayed = 'most_played';
  static const idDiscover = 'discover';
  static const idCloudLibrary = 'cloud_library';
  static const idOneDrive = 'onedrive';

  /// OneDrive 点播下载到本地的曲目汇总（默认缓存目录与用户下载目录）。
  static const idOneDriveCachePlaylist = 'onedrive_cache_playlist';

  /// OneDrive 传输队列（下载 / 上传任务）。
  static const idOneDriveTransferQueue = 'onedrive_transfer_queue';

  /// 听歌识曲（麦克风 + AudD）
  static const idSongRecognizer = 'song_recognizer';

  /// 规范顺序：默认首页从左到右；[normalizeInPlace] 补全缺失 id 时也按此顺序追加。
  ///
  /// 调整首页快捷入口默认顺序时，直接移动下面这些 id 即可。
  static const allIds = [
    /// 本地曲库。
    idLibrary,
    /// OneDrive 云端曲库。
    idCloudLibrary,
    /// OneDrive 已缓存 / 已下载歌曲。
    idOneDriveCachePlaylist,
    /// OneDrive 传输队列（下载 / 上传任务）。
    idOneDriveTransferQueue,
    /// 听歌识曲。
    idSongRecognizer,
    /// 最近播放。
    idRecent,
    /// 最常播放。
    idMostPlayed,
    /// 用户歌单。
    idPlaylists,
    /// 发现页。
    idDiscover,
    /// OneDrive 文件浏览入口。
    idOneDrive,
  ];

  /// 全部门口的排列顺序（含被隐藏的，便于管理页排序）
  List<String> order;
  final Set<String> hidden;

  factory QuickEntryConfig.defaultConfig() {
    return QuickEntryConfig(order: List<String>.from(allIds), hidden: {});
  }

  /// 去重、补全、清理非法 [hidden]（可在外存盘前再调一次）
  void normalizeInPlace() {
    // 去重、补全、去掉未知 id
    final seen = <String>{};
    final out = <String>[];
    for (final id in order) {
      if (allIds.contains(id) && !seen.contains(id)) {
        out.add(id);
        seen.add(id);
      }
    }
    for (final id in allIds) {
      if (!seen.contains(id)) {
        out.add(id);
        seen.add(id);
      }
    }
    order = out;
    hidden.removeWhere((id) => !allIds.contains(id));
  }

  /// 在首页一行中从左到右显示的 id（不隐藏的顺序）
  List<String> get visibleInOrder {
    return order.where((id) => !hidden.contains(id)).toList();
  }

  static QuickEntryConfig? fromStorage(
    List<dynamic>? orderRaw,
    List<dynamic>? hiddenRaw,
  ) {
    final order = <String>[];
    if (orderRaw != null) {
      for (final e in orderRaw) {
        if (e is String && allIds.contains(e)) {
          order.add(e);
        }
      }
    }
    final hidden = <String>{};
    if (hiddenRaw != null) {
      for (final e in hiddenRaw) {
        if (e is String && allIds.contains(e)) {
          hidden.add(e);
        }
      }
    }
    if (order.isEmpty && hidden.isEmpty) {
      return null;
    }
    return QuickEntryConfig(order: order, hidden: hidden);
  }
}
