// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 1;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      fields[0] as String,
    )
      ..title = fields[1] as String?
      ..album = fields[2] as String?
      ..year = fields[3] as DateTime?
      ..artist = fields[4] as String?
      ..imageBytes = fields[7] as Uint8List?
      ..createDateTime = fields[8] as DateTime?
      ..updateDateTime = fields[9] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.album)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.artist)
      ..writeByte(5)
      ..write(obj.performers)
      ..writeByte(7)
      ..write(obj.imageBytes)
      ..writeByte(8)
      ..write(obj.createDateTime)
      ..writeByte(9)
      ..write(obj.updateDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
