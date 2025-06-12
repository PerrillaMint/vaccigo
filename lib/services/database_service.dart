// lib/services/database_service.dart - Enhanced with Current User Management
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

class DatabaseService {
  static const String _userBoxName = 'users';
  static const String _vaccinationBoxName = 'vaccinations';
  static const String _categoryBoxName = 'vaccine_categories';
  static const String _sessionBoxName = 'session';

  // ==== USER OPERATIONS ====
  
  // Create/Save User with email validation
  Future<void> saveUser(User user) async {
    final box = await Hive.openBox<User>(_userBoxName);
    
    // Check if email already exists
    final existingUser = await getUserByEmail(user.email);
    if (existingUser != null) {
      throw Exception('Un compte existe déjà avec cette adresse email');
    }
    
    await box.add(user);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.values.toList();
  }

  // Get user by index
  Future<User?> getUser(int index) async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.getAt(index);
  }

  // Get current user (from session)
  Future<User?> getCurrentUser() async {
    try {
      final sessionBox = await Hive.openBox(_sessionBoxName);
      final currentUserKey = sessionBox.get('currentUserKey');
      
      if (currentUserKey != null) {
        final userBox = await Hive.openBox<User>(_userBoxName);
        return userBox.get(currentUserKey);
      }
      
      // Fallback to first user if no session (for backward compatibility)
      final userBox = await Hive.openBox<User>(_userBoxName);
      if (userBox.values.isNotEmpty) {
        return userBox.values.first;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Set current user (for login session)
  Future<void> setCurrentUser(User user) async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.put('currentUserKey', user.key);
  }

  // Clear current user session (for logout)
  Future<void> clearCurrentUser() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.delete('currentUserKey');
  }

  // Update user with email validation
  Future<void> updateUser(int index, User user) async {
    final box = await Hive.openBox<User>(_userBoxName);
    
    // Check if email already exists (excluding current user)
    final existingUser = await getUserByEmail(user.email);
    if (existingUser != null && existingUser.key != user.key) {
      throw Exception('Un compte existe déjà avec cette adresse email');
    }
    
    await box.putAt(index, user);
  }

  // Delete user
  Future<void> deleteUser(int index) async {
    final box = await Hive.openBox<User>(_userBoxName);
    final user = box.getAt(index);
    
    // Clear session if deleting current user
    if (user != null) {
      final currentUser = await getCurrentUser();
      if (currentUser?.key == user.key) {
        await clearCurrentUser();
      }
    }
    
    await box.deleteAt(index);
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final box = await Hive.openBox<User>(_userBoxName);
    try {
      return box.values.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // Remove duplicate users (keep the first one for each email)
  Future<int> removeDuplicateUsers() async {
    final box = await Hive.openBox<User>(_userBoxName);
    final users = box.values.toList();
    final seenEmails = <String>{};
    final duplicateIndices = <int>[];
    
    for (int i = 0; i < users.length; i++) {
      final email = users[i].email.toLowerCase();
      if (seenEmails.contains(email)) {
        duplicateIndices.add(i);
      } else {
        seenEmails.add(email);
      }
    }
    
    // Remove duplicates in reverse order to maintain indices
    for (int i = duplicateIndices.length - 1; i >= 0; i--) {
      await box.deleteAt(duplicateIndices[i]);
    }
    
    return duplicateIndices.length;
  }

  // Get unique users (helper method)
  Future<List<User>> getUniqueUsers() async {
    await removeDuplicateUsers(); // Clean up first
    return getAllUsers();
  }

  // ==== VACCINATION OPERATIONS ====
  
  // Save vaccination
  Future<void> saveVaccination(Vaccination vaccination) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    await box.add(vaccination);
  }

  // Get vaccinations by user ID
  Future<List<Vaccination>> getVaccinationsByUser(String userId) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    return box.values.where((v) => v.userId == userId).toList();
  }

  // Get all vaccinations
  Future<List<Vaccination>> getAllVaccinations() async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    return box.values.toList();
  }

  // Update vaccination
  Future<void> updateVaccination(int index, Vaccination vaccination) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    await box.putAt(index, vaccination);
  }

  // Delete vaccination
  Future<void> deleteVaccination(int index) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    await box.deleteAt(index);
  }

  // Get vaccinations by vaccine name
  Future<List<Vaccination>> getVaccinationsByVaccine(String vaccineName) async {
    final box = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    return box.values.where((v) => 
      v.vaccineName.toLowerCase().contains(vaccineName.toLowerCase())
    ).toList();
  }

  // ==== VACCINE CATEGORY OPERATIONS ====
  
  // Save vaccine category
  Future<void> saveVaccineCategory(VaccineCategory category) async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    await box.add(category);
  }

  // Get all vaccine categories
  Future<List<VaccineCategory>> getAllVaccineCategories() async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    return box.values.toList();
  }

  // Update vaccine category
  Future<void> updateVaccineCategory(int index, VaccineCategory category) async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    await box.putAt(index, category);
  }

  // Delete vaccine category
  Future<void> deleteVaccineCategory(int index) async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    await box.deleteAt(index);
  }

  // ==== SESSION MANAGEMENT ====
  
  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }

  // Get current user's vaccinations
  Future<List<Vaccination>> getCurrentUserVaccinations() async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      return getVaccinationsByUser(currentUser.key.toString());
    }
    return [];
  }

  // ==== DATABASE MANAGEMENT ====
  
  // Clear all data
  Future<void> clearAllData() async {
    final userBox = await Hive.openBox<User>(_userBoxName);
    final vaccinationBox = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    final categoryBox = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    final sessionBox = await Hive.openBox(_sessionBoxName);
    
    await userBox.clear();
    await vaccinationBox.clear();
    await categoryBox.clear();
    await sessionBox.clear();
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final userBox = await Hive.openBox<User>(_userBoxName);
    final vaccinationBox = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    final categoryBox = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    
    return {
      'users': userBox.length,
      'vaccinations': vaccinationBox.length,
      'categories': categoryBox.length,
    };
  }

  // Export data as JSON
  Future<Map<String, dynamic>> exportData() async {
    final users = await getAllUsers();
    final vaccinations = await getAllVaccinations();
    final categories = await getAllVaccineCategories();
    
    return {
      'users': users.map((u) => {
        'name': u.name,
        'email': u.email,
        'dateOfBirth': u.dateOfBirth,
        'diseases': u.diseases,
        'treatments': u.treatments,
        'allergies': u.allergies,
      }).toList(),
      'vaccinations': vaccinations.map((v) => {
        'vaccineName': v.vaccineName,
        'lot': v.lot,
        'date': v.date,
        'ps': v.ps,
        'userId': v.userId,
      }).toList(),
      'categories': categories.map((c) => {
        'name': c.name,
        'iconType': c.iconType,
        'colorHex': c.colorHex,
        'vaccines': c.vaccines,
      }).toList(),
    };
  }

  // Initialize default categories
  Future<void> initializeDefaultCategories() async {
    final box = await Hive.openBox<VaccineCategory>(_categoryBoxName);
    
    if (box.isEmpty) {
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

  // Clean up database (remove duplicates and orphaned data)
  Future<Map<String, int>> cleanupDatabase() async {
    final duplicatesRemoved = await removeDuplicateUsers();
    
    // Remove vaccinations for non-existent users
    final users = await getAllUsers();
    final userIds = users.map((u) => u.key.toString()).toSet();
    
    final vaccinationBox = await Hive.openBox<Vaccination>(_vaccinationBoxName);
    final vaccinationsToRemove = <int>[];
    
    for (int i = 0; i < vaccinationBox.length; i++) {
      final vaccination = vaccinationBox.getAt(i);
      if (vaccination != null && !userIds.contains(vaccination.userId)) {
        vaccinationsToRemove.add(i);
      }
    }
    
    // Remove orphaned vaccinations in reverse order
    for (int i = vaccinationsToRemove.length - 1; i >= 0; i--) {
      await vaccinationBox.deleteAt(vaccinationsToRemove[i]);
    }
    
    return {
      'duplicateUsersRemoved': duplicatesRemoved,
      'orphanedVaccinationsRemoved': vaccinationsToRemove.length,
    };
  }

  // ==== PASSWORD RESET FUNCTIONALITY ====
  
  // Simulate password reset (in real app, this would trigger email)
  Future<bool> requestPasswordReset(String email) async {
    final user = await getUserByEmail(email);
    if (user != null) {
      // In a real app, this would:
      // 1. Generate a secure reset token
      // 2. Store it with expiration time
      // 3. Send email with reset link
      // For demo purposes, we'll just return true
      return true;
    }
    return false;
  }

  // Update user password (for password reset)
  Future<void> updateUserPassword(String email, String newPassword) async {
    final user = await getUserByEmail(email);
    if (user != null) {
      user.password = newPassword;
      await user.save();
    } else {
      throw Exception('Utilisateur non trouvé');
    }
  }
}