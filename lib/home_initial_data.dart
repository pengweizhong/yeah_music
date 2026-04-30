import 'package:yeah_music/models/quick_entry_config.dart';

/// [HomePage] 可选的首屏数据快照；传入时可跳过首页内对部分数据的二次拉取。
class HomeInitialData {
  const HomeInitialData({
    required this.recentPaths,
    required this.mostPlayedRaw,
    required this.quickEntry,
  });

  final List<String> recentPaths;
  final List<({String path, int count})> mostPlayedRaw;
  final QuickEntryConfig quickEntry;
}
