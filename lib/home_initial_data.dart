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
