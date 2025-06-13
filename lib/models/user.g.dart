// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      name: fields[0] as String,
      email: fields[1] as String,
      passwordHash: fields[2] as String,
      dateOfBirth: fields[3] as String,
      diseases: fields[4] as String?,
      treatments: fields[5] as String?,
      allergies: fields[6] as String?,
      salt: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      lastLogin: fields[9] as DateTime?,
      isActive: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.passwordHash)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.diseases)
      ..writeByte(5)
      ..write(obj.treatments)
      ..writeByte(6)
      ..write(obj.allergies)
      ..writeByte(7)
      ..write(obj.salt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastLogin)
      ..writeByte(10)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
