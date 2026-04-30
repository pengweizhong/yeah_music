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
      ..showOriginal = fields[0] as bool
      ..showTranslations = fields[1] as bool
      ..originalFontSize = fields[2] as double
      ..translationFontSize = fields[3] as double
      ..activeOriginalColor = fields[4] as int
      ..activeTranslationColor = fields[5] as int
      ..playedOriginalColor = fields[6] as int
      ..playedTranslationColor = fields[7] as int
      ..upcomingOriginalColor = fields[8] as int
      ..upcomingTranslationColor = fields[9] as int
      ..lyricDisplayModeList = (fields[10] as List).cast<String>()
      ..lyricLineSpacing = fields[11] as double
      ..lyricTextAlignIndex = (fields[12] as int?) ?? 1
      ..activeLyricUseGradient = fields[13] as bool? ?? false
      ..activeLyricGradientStart = fields[14] as int? ?? 0xFFFFFFFF
      ..activeLyricGradientEnd = fields[15] as int? ?? 0xFFFFB74D
      ..activeLyricGradientDirectionIndex = fields[16] as int? ?? 0
      ..playedLyricUseGradient = fields[17] as bool? ?? false
      ..playedLyricGradientStart = fields[18] as int? ?? 0xFF81C784
      ..playedLyricGradientEnd = fields[19] as int? ?? 0xFFC8E6C9
      ..playedLyricGradientDirectionIndex = fields[20] as int? ?? 0
      ..upcomingLyricUseGradient = fields[21] as bool? ?? false
      ..upcomingLyricGradientStart = fields[22] as int? ?? 0xFF64B5F6
      ..upcomingLyricGradientEnd = fields[23] as int? ?? 0xFFBBDEFB
      ..upcomingLyricGradientDirectionIndex = fields[24] as int? ?? 0;
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
