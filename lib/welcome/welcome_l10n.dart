import 'package:yeah_music/l10n/app_localizations.dart';

/// 首帧在 [didChangeDependencies] 拿到本地化之前用于轮播占位，避免空白 [SizedBox.shrink()]。
/// 语义与本地化字符串一致（默认中文）。
const List<String> kWelcomeFakeHintsPlaceholder = <String>[
  '加载个性化偏好 …',
  '整理本地媒体索引 …',
  '同步自建歌单结构 …',
  '准备沉浸式播放链路 …',
  '即将就绪 …',
];

List<String> welcomeFakeLoadHintsList(AppLocalizations l10n) {
  return <String>[
    l10n.welcomeFakeUserSettings,
    l10n.welcomeFakeLibrary,
    l10n.welcomeFakePlaylists,
    l10n.welcomeFakeOther,
    l10n.welcomeFakeFinishing,
  ];
}
