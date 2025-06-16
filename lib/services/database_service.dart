// lib/services/database_service.dart - FIXED authentication and user management
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

class DatabaseService {
  static const String _userBoxName = 'users_v2';
  static const String _vaccinationBoxName = 'vaccinations_v2';
  static const String _categoryBoxName = 'vaccine_categories_v2';
  static const String _sessionBoxName = 'session_v2';
  static const String _auditBoxName = 'audit_logs';

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
      return box;
    } catch (e) {
      _boxCache.remove(boxName);
      completer.completeError(e);
      rethrow;
    }
  }

  Future<void> _cleanupUnusedBoxes() async {
    final now = DateTime.now();
    final boxesToClose = <String>[];
    
    for (final entry in _lastAccess.entries) {
      if (now.difference(entry.value).inMinutes > 30) {
        boxesToClose.add(entry.key);
      }
    }
    
    for (final boxName in boxesToClose) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        _boxCache.remove(boxName);
        _lastAccess.remove(boxName);
      } catch (e) {
        print('Failed to close box $boxName: $e');
      }
    }
  }

  // ==== USER OPERATIONS ====
  
  Future<void> saveUser(User user) async {
    if (!_checkRateLimit('saveUser')) {
      throw DatabaseException('Rate limit exceeded for user creation');
    }

    try {
      final box = await _getBox<User>(_userBoxName);
      
      final existingUser = await _getUserByEmailInternal(user.email);
      if (existingUser != null) {
        throw DatabaseException('Un compte existe déjà avec cette adresse email');
      }
      
      // FIXED: Save user to box and ensure it has a key
      final key = await box.add(user);
      
      // FIXED: Ensure the user object is properly attached to the box
      await user.save(); // This ensures the user is fully persisted
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'User',
        entityId: key.toString(),
        metadata: {'email': user.email, 'name': user.name},
      );
    } catch (e) {
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
      
      await _logAuditEvent(
        action: 'READ_ALL',
        entity: 'User',
        metadata: {'count': users.length},
      );
      
      return users;
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  Future<List<User>> getUniqueUsers() async {
    try {
      final allUsers = await getAllUsers();
      final uniqueUsers = <String, User>{};
      
      // Keep only one user per email (most recent)
      for (final user in allUsers) {
        final email = user.email.toLowerCase();
        if (!uniqueUsers.containsKey(email) || 
            user.createdAt.isAfter(uniqueUsers[email]!.createdAt)) {
          uniqueUsers[email] = user;
        }
      }
      
      return uniqueUsers.values.toList();
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des utilisateurs uniques: $e');
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      
      // FIXED: Parse userId safely
      final key = int.tryParse(userId);
      if (key == null) return null;
      
      final user = box.get(key);
      
      if (user != null && !user.isActive) {
        return null;
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
      
      for (final user in box.values) {
        if (user.email.toLowerCase() == sanitizedEmail && user.isActive) {
          return user;
        }
      }
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
        entityId: user.key?.toString(),
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

  // FIXED: Completely rewritten authentication method to handle null cases properly
  Future<User?> authenticateUser(String email, String password) async {
    if (!_checkRateLimit('authenticateUser')) {
      throw DatabaseException('Trop de tentatives de connexion. Réessayez plus tard.');
    }

    try {
      // Input validation
      if (email.trim().isEmpty || password.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
        return null;
      }

      final user = await _getUserByEmailInternal(email);
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        return null;
      }

      if (!user.verifyPassword(password)) {
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString(),
          metadata: {'email': email, 'reason': 'invalid_password'},
        );
        await Future.delayed(const Duration(milliseconds: 500));
        return null;
      }

      // FIXED: Safe update of last login without calling save() if user isn't properly persisted
      try {
        if (user.key != null) {
          // User is properly saved in Hive, safe to update
          user.lastLogin = DateTime.now();
          await user.save();
        } else {
          // User exists but might not be properly saved, just update in memory
          user.lastLogin = DateTime.now();
        }
      } catch (saveError) {
        // If save fails, just log but don't fail authentication
        print('Warning: Could not save last login time: $saveError');
      }
      
      await _logAuditEvent(
        action: 'LOGIN',
        entity: 'User',
        entityId: user.key?.toString(),
        metadata: {'email': email},
      );

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
        final user = await getUserById(currentUserKey);
        return user;
      }
      
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // FIXED: Safer session management
  Future<void> setCurrentUser(User user) async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      
      // FIXED: Ensure user has a key before setting session
      String userKey;
      if (user.key != null) {
        userKey = user.key.toString();
      } else {
        // If user doesn't have a key, try to find it by email
        final foundUser = await _getUserByEmailInternal(user.email);
        if (foundUser?.key != null) {
          userKey = foundUser!.key.toString();
        } else {
          throw DatabaseException('Utilisateur non sauvegardé dans la base de données');
        }
      }
      
      await sessionBox.put('currentUserKey', userKey);
      await sessionBox.put('sessionStart', DateTime.now().toIso8601String());
      
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
          entityId: currentUserKey,
          userId: currentUserKey,
        );
      }
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
      
      vaccinations.sort((a, b) {
        try {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      
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
      
      // FIXED: Parse key safely
      final key = int.tryParse(vaccinationId);
      if (key == null) {
        throw DatabaseException('ID de vaccination invalide');
      }
      
      final vaccination = box.get(key);
      
      if (vaccination == null) {
        throw DatabaseException('Vaccination introuvable');
      }
      
      await box.delete(key);
      
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

  Future<void> deleteVaccinationByIndex(int index) async {
    try {
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      final keys = box.keys.toList();
      
      if (index >= 0 && index < keys.length) {
        await deleteVaccination(keys[index].toString());
      } else {
        throw DatabaseException('Index de vaccination invalide');
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la suppression par index: $e');
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
      }
    } catch (e) {
      print('Error initializing default categories: $e');
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
      
      final userBox = await _getBox<User>(_userBoxName);
      final emailToUsers = <String, List<User>>{};
      
      for (final user in userBox.values) {
        emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
      }
      
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          for (int i = 1; i < users.length; i++) {
            try {
              await users[i].delete();
              duplicatesRemoved++;
            } catch (e) {
              print('Error deleting duplicate user: $e');
            }
          }
        }
      }
      
      final vaccinationBox = await _getBox<Vaccination>(_vaccinationBoxName);
      final activeUserIds = userBox.values
          .where((user) => user.isActive)
          .map((user) => user.key?.toString())
          .where((id) => id != null)
          .cast<String>()
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
      
      await _cleanupOldSessions();
      await _cleanupOldAuditLogs();
      
      await _logAuditEvent(
        action: 'CLEANUP',
        entity: 'Database',
        metadata: {
          'duplicatesRemoved': duplicatesRemoved,
          'orphanedVaccinationsRemoved': orphanedVaccinationsRemoved,
        },
      );
      
      return {
        'duplicateUsersRemoved': duplicatesRemoved,
        'orphanedVaccinationsRemoved': orphanedVaccinationsRemoved,
      };
    } catch (e) {
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
    } catch (e) {
      print('Failed to cleanup old audit logs: $e');
    }
  }

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
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de l\'export: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _cleanupUnusedBoxes();
      _boxCache.clear();
      _lastAccess.clear();
      _operationTimestamps.clear();
    } catch (e) {
      print('Error during disposal: $e');
    }
  }
}

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