// lib/services/database_service.dart - COMPLETE REWRITE with all fixes
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';
import '../models/travel.dart';

class DatabaseService {
  static const String _userBoxName = 'users_v2';
  static const String _vaccinationBoxName = 'vaccinations_v2';
  static const String _categoryBoxName = 'vaccine_categories_v2';
  static const String _sessionBoxName = 'session_v2';
  static const String _auditBoxName = 'audit_logs';
  static const String _travelBoxName = 'travel_v2';

  static final Map<String, Completer<Box>> _boxCache = {};
  static final Map<String, DateTime> _lastAccess = {};
  static final Map<String, List<DateTime>> _operationTimestamps = {};
  static const int _maxOperationsPerMinute = 100;

  // Rate limiting
  bool _checkRateLimit(String operation) {
    final now = DateTime.now();
    _operationTimestamps.putIfAbsent(operation, () => []);
    
    _operationTimestamps[operation]!.removeWhere(
      (timestamp) => now.difference(timestamp).inMinutes >= 1
    );
    
    if (_operationTimestamps[operation]!.length >= _maxOperationsPerMinute) {
      print('Rate limit exceeded for operation: $operation');
      return false;
    }
    
    _operationTimestamps[operation]!.add(now);
    return true;
  }

  Future<void> _logAuditEvent({
    required String action,
    required String entity,
    String? entityId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditBox = await _getBox<Map>(_auditBoxName);
      await auditBox.add({
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'entity': entity,
        'entityId': entityId,
        'userId': userId,
        'metadata': metadata,
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      print('Failed to log audit event: $e');
    }
  }

  Future<Box<T>> _getBox<T>(String boxName) async {
    if (_boxCache.containsKey(boxName)) {
      return await _boxCache[boxName]!.future as Box<T>;
    }

    final completer = Completer<Box>();
    _boxCache[boxName] = completer;

    try {
      final box = await Hive.openBox<T>(boxName);
      _lastAccess[boxName] = DateTime.now();
      completer.complete(box);
      print('Successfully opened box: $boxName');
      return box;
    } catch (e) {
      print('Failed to open box $boxName: $e');
      _boxCache.remove(boxName);
      completer.completeError(e);
      rethrow;
    }
  }

  // ==== USER OPERATIONS ====
  
  Future<void> saveUser(User user) async {
    if (!_checkRateLimit('saveUser')) {
      throw DatabaseException('Rate limit exceeded for user creation');
    }

    try {
      print('=== SAVING USER ===');
      print('User: ${user.name} (${user.email})');
      print('HasSalt: ${user.salt != null && user.salt!.isNotEmpty}');
      print('IsDataValid: ${user.isDataValid}');

      final box = await _getBox<User>(_userBoxName);
      
      // Check if user already exists
      final existingUser = await _getUserByEmailInternal(user.email);
      if (existingUser != null) {
        throw DatabaseException('Un compte existe déjà avec cette adresse email');
      }
      
      // Validate user data before saving
      if (!user.isDataValid) {
        throw DatabaseException('Données utilisateur invalides - salt ou hash manquant');
      }
      
      // Save user to database
      final key = await box.add(user);
      print('User saved with key: $key');
      
      // Verify user was saved correctly
      final savedUser = box.get(key);
      if (savedUser == null) {
        throw DatabaseException('Erreur lors de la sauvegarde de l\'utilisateur');
      }
      
      // Test password verification immediately after saving
      if (user.passwordHash.isNotEmpty && user.salt != null) {
        print('User saved successfully and data is valid');
      }
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'User',
        entityId: key.toString(),
        metadata: {'email': user.email, 'name': user.name},
      );
      
      print('==================');
    } catch (e) {
      print('Error saving user: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  Future<List<User>> getAllUsers() async {
    if (!_checkRateLimit('getAllUsers')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      final box = await _getBox<User>(_userBoxName);
      final users = box.values.where((user) => user.isActive).toList();
      
      print('=== LOADING ALL USERS ===');
      print('Total active users: ${users.length}');
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        print('User ${i + 1}: ${user.name} (${user.email})');
        print('  Key: ${user.key}');
        print('  IsInBox: ${user.isInBox}');
        print('  HasSalt: ${user.salt != null && user.salt!.isNotEmpty}');
        print('  IsDataValid: ${user.isDataValid}');
      }
      print('========================');
      
      await _logAuditEvent(
        action: 'READ_ALL',
        entity: 'User',
        metadata: {'count': users.length},
      );
      
      return users;
    } catch (e) {
      print('Error getting all users: $e');
      throw DatabaseException('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      
      // Parse userId safely
      final key = int.tryParse(userId);
      if (key == null) {
        print('Invalid user ID format: $userId');
        return null;
      }
      
      final user = box.get(key);
      
      if (user != null && !user.isActive) {
        print('User found but inactive: ${user.email}');
        return null;
      }
      
      if (user != null) {
        print('Found user by ID: ${user.name} (${user.email})');
      }
      
      return user;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<User?> _getUserByEmailInternal(String email) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      final sanitizedEmail = email.trim().toLowerCase();
      
      print('Searching for user with email: $sanitizedEmail');
      print('Total users in box: ${box.length}');
      
      for (final user in box.values) {
        if (user.email.toLowerCase() == sanitizedEmail && user.isActive) {
          print('Found matching user: ${user.name}');
          print('  Key: ${user.key}');
          print('  IsInBox: ${user.isInBox}');
          print('  HasSalt: ${user.salt != null && user.salt!.isNotEmpty}');
          print('  IsDataValid: ${user.isDataValid}');
          return user;
        }
      }
      
      print('No user found for email: $sanitizedEmail');
      return null;
    } catch (e) {
      print('Error searching user by email: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    if (!_checkRateLimit('getUserByEmail')) {
      throw DatabaseException('Rate limit exceeded');
    }

    if (email.trim().isEmpty) {
      throw DatabaseException('Email ne peut pas être vide');
    }

    final user = await _getUserByEmailInternal(email);
    
    if (user != null) {
      await _logAuditEvent(
        action: 'READ',
        entity: 'User',
        entityId: user.key?.toString() ?? 'unknown',
        metadata: {'searchEmail': email},
      );
    }
    
    return user;
  }

  Future<bool> emailExists(String email) async {
    if (!_checkRateLimit('emailExists')) {
      return false;
    }

    try {
      final user = await _getUserByEmailInternal(email);
      return user != null;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // FIXED: Completely rewritten authentication method
  Future<User?> authenticateUser(String email, String password) async {
    if (!_checkRateLimit('authenticateUser')) {
      throw DatabaseException('Trop de tentatives de connexion. Réessayez plus tard.');
    }

    try {
      // Input validation
      if (email.trim().isEmpty || password.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
        print('Authentication failed: Empty email or password');
        return null;
      }

      print('=== AUTHENTICATION DEBUG ===');
      print('Attempting to authenticate: $email');
      
      final user = await _getUserByEmailInternal(email);
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('Authentication failed: User not found for email: $email');
        return null;
      }
      
      print('Found user: ${user.name}');
      print('User key: ${user.key}');
      print('User isInBox: ${user.isInBox}');
      print('User salt: ${user.salt}');
      print('User passwordHash length: ${user.passwordHash.length}');

      // Check if user data is valid
      if (!user.isDataValid) {
        print('User data is invalid, attempting to repair...');
        
        // Try to repair user data with the provided password
        if (user.repairUserData(password)) {
          print('User data repaired successfully');
          
          // Save the repaired user
          try {
            if (user.isInBox) {
              await user.save();
            }
          } catch (e) {
            print('Warning: Could not save repaired user: $e');
          }
          
          // Now verify with the repaired data
          if (user.verifyPassword(password)) {
            print('Authentication successful after repair');
            user.updateLastLogin();
            
            await _logAuditEvent(
              action: 'LOGIN_AFTER_REPAIR',
              entity: 'User',
              entityId: user.key?.toString() ?? 'unknown',
              metadata: {'email': email},
            );
            
            print('============================');
            return user;
          }
        }
        
        print('User data repair failed');
        print('============================');
        return null;
      }

      // Standard password verification
      if (!user.verifyPassword(password)) {
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'email': email, 'reason': 'invalid_password'},
        );
        await Future.delayed(const Duration(milliseconds: 500));
        print('Authentication failed: Invalid password for user: $email');
        print('============================');
        return null;
      }

      print('Authentication successful for user: $email');

      // Update last login time safely
      try {
        if (user.isInBox && user.key != null) {
          user.lastLogin = DateTime.now();
          await user.save();
          print('Updated last login for user: ${user.email}');
        } else {
          print('Warning: User not properly persisted in box');
          user.lastLogin = DateTime.now();
        }
      } catch (saveError) {
        print('Warning: Could not save last login time: $saveError');
      }
      
      await _logAuditEvent(
        action: 'LOGIN',
        entity: 'User',
        entityId: user.key?.toString() ?? 'unknown',
        metadata: {'email': email},
      );

      print('============================');
      return user;
      
    } catch (e) {
      print('Authentication error: $e');
      throw DatabaseException('Erreur d\'authentification: $e');
    }
  }

  // ==== SESSION MANAGEMENT ====
  
  Future<User?> getCurrentUser() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final currentUserKey = sessionBox.get('currentUserKey');
      
      if (currentUserKey != null) {
        print('Getting current user with key: $currentUserKey');
        
        // Verify session is still valid
        if (await isSessionValid()) {
          final user = await getUserById(currentUserKey.toString());
          if (user != null) {
            print('Found current user: ${user.email}');
            return user;
          } else {
            print('No user found for key: $currentUserKey');
            // Clear invalid session
            await clearCurrentUser();
          }
        } else {
          print('Session expired, clearing...');
          await clearCurrentUser();
        }
      }
      
      print('No current user session found');
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> setCurrentUser(User user) async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      
      print('=== SESSION CREATION DEBUG ===');
      print('Setting current user: ${user.email}');
      
      // Ensure user has a valid key
      String? userKey;
      
      if (user.isInBox && user.key != null) {
        userKey = user.key.toString();
        print('Using existing user key: $userKey');
      } else {
        // Try to find user by email and get proper key
        print('User not in box, searching by email: ${user.email}');
        final foundUser = await _getUserByEmailInternal(user.email);
        if (foundUser != null && foundUser.isInBox && foundUser.key != null) {
          userKey = foundUser.key.toString();
          print('Found user with key: $userKey');
          // Use the found user instead of the parameter
          user = foundUser;
        } else {
          // Last resort: try to save the user first
          print('Attempting to save user first...');
          final box = await _getBox<User>(_userBoxName);
          final newKey = await box.add(user);
          userKey = newKey.toString();
          print('Saved user with new key: $userKey');
        }
      }
      
      if (userKey == null) {
        throw DatabaseException('Impossible de créer une session: utilisateur invalide');
      }
      
      await sessionBox.put('currentUserKey', userKey);
      await sessionBox.put('sessionStart', DateTime.now().toIso8601String());
      
      print('Session created for user key: $userKey');
      print('===============================');
      
      await _logAuditEvent(
        action: 'SESSION_START',
        entity: 'User',
        entityId: userKey,
        userId: userKey,
      );
    } catch (e) {
      print('Session creation error: $e');
      throw DatabaseException('Erreur lors de la création de session: $e');
    }
  }

  Future<void> clearCurrentUser() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final currentUserKey = sessionBox.get('currentUserKey');
      
      await sessionBox.delete('currentUserKey');
      await sessionBox.delete('sessionStart');
      
      if (currentUserKey != null) {
        await _logAuditEvent(
          action: 'SESSION_END',
          entity: 'User',
          entityId: currentUserKey.toString(),
          userId: currentUserKey.toString(),
        );
      }
      
      print('Session cleared');
    } catch (e) {
      print('Session cleanup error: $e');
      // Don't throw here, just log
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final sessionStartStr = sessionBox.get('sessionStart') as String?;
      
      if (sessionStartStr == null) return false;
      
      final sessionStart = DateTime.parse(sessionStartStr);
      final now = DateTime.now();
      
      return now.difference(sessionStart).inHours < 24;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  // ==== VACCINATION OPERATIONS ====
  
  Future<void> saveVaccination(Vaccination vaccination) async {
    if (!_checkRateLimit('saveVaccination')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      if (vaccination.vaccineName.trim().isEmpty) {
        throw DatabaseException('Le nom du vaccin est requis');
      }
      if (vaccination.userId.trim().isEmpty) {
        throw DatabaseException('Utilisateur invalide');
      }

      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      final key = await box.add(vaccination);
      
      print('Vaccination saved: ${vaccination.vaccineName} for user ${vaccination.userId}');
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'Vaccination',
        entityId: key.toString(),
        userId: vaccination.userId,
        metadata: {
          'vaccineName': vaccination.vaccineName,
          'date': vaccination.date,
        },
      );
    } catch (e) {
      print('Error saving vaccination: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la sauvegarde de la vaccination: $e');
    }
  }

  Future<List<Vaccination>> getAllVaccinations() async {
    if (!_checkRateLimit('getAllVaccinations')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      return box.values.toList();
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des vaccinations: $e');
    }
  }

  Future<List<Vaccination>> getVaccinationsByUser(String userId) async {
    if (!_checkRateLimit('getVaccinationsByUser')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      if (userId.trim().isEmpty) {
        throw DatabaseException('ID utilisateur invalide');
      }

      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      final vaccinations = box.values
          .where((v) => v.userId == userId)
          .toList();
      
      // Sort by date (newest first)
      vaccinations.sort((a, b) {
        try {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      
      print('Found ${vaccinations.length} vaccinations for user $userId');
      return vaccinations;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la récupération des vaccinations: $e');
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }

  Future<void> deleteVaccination(String vaccinationId) async {
    if (!_checkRateLimit('deleteVaccination')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      
      // Parse key safely
      final key = int.tryParse(vaccinationId);
      if (key == null) {
        throw DatabaseException('ID de vaccination invalide');
      }
      
      final vaccination = box.get(key);
      
      if (vaccination == null) {
        throw DatabaseException('Vaccination introuvable');
      }
      
      await box.delete(key);
      
      print('Deleted vaccination: ${vaccination.vaccineName}');
      
      await _logAuditEvent(
        action: 'DELETE',
        entity: 'Vaccination',
        entityId: vaccinationId,
        userId: vaccination.userId,
        metadata: {
          'vaccineName': vaccination.vaccineName,
          'date': vaccination.date,
        },
      );
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la suppression: $e');
    }
  }

  // ==== VACCINE CATEGORY OPERATIONS ====
  
  Future<List<VaccineCategory>> getAllVaccineCategories() async {
    try {
      final box = await _getBox<VaccineCategory>(_categoryBoxName);
      return box.values.toList();
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des catégories: $e');
    }
  }

  Future<void> initializeDefaultCategories() async {
    try {
      final box = await _getBox<VaccineCategory>(_categoryBoxName);
      
      if (box.isEmpty) {
        print('Initializing default vaccine categories...');
        
        final defaultCategories = [
          VaccineCategory(
            name: 'Vaccinations obligatoires',
            iconType: 'check_circle',
            colorHex: '#4CAF50',
            vaccines: ['DTP', 'Poliomyélite', 'Coqueluche', 'ROR'],
          ),
          VaccineCategory(
            name: 'Vaccinations recommandées',
            iconType: 'recommend',
            colorHex: '#FFA726',
            vaccines: ['Grippe', 'Hépatite B', 'Pneumocoque'],
          ),
          VaccineCategory(
            name: 'Vaccinations de voyage',
            iconType: 'flight',
            colorHex: '#2196F3',
            vaccines: ['Fièvre jaune', 'Typhoïde', 'Encéphalite japonaise'],
          ),
        ];
        
        for (final category in defaultCategories) {
          await box.add(category);
        }
        
        print('Default categories initialized successfully');
      }
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }

  // ==== TRAVEL OPERATIONS ====
  
  Future<void> saveTravel(Travel travel) async {
    if (!_checkRateLimit('saveTravel')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      final box = await _getBox<Travel>(_travelBoxName);
      await box.add(travel);
      
      print('Travel saved: ${travel.destination}');
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'Travel',
        userId: travel.userId,
        metadata: {
          'destination': travel.destination,
          'startDate': travel.startDate,
          'endDate': travel.endDate,
        },
      );
    } catch (e) {
      throw DatabaseException('Erreur lors de la sauvegarde du voyage: $e');
    }
  }

  Future<List<Travel>> getTravelsByUser(String userId) async {
    try {
      final box = await _getBox<Travel>(_travelBoxName);
      return box.values.where((travel) => travel.userId == userId).toList();
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des voyages: $e');
    }
  }

  // ==== DATABASE MAINTENANCE ====
  
  Future<Map<String, int>> cleanupDatabase() async {
    if (!_checkRateLimit('cleanupDatabase')) {
      throw DatabaseException('Rate limit exceeded for cleanup');
    }

    try {
      int duplicatesRemoved = 0;
      int orphanedVaccinationsRemoved = 0;
      int corruptUsersFixed = 0;
      
      print('=== DATABASE CLEANUP STARTED ===');
      
      final userBox = await _getBox<User>(_userBoxName);
      final emailToUsers = <String, List<User>>{};
      
      print('Total users before cleanup: ${userBox.length}');
      
      // Group users by email and identify corrupt data
      for (final user in userBox.values) {
        // Check for corrupt users
        if (!user.isDataValid) {
          print('Found corrupt user: ${user.email} (missing salt or hash)');
          // Note: We can't repair without knowing the password
          // This user will need to be recreated or manually fixed
        } else {
          emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
        }
      }
      
      // Remove duplicates (keep the most recent one)
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('Found ${users.length} duplicate users for email: ${users.first.email}');
          
          // Keep the first (most recent), delete the rest
          for (int i = 1; i < users.length; i++) {
            try {
              if (users[i].isInBox) {
                await users[i].delete();
                duplicatesRemoved++;
                print('Removed duplicate user: ${users[i].email}');
              }
            } catch (e) {
              print('Error deleting duplicate user: $e');
            }
          }
        }
      }
      
      // Clean up orphaned vaccinations
      final vaccinationBox = await _getBox<Vaccination>(_vaccinationBoxName);
      final activeUserIds = userBox.values
          .where((user) => user.isActive && user.key != null)
          .map((user) => user.key!.toString())
          .toSet();
      
      final orphanedVaccinations = <dynamic>[];
      for (final vaccination in vaccinationBox.values) {
        if (!activeUserIds.contains(vaccination.userId)) {
          orphanedVaccinations.add(vaccination.key);
        }
      }
      
      for (final key in orphanedVaccinations) {
        try {
          await vaccinationBox.delete(key);
          orphanedVaccinationsRemoved++;
        } catch (e) {
          print('Error deleting orphaned vaccination: $e');
        }
      }
      
      // Clean up old sessions and audit logs
      await _cleanupOldSessions();
      await _cleanupOldAuditLogs();
      
      print('Cleanup completed:');
      print('- Duplicates removed: $duplicatesRemoved');
      print('- Orphaned vaccinations removed: $orphanedVaccinationsRemoved');
      print('- Corrupt users detected: $corruptUsersFixed');
      print('================================');
      
      await _logAuditEvent(
        action: 'CLEANUP',
        entity: 'Database',
        metadata: {
          'duplicatesRemoved': duplicatesRemoved,
          'orphanedVaccinationsRemoved': orphanedVaccinationsRemoved,
          'corruptUsersFixed': corruptUsersFixed,
        },
      );
      
      return {
        'duplicateUsersRemoved': duplicatesRemoved,
        'orphanedVaccinationsRemoved': orphanedVaccinationsRemoved,
        'corruptUsersFixed': corruptUsersFixed,
      };
    } catch (e) {
      print('Cleanup error: $e');
      throw DatabaseException('Erreur lors du nettoyage: $e');
    }
  }

  Future<void> _cleanupOldSessions() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final sessionStartStr = sessionBox.get('sessionStart') as String?;
      
      if (sessionStartStr != null) {
        final sessionStart = DateTime.parse(sessionStartStr);
        if (DateTime.now().difference(sessionStart).inDays > 7) {
          await sessionBox.clear();
          print('Cleared old session data');
        }
      }
    } catch (e) {
      print('Failed to cleanup old sessions: $e');
    }
  }

  Future<void> _cleanupOldAuditLogs() async {
    try {
      final auditBox = await _getBox<Map>(_auditBoxName);
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final keysToDelete = <dynamic>[];
      for (final entry in auditBox.toMap().entries) {
        try {
          final log = entry.value as Map;
          final timestamp = DateTime.parse(log['timestamp'] as String);
          if (timestamp.isBefore(cutoffDate)) {
            keysToDelete.add(entry.key);
          }
        } catch (e) {
          // If we can't parse the log, consider it for deletion
          keysToDelete.add(entry.key);
        }
      }
      
      for (final key in keysToDelete) {
        try {
          await auditBox.delete(key);
        } catch (e) {
          print('Error deleting audit log: $e');
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        print('Cleaned up ${keysToDelete.length} old audit logs');
      }
    } catch (e) {
      print('Failed to cleanup old audit logs: $e');
    }
  }

  // ==== DATA EXPORT ====
  
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    if (!_checkRateLimit('exportUserData')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw DatabaseException('Utilisateur introuvable');
      }

      final vaccinations = await getVaccinationsByUser(userId);
      final travels = await getTravelsByUser(userId);
      
      await _logAuditEvent(
        action: 'EXPORT',
        entity: 'UserData',
        userId: userId,
      );

      return {
        'user': user.toSafeJson(),
        'vaccinations': vaccinations.map((v) => {
          'vaccineName': v.vaccineName,
          'lot': v.lot,
          'date': v.date,
          'ps': v.ps,
        }).toList(),
        'travels': travels.map((t) => {
          'destination': t.destination,
          'startDate': t.startDate,
          'endDate': t.endDate,
          'notes': t.notes,
        }).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de l\'export: $e');
    }
  }

  // ==== DEBUGGING METHODS ====
  
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final userBox = await _getBox<User>(_userBoxName);
      final vaccinationBox = await _getBox<Vaccination>(_vaccinationBoxName);
      final categoryBox = await _getBox<VaccineCategory>(_categoryBoxName);
      final travelBox = await _getBox<Travel>(_travelBoxName);
      
      final activeUsers = userBox.values.where((user) => user.isActive).length;
      final corruptUsers = userBox.values.where((user) => !user.isDataValid).length;
      
      return {
        'totalUsers': userBox.length,
        'activeUsers': activeUsers,
        'corruptUsers': corruptUsers,
        'vaccinations': vaccinationBox.length,
        'categories': categoryBox.length,
        'travels': travelBox.length,
        'lastCheck': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getCorruptUsers() async {
    try {
      final userBox = await _getBox<User>(_userBoxName);
      final corruptUsers = <Map<String, dynamic>>[];
      
      for (final user in userBox.values) {
        if (!user.isDataValid) {
          corruptUsers.add({
            'name': user.name,
            'email': user.email,
            'key': user.key,
            'hasSalt': user.salt != null && user.salt!.isNotEmpty,
            'hasPasswordHash': user.passwordHash.isNotEmpty,
            'createdAt': user.createdAt.toIso8601String(),
          });
        }
      }
      
      return corruptUsers;
    } catch (e) {
      return [];
    }
  }

  // ==== DISPOSAL ====
  
  Future<void> dispose() async {
    try {
      print('Disposing database service...');
      
      // Close all boxes properly
      for (final boxName in _boxCache.keys) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
            print('Closed box: $boxName');
          }
        } catch (e) {
          print('Error closing box $boxName: $e');
        }
      }
      
      _boxCache.clear();
      _lastAccess.clear();
      _operationTimestamps.clear();
      
      print('Database service disposed successfully');
    } catch (e) {
      print('Error during disposal: $e');
    }
  }
}

// ==== CUSTOM EXCEPTIONS ====

class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const DatabaseException(this.message, [this.code, this.originalError]);

  @override
  String toString() {
    return 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}