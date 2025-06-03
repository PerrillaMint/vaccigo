// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaccinationAdapter extends TypeAdapter<Vaccination> {
  @override
  final int typeId = 1;

  @override
  Vaccination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vaccination(
      vaccineName: fields[0] as String,
      lot: fields[1] as String,
      date: fields[2] as String,
      ps: fields[3] as String,
      userId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Vaccination obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.vaccineName)
      ..writeByte(1)
      ..write(obj.lot)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.ps)
      ..writeByte(4)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
