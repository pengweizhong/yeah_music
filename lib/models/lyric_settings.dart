import 'package:flutter/painting.dart' show TextAlign;
import 'package:hive/hive.dart';

part 'lyric_settings.g.dart';

@HiveType(typeId: 2)
class LyricSettings extends HiveObject {
  /// 与歌词样式面板的滑条范围一致
  static const double minFontSize = 5;
  static const double maxFontSize = 40;
  static const double minLineSpacing = 0;
  static const double maxLineSpacing = 50;

  @HiveField(0)
  bool showOriginal = true;

  @HiveField(1)
  bool showTranslations = true;

  @HiveField(2)
  double originalFontSize = 20.0;

  @HiveField(3)
  double translationFontSize = 14.0;

  @HiveField(4)
  int activeOriginalColor = 0xFFFFFFFF; // Colors.white

  @HiveField(5)
  int activeTranslationColor = 0xFFD0D0D0;

  @HiveField(6)
  int playedOriginalColor = 0xFFB0B0B0;

  @HiveField(7)
  int playedTranslationColor = 0xFF909090;

  @HiveField(8)
  int upcomingOriginalColor = 0xFF7A7A7A;

  @HiveField(9)
  int upcomingTranslationColor = 0xFF6A6A6A;

  // Note: Hive doesn't support Map directly, so we'll store as List<String> with format "key:value"
  @HiveField(10)
  List<String> lyricDisplayModeList = []; // stored as "key:value" strings

  @HiveField(11)
  double lyricLineSpacing = 12.0; // 歌词行间距

  /// 0=靠左, 1=居中, 2=靠右（与 [lyricTextAlign] 一致）
  @HiveField(12)
  int lyricTextAlignIndex = 1;

  /// 为 true 时「正在播放」高亮行（原文与译文）使用下方渐变，而非 [activeOriginalColor] / [activeTranslationColor]。
  @HiveField(13)
  bool activeLyricUseGradient = false;

  /// 渐变起始色 ARGB（与 [PlaylistCoverGradientDirection] 搭配）。
  @HiveField(14)
  int activeLyricGradientStart = 0xFFFFFFFF;

  @HiveField(15)
  int activeLyricGradientEnd = 0xFFFFB74D;

  /// [PlaylistCoverGradientDirection.index]，持久化与歌单封面渐变方向一致。
  @HiveField(16)
  int activeLyricGradientDirectionIndex = 0;

  /// 「已播过」行：开启时原文/译文共用下方渐变，优先于 [playedOriginalColor] / [playedTranslationColor]。
  @HiveField(17)
  bool playedLyricUseGradient = false;

  @HiveField(18)
  int playedLyricGradientStart = 0xFF81C784;

  @HiveField(19)
  int playedLyricGradientEnd = 0xFFC8E6C9;

  @HiveField(20)
  int playedLyricGradientDirectionIndex = 0;

  /// 「未播到」行：同上，优先于 upcoming 纯色。
  @HiveField(21)
  bool upcomingLyricUseGradient = false;

  @HiveField(22)
  int upcomingLyricGradientStart = 0xFF64B5F6;

  @HiveField(23)
  int upcomingLyricGradientEnd = 0xFFBBDEFB;

  @HiveField(24)
  int upcomingLyricGradientDirectionIndex = 0;

  LyricSettings();

  /// 将字号、行距限制在可编辑范围内（与 UI 滑条、历史存盘数据对齐）
  void normalizeLayoutFields() {
    originalFontSize = originalFontSize.clamp(minFontSize, maxFontSize);
    translationFontSize = translationFontSize.clamp(minFontSize, maxFontSize);
    lyricLineSpacing = lyricLineSpacing.clamp(minLineSpacing, maxLineSpacing);
  }

  /// 歌词行文字对齐
  TextAlign get lyricTextAlign {
    switch (lyricTextAlignIndex) {
      case 0:
        return TextAlign.left;
      case 2:
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  // Helper methods to convert between Map and List
  Map<int, int> get lyricDisplayMode {
    final map = <int, int>{};
    for (final item in lyricDisplayModeList) {
      final parts = item.split(':');
      if (parts.length == 2) {
        map[int.parse(parts[0])] = int.parse(parts[1]);
      }
    }
    return map;
  }

  set lyricDisplayMode(Map<int, int> value) {
    lyricDisplayModeList = value.entries.map((e) => '${e.key}:${e.value}').toList();
  }

  /// 与播放页从 Hive 恢复后的「全局多行模式」一致：map 为空为全部行（-1），否则取存盘代表值。
  int get resolvedGlobalLyricDisplayMode {
    final m = lyricDisplayMode;
    if (m.isEmpty) return -1;
    return m.values.first;
  }

  // Convert Color to int for storage
  static int colorToInt(int color) => color;

  // Convert int to Color
  static int intToColor(int value) => value;

  /// 歌词设置 JSON 快照（云端备份用；字段与 Hive 一致便于还原）。
  Map<String, dynamic> toBackupMap() => {
        'showOriginal': showOriginal,
        'showTranslations': showTranslations,
        'originalFontSize': originalFontSize,
        'translationFontSize': translationFontSize,
        'activeOriginalColor': activeOriginalColor,
        'activeTranslationColor': activeTranslationColor,
        'playedOriginalColor': playedOriginalColor,
        'playedTranslationColor': playedTranslationColor,
        'upcomingOriginalColor': upcomingOriginalColor,
        'upcomingTranslationColor': upcomingTranslationColor,
        'lyricDisplayModeList': List<String>.from(lyricDisplayModeList),
        'lyricLineSpacing': lyricLineSpacing,
        'lyricTextAlignIndex': lyricTextAlignIndex,
        'activeLyricUseGradient': activeLyricUseGradient,
        'activeLyricGradientStart': activeLyricGradientStart,
        'activeLyricGradientEnd': activeLyricGradientEnd,
        'activeLyricGradientDirectionIndex': activeLyricGradientDirectionIndex,
        'playedLyricUseGradient': playedLyricUseGradient,
        'playedLyricGradientStart': playedLyricGradientStart,
        'playedLyricGradientEnd': playedLyricGradientEnd,
        'playedLyricGradientDirectionIndex': playedLyricGradientDirectionIndex,
        'upcomingLyricUseGradient': upcomingLyricUseGradient,
        'upcomingLyricGradientStart': upcomingLyricGradientStart,
        'upcomingLyricGradientEnd': upcomingLyricGradientEnd,
        'upcomingLyricGradientDirectionIndex': upcomingLyricGradientDirectionIndex,
      };

  factory LyricSettings.fromBackupMap(Map<String, dynamic> m) {
    final s = LyricSettings()
      ..showOriginal = m['showOriginal'] as bool? ?? true
      ..showTranslations = m['showTranslations'] as bool? ?? true
      ..originalFontSize = (m['originalFontSize'] as num?)?.toDouble() ?? 20.0
      ..translationFontSize = (m['translationFontSize'] as num?)?.toDouble() ?? 14.0
      ..activeOriginalColor = (m['activeOriginalColor'] as num?)?.toInt() ?? 0xFFFFFFFF
      ..activeTranslationColor = (m['activeTranslationColor'] as num?)?.toInt() ?? 0xFFD0D0D0
      ..playedOriginalColor = (m['playedOriginalColor'] as num?)?.toInt() ?? 0xFFB0B0B0
      ..playedTranslationColor = (m['playedTranslationColor'] as num?)?.toInt() ?? 0xFF909090
      ..upcomingOriginalColor = (m['upcomingOriginalColor'] as num?)?.toInt() ?? 0xFF7A7A7A
      ..upcomingTranslationColor = (m['upcomingTranslationColor'] as num?)?.toInt() ?? 0xFF6A6A6A
      ..lyricLineSpacing = (m['lyricLineSpacing'] as num?)?.toDouble() ?? 12.0
      ..lyricTextAlignIndex = (m['lyricTextAlignIndex'] as num?)?.toInt() ?? 1
      ..activeLyricUseGradient =
          m['activeLyricUseGradient'] as bool? ?? false
      ..activeLyricGradientStart =
          (m['activeLyricGradientStart'] as num?)?.toInt() ?? 0xFFFFFFFF
      ..activeLyricGradientEnd =
          (m['activeLyricGradientEnd'] as num?)?.toInt() ?? 0xFFFFB74D
      ..activeLyricGradientDirectionIndex =
          (m['activeLyricGradientDirectionIndex'] as num?)?.toInt() ?? 0
      ..playedLyricUseGradient =
          m['playedLyricUseGradient'] as bool? ?? false
      ..playedLyricGradientStart =
          (m['playedLyricGradientStart'] as num?)?.toInt() ?? 0xFF81C784
      ..playedLyricGradientEnd =
          (m['playedLyricGradientEnd'] as num?)?.toInt() ?? 0xFFC8E6C9
      ..playedLyricGradientDirectionIndex =
          (m['playedLyricGradientDirectionIndex'] as num?)?.toInt() ?? 0
      ..upcomingLyricUseGradient =
          m['upcomingLyricUseGradient'] as bool? ?? false
      ..upcomingLyricGradientStart =
          (m['upcomingLyricGradientStart'] as num?)?.toInt() ?? 0xFF64B5F6
      ..upcomingLyricGradientEnd =
          (m['upcomingLyricGradientEnd'] as num?)?.toInt() ?? 0xFFBBDEFB
      ..upcomingLyricGradientDirectionIndex =
          (m['upcomingLyricGradientDirectionIndex'] as num?)?.toInt() ?? 0;
    final modeListRaw = m['lyricDisplayModeList'];
    if (modeListRaw is List) {
      s.lyricDisplayModeList = modeListRaw.map((e) => '$e').toList();
    }
    s.normalizeLayoutFields();
    return s;
  }
}

