// lib/models/travel.dart
import 'package:hive/hive.dart';

part 'travel.g.dart';

@HiveType(typeId: 3)
class Travel extends HiveObject {
  @HiveField(0)
  String destination;

  @HiveField(1)
  String startDate;

  @HiveField(2)
  String endDate;

  @HiveField(3)
  String userId;

  @HiveField(4)
  String? notes;

  Travel({
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.userId,
    this.notes,
  });
}
