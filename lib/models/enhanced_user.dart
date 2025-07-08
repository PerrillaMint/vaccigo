// lib/models/enhanced_user.dart - Modèle utilisateur amélioré avec gestion famille
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

part 'enhanced_user.g.dart';

@HiveType(typeId: 0)
class EnhancedUser extends HiveObject {
  // Champs de base
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String dateOfBirth;

  // Informations médicales
  @HiveField(4)
  String? diseases;

  @HiveField(5)
  String? treatments;

  @HiveField(6)
  String? allergies;

  // Sécurité
  @HiveField(7)
  String? salt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime lastLogin;

  @HiveField(10)
  bool isActive;

  // NOUVEAUX CHAMPS pour multi-utilisateurs
  @HiveField(11)
  String? familyAccountId; // Référence au compte famille

  @HiveField(12)
  UserRole role; // Rôle dans la famille

  @HiveField(13)
  String? parentUserId; // Pour les mineurs, référence au parent/tuteur

  @HiveField(14)
  UserType userType; // Type d'utilisateur

  @HiveField(15)
  Map<String, dynamic>? preferences; // Préférences utilisateur

  @HiveField(16)
  bool emailVerified; // Email vérifié

  @HiveField(17)
  DateTime? emailVerifiedAt;

  @HiveField(18)
  String? phoneNumber; // Numéro de téléphone optionnel

  @HiveField(19)
  String? emergencyContact; // Contact d'urgence

  @HiveField(20)
  String? profilePicturePath; // Chemin vers photo de profil

  EnhancedUser({
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
    this.familyAccountId,
    this.role = UserRole.member,
    this.parentUserId,
    this.userType = UserType.adult,
    this.preferences,
    this.emailVerified = false,
    this.emailVerifiedAt,
    this.phoneNumber,
    this.emergencyContact,
    this.profilePicturePath,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastLogin = lastLogin ?? DateTime.now();

  // Factory pour créer un utilisateur sécurisé
  factory EnhancedUser.createSecure({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
    UserRole role = UserRole.member,
    UserType? userType,
    String? parentUserId,
    String? phoneNumber,
    String? emergencyContact,
  }) {
    try {
      // Détermine automatiquement le type d'utilisateur basé sur l'âge
      final calculatedUserType = userType ?? _determineUserType(dateOfBirth);
      
      // Valide les données
      final errors = validateUserData(
        name: name,
        email: email,
        password: password,
        dateOfBirth: dateOfBirth,
        userType: calculatedUserType,
        parentUserId: parentUserId,
      );
      
      if (errors.isNotEmpty) {
        throw ValidationException('Données utilisateur invalides', errors);
      }
      
      // Génère sel et hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      
      return EnhancedUser(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
        dateOfBirth: dateOfBirth.trim(),
        diseases: diseases?.trim(),
        treatments: treatments?.trim(),
        allergies: allergies?.trim(),
        salt: salt,
        role: role,
        userType: calculatedUserType,
        parentUserId: parentUserId,
        phoneNumber: phoneNumber?.trim(),
        emergencyContact: emergencyContact?.trim(),
        preferences: _getDefaultPreferences(),
      );
    } catch (e) {
      print('Erreur création utilisateur sécurisé: $e');
      rethrow;
    }
  }

  // Détermine le type d'utilisateur basé sur l'âge
  static UserType _determineUserType(String dateOfBirth) {
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length != 3) return UserType.adult;
      
      final birthDate = DateTime(
        int.parse(parts[2]), // année
        int.parse(parts[1]), // mois
        int.parse(parts[0]), // jour
      );
      
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      
      if (age < 13) return UserType.child;
      if (age < 18) return UserType.teen;
      if (age >= 65) return UserType.senior;
      return UserType.adult;
    } catch (e) {
      return UserType.adult;
    }
  }

  // Préférences par défaut
  static Map<String, dynamic> _getDefaultPreferences() {
    return {
      'language': 'fr',
      'notifications': {
        'vaccineReminders': true,
        'appointmentReminders': true,
        'healthTips': false,
        'familyUpdates': true,
      },
      'privacy': {
        'shareWithFamily': true,
        'shareWithDoctors': false,
        'dataAnalytics': false,
      },
      'display': {
        'theme': 'light',
        'fontSize': 'medium',
        'highContrast': false,
      }
    };
  }

  // Validation des données utilisateur améliorée
  static Map<String, String> validateUserData({
    String? name,
    String? email,
    String? password,
    String? dateOfBirth,
    UserType? userType,
    String? parentUserId,
  }) {
    final errors = <String, String>{};
    
    // Validation nom
    if (name == null || name.trim().isEmpty) {
      errors['name'] = 'Le nom est requis';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Le nom doit contenir au moins 2 caractères';
    } else if (name.trim().length > 100) {
      errors['name'] = 'Le nom est trop long';
    }
    
    // Validation email
    if (email == null || email.trim().isEmpty) {
      errors['email'] = 'L\'email est requis';
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        errors['email'] = 'Format d\'email invalide';
      }
    }
    
    // Validation mot de passe
    if (password == null || password.isEmpty) {
      errors['password'] = 'Le mot de passe est requis';
    } else {
      if (password.length < 8) {
        errors['password'] = 'Minimum 8 caractères requis';
      }
      if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
        errors['password'] = 'Au moins une lettre requise';
      }
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        errors['password'] = 'Au moins un chiffre requis';
      }
    }
    
    // Validation date de naissance
    if (dateOfBirth == null || dateOfBirth.trim().isEmpty) {
      errors['dateOfBirth'] = 'La date de naissance est requise';
    } else {
      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateOfBirth.trim())) {
        errors['dateOfBirth'] = 'Format invalide (JJ/MM/AAAA)';
      }
    }
    
    // Validation spécifique pour les mineurs
    if (userType == UserType.child || userType == UserType.teen) {
      if (parentUserId == null || parentUserId.trim().isEmpty) {
        errors['parentUserId'] = 'Un tuteur est requis pour les mineurs';
      }
    }
    
    return errors;
  }

  // Vérification mot de passe améliorée
  bool verifyPassword(String password) {
    try {
      if (password.isEmpty || salt == null || salt!.isEmpty || passwordHash.isEmpty) {
        return false;
      }
      
      final hashedInput = _hashPassword(password, salt!);
      return hashedInput == passwordHash;
    } catch (e) {
      print('Erreur vérification mot de passe: $e');
      return false;
    }
  }

  // Méthodes de sécurité
  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(values);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Getters utiles
  int get age {
    try {
      final parts = dateOfBirth.split('/');
      if (parts.length != 3) return 0;
      
      final birthDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age >= 0 ? age : 0;
    } catch (e) {
      return 0;
    }
  }

  bool get isMinor => age < 18;
  bool get isChild => userType == UserType.child;
  bool get isTeen => userType == UserType.teen;
  bool get isAdult => userType == UserType.adult;
  bool get isSenior => userType == UserType.senior;
  
  bool get isPrimaryUser => role == UserRole.primary;
  bool get isSecondaryUser => role == UserRole.secondary;
  bool get isMember => role == UserRole.member;
  
  bool get hasParent => parentUserId != null && parentUserId!.isNotEmpty;
  bool get isInFamily => familyAccountId != null && familyAccountId!.isNotEmpty;

  // Validation des données
  bool get isDataValid {
    return name.isNotEmpty && 
           email.isNotEmpty && 
           passwordHash.isNotEmpty && 
           salt != null && 
           salt!.isNotEmpty &&
           dateOfBirth.isNotEmpty &&
           (!isMinor || hasParent); // Les mineurs doivent avoir un parent
  }

  // Met à jour les préférences
  void updatePreference(String key, dynamic value) {
    preferences ??= _getDefaultPreferences();
    preferences![key] = value;
  }

  // Obtient une préférence
  T? getPreference<T>(String key, [T? defaultValue]) {
    if (preferences == null) return defaultValue;
    return preferences![key] as T? ?? defaultValue;
  }

  // Marque l'email comme vérifié
  void markEmailAsVerified() {
    emailVerified = true;
    emailVerifiedAt = DateTime.now();
  }

  // Met à jour la dernière connexion
  void updateLastLogin() {
    lastLogin = DateTime.now();
    if (isInBox) save();
  }

  // Désactive l'utilisateur
  void deactivate() {
    isActive = false;
    if (isInBox) save();
  }

  // Conversion sécurisée vers JSON
  Map<String, dynamic> toSafeJson() {
    return {
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'userType': userType.toString(),
      'role': role.toString(),
      'isMinor': isMinor,
      'hasParent': hasParent,
      'isInFamily': isInFamily,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'hasMedicalInfo': diseases?.isNotEmpty == true || 
                       treatments?.isNotEmpty == true || 
                       allergies?.isNotEmpty == true,
    };
  }

  @override
  String toString() {
    return 'EnhancedUser{name: $name, email: $email, type: $userType, role: $role}';
  }
}

// Énumérations pour les nouveaux champs
@HiveType(typeId: 10)
enum UserRole {
  @HiveField(0)
  primary,    // Propriétaire principal du compte famille
  
  @HiveField(1)
  secondary,  // Utilisateur secondaire avec permissions étendues
  
  @HiveField(2)
  member,     // Membre normal de la famille
}

@HiveType(typeId: 11)
enum UserType {
  @HiveField(0)
  child,      // Moins de 13 ans
  
  @HiveField(1)
  teen,       // 13-17 ans
  
  @HiveField(2)
  adult,      // 18-64 ans
  
  @HiveField(3)
  senior,     // 65 ans et plus
}

// Adaptateurs Hive pour les énumérations
class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 10;

  @override
  UserRole read(BinaryReader reader) {
    return UserRole.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    writer.writeByte(obj.index);
  }
}

class UserTypeAdapter extends TypeAdapter<UserType> {
  @override
  final int typeId = 11;

  @override
  UserType read(BinaryReader reader) {
    return UserType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, UserType obj) {
    writer.writeByte(obj.index);
  }
}

// Exception de validation
class ValidationException implements Exception {
  final String message;
  final Map<String, String> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() => 'ValidationException: $message - $errors';
}