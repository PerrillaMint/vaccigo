// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelAdapter extends TypeAdapter<Travel> {
  @override
  final int typeId = 3;

  @override
  Travel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Travel(
      destination: fields[0] as String,
      startDate: fields[1] as String,
      endDate: fields[2] as String,
      userId: fields[3] as String,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Travel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.destination)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
