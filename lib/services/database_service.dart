// lib/services/database_service.dart - FIXED with security and error handling
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

class DatabaseService {
  static const String _userBoxName = 'users_v2'; // FIXED: Version box names
  static const String _vaccinationBoxName = 'vaccinations_v2';
  static const String _categoryBoxName = 'vaccine_categories_v2';
  static const String _sessionBoxName = 'session_v2';
  static const String _auditBoxName = 'audit_logs'; // FIXED: Add audit logging

  // FIXED: Add connection pooling and error handling
  static final Map<String, Completer<Box>> _boxCache = {};
  static final Map<String, DateTime> _lastAccess = {};
  
  // FIXED: Rate limiting to prevent abuse
  static final Map<String, List<DateTime>> _operationTimestamps = {};
  static const int _maxOperationsPerMinute = 100;

  // ==== SECURITY & VALIDATION ====
  
  bool _checkRateLimit(String operation) {
    final now = DateTime.now();
    _operationTimestamps.putIfAbsent(operation, () => []);
    
    // Remove old timestamps (older than 1 minute)
    _operationTimestamps[operation]!.removeWhere(
      (timestamp) => now.difference(timestamp).inMinutes >= 1
    );
    
    // Check if limit exceeded
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
      // Don't throw - audit logging shouldn't break app
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

  // FIXED: Cleanup unused boxes to prevent memory leaks
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

  // ==== USER OPERATIONS (SECURED) ====
  
  Future<void> saveUser(User user) async {
    if (!_checkRateLimit('saveUser')) {
      throw DatabaseException('Rate limit exceeded for user creation');
    }

    try {
      final box = await _getBox<User>(_userBoxName);
      
      // FIXED: Check if email already exists with better error handling
      final existingUser = await _getUserByEmailInternal(user.email);
      if (existingUser != null) {
        throw DatabaseException('Un compte existe déjà avec cette adresse email');
      }
      
      await box.add(user);
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'User',
        entityId: user.key?.toString(),
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

  Future<User?> getUserById(String userId) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      final user = box.get(userId);
      
      if (user != null && !user.isActive) {
        return null; // Don't return deactivated users
      }
      
      return user;
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // FIXED: Private method for internal email lookup (no rate limiting)
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
      throw DatabaseException('Erreur lors de la recherche par email: $e');
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
      return false; // Conservative approach for rate limiting
    }

    final user = await _getUserByEmailInternal(email);
    return user != null;
  }

  // FIXED: Secure login with password verification
  Future<User?> authenticateUser(String email, String password) async {
    if (!_checkRateLimit('authenticateUser')) {
      throw DatabaseException('Trop de tentatives de connexion. Réessayez plus tard.');
    }

    try {
      final user = await _getUserByEmailInternal(email);
      if (user == null) {
        // FIXED: Don't reveal if email exists
        await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
        return null;
      }

      if (!user.verifyPassword(password)) {
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString(),
          metadata: {'email': email, 'reason': 'invalid_password'},
        );
        return null;
      }

      // Update last login
      user.updateLastLogin();
      
      await _logAuditEvent(
        action: 'LOGIN',
        entity: 'User',
        entityId: user.key?.toString(),
        metadata: {'email': email},
      );

      return user;
    } catch (e) {
      throw DatabaseException('Erreur d\'authentification: $e');
    }
  }

  // ==== SESSION MANAGEMENT (SECURED) ====
  
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

  Future<void> setCurrentUser(User user) async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      await sessionBox.put('currentUserKey', user.key?.toString());
      await sessionBox.put('sessionStart', DateTime.now().toIso8601String());
      
      await _logAuditEvent(
        action: 'SESSION_START',
        entity: 'User',
        entityId: user.key?.toString(),
        userId: user.key?.toString(),
      );
    } catch (e) {
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
      throw DatabaseException('Erreur lors de la déconnexion: $e');
    }
  }

  // FIXED: Session timeout check
  Future<bool> isSessionValid() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final sessionStartStr = sessionBox.get('sessionStart') as String?;
      
      if (sessionStartStr == null) return false;
      
      final sessionStart = DateTime.parse(sessionStartStr);
      final now = DateTime.now();
      
      // Session expires after 24 hours
      return now.difference(sessionStart).inHours < 24;
    } catch (e) {
      return false;
    }
  }

  // ==== VACCINATION OPERATIONS (SECURED) ====
  
  Future<void> saveVaccination(Vaccination vaccination) async {
    if (!_checkRateLimit('saveVaccination')) {
      throw DatabaseException('Rate limit exceeded');
    }

    try {
      // FIXED: Validate vaccination data
      if (vaccination.vaccineName.trim().isEmpty) {
        throw DatabaseException('Le nom du vaccin est requis');
      }
      if (vaccination.userId.trim().isEmpty) {
        throw DatabaseException('Utilisateur invalide');
      }

      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      await box.add(vaccination);
      
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'Vaccination',
        entityId: vaccination.key?.toString(),
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
      
      // FIXED: Sort by date (most recent first)
      vaccinations.sort((a, b) {
        try {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0; // Keep original order if date parsing fails
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
      final vaccination = box.get(vaccinationId);
      
      if (vaccination == null) {
        throw DatabaseException('Vaccination introuvable');
      }
      
      await box.delete(vaccinationId);
      
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

  // ==== DATABASE MAINTENANCE (SECURED) ====
  
  Future<Map<String, int>> cleanupDatabase() async {
    if (!_checkRateLimit('cleanupDatabase')) {
      throw DatabaseException('Rate limit exceeded for cleanup');
    }

    try {
      int duplicatesRemoved = 0;
      int orphanedVaccinationsRemoved = 0;
      
      // FIXED: Remove duplicate users (keep most recent)
      final userBox = await _getBox<User>(_userBoxName);
      final emailToUsers = <String, List<User>>{};
      
      // Group users by email
      for (final user in userBox.values) {
        emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
      }
      
      // Remove duplicates (keep the most recently created)
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Keep the first (most recent), remove others
          for (int i = 1; i < users.length; i++) {
            await users[i].delete();
            duplicatesRemoved++;
          }
        }
      }
      
      // FIXED: Remove orphaned vaccinations
      final vaccinationBox = await _getBox<Vaccination>(_vaccinationBoxName);
      final activeUserIds = userBox.values
          .where((user) => user.isActive)
          .map((user) => user.key?.toString())
          .where((id) => id != null)
          .toSet();
      
      final orphanedVaccinations = <String>[];
      for (final vaccination in vaccinationBox.values) {
        if (!activeUserIds.contains(vaccination.userId)) {
          orphanedVaccinations.add(vaccination.key.toString());
        }
      }
      
      for (final id in orphanedVaccinations) {
        await vaccinationBox.delete(id);
        orphanedVaccinationsRemoved++;
      }
      
      // FIXED: Cleanup old sessions and audit logs
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
        final log = entry.value as Map;
        final timestamp = DateTime.parse(log['timestamp'] as String);
        if (timestamp.isBefore(cutoffDate)) {
          keysToDelete.add(entry.key);
        }
      }
      
      for (final key in keysToDelete) {
        await auditBox.delete(key);
      }
    } catch (e) {
      print('Failed to cleanup old audit logs: $e');
    }
  }

  // FIXED: Secure data export (without sensitive information)
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
        'user': user.toSafeJson(), // Uses safe JSON without sensitive data
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

  // FIXED: Resource cleanup
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

// FIXED: Custom exception for database errors
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