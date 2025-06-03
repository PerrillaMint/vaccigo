// lib/models/vaccination.dart
import 'package:hive/hive.dart';

part 'vaccination.g.dart';

@HiveType(typeId: 1)
class Vaccination extends HiveObject {
  @HiveField(0)
  String vaccineName;

  @HiveField(1)
  String lot;

  @HiveField(2)
  String date;

  @HiveField(3)
  String ps;

  @HiveField(4)
  String userId;

  Vaccination({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.userId,
  });
}