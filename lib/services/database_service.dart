// lib/services/database_service.dart - Service base de données corrigé et sécurisé
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/enhanced_user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';

class DatabaseService {
  // === NOMS DES BOÎTES AVEC VERSIONING ===
  static const String _userBoxName = 'enhanced_users_v2'; // UPDATED version
  static const String _vaccinationBoxName = 'vaccinations_v3'; // UPDATED version
  static const String _categoryBoxName = 'vaccine_categories_v3';
  static const String _sessionBoxName = 'session_v3';
  static const String _auditBoxName = 'audit_logs_v1';

  // === CACHE ET PERFORMANCE ===
  static final Map<String, Box> _openBoxes = {};
  static final Map<String, Completer<Box>> _boxCache = {};
  static bool _isInitialized = false;

  // === INITIALISATION SÉCURISÉE ===
  Future<void> initializeDatabase() async {
    if (_isInitialized) return;
    
    try {
      print('🔧 Initialisation de la base de données...');
      
      // Nettoie les anciennes boîtes corrompues
      await _cleanupCorruptedBoxes();
      
      // Initialise les nouvelles boîtes
      await _initializeBoxes();
      
      _isInitialized = true;
      print('✅ Base de données initialisée avec succès');
    } catch (e) {
      print('❌ Erreur initialisation base de données: $e');
      rethrow;
    }
  }

  Future<void> _cleanupCorruptedBoxes() async {
    final corruptedBoxes = [
      'enhanced_users_v1',
      'vaccinations_v2', 
      'vaccine_categories_v2',
      'session_v2',
    ];
    
    for (final boxName in corruptedBoxes) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        if (await Hive.boxExists(boxName)) {
          await Hive.deleteBoxFromDisk(boxName);
          print('🧹 Boîte corrompue supprimée: $boxName');
        }
      } catch (e) {
        print('⚠️ Erreur nettoyage $boxName: $e');
      }
    }
  }

  Future<void> _initializeBoxes() async {
    // Pré-ouvre les boîtes principales
    await _getBox<EnhancedUser>(_userBoxName);
    await _getBox<Vaccination>(_vaccinationBoxName);
    await _getBox<VaccineCategory>(_categoryBoxName);
    await _getBox(_sessionBoxName);
  }

  // === GESTION SÉCURISÉE DES BOÎTES ===
  Future<Box<T>> _getBox<T>(String boxName) async {
    // Vérifie le cache
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]! as Box<T>;
    }

    // Vérifie les opérations en cours
    if (_boxCache.containsKey(boxName)) {
      return await _boxCache[boxName]!.future as Box<T>;
    }

    final completer = Completer<Box>();
    _boxCache[boxName] = completer;

    try {
      // Ferme la boîte si elle est ouverte avec un mauvais type
      if (Hive.isBoxOpen(boxName)) {
        try {
          await Hive.box(boxName).close();
        } catch (e) {
          print('⚠️ Erreur fermeture boîte existante $boxName: $e');
        }
      }

      // Ouvre avec le bon type
      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
      
      completer.complete(box);
      return box;
    } catch (e) {
      print('❌ Erreur ouverture $boxName: $e');
      
      // Tente de supprimer et recréer la boîte corrompue
      try {
        await Hive.deleteBoxFromDisk(boxName);
        final box = await Hive.openBox<T>(boxName);
        _openBoxes[boxName] = box;
        completer.complete(box);
        print('✅ Boîte recréée: $boxName');
        return box;
      } catch (recreateError) {
        completer.completeError(recreateError);
        _boxCache.remove(boxName);
        rethrow;
      }
    } finally {
      _boxCache.remove(boxName);
    }
  }

  // === OPÉRATIONS UTILISATEUR AMÉLIORÉES ===
  
  Future<void> saveUser(EnhancedUser user) async {
    try {
      await initializeDatabase();
      
      print('💾 Sauvegarde utilisateur: ${user.email}');
      
      // Validation des données
      if (user.email.trim().isEmpty) {
        throw DatabaseException('Email requis');
      }
      if (user.name.trim().isEmpty) {
        throw DatabaseException('Nom requis');
      }
      if (user.passwordHash.isEmpty) {
        throw DatabaseException('Mot de passe requis');
      }

      final box = await _getBox<EnhancedUser>(_userBoxName);
      
      // Vérifie l'unicité de l'email
      final existingUser = await _findUserByEmail(user.email);
      if (existingUser != null) {
        throw DatabaseException('Un compte existe déjà avec cet email');
      }
      
      // Sauvegarde
      final key = await box.add(user);
      print('✅ Utilisateur sauvegardé avec la clé: $key');
      
      await _logAuditEvent(
        action: 'CREATE_USER',
        entity: 'User',
        entityId: key.toString(),
        metadata: {'email': user.email, 'name': user.name},
      );
      
    } catch (e) {
      print('❌ Erreur sauvegarde utilisateur: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur création utilisateur: $e');
    }
  }

  Future<EnhancedUser?> _findUserByEmail(String email) async {
    try {
      final box = await _getBox<EnhancedUser>(_userBoxName);
      final lowerEmail = email.trim().toLowerCase();
      
      for (final user in box.values) {
        if (user.email.toLowerCase() == lowerEmail && user.isActive) {
          return user;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur recherche email: $e');
      return null;
    }
  }

  Future<List<EnhancedUser>> getAllUsers() async {
    try {
      await initializeDatabase();
      final box = await _getBox<EnhancedUser>(_userBoxName);
      
      final users = box.values.where((user) => user.isActive).toList();
      print('📋 ${users.length} utilisateur(s) actif(s) trouvé(s)');
      
      return users;
    } catch (e) {
      print('❌ Erreur récupération utilisateurs: $e');
      throw DatabaseException('Erreur récupération utilisateurs: $e');
    }
  }

  Future<EnhancedUser?> getUserById(String userId) async {
    try {
      await initializeDatabase();
      final box = await _getBox<EnhancedUser>(_userBoxName);
      
      final key = int.tryParse(userId);
      if (key == null) return null;
      
      final user = box.get(key);
      return (user?.isActive == true) ? user : null;
    } catch (e) {
      print('❌ Erreur getUserById: $e');
      return null;
    }
  }

  Future<EnhancedUser?> getUserByEmail(String email) async {
    try {
      await initializeDatabase();
      
      if (email.trim().isEmpty) {
        throw DatabaseException('Email vide');
      }
      
      final user = await _findUserByEmail(email);
      
      if (user != null) {
        await _logAuditEvent(
          action: 'READ_USER',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
        );
      }
      
      return user;
    } catch (e) {
      print('❌ Erreur getUserByEmail: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur recherche utilisateur: $e');
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      final user = await _findUserByEmail(email);
      return user != null;
    } catch (e) {
      print('❌ Erreur emailExists: $e');
      return false;
    }
  }

  // === AUTHENTIFICATION ROBUSTE ===
  Future<EnhancedUser?> authenticateUser(String email, String password) async {
    try {
      await initializeDatabase();
      
      if (email.trim().isEmpty || password.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        return null;
      }

      print('🔐 Tentative authentification: $email');
      
      final user = await _findUserByEmail(email);
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('❌ Utilisateur non trouvé');
        return null;
      }
      
      print('👤 Utilisateur trouvé: ${user.name}');
      
      // Vérifie les données utilisateur
      if (!user.isDataValid) {
        print('❌ Données utilisateur invalides');
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'reason': 'invalid_data', 'email': email},
        );
        return null;
      }

      // Vérifie le mot de passe
      bool passwordValid = false;
      try {
        passwordValid = user.verifyPassword(password);
      } catch (e) {
        print('❌ Erreur vérification mot de passe: $e');
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'reason': 'verification_error', 'email': email, 'error': e.toString()},
        );
        return null;
      }

      if (!passwordValid) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('❌ Mot de passe invalide');
        await _logAuditEvent(
          action: 'FAILED_LOGIN',
          entity: 'User',
          entityId: user.key?.toString() ?? 'unknown',
          metadata: {'reason': 'invalid_password', 'email': email},
        );
        return null;
      }

      print('✅ Authentification réussie');

      // Met à jour la dernière connexion
      try {
        user.lastLogin = DateTime.now();
        if (user.isInBox) {
          await user.save();
        }
      } catch (e) {
        print('⚠️ Impossible de sauvegarder la dernière connexion: $e');
      }
      
      await _logAuditEvent(
        action: 'LOGIN',
        entity: 'User',
        entityId: user.key?.toString() ?? 'unknown',
        metadata: {'email': email},
      );

      return user;
      
    } catch (e) {
      print('❌ Erreur authentification: $e');
      throw DatabaseException('Erreur authentification: $e');
    }
  }

  // === GESTION DES SESSIONS ===
  
  Future<void> setCurrentUser(EnhancedUser user) async {
    try {
      await initializeDatabase();
      final sessionBox = await _getBox(_sessionBoxName);
      
      String? userKey;
      
      if (user.isInBox && user.key != null) {
        userKey = user.key.toString();
      } else {
        // Trouve l'utilisateur dans la base
        final foundUser = await _findUserByEmail(user.email);
        if (foundUser?.key != null) {
          userKey = foundUser!.key.toString();
        }
      }
      
      if (userKey == null) {
        throw DatabaseException('Impossible de créer la session');
      }
      
      await sessionBox.put('currentUserKey', userKey);
      await sessionBox.put('sessionStart', DateTime.now().toIso8601String());
      
      print('✅ Session créée pour utilisateur: $userKey');
      
    } catch (e) {
      print('❌ Erreur création session: $e');
      throw DatabaseException('Erreur création session: $e');
    }
  }

  Future<EnhancedUser?> getCurrentUser() async {
    try {
      await initializeDatabase();
      final sessionBox = await _getBox(_sessionBoxName);
      
      final currentUserKey = sessionBox.get('currentUserKey');
      if (currentUserKey == null) return null;
      
      if (await _isSessionValid()) {
        return await getUserById(currentUserKey.toString());
      } else {
        await clearCurrentUser();
        return null;
      }
      
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    try {
      await initializeDatabase();
      final sessionBox = await _getBox(_sessionBoxName);
      
      await sessionBox.delete('currentUserKey');
      await sessionBox.delete('sessionStart');
      
      print('🧹 Session effacée');
    } catch (e) {
      print('❌ Erreur clearCurrentUser: $e');
    }
  }

  Future<bool> _isSessionValid() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final sessionStartStr = sessionBox.get('sessionStart');
      
      if (sessionStartStr == null) return false;
      
      final sessionStart = DateTime.parse(sessionStartStr);
      final now = DateTime.now();
      
      return now.difference(sessionStart).inHours < 24;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isSessionValid() async {
    return await _isSessionValid();
  }

  // === OPÉRATIONS VACCINATION ===
  
  Future<void> saveVaccination(Vaccination vaccination) async {
    try {
      await initializeDatabase();
      
      if (vaccination.vaccineName.trim().isEmpty) {
        throw DatabaseException('Nom du vaccin requis');
      }
      if (vaccination.userId.trim().isEmpty) {
        throw DatabaseException('Utilisateur invalide');
      }

      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      final key = await box.add(vaccination);
      
      print('✅ Vaccination sauvegardée: ${vaccination.vaccineName}');
      
      await _logAuditEvent(
        action: 'CREATE_VACCINATION',
        entity: 'Vaccination',
        entityId: key.toString(),
        userId: vaccination.userId,
      );
      
    } catch (e) {
      print('❌ Erreur saveVaccination: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur sauvegarde vaccination: $e');
    }
  }

  Future<void> saveMultipleVaccinations(List<Vaccination> vaccinations) async {
    try {
      await initializeDatabase();
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      
      int saved = 0;
      for (final vaccination in vaccinations) {
        if (vaccination.vaccineName.trim().isNotEmpty && 
            vaccination.userId.trim().isNotEmpty) {
          await box.add(vaccination);
          saved++;
        }
      }
      
      print('✅ $saved/$vaccinations.length vaccinations sauvegardées');
      
    } catch (e) {
      print('❌ Erreur saveMultipleVaccinations: $e');
      throw DatabaseException('Erreur sauvegarde multiple: $e');
    }
  }

  Future<List<Vaccination>> getVaccinationsByUser(String userId) async {
    try {
      await initializeDatabase();
      
      if (userId.trim().isEmpty) {
        throw DatabaseException('ID utilisateur invalide');
      }

      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      final vaccinations = box.values
          .where((v) => v.userId == userId)
          .toList();
      
      // Trie par date (plus récent en premier)
      vaccinations.sort((a, b) {
        try {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      
      print('📋 ${vaccinations.length} vaccination(s) pour utilisateur $userId');
      return vaccinations;
      
    } catch (e) {
      print('❌ Erreur getVaccinationsByUser: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur récupération vaccinations: $e');
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
      // Ignore
    }
    return DateTime.now();
  }

  Future<void> deleteVaccination(String vaccinationId) async {
    try {
      await initializeDatabase();
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      
      final key = int.tryParse(vaccinationId);
      if (key == null) {
        throw DatabaseException('ID vaccination invalide');
      }
      
      final vaccination = box.get(key);
      if (vaccination == null) {
        throw DatabaseException('Vaccination introuvable');
      }
      
      await box.delete(key);
      print('✅ Vaccination supprimée: ${vaccination.vaccineName}');
      
    } catch (e) {
      print('❌ Erreur deleteVaccination: $e');
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur suppression: $e');
    }
  }

  // === CATÉGORIES DE VACCINS ===
  
  Future<void> initializeDefaultCategories() async {
    try {
      await initializeDatabase();
      final box = await _getBox<VaccineCategory>(_categoryBoxName);
      
      if (box.isEmpty) {
        print('📋 Initialisation catégories par défaut...');
        
        final categories = [
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
        
        for (final category in categories) {
          await box.add(category);
        }
        
        print('✅ Catégories initialisées');
      }
    } catch (e) {
      print('❌ Erreur initializeDefaultCategories: $e');
    }
  }

  Future<List<VaccineCategory>> getAllVaccineCategories() async {
    try {
      await initializeDatabase();
      final box = await _getBox<VaccineCategory>(_categoryBoxName);
      return box.values.toList();
    } catch (e) {
      print('❌ Erreur getAllVaccineCategories: $e');
      return [];
    }
  }

  // === AUDIT ===
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
      print('⚠️ Erreur audit: $e');
    }
  }

  // === MAINTENANCE ET NETTOYAGE ===
  
  Future<Map<String, int>> cleanupDatabase() async {
    try {
      await initializeDatabase();
      
      int duplicatesRemoved = 0;
      int orphanedVaccinationsRemoved = 0;
      
      print('🧹 Démarrage du nettoyage de la base de données...');
      
      final userBox = await _getBox<EnhancedUser>(_userBoxName);
      final emailToUsers = <String, List<EnhancedUser>>{};
      
      // Groupe les utilisateurs par email
      for (final user in userBox.values) {
        if (user.isDataValid) {
          emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
        }
      }
      
      // Supprime les doublons (garde le plus récent)
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('${users.length} doublons trouvés pour: ${users.first.email}');
          
          for (int i = 1; i < users.length; i++) {
            try {
              if (users[i].isInBox) {
                await users[i].delete();
                duplicatesRemoved++;
                print('Doublon supprimé: ${users[i].email}');
              }
            } catch (e) {
              print('Erreur suppression doublon: $e');
            }
          }
        }
      }
      
      // Nettoie les vaccinations orphelines
      final vaccinationBox = await _getBox<Vaccination>(_vaccinationBoxName);
      final activeUserIds = userBox.values
          .where((user) => user.isActive && user.key != null)
          .map((user) => user.key!.toString())
          .toSet();
      
      final orphanedKeys = <dynamic>[];
      for (final vaccination in vaccinationBox.values) {
        if (!activeUserIds.contains(vaccination.userId)) {
          orphanedKeys.add(vaccination.key);
        }
      }
      
      for (final key in orphanedKeys) {
        try {
          await vaccinationBox.delete(key);
          orphanedVaccinationsRemoved++;
        } catch (e) {
          print('Erreur suppression vaccination orpheline: $e');
        }
      }
      
      print('Nettoyage terminé:');
      print('- Doublons supprimés: $duplicatesRemoved');
      print('- Vaccinations orphelines supprimées: $orphanedVaccinationsRemoved');
      
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
      print('❌ Erreur nettoyage: $e');
      throw DatabaseException('Erreur lors du nettoyage: $e');
    }
  }
  Future<void> dispose() async {
    try {
      print('🧹 Fermeture service base de données...');
      
      for (final entry in _openBoxes.entries) {
        try {
          if (entry.value.isOpen) {
            await entry.value.close();
          }
        } catch (e) {
          print('⚠️ Erreur fermeture ${entry.key}: $e');
        }
      }
      
      _openBoxes.clear();
      _boxCache.clear();
      _isInitialized = false;
      
      print('✅ Service fermé');
    } catch (e) {
      print('❌ Erreur dispose: $e');
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  final String? code;

  const DatabaseException(this.message, [this.code]);

  @override
  String toString() => 'DatabaseException: $message';
}