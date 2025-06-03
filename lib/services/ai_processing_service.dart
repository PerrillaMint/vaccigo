// lib/services/database_service.dart
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

class DatabaseService {
  static const String _userBoxName = 'users';
  static const String _vaccinationBoxName = 'vaccinations';
  static const String _categoryBoxName = 'vaccine_categories';

  // User operations
  Future<void> saveUser(User user) async {
    final box = await Hive.openBox<User>(_userBoxName);
    await box.add(user);
  }

  Future<List<User>> getAllUsers() async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.values.toList();
  }

  Future<User?> getUser(int index) async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.getAt(index);
  }

  Future<User?> getCurrentUser() async {
    final box = await Hive.openBox<User>(_userBoxName);
    if (box.values.isNotEmpty) {
      return box.values.first;
    }
    return null;
  }

  // Vaccination operations
  Future<void> saveVaccination(Vaccination vaccination) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    await box.add(vaccination);
  }

  Future<List<Vaccination>> getVaccinationsByUser(String userId) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    return box.values.where((v) => v.userId == userId).toList();
  }

  Future<List<Vaccination>> getAllVaccinations() async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    return box.values.toList();
  }

  // Vaccine Category operations
  Future<void> saveVaccineCategory(VaccineCategory category) async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    await box.add(category);
  }

  Future<List<VaccineCategory>> getAllVaccineCategories() async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    return box.values.toList();
  }

  Future<void> initializeDefaultCategories() async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    
    // Only initialize if empty
    if (box.isEmpty) {
      // This would typically be loaded from a remote server or config
      // but for now we'll initialize with empty lists that can be populated by admin
      await box.add(VaccineCategory(
        name: 'Vaccins obligatoires',
        iconType: 'check_circle',
        colorHex: '4CAF50',
        vaccines: [],
      ));
      
      await box.add(VaccineCategory(
        name: 'Vaccins recommandés',
        iconType: 'recommend',
        colorHex: 'FF9800',
        vaccines: [],
      ));
      
      await box.add(VaccineCategory(
        name: 'Je voyage',
        iconType: 'flight',
        colorHex: '2196F3',
        vaccines: [],
      ));
    }
  }

  Future<void> updateVaccineCategory(int index, VaccineCategory category) async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    await box.putAt(index, category);
  }

  Future<void> deleteVaccination(int index) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    await box.deleteAt(index);
  }
}
