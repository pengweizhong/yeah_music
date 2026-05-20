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

/// 与哪个列表/场景发起的当前播放会话一致，用于从播放页返回时仅在该表自动滚到正在播的行。
enum PlaybackSessionSurface {
  /// 全库 / 「全部歌曲」
  library,

  /// 最近播放页、主页「最近」条等（顺序即最近序）
  recentList,

  /// 最多播放全屏列表等（顺序为播放次数排行）
  mostPlayedList,

  /// 某艺术家下列出的该歌手曲目队列
  libraryByArtist,

  /// 某专辑下列出的该专辑曲目队列
  libraryByAlbum,

  /// 某用户歌单
  userPlaylist,

  /// 其他临时队列
  adHoc,
}
