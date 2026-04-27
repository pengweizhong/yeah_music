import 'package:yeah_music/models/quick_entry_config.dart';

/// 由 [WelcomeEntryPage] 预加载后交给 [HomePage]，避免首屏再跑一遍 [HomePage] 的冷启动拉取。
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
