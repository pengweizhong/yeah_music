/// 与哪个列表/场景发起的当前播放会话一致，用于从播放页返回时仅在该表自动滚到正在播的行。
enum PlaybackSessionSurface {
  /// 全库 / 「全部歌曲」
  library,

  /// 最近播放页、主页「最近」条等（顺序即最近序）
  recentList,

  /// 某用户歌单
  userPlaylist,

  /// 主页「最多播放」等无独立全屏列表的临时队列
  adHoc,
}
