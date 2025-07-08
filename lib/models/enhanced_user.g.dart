// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnhancedUserAdapter extends TypeAdapter<EnhancedUser> {
  @override
  final int typeId = 0;

  @override
  EnhancedUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnhancedUser(
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
      familyAccountId: fields[11] as String?,
      role: fields[12] as UserRole,
      parentUserId: fields[13] as String?,
      userType: fields[14] as UserType,
      preferences: (fields[15] as Map?)?.cast<String, dynamic>(),
      emailVerified: fields[16] as bool,
      emailVerifiedAt: fields[17] as DateTime?,
      phoneNumber: fields[18] as String?,
      emergencyContact: fields[19] as String?,
      profilePicturePath: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EnhancedUser obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.familyAccountId)
      ..writeByte(12)
      ..write(obj.role)
      ..writeByte(13)
      ..write(obj.parentUserId)
      ..writeByte(14)
      ..write(obj.userType)
      ..writeByte(15)
      ..write(obj.preferences)
      ..writeByte(16)
      ..write(obj.emailVerified)
      ..writeByte(17)
      ..write(obj.emailVerifiedAt)
      ..writeByte(18)
      ..write(obj.phoneNumber)
      ..writeByte(19)
      ..write(obj.emergencyContact)
      ..writeByte(20)
      ..write(obj.profilePicturePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 10;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.primary;
      case 1:
        return UserRole.secondary;
      case 2:
        return UserRole.member;
      default:
        return UserRole.primary;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.primary:
        writer.writeByte(0);
        break;
      case UserRole.secondary:
        writer.writeByte(1);
        break;
      case UserRole.member:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserTypeAdapter extends TypeAdapter<UserType> {
  @override
  final int typeId = 11;

  @override
  UserType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserType.child;
      case 1:
        return UserType.teen;
      case 2:
        return UserType.adult;
      case 3:
        return UserType.senior;
      default:
        return UserType.child;
    }
  }

  @override
  void write(BinaryWriter writer, UserType obj) {
    switch (obj) {
      case UserType.child:
        writer.writeByte(0);
        break;
      case UserType.teen:
        writer.writeByte(1);
        break;
      case UserType.adult:
        writer.writeByte(2);
        break;
      case UserType.senior:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
