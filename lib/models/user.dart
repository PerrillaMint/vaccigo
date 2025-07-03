// lib/models/user.dart - Modèle utilisateur avec sécurité renforcée
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Génère automatiquement user.g.dart avec les adaptateurs Hive
part 'user.g.dart';

// Annotation Hive pour la sérialisation - typeId unique pour éviter les conflits
@HiveType(typeId: 0)
class User extends HiveObject {
  // === CHAMPS PRINCIPAUX ===
  // Nom complet de l'utilisateur (prénom + nom)
  @HiveField(0)
  String name;
  
  // Adresse email - utilisée comme identifiant unique
  @HiveField(1)
  String email;

  // Hash sécurisé du mot de passe (jamais le mot de passe en clair!)
  @HiveField(2)
  String passwordHash;

  // Date de naissance au format DD/MM/YYYY
  @HiveField(3)
  String dateOfBirth;

  // === INFORMATIONS MÉDICALES OPTIONNELLES ===
  // Maladies chroniques de l'utilisateur (diabète, hypertension, etc.)
  @HiveField(4)
  String? diseases;

  // Traitements médicaux en cours (médicaments, thérapies)
  @HiveField(5)
  String? treatments;

  // Allergies connues (médicaments, aliments, substances)
  @HiveField(6)
  String? allergies;

  // === SÉCURITÉ ===
  // Sel cryptographique pour sécuriser le hachage du mot de passe
  // Unique pour chaque utilisateur, empêche les attaques par rainbow table
  @HiveField(7)
  String? salt;

  // === MÉTADONNÉES ===
  // Date de création du compte
  @HiveField(8)
  DateTime createdAt;

  // Dernière connexion de l'utilisateur
  @HiveField(9)
  DateTime lastLogin;

  // Indique si le compte est actif (permet la désactivation temporaire)
  @HiveField(10)
  bool isActive;

  // === CONSTRUCTEUR PRINCIPAL ===
  // Utilisé par Hive pour reconstruire l'objet depuis la base de données
  User({
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.dateOfBirth,
    this.diseases,
    this.treatments,
    this.allergies,
    this.salt,
    DateTime? createdAt,
    DateTime? lastLogin,
    this.isActive = true,
  }) : 
    // Initialise les dates avec des valeurs par défaut si non fournies
    createdAt = createdAt ?? DateTime.now(),
    lastLogin = lastLogin ?? DateTime.now();

  // === FACTORY CONSTRUCTOR SÉCURISÉ ===
  // Crée un nouvel utilisateur avec hachage automatique du mot de passe
  factory User.create({
    required String name,
    required String email,
    required String password, // Mot de passe en clair - sera hashé
    required String dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool isActive = true,
  }) {
    try {
      // Génère un sel cryptographique unique pour cet utilisateur
      final salt = _generateSalt();
      
      // Hash le mot de passe avec le sel pour sécuriser le stockage
      final passwordHash = _hashPassword(password, salt);
      
      print('=== CRÉATION UTILISATEUR ===');
      print('Utilisateur: $email');
      print('Sel généré: $salt');
      print('Hash créé: $passwordHash');
      print('============================');
      
      return User(
        name: name,
        email: email,
        passwordHash: passwordHash,
        dateOfBirth: dateOfBirth,
        diseases: diseases,
        treatments: treatments,
        allergies: allergies,
        salt: salt,
        createdAt: createdAt,
        lastLogin: lastLogin,
        isActive: isActive,
      );
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  // === MÉTHODES DE SÉCURITÉ PRIVÉES ===
  
  // Génère un sel cryptographique aléatoire de 32 bytes
  static String _generateSalt() {
    try {
      // Utilise un générateur sécurisé pour la cryptographie
      final random = Random.secure();
      
      // Génère 32 bytes aléatoires (256 bits de sécurité)
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      
      // Encode en base64 pour stockage sous forme de string
      final saltString = base64.encode(values);
      
      if (saltString.isEmpty) {
        throw Exception('Le sel généré est vide');
      }
      
      return saltString;
    } catch (e) {
      print('Erreur lors de la génération du sel: $e');
      rethrow;
    }
  }

  // Hash un mot de passe avec un sel en utilisant SHA-256
  static String _hashPassword(String password, String salt) {
    try {
      if (password.isEmpty) {
        throw Exception('Le mot de passe ne peut pas être vide');
      }
      if (salt.isEmpty) {
        throw Exception('Le sel ne peut pas être vide');
      }
      
      // Combine le mot de passe et le sel
      final bytes = utf8.encode(password + salt);
      
      // Applique le hachage SHA-256
      final digest = sha256.convert(bytes);
      
      // Convertit en string hexadécimale
      final hashString = digest.toString();
      
      if (hashString.isEmpty) {
        throw Exception('Le hash généré est vide');
      }
      
      return hashString;
    } catch (e) {
      print('Erreur lors du hachage du mot de passe: $e');
      rethrow;
    }
  }

  // === VÉRIFICATION DE MOT DE PASSE ===
  // Vérifie si un mot de passe fourni correspond au hash stocké
  bool verifyPassword(String password) {
    print('=== VÉRIFICATION MOT DE PASSE ===');
    print('Vérification pour: $email');
    print('Longueur mot de passe: ${password.length}');
    print('Sel stocké: $salt');
    print('Hash stocké: $passwordHash');
    
    try {
      // Valide l'entrée
      if (password.isEmpty) {
        print('ERREUR: Mot de passe vide');
        print('=================================');
        return false;
      }
      
      // Vérifie que le sel existe AVANT de l'utiliser
      if (salt == null) {
        print('ERREUR: Sel null - utilisateur mal créé');
        print('=================================');
        return false;
      }
      
      if (salt!.isEmpty) {
        print('ERREUR: Sel vide - utilisateur mal créé');
        print('=================================');
        return false;
      }
      
      // Vérifie que le hash existe
      if (passwordHash.isEmpty) {
        print('ERREUR: Hash vide - utilisateur mal créé');
        print('=================================');
        return false;
      }
      
      // Vérification sécurisée avec gestion d'erreur
      final hashedInput = _hashPassword(password, salt!);
      final isValid = hashedInput == passwordHash;
      
      print('Hash généré: $hashedInput');
      print('Mots de passe correspondent: $isValid');
      print('=================================');
      
      return isValid;
      
    } catch (e) {
      print('ERREUR pendant la vérification: $e');
      print('Stack trace: ${StackTrace.current}');
      print('=================================');
      return false;
    }
  }

  // === MISE À JOUR DE MOT DE PASSE ===
  // Met à jour le mot de passe de l'utilisateur avec un nouveau hash et sel
  void updatePassword(String newPassword) {
    try {
      if (newPassword.isEmpty) {
        throw Exception('Le mot de passe ne peut pas être vide');
      }
      
      // Génère un nouveau sel pour plus de sécurité
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);
      
      // Valide les valeurs générées
      if (newSalt.isEmpty || newHash.isEmpty) {
        throw Exception('Échec de génération du sel ou hash valide');
      }
      
      // Met à jour les champs
      salt = newSalt;
      passwordHash = newHash;
      
      print('=== MISE À JOUR MOT DE PASSE ===');
      print('Mot de passe mis à jour pour: $email');
      print('Nouveau sel: $newSalt');
      print('Nouveau hash: $newHash');
      print('===============================');
      
    } catch (e) {
      print('Erreur lors de la mise à jour du mot de passe: $e');
      rethrow;
    }
  }

  // === VALIDATION DES DONNÉES ===
  // Vérifie que les données de l'utilisateur sont valides
  bool get isDataValid {
    try {
      return name.isNotEmpty && 
             email.isNotEmpty && 
             passwordHash.isNotEmpty && 
             salt != null && 
             salt!.isNotEmpty &&
             dateOfBirth.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de validité: $e');
      return false;
    }
  }

  // Répare les données utilisateur corrompues si possible
  bool repairUserData(String plainPassword) {
    if (isDataValid) return true;
    
    try {
      print('=== RÉPARATION DONNÉES UTILISATEUR ===');
      print('Utilisateur: $email');
      print('Sel manquant: ${salt == null || (salt != null && salt!.isEmpty)}');
      print('Hash manquant: ${passwordHash.isEmpty}');
      print('Nom manquant: ${name.isEmpty}');
      print('Email manquant: ${email.isEmpty}');
      print('Date naissance manquante: ${dateOfBirth.isEmpty}');
      
      if (plainPassword.isEmpty) {
        print('Impossible de réparer: mot de passe vide');
        print('=====================================');
        return false;
      }
      
      // Ne répare que si les données essentielles existent
      if (name.isEmpty || email.isEmpty || dateOfBirth.isEmpty) {
        print('Impossible de réparer: données essentielles manquantes');
        print('=====================================');
        return false;
      }
      
      // Génère un nouveau sel et hash
      final newSalt = _generateSalt();
      final newHash = _hashPassword(plainPassword, newSalt);
      
      salt = newSalt;
      passwordHash = newHash;
      
      print('Réparé avec nouveau sel: $newSalt');
      print('=====================================');
      
      return isDataValid;
      
    } catch (e) {
      print('Échec de la réparation des données: $e');
      print('=====================================');
      return false;
    }
  }

  // === MÉTHODES DE VALIDATION STATIQUES ===
  
  // Valide un nom d'utilisateur
  static String? validateName(String? name) {
    if (name == null) {
      return 'Le nom est requis';
    }
    
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Le nom est requis';
    }
    if (trimmedName.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (trimmedName.length > 100) {
      return 'Le nom est trop long';
    }
    // Vérifie les caractères dangereux pour la sécurité
    if (RegExp(r'[<>"\/\\]').hasMatch(trimmedName)) {
      return 'Le nom contient des caractères invalides';
    }
    return null;
  }

  // Valide une adresse email
  static String? validateEmail(String? email) {
    if (email == null) {
      return "L'email est requis";
    }
    
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return "L'email est requis";
    }
    
    // Normalise en minuscules
    final sanitizedEmail = trimmedEmail.toLowerCase();
    
    if (sanitizedEmail.length > 254) {
      return "L'email est trop long";
    }
    
    // Expression régulière stricte pour valider l'email
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    );
    
    if (!emailRegex.hasMatch(sanitizedEmail)) {
      return "Format d'email invalide";
    }
    
    return null;
  }

  // Valide un mot de passe selon les critères de sécurité
  static String? validatePassword(String? password) {
    if (password == null) {
      return 'Le mot de passe est requis';
    }
    if (password.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (password.length > 128) {
      return 'Le mot de passe est trop long';
    }
    
    // Vérifie la présence d'au moins une lettre
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins une lettre';
    }
    // Vérifie la présence d'au moins un chiffre
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    // Liste des mots de passe faibles courants
    final weakPasswords = [
      '12345678', 'password', 'motdepasse', 'azerty123', 'qwerty123'
    ];
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'Ce mot de passe est trop faible';
    }
    
    return null;
  }

  // Valide une date de naissance
  static String? validateDateOfBirth(String? date) {
    if (date == null) {
      return 'La date de naissance est requise';
    }
    
    final trimmedDate = date.trim();
    if (trimmedDate.isEmpty) {
      return 'La date de naissance est requise';
    }
    
    // Vérifie le format DD/MM/YYYY
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(trimmedDate)) {
      return 'Format invalide. Utilisez JJ/MM/AAAA';
    }
    
    try {
      final parts = trimmedDate.split('/');
      if (parts.length != 3) {
        return 'Format invalide';
      }
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Valide les plages de valeurs
      if (day < 1 || day > 31) return 'Jour invalide';
      if (month < 1 || month > 12) return 'Mois invalide';
      
      final currentYear = DateTime.now().year;
      if (year < 1900 || year > currentYear) return 'Année invalide';
      
      // Calcule et valide l'âge
      final age = currentYear - year;
      if (age < 0) return 'Date de naissance future invalide';
      if (age > 150) return 'Âge invalide';
      
      // Vérifie que la date existe réellement (pas de 30 février)
      final birthDate = DateTime(year, month, day);
      if (birthDate.day != day || birthDate.month != month || birthDate.year != year) {
        return 'Date invalide';
      }
      
      return null;
    } catch (e) {
      return 'Date invalide';
    }
  }

  // === MÉTHODES UTILITAIRES ===
  
  // Nettoie et sécurise une chaîne d'entrée
  static String _sanitizeString(String? input) {
    if (input == null) return '';
    
    return input
        .replaceAll(RegExp(r'[<>"\/\\]'), '') // Supprime caractères dangereux
        .replaceAll(RegExp(r'\s+'), ' ')      // Normalise les espaces
        .trim();
  }

  // Valide toutes les données utilisateur en une fois
  static Map<String, String> validateUserData({
    String? name,
    String? email,
    String? password,
    String? dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
  }) {
    final errors = <String, String>{};
    
    final nameError = validateName(name);
    if (nameError != null) errors['name'] = nameError;
    
    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;
    
    final passwordError = validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;
    
    final dateError = validateDateOfBirth(dateOfBirth);
    if (dateError != null) errors['dateOfBirth'] = dateError;
    
    return errors;
  }

  // === FACTORY CONSTRUCTOR AVEC VALIDATION ===
  // Crée un utilisateur en validant toutes les données d'entrée
  factory User.createSecure({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
  }) {
    try {
      // Valide toutes les données avant création
      final errors = validateUserData(
        name: name,
        email: email,
        password: password,
        dateOfBirth: dateOfBirth,
        diseases: diseases,
        treatments: treatments,
        allergies: allergies,
      );
      
      if (errors.isNotEmpty) {
        throw ValidationException('Données utilisateur invalides', errors);
      }
      
      // Nettoie les données d'entrée
      final sanitizedName = _sanitizeString(name);
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedDateOfBirth = dateOfBirth.trim();
      final sanitizedDiseases = diseases?.isNotEmpty == true ? _sanitizeString(diseases) : null;
      final sanitizedTreatments = treatments?.isNotEmpty == true ? _sanitizeString(treatments) : null;
      final sanitizedAllergies = allergies?.isNotEmpty == true ? _sanitizeString(allergies) : null;
      
      if (sanitizedName.isEmpty || sanitizedEmail.isEmpty || sanitizedDateOfBirth.isEmpty) {
        throw ValidationException('Données essentielles manquantes après nettoyage', {});
      }
      
      return User.create(
        name: sanitizedName,
        email: sanitizedEmail,
        password: password,
        dateOfBirth: sanitizedDateOfBirth,
        diseases: sanitizedDiseases,
        treatments: sanitizedTreatments,
        allergies: sanitizedAllergies,
      );
    } catch (e) {
      print('Erreur dans createSecure: $e');
      rethrow;
    }
  }

  // === MÉTHODES DE GESTION ===
  
  // Met à jour l'heure de dernière connexion
  void updateLastLogin() {
    try {
      lastLogin = DateTime.now();
      if (isInBox) {
        save(); // Sauvegarde automatiquement si l'objet est dans Hive
      }
    } catch (e) {
      print('Échec de sauvegarde de l\'heure de connexion: $e');
    }
  }

  // Désactive le compte utilisateur
  void deactivate() {
    try {
      isActive = false;
      if (isInBox) {
        save();
      }
    } catch (e) {
      print('Échec de sauvegarde de la désactivation: $e');
    }
  }

  // Calcule l'âge à partir de la date de naissance
  int get age {
    try {
      if (dateOfBirth.isEmpty) return 0;
      
      final parts = dateOfBirth.split('/');
      if (parts.length != 3) return 0;
      
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      
      if (day == null || month == null || year == null) return 0;
      
      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // Ajuste si l'anniversaire n'est pas encore passé cette année
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age >= 0 ? age : 0;
    } catch (e) {
      print('Erreur lors du calcul de l\'âge: $e');
      return 0;
    }
  }

  // === SÉRIALISATION SÉCURISÉE ===
  // Convertit en JSON sans exposer les données sensibles
  Map<String, dynamic> toSafeJson() {
    try {
      return {
        'name': name,
        'email': email,
        'dateOfBirth': dateOfBirth,
        'age': age,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
        'isActive': isActive,
        'hasValidData': isDataValid,
        'hasDiseases': diseases?.isNotEmpty == true,
        'hasTreatments': treatments?.isNotEmpty == true,
        'hasAllergies': allergies?.isNotEmpty == true,
        // NOTE: passwordHash et salt sont volontairement exclus pour sécurité
      };
    } catch (e) {
      print('Erreur lors de la création du JSON sécurisé: $e');
      return {
        'name': name,
        'email': email,
        'error': 'Échec de sérialisation des données utilisateur',
      };
    }
  }

  @override
  String toString() {
    try {
      return 'User{name: $name, email: $email, isActive: $isActive, hasValidData: $isDataValid}';
    } catch (e) {
      return 'User{error: $e}';
    }
  }

  // === ACCESSEURS SÉCURISÉS ===
  // Méthodes pour accéder aux champs optionnels sans risque de null
  
  String get safeDiseases => diseases ?? '';
  String get safeTreatments => treatments ?? '';
  String get safeAllergies => allergies ?? '';
  
  // Vérifie si l'utilisateur a des informations médicales
  bool get hasMedicalInfo {
    try {
      return (diseases?.isNotEmpty == true) ||
             (treatments?.isNotEmpty == true) ||
             (allergies?.isNotEmpty == true);
    } catch (e) {
      return false;
    }
  }
}

// === EXCEPTION PERSONNALISÉE ===
// Exception lancée lors d'erreurs de validation
class ValidationException implements Exception {
  final String message;
  final Map<String, String> errors; // Détails des erreurs par champ

  ValidationException(this.message, this.errors);

  @override
  String toString() {
    try {
      return 'ValidationException: $message - Erreurs: $errors';
    } catch (e) {
      return 'ValidationException: $message';
    }
  }
}