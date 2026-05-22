// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyric_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricSettingsAdapter extends TypeAdapter<LyricSettings> {
  @override
  final int typeId = 2;

  @override
  LyricSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricSettings()
      ..showOriginal = fields[0] == null ? true : fields[0] as bool
      ..showTranslations = fields[1] == null ? true : fields[1] as bool
      ..originalFontSize = fields[2] == null ? 20.0 : fields[2] as double
      ..translationFontSize = fields[3] == null ? 14.0 : fields[3] as double
      ..activeOriginalColor = fields[4] == null ? 4294967295 : fields[4] as int
      ..activeTranslationColor =
          fields[5] == null ? 4291875024 : fields[5] as int
      ..playedOriginalColor = fields[6] == null ? 4289769648 : fields[6] as int
      ..playedTranslationColor =
          fields[7] == null ? 4287664272 : fields[7] as int
      ..upcomingOriginalColor =
          fields[8] == null ? 4286216826 : fields[8] as int
      ..upcomingTranslationColor =
          fields[9] == null ? 4285164138 : fields[9] as int
      ..lyricDisplayModeList =
          fields[10] == null ? [] : (fields[10] as List).cast<String>()
      ..lyricLineSpacing = fields[11] == null ? 12.0 : fields[11] as double
      ..lyricTextAlignIndex = fields[12] == null ? 1 : fields[12] as int
      ..activeLyricUseGradient = fields[13] == null ? false : fields[13] as bool
      ..activeLyricGradientStart =
          fields[14] == null ? 4294967295 : fields[14] as int
      ..activeLyricGradientEnd =
          fields[15] == null ? 4294948685 : fields[15] as int
      ..activeLyricGradientDirectionIndex =
          fields[16] == null ? 0 : fields[16] as int
      ..playedLyricUseGradient = fields[17] == null ? false : fields[17] as bool
      ..playedLyricGradientStart =
          fields[18] == null ? 4286695300 : fields[18] as int
      ..playedLyricGradientEnd =
          fields[19] == null ? 4291356361 : fields[19] as int
      ..playedLyricGradientDirectionIndex =
          fields[20] == null ? 0 : fields[20] as int
      ..upcomingLyricUseGradient =
          fields[21] == null ? false : fields[21] as bool
      ..upcomingLyricGradientStart =
          fields[22] == null ? 4284790262 : fields[22] as int
      ..upcomingLyricGradientEnd =
          fields[23] == null ? 4290502395 : fields[23] as int
      ..upcomingLyricGradientDirectionIndex =
          fields[24] == null ? 0 : fields[24] as int;
  }

  @override
  void write(BinaryWriter writer, LyricSettings obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.showOriginal)
      ..writeByte(1)
      ..write(obj.showTranslations)
      ..writeByte(2)
      ..write(obj.originalFontSize)
      ..writeByte(3)
      ..write(obj.translationFontSize)
      ..writeByte(4)
      ..write(obj.activeOriginalColor)
      ..writeByte(5)
      ..write(obj.activeTranslationColor)
      ..writeByte(6)
      ..write(obj.playedOriginalColor)
      ..writeByte(7)
      ..write(obj.playedTranslationColor)
      ..writeByte(8)
      ..write(obj.upcomingOriginalColor)
      ..writeByte(9)
      ..write(obj.upcomingTranslationColor)
      ..writeByte(10)
      ..write(obj.lyricDisplayModeList)
      ..writeByte(11)
      ..write(obj.lyricLineSpacing)
      ..writeByte(12)
      ..write(obj.lyricTextAlignIndex)
      ..writeByte(13)
      ..write(obj.activeLyricUseGradient)
      ..writeByte(14)
      ..write(obj.activeLyricGradientStart)
      ..writeByte(15)
      ..write(obj.activeLyricGradientEnd)
      ..writeByte(16)
      ..write(obj.activeLyricGradientDirectionIndex)
      ..writeByte(17)
      ..write(obj.playedLyricUseGradient)
      ..writeByte(18)
      ..write(obj.playedLyricGradientStart)
      ..writeByte(19)
      ..write(obj.playedLyricGradientEnd)
      ..writeByte(20)
      ..write(obj.playedLyricGradientDirectionIndex)
      ..writeByte(21)
      ..write(obj.upcomingLyricUseGradient)
      ..writeByte(22)
      ..write(obj.upcomingLyricGradientStart)
      ..writeByte(23)
      ..write(obj.upcomingLyricGradientEnd)
      ..writeByte(24)
      ..write(obj.upcomingLyricGradientDirectionIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
