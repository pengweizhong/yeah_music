import 'package:flutter/painting.dart' show TextAlign;
import 'package:hive/hive.dart';

part 'lyric_settings.g.dart';

@HiveType(typeId: 2)
class LyricSettings extends HiveObject {
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

  LyricSettings();

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

  // Convert Color to int for storage
  static int colorToInt(int color) => color;

  // Convert int to Color
  static int intToColor(int value) => value;
}
