// lib/services/database_service.dart - Fixed to use EnhancedUser
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/enhanced_user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

// Service principal pour toutes les opérations de base de données
class DatabaseService {
  // === NOMS DES BOÎTES HIVE ===
  static const String _userBoxName = 'users_v2';
  static const String _vaccinationBoxName = 'vaccinations_v2';
  static const String _categoryBoxName = 'vaccine_categories_v2';
  static const String _sessionBoxName = 'session_v2';
  static const String _auditBoxName = 'audit_logs';

  // === GESTION DU CACHE ET PERFORMANCE ===
  static final Map<String, Completer<Box>> _boxCache = {};
  static final Map<String, DateTime> _lastAccess = {};
  
  // === LIMITATION DU TAUX D'OPÉRATIONS ===
  static final Map<String, List<DateTime>> _operationTimestamps = {};
  static const int _maxOperationsPerMinute = 100;

  // Vérifie si une opération respecte les limites de taux
  bool _checkRateLimit(String operation) {
    final now = DateTime.now();
    _operationTimestamps.putIfAbsent(operation, () => []);
    
    // Nettoie les timestamps plus anciens qu'une minute
    _operationTimestamps[operation]!.removeWhere(
      (timestamp) => now.difference(timestamp).inMinutes >= 1
    );
    
    // Vérifie si la limite est dépassée
    if (_operationTimestamps[operation]!.length >= _maxOperationsPerMinute) {
      print('Limite de taux dépassée pour l\'opération: $operation');
      return false;
    }
    
    // Ajoute le timestamp actuel
    _operationTimestamps[operation]!.add(now);
    return true;
  }

  // === SYSTÈME D'AUDIT ===
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
      print('Échec de l\'enregistrement de l\'événement d\'audit: $e');
    }
  }

  // === GESTION SÉCURISÉE DES BOÎTES HIVE ===
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
      print('Boîte ouverte avec succès: $boxName');
      return box;
    } catch (e) {
      print('Échec de l\'ouverture de la boîte $boxName: $e');
      _boxCache.remove(boxName);
      completer.completeError(e);
      rethrow;
    }
  }

  // ==== OPÉRATIONS UTILISATEUR ====
  
  // Sauvegarde un nouvel utilisateur avec validation complète
  Future<void> saveUser(EnhancedUser user) async {
    if (!_checkRateLimit('saveUser')) {
      throw DatabaseException('Limite de taux dépassée pour la création d\'utilisateur');
    }

    try {
      print('=== SAUVEGARDE UTILISATEUR ===');
      print('Utilisateur: ${user.name} (${user.email})');
      print('A un sel: ${user.salt != null && user.salt!.isNotEmpty}');
      print('Données valides: ${user.isDataValid}');

      final box = await _getBox<EnhancedUser>(_userBoxName);
      
      // Vérifie que l'utilisateur n'existe pas déjà
      final existingUser = await _getUserByEmailInternal(user.email);
      if (existingUser != null) {
        throw DatabaseException('Un compte existe déjà avec cette adresse email');
      }
      
      // Valide les données avant sauvegarde
      if (!user.isDataValid) {
        throw DatabaseException('Données utilisateur invalides - sel ou hash manquant');
      }
      
      // Sauvegarde dans la base de données
      final key = await box.add(user);
      print('Utilisateur sauvegardé avec la clé: $key');
      
      // Vérifie que la sauvegarde a réussi
      final savedUser = box.get(key);
      if (savedUser == null) {
        throw DatabaseException('Erreur lors de la sauvegarde de l\'utilisateur');
      }
      
      print('Utilisateur sauvegardé avec succès, données valides');
      
      // Enregistre l'événement dans l'audit
      await _logAuditEvent(
        action: 'CREATE',
        entity: 'User',
        entityId: key.toString(),
        metadata: {'email': user.email, 'name': user.name},
      );
      
      print('===============================');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'utilisateur: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Récupère tous les utilisateurs actifs
  Future<List<EnhancedUser>> getAllUsers() async {
    if (!_checkRateLimit('getAllUsers')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    try {
      final box = await _getBox<EnhancedUser>(_userBoxName);
      final users = box.values.where((user) => user.isActive).toList();
      
      print('=== CHARGEMENT TOUS UTILISATEURS ===');
      print('Total utilisateurs actifs: ${users.length}');
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        print('Utilisateur ${i + 1}: ${user.name} (${user.email})');
        print('  Clé: ${user.key}');
        print('  Dans boîte: ${user.isInBox}');
        print('  A un sel: ${user.salt != null && user.salt!.isNotEmpty}');
        print('  Données valides: ${user.isDataValid}');
      }
      print('===================================');
      
      await _logAuditEvent(
        action: 'READ_ALL',
        entity: 'User',
        metadata: {'count': users.length},
      );
      
      return users;
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      throw DatabaseException('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  // Récupère un utilisateur par son ID
  Future<EnhancedUser?> getUserById(String userId) async {
    try {
      final box = await _getBox<EnhancedUser>(_userBoxName);
      
      final key = int.tryParse(userId);
      if (key == null) {
        print('Format d\'ID utilisateur invalide: $userId');
        return null;
      }
      
      final user = box.get(key);
      
      if (user != null && !user.isActive) {
        print('Utilisateur trouvé mais inactif: ${user.email}');
        return null;
      }
      
      if (user != null) {
        print('Utilisateur trouvé par ID: ${user.name} (${user.email})');
      }
      
      return user;
    } catch (e) {
      print('Erreur lors de la récupération par ID: $e');
      return null;
    }
  }

  // Méthode interne pour chercher un utilisateur par email
  Future<EnhancedUser?> _getUserByEmailInternal(String email) async {
    try {
      final box = await _getBox<EnhancedUser>(_userBoxName);
      final sanitizedEmail = email.trim().toLowerCase();
      
      print('Recherche utilisateur avec email: $sanitizedEmail');
      print('Total utilisateurs dans la boîte: ${box.length}');
      
      for (final user in box.values) {
        if (user.email.toLowerCase() == sanitizedEmail && user.isActive) {
          print('Utilisateur correspondant trouvé: ${user.name}');
          print('  Clé: ${user.key}');
          print('  Dans boîte: ${user.isInBox}');
          print('  A un sel: ${user.salt != null && user.salt!.isNotEmpty}');
          print('  Données valides: ${user.isDataValid}');
          return user;
        }
      }
      
      print('Aucun utilisateur trouvé pour l\'email: $sanitizedEmail');
      return null;
    } catch (e) {
      print('Erreur lors de la recherche par email: $e');
      return null;
    }
  }

  // Version publique de la recherche par email
  Future<EnhancedUser?> getUserByEmail(String email) async {
    if (!_checkRateLimit('getUserByEmail')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    if (email.trim().isEmpty) {
      throw DatabaseException('L\'email ne peut pas être vide');
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

  // Vérifie si un email existe déjà
  Future<bool> emailExists(String email) async {
    if (!_checkRateLimit('emailExists')) {
      return false;
    }

    try {
      final user = await _getUserByEmailInternal(email);
      return user != null;
    } catch (e) {
      print('Erreur lors de la vérification d\'existence d\'email: $e');
      return false;
    }
  }

  // === AUTHENTIFICATION SÉCURISÉE ===
  Future<EnhancedUser?> authenticateUser(String email, String password) async {
    if (!_checkRateLimit('authenticateUser')) {
      throw DatabaseException('Trop de tentatives de connexion. Réessayez plus tard.');
    }

    try {
      if (email.trim().isEmpty || password.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('Authentification échouée: email ou mot de passe vide');
        return null;
      }

      print('=== DEBUG AUTHENTIFICATION ===');
      print('Tentative d\'authentification: $email');
      
      final user = await _getUserByEmailInternal(email);
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('Authentification échouée: utilisateur non trouvé pour: $email');
        return null;
      }
      
      print('Utilisateur trouvé: ${user.name}');
      print('Clé utilisateur: ${user.key}');
      print('Utilisateur dans boîte: ${user.isInBox}');
      print('Sel utilisateur: ${user.salt}');
      print('Longueur hash mot de passe: ${user.passwordHash.length}');

      if (!user.isDataValid) {
        print('Données utilisateur invalides - impossible d\'authentifier');
        print('  Sel manquant: ${user.salt == null || (user.salt != null && user.salt!.isEmpty)}');
        print('  Hash manquant: ${user.passwordHash.isEmpty}');
        print('  Nom manquant: ${user.name.isEmpty}');
        print('  Email manquant: ${user.email.isEmpty}');
        print('==============================');
        
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'email': email, 'reason': 'invalid_user_data'},
        );
        
        return null;
      }

      bool passwordValid = false;
      try {
        passwordValid = user.verifyPassword(password);
      } catch (e) {
        print('La vérification du mot de passe a levé une erreur: $e');
        print('Stack trace: ${StackTrace.current}');
        print('==============================');
        
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'email': email, 'reason': 'verification_error', 'error': e.toString()},
        );
        
        return null;
      }

      if (!passwordValid) {
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'email': email, 'reason': 'invalid_password'},
        );
        await Future.delayed(const Duration(milliseconds: 500));
        print('Authentification échouée: mot de passe invalide pour: $email');
        print('==============================');
        return null;
      }

      print('Authentification réussie pour: $email');

      try {
        if (user.isInBox && user.key != null) {
          user.lastLogin = DateTime.now();
          await user.save();
          print('Heure de dernière connexion mise à jour pour: ${user.email}');
        } else {
          print('Attention: utilisateur pas correctement persisté dans la boîte');
          user.lastLogin = DateTime.now();
        }
      } catch (saveError) {
        print('Attention: impossible de sauvegarder l\'heure de connexion: $saveError');
      }
      
      await _logAuditEvent(
        action: 'LOGIN',
        entity: 'User',
        entityId: user.key?.toString() ?? 'unknown',
        metadata: {'email': email},
      );

      print('==============================');
      return user;
      
    } catch (e) {
      print('Erreur d\'authentification: $e');
      print('Stack trace: ${StackTrace.current}');
      
      await _logAuditEvent(
        action: 'LOGIN_ERROR',
        entity: 'System',
        metadata: {'email': email, 'error': e.toString()},
      );
      
      throw DatabaseException('Erreur d\'authentification: Une erreur interne s\'est produite');
    }
  }

  // === GESTION DES SESSIONS ===
  
  Future<EnhancedUser?> getCurrentUser() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final currentUserKey = sessionBox.get('currentUserKey');
      
      if (currentUserKey != null) {
        print('Récupération utilisateur actuel avec clé: $currentUserKey');
        
        if (await isSessionValid()) {
          final user = await getUserById(currentUserKey.toString());
          if (user != null) {
            print('Utilisateur actuel trouvé: ${user.email}');
            return user;
          } else {
            print('Aucun utilisateur trouvé pour la clé: $currentUserKey');
            await clearCurrentUser();
          }
        } else {
          print('Session expirée, nettoyage...');
          await clearCurrentUser();
        }
      }
      
      print('Aucune session utilisateur actuelle trouvée');
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur actuel: $e');
      return null;
    }
  }

  Future<void> setCurrentUser(EnhancedUser user) async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      
      print('=== DEBUG CRÉATION SESSION ===');
      print('Définition utilisateur actuel: ${user.email}');
      
      String? userKey;
      
      if (user.isInBox && user.key != null) {
        userKey = user.key.toString();
        print('Utilisation clé utilisateur existante: $userKey');
      } else {
        print('Utilisateur pas dans boîte, recherche par email: ${user.email}');
        final foundUser = await _getUserByEmailInternal(user.email);
        if (foundUser != null && foundUser.isInBox && foundUser.key != null) {
          userKey = foundUser.key.toString();
          print('Utilisateur trouvé avec clé: $userKey');
          user = foundUser;
        } else {
          print('Tentative de sauvegarde d\'utilisateur d\'abord...');
          final box = await _getBox<EnhancedUser>(_userBoxName);
          final newKey = await box.add(user);
          userKey = newKey.toString();
          print('Utilisateur sauvegardé avec nouvelle clé: $userKey');
        }
      }
      
      if (userKey == null) {
        throw DatabaseException('Impossible de créer une session: utilisateur invalide');
      }
      
      await sessionBox.put('currentUserKey', userKey);
      await sessionBox.put('sessionStart', DateTime.now().toIso8601String());
      
      print('Session créée pour clé utilisateur: $userKey');
      print('===============================');
      
      await _logAuditEvent(
        action: 'SESSION_START',
        entity: 'User',
        entityId: userKey,
        userId: userKey,
      );
    } catch (e) {
      print('Erreur de création de session: $e');
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
      
      print('Session effacée');
    } catch (e) {
      print('Erreur de nettoyage de session: $e');
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
      print('Erreur lors de la vérification de validité de session: $e');
      return false;
    }
  }

  // === OPÉRATIONS DE VACCINATION ===
  
  Future<void> saveVaccination(Vaccination vaccination) async {
    if (!_checkRateLimit('saveVaccination')) {
      throw DatabaseException('Limite de taux dépassée');
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
      
      print('Vaccination sauvegardée: ${vaccination.vaccineName} pour utilisateur ${vaccination.userId}');
      
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
      print('Erreur lors de la sauvegarde de vaccination: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la sauvegarde de la vaccination: $e');
    }
  }

  Future<List<Vaccination>> getAllVaccinations() async {
    if (!_checkRateLimit('getAllVaccinations')) {
      throw DatabaseException('Limite de taux dépassée');
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
      throw DatabaseException('Limite de taux dépassée');
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
      
      print('${vaccinations.length} vaccinations trouvées pour utilisateur $userId');
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
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return DateTime.now();
  }

  Future<void> deleteVaccination(String vaccinationId) async {
    if (!_checkRateLimit('deleteVaccination')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    try {
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      
      final key = int.tryParse(vaccinationId);
      if (key == null) {
        throw DatabaseException('ID de vaccination invalide');
      }
      
      final vaccination = box.get(key);
      
      if (vaccination == null) {
        throw DatabaseException('Vaccination introuvable');
      }
      
      await box.delete(key);
      
      print('Vaccination supprimée: ${vaccination.vaccineName}');
      
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

  // === OPÉRATIONS DE CATÉGORIES DE VACCINS ===
  
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
        print('Initialisation des catégories de vaccins par défaut...');
        
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
        
        print('Catégories par défaut initialisées avec succès');
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des catégories par défaut: $e');
    }
  }

  // === MAINTENANCE ===
  
  Future<Map<String, int>> cleanupDatabase() async {
    if (!_checkRateLimit('cleanupDatabase')) {
      throw DatabaseException('Limite de taux dépassée pour le nettoyage');
    }

    try {
      int duplicatesRemoved = 0;
      int orphanedVaccinationsRemoved = 0;
      int corruptUsersFixed = 0;
      
      print('=== NETTOYAGE BASE DE DONNÉES DÉMARRÉ ===');
      
      final userBox = await _getBox<EnhancedUser>(_userBoxName);
      final emailToUsers = <String, List<EnhancedUser>>{};
      
      print('Total utilisateurs avant nettoyage: ${userBox.length}');
      
      for (final user in userBox.values) {
        if (!user.isDataValid) {
          print('Utilisateur corrompu trouvé: ${user.email} (sel ou hash manquant)');
        } else {
          emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
        }
      }
      
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('${users.length} utilisateurs en double trouvés pour: ${users.first.email}');
          
          for (int i = 1; i < users.length; i++) {
            try {
              if (users[i].isInBox) {
                await users[i].delete();
                duplicatesRemoved++;
                print('Utilisateur en double supprimé: ${users[i].email}');
              }
            } catch (e) {
              print('Erreur lors de la suppression d\'utilisateur en double: $e');
            }
          }
        }
      }
      
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
          print('Erreur lors de la suppression de vaccination orpheline: $e');
        }
      }
      
      await _cleanupOldSessions();
      await _cleanupOldAuditLogs();
      
      print('Nettoyage terminé:');
      print('- Doublons supprimés: $duplicatesRemoved');
      print('- Vaccinations orphelines supprimées: $orphanedVaccinationsRemoved');
      print('- Utilisateurs corrompus détectés: $corruptUsersFixed');
      print('=======================================');
      
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
      print('Erreur de nettoyage: $e');
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
          print('Anciennes données de session effacées');
        }
      }
    } catch (e) {
      print('Échec du nettoyage des anciennes sessions: $e');
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
          keysToDelete.add(entry.key);
        }
      }
      
      for (final key in keysToDelete) {
        try {
          await auditBox.delete(key);
        } catch (e) {
          print('Erreur lors de la suppression de log d\'audit: $e');
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        print('${keysToDelete.length} anciens logs d\'audit nettoyés');
      }
    } catch (e) {
      print('Échec du nettoyage des anciens logs d\'audit: $e');
    }
  }

  Future<void> dispose() async {
    try {
      print('Libération du service de base de données...');
      
      for (final boxName in _boxCache.keys) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
            print('Boîte fermée: $boxName');
          }
        } catch (e) {
          print('Erreur lors de la fermeture de boîte $boxName: $e');
        }
      }
      
      _boxCache.clear();
      _lastAccess.clear();
      _operationTimestamps.clear();
      
      print('Service de base de données libéré avec succès');
    } catch (e) {
      print('Erreur lors de la libération: $e');
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