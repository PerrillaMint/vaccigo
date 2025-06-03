// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccine_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaccineCategoryAdapter extends TypeAdapter<VaccineCategory> {
  @override
  final int typeId = 2;

  @override
  VaccineCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaccineCategory(
      name: fields[0] as String,
      iconType: fields[1] as String,
      colorHex: fields[2] as String,
      vaccines: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VaccineCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.iconType)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.vaccines);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccineCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
