
// lib/models/vaccine_category.dart
import 'package:hive/hive.dart';

part 'vaccine_category.g.dart';

@HiveType(typeId: 2)
class VaccineCategory extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String iconType;

  @HiveField(2)
  String colorHex;

  @HiveField(3)
  List<String> vaccines;

  VaccineCategory({
    required this.name,
    required this.iconType,
    required this.colorHex,
    required this.vaccines,
  });
}