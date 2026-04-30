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
  static const allIds = [
    idLibrary,
    idPlaylists,
    idRecent,
    idMostPlayed,
    idDiscover,
    idCloudLibrary,
    idOneDrive,
    idOneDriveCachePlaylist,
  ];

  /// 全部门口的排列顺序（含被隐藏的，便于管理页排序）
  List<String> order;
  final Set<String> hidden;

  factory QuickEntryConfig.defaultConfig() {
    return QuickEntryConfig(
      order: List<String>.from(allIds),
      hidden: {},
    );
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
