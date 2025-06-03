// lib/models/user.dart
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  @HiveField(3)
  String dateOfBirth;

  @HiveField(4)
  String? diseases;

  @HiveField(5)
  String? treatments;

  @HiveField(6)
  String? allergies;

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.dateOfBirth,
    this.diseases,
    this.treatments,
    this.allergies,
  });
}