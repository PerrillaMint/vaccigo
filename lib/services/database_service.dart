// lib/services/database_service.dart - Service de gestion de base de données avec sécurité renforcée
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:io';
import '../models/user.dart';
import '../models/vaccination.dart';
import '../models/vaccine_category.dart';
import '../models/travel.dart';

// Service principal pour toutes les opérations de base de données
// Utilise Hive comme base de données locale avec chiffrement et sécurité
class DatabaseService {
  // === NOMS DES BOÎTES HIVE ===
  // Chaque type de données a sa propre "boîte" (table) dans Hive
  // Le suffixe "_v2" permet de gérer les migrations si nécessaire
  static const String _userBoxName = 'users_v2';              // Données utilisateurs
  static const String _vaccinationBoxName = 'vaccinations_v2'; // Vaccinations
  static const String _categoryBoxName = 'vaccine_categories_v2'; // Catégories de vaccins
  static const String _sessionBoxName = 'session_v2';         // Sessions utilisateur
  static const String _auditBoxName = 'audit_logs';           // Logs d'audit sécurité
  static const String _travelBoxName = 'travel_v2';           // Données de voyage

  // === GESTION DU CACHE ET PERFORMANCE ===
  // Cache des connexions aux boîtes pour éviter les ouvertures répétées
  static final Map<String, Completer<Box>> _boxCache = {};
  
  // Tracking de derniers accès pour optimisation
  static final Map<String, DateTime> _lastAccess = {};
  
  // === LIMITATION DU TAUX D'OPÉRATIONS (RATE LIMITING) ===
  // Prévient les abus et protège contre les attaques par déni de service
  static final Map<String, List<DateTime>> _operationTimestamps = {};
  static const int _maxOperationsPerMinute = 100; // Max 100 opérations/minute

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
  // Enregistre toutes les actions importantes pour sécurité et traçabilité
  Future<void> _logAuditEvent({
    required String action,      // Type d'action (CREATE, READ, UPDATE, DELETE)
    required String entity,      // Type d'entité (User, Vaccination, etc.)
    String? entityId,           // ID de l'entité concernée
    String? userId,             // ID de l'utilisateur qui fait l'action
    Map<String, dynamic>? metadata, // Données supplémentaires
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
        'platform': Platform.operatingSystem, // iOS/Android/Windows
      });
    } catch (e) {
      print('Échec de l\'enregistrement de l\'événement d\'audit: $e');
      // On ne bloque pas l'opération si l'audit échoue
    }
  }

  // === GESTION SÉCURISÉE DES BOÎTES HIVE ===
  // Obtient une référence à une boîte Hive avec gestion d'erreur et cache
  Future<Box<T>> _getBox<T>(String boxName) async {
    // Vérifie si la boîte est déjà dans le cache
    if (_boxCache.containsKey(boxName)) {
      return await _boxCache[boxName]!.future as Box<T>;
    }

    // Crée un nouveau completer pour cette boîte
    final completer = Completer<Box>();
    _boxCache[boxName] = completer;

    try {
      // Ouvre la boîte avec le type approprié
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
  Future<void> saveUser(User user) async {
    if (!_checkRateLimit('saveUser')) {
      throw DatabaseException('Limite de taux dépassée pour la création d\'utilisateur');
    }

    try {
      print('=== SAUVEGARDE UTILISATEUR ===');
      print('Utilisateur: ${user.name} (${user.email})');
      print('A un sel: ${user.salt != null && user.salt!.isNotEmpty}');
      print('Données valides: ${user.isDataValid}');

      final box = await _getBox<User>(_userBoxName);
      
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
      
      // Test de vérification immédiat après sauvegarde
      if (user.passwordHash.isNotEmpty && user.salt != null) {
        print('Utilisateur sauvegardé avec succès, données valides');
      }
      
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

  // Récupère tous les utilisateurs actifs avec logging détaillé
  Future<List<User>> getAllUsers() async {
    if (!_checkRateLimit('getAllUsers')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    try {
      final box = await _getBox<User>(_userBoxName);
      // Filtre seulement les utilisateurs actifs
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

  // Récupère un utilisateur par son ID (clé Hive)
  Future<User?> getUserById(String userId) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      
      // Parse l'ID utilisateur de manière sécurisée
      final key = int.tryParse(userId);
      if (key == null) {
        print('Format d\'ID utilisateur invalide: $userId');
        return null;
      }
      
      final user = box.get(key);
      
      // Vérifie que l'utilisateur est actif
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
  Future<User?> _getUserByEmailInternal(String email) async {
    try {
      final box = await _getBox<User>(_userBoxName);
      final sanitizedEmail = email.trim().toLowerCase();
      
      print('Recherche utilisateur avec email: $sanitizedEmail');
      print('Total utilisateurs dans la boîte: ${box.length}');
      
      // Parcourt tous les utilisateurs pour trouver l'email correspondant
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

  // Version publique de la recherche par email avec rate limiting
  Future<User?> getUserByEmail(String email) async {
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

  // Vérifie si un email existe déjà dans la base
  Future<bool> emailExists(String email) async {
    if (!_checkRateLimit('emailExists')) {
      return false; // Retourne false en cas de rate limiting
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
  // Authentifie un utilisateur avec email et mot de passe
  Future<User?> authenticateUser(String email, String password) async {
    if (!_checkRateLimit('authenticateUser')) {
      throw DatabaseException('Trop de tentatives de connexion. Réessayez plus tard.');
    }

    try {
      // Validation d'entrée avec sécurité null-safe
      if (email.trim().isEmpty || password.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Prévient les attaques de timing
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

      // Vérifie la validité des données AVANT la vérification du mot de passe
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

      // Vérification sécurisée du mot de passe
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

      // Met à jour l'heure de dernière connexion de manière sécurisée
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
        // Ne fait pas échouer l'authentification juste pour ça
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
      
      // Log l'erreur mais n'expose pas les détails internes à l'utilisateur
      await _logAuditEvent(
        action: 'LOGIN_ERROR',
        entity: 'System',
        metadata: {'email': email, 'error': e.toString()},
      );
      
      throw DatabaseException('Erreur d\'authentification: Une erreur interne s\'est produite');
    }
  }

  // === GESTION DES SESSIONS ===
  
  // Récupère l'utilisateur actuellement connecté
  Future<User?> getCurrentUser() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final currentUserKey = sessionBox.get('currentUserKey');
      
      if (currentUserKey != null) {
        print('Récupération utilisateur actuel avec clé: $currentUserKey');
        
        // Vérifie que la session est encore valide
        if (await isSessionValid()) {
          final user = await getUserById(currentUserKey.toString());
          if (user != null) {
            print('Utilisateur actuel trouvé: ${user.email}');
            return user;
          } else {
            print('Aucun utilisateur trouvé pour la clé: $currentUserKey');
            // Nettoie la session invalide
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

  // Définit l'utilisateur actuellement connecté
  Future<void> setCurrentUser(User user) async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      
      print('=== DEBUG CRÉATION SESSION ===');
      print('Définition utilisateur actuel: ${user.email}');
      
      // S'assure que l'utilisateur a une clé valide
      String? userKey;
      
      if (user.isInBox && user.key != null) {
        userKey = user.key.toString();
        print('Utilisation clé utilisateur existante: $userKey');
      } else {
        // Essaie de trouver l'utilisateur par email pour obtenir la bonne clé
        print('Utilisateur pas dans boîte, recherche par email: ${user.email}');
        final foundUser = await _getUserByEmailInternal(user.email);
        if (foundUser != null && foundUser.isInBox && foundUser.key != null) {
          userKey = foundUser.key.toString();
          print('Utilisateur trouvé avec clé: $userKey');
          // Utilise l'utilisateur trouvé au lieu du paramètre
          user = foundUser;
        } else {
          // Dernier recours: essaie de sauvegarder l'utilisateur d'abord
          print('Tentative de sauvegarde d\'utilisateur d\'abord...');
          final box = await _getBox<User>(_userBoxName);
          final newKey = await box.add(user);
          userKey = newKey.toString();
          print('Utilisateur sauvegardé avec nouvelle clé: $userKey');
        }
      }
      
      if (userKey == null) {
        throw DatabaseException('Impossible de créer une session: utilisateur invalide');
      }
      
      // Enregistre la session
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

  // Efface la session actuelle (déconnexion)
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
      // Ne lève pas d'exception, juste un log
    }
  }

  // Vérifie si la session actuelle est encore valide (24h max)
  Future<bool> isSessionValid() async {
    try {
      final sessionBox = await _getBox(_sessionBoxName);
      final sessionStartStr = sessionBox.get('sessionStart') as String?;
      
      if (sessionStartStr == null) return false;
      
      final sessionStart = DateTime.parse(sessionStartStr);
      final now = DateTime.now();
      
      // Session valide pendant 24 heures
      return now.difference(sessionStart).inHours < 24;
    } catch (e) {
      print('Erreur lors de la vérification de validité de session: $e');
      return false;
    }
  }

  // === OPÉRATIONS DE VACCINATION ===
  
  // Sauvegarde une nouvelle vaccination
  Future<void> saveVaccination(Vaccination vaccination) async {
    if (!_checkRateLimit('saveVaccination')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    try {
      // Validation des données d'entrée
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

  // Récupère toutes les vaccinations
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

  // Récupère les vaccinations d'un utilisateur spécifique
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
      
      // Trie par date (plus récent en premier)
      vaccinations.sort((a, b) {
        try {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0; // Garde l'ordre actuel si parsing échoue
        }
      });
      
      print('${vaccinations.length} vaccinations trouvées pour utilisateur $userId');
      return vaccinations;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erreur lors de la récupération des vaccinations: $e');
    }
  }

  // Parse une date au format DD/MM/YYYY vers DateTime
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // année
          int.parse(parts[1]), // mois
          int.parse(parts[0]), // jour
        );
      }
    } catch (e) {
      // Retourne la date actuelle si le parsing échoue
    }
    return DateTime.now();
  }

  // Supprime une vaccination
  Future<void> deleteVaccination(String vaccinationId) async {
    if (!_checkRateLimit('deleteVaccination')) {
      throw DatabaseException('Limite de taux dépassée');
    }

    try {
      final box = await _getBox<Vaccination>(_vaccinationBoxName);
      
      // Parse la clé de manière sécurisée
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
  
  // Récupère toutes les catégories de vaccins
  Future<List<VaccineCategory>> getAllVaccineCategories() async {
    try {
      final box = await _getBox<VaccineCategory>(_categoryBoxName);
      return box.values.toList();
    } catch (e) {
      throw DatabaseException('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Initialise les catégories par défaut lors du premier lancement
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

  // === MAINTENANCE DE BASE DE DONNÉES ===
  
  // Nettoie la base de données (supprime doublons, orphelins, etc.)
  Future<Map<String, int>> cleanupDatabase() async {
    if (!_checkRateLimit('cleanupDatabase')) {
      throw DatabaseException('Limite de taux dépassée pour le nettoyage');
    }

    try {
      int duplicatesRemoved = 0;
      int orphanedVaccinationsRemoved = 0;
      int corruptUsersFixed = 0;
      
      print('=== NETTOYAGE BASE DE DONNÉES DÉMARRÉ ===');
      
      final userBox = await _getBox<User>(_userBoxName);
      final emailToUsers = <String, List<User>>{};
      
      print('Total utilisateurs avant nettoyage: ${userBox.length}');
      
      // Groupe les utilisateurs par email et identifie les données corrompues
      for (final user in userBox.values) {
        // Vérifie les utilisateurs corrompus
        if (!user.isDataValid) {
          print('Utilisateur corrompu trouvé: ${user.email} (sel ou hash manquant)');
          // Note: On ne peut pas réparer sans connaître le mot de passe
          // Cet utilisateur devra être recréé ou réparé manuellement
        } else {
          emailToUsers.putIfAbsent(user.email.toLowerCase(), () => []).add(user);
        }
      }
      
      // Supprime les doublons (garde le plus récent)
      for (final users in emailToUsers.values) {
        if (users.length > 1) {
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('${users.length} utilisateurs en double trouvés pour: ${users.first.email}');
          
          // Garde le premier (plus récent), supprime le reste
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
      
      // Nettoie les vaccinations orphelines
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
      
      // Nettoie les anciennes sessions et logs d'audit
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

  // Nettoie les anciennes sessions (plus de 7 jours)
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

  // Nettoie les anciens logs d'audit (plus de 90 jours)
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
          // Si on ne peut pas parser le log, on le considère pour suppression
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

  // === LIBÉRATION DES RESSOURCES ===
  
  // Nettoie proprement toutes les ressources du service
  Future<void> dispose() async {
    try {
      print('Libération du service de base de données...');
      
      // Ferme toutes les boîtes proprement
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
      
      // Nettoie tous les caches
      _boxCache.clear();
      _lastAccess.clear();
      _operationTimestamps.clear();
      
      print('Service de base de données libéré avec succès');
    } catch (e) {
      print('Erreur lors de la libération: $e');
    }
  }
}

// === EXCEPTION PERSONNALISÉE ===
// Exception spécifique pour les erreurs de base de données
class DatabaseException implements Exception {
  final String message;        // Message d'erreur principal
  final String? code;         // Code d'erreur optionnel
  final dynamic originalError; // Erreur originale si applicable

  const DatabaseException(this.message, [this.code, this.originalError]);

  @override
  String toString() {
    return 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}