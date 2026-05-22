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

/// 全局应用配置（展示名称与版本见 [AppProductInfo]）。
class AppConfig {
  static const copyright = "©2026 pengweizhong. GPL-3.0 license";
  static const supportedFormats = [
    ".mp3",
    ".flac",
    ".m4a",
    ".wav",
    ".dsf",
    ".dff",
  ];
  ///播放页底部高度 用来控制整体封面、播放按钮、进度条的高度
  static const double bottomHeight = 160;
  ///播放页底部高度 用来控制封面高度
  static const double bottomCoverHeight = 170;
}
