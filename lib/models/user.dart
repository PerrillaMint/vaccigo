// lib/models/user.dart - COMPLETELY REWRITTEN with null safety fixes
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String dateOfBirth;

  @HiveField(4)
  String? diseases;

  @HiveField(5)
  String? treatments;

  @HiveField(6)
  String? allergies;

  @HiveField(7)
  String? salt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime lastLogin;

  @HiveField(10)
  bool isActive;

  // Main constructor - Hive will use this for reconstruction
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
    createdAt = createdAt ?? DateTime.now(),
    lastLogin = lastLogin ?? DateTime.now();

  // Factory constructor for creating new users with plain password
  factory User.create({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool isActive = true,
  }) {
    try {
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      
      print('=== USER CREATION DEBUG ===');
      print('Creating user: $email');
      print('Generated salt: $salt');
      print('Password hash: $passwordHash');
      print('===========================');
      
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
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Secure password hashing
  static String _generateSalt() {
    try {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      final saltString = base64.encode(values);
      
      if (saltString.isEmpty) {
        throw Exception('Generated salt is empty');
      }
      
      return saltString;
    } catch (e) {
      print('Error generating salt: $e');
      rethrow;
    }
  }

  static String _hashPassword(String password, String salt) {
    try {
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (salt.isEmpty) {
        throw Exception('Salt cannot be empty');
      }
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      final hashString = digest.toString();
      
      if (hashString.isEmpty) {
        throw Exception('Generated hash is empty');
      }
      
      return hashString;
    } catch (e) {
      print('Error hashing password: $e');
      rethrow;
    }
  }

  // FIXED: Completely rewritten password verification with null safety
  bool verifyPassword(String password) {
    print('=== PASSWORD VERIFICATION DEBUG ===');
    print('Verifying password for user: $email');
    print('Input password length: ${password.length}');
    print('Stored salt: $salt');
    print('Stored hash: $passwordHash');
    
    try {
      // FIXED: Validate input
      if (password.isEmpty) {
        print('ERROR: Password is empty');
        print('===================================');
        return false;
      }
      
      // FIXED: Check if salt exists BEFORE using it
      if (salt == null) {
        print('ERROR: Salt is null - this user was not properly created');
        print('===================================');
        return false;
      }
      
      if (salt!.isEmpty) {
        print('ERROR: Salt is empty - this user was not properly created');
        print('===================================');
        return false;
      }
      
      // FIXED: Check if passwordHash exists
      if (passwordHash.isEmpty) {
        print('ERROR: Password hash is empty - this user was not properly created');
        print('===================================');
        return false;
      }
      
      // FIXED: Safe password verification with proper error handling
      final hashedInput = _hashPassword(password, salt!);
      final isValid = hashedInput == passwordHash;
      
      print('Generated hash from input: $hashedInput');
      print('Password matches: $isValid');
      print('===================================');
      
      return isValid;
      
    } catch (e) {
      print('ERROR during password verification: $e');
      print('Stack trace: ${StackTrace.current}');
      print('===================================');
      return false;
    }
  }

  // FIXED: Enhanced password update with validation and null safety
  void updatePassword(String newPassword) {
    try {
      if (newPassword.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);
      
      // Validate generated values
      if (newSalt.isEmpty || newHash.isEmpty) {
        throw Exception('Failed to generate valid salt or hash');
      }
      
      salt = newSalt;
      passwordHash = newHash;
      
      print('=== PASSWORD UPDATE DEBUG ===');
      print('Updated password for user: $email');
      print('New salt: $newSalt');
      print('New hash: $newHash');
      print('==============================');
      
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }

  // FIXED: Method to check if user data is valid with null safety
  bool get isDataValid {
    try {
      return name.isNotEmpty && 
             email.isNotEmpty && 
             passwordHash.isNotEmpty && 
             salt != null && 
             salt!.isNotEmpty &&
             dateOfBirth.isNotEmpty;
    } catch (e) {
      print('Error checking data validity: $e');
      return false;
    }
  }

  // FIXED: Method to repair user data if needed with null safety
  bool repairUserData(String plainPassword) {
    if (isDataValid) return true;
    
    try {
      print('=== REPAIRING USER DATA ===');
      print('User: $email');
      print('Missing salt: ${salt == null || (salt != null && salt!.isEmpty)}');
      print('Missing hash: ${passwordHash.isEmpty}');
      print('Missing name: ${name.isEmpty}');
      print('Missing email: ${email.isEmpty}');
      print('Missing dateOfBirth: ${dateOfBirth.isEmpty}');
      
      if (plainPassword.isEmpty) {
        print('Cannot repair: plainPassword is empty');
        print('===========================');
        return false;
      }
      
      // Only repair if we have the essential data
      if (name.isEmpty || email.isEmpty || dateOfBirth.isEmpty) {
        print('Cannot repair: Essential user data is missing');
        print('===========================');
        return false;
      }
      
      // Generate new salt and hash
      final newSalt = _generateSalt();
      final newHash = _hashPassword(plainPassword, newSalt);
      
      salt = newSalt;
      passwordHash = newHash;
      
      print('Repaired with new salt: $newSalt');
      print('===========================');
      
      return isDataValid;
      
    } catch (e) {
      print('Failed to repair user data: $e');
      print('===========================');
      return false;
    }
  }

  // Data validation methods with null safety
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
    if (RegExp(r'[<>"\/\\]').hasMatch(trimmedName)) {
      return 'Le nom contient des caractères invalides';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null) {
      return "L'email est requis";
    }
    
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return "L'email est requis";
    }
    
    final sanitizedEmail = trimmedEmail.toLowerCase();
    
    if (sanitizedEmail.length > 254) {
      return "L'email est trop long";
    }
    
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    );
    
    if (!emailRegex.hasMatch(sanitizedEmail)) {
      return "Format d'email invalide";
    }
    
    return null;
  }

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
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins une lettre';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    final weakPasswords = [
      '12345678', 'password', 'motdepasse', 'azerty123', 'qwerty123'
    ];
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'Ce mot de passe est trop faible';
    }
    
    return null;
  }

  static String? validateDateOfBirth(String? date) {
    if (date == null) {
      return 'La date de naissance est requise';
    }
    
    final trimmedDate = date.trim();
    if (trimmedDate.isEmpty) {
      return 'La date de naissance est requise';
    }
    
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
      
      if (day < 1 || day > 31) return 'Jour invalide';
      if (month < 1 || month > 12) return 'Mois invalide';
      
      final currentYear = DateTime.now().year;
      if (year < 1900 || year > currentYear) return 'Année invalide';
      
      final age = currentYear - year;
      if (age < 0) return 'Date de naissance future invalide';
      if (age > 150) return 'Âge invalide';
      
      final birthDate = DateTime(year, month, day);
      if (birthDate.day != day || birthDate.month != month || birthDate.year != year) {
        return 'Date invalide';
      }
      
      return null;
    } catch (e) {
      return 'Date invalide';
    }
  }

  // Sanitize input data with null safety
  static String _sanitizeString(String? input) {
    if (input == null) return '';
    
    return input
        .replaceAll(RegExp(r'[<>"\/\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Validate all user data with null safety
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

  // Secure factory constructor with null safety
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
      print('Error in createSecure: $e');
      rethrow;
    }
  }

  // Update last login timestamp with null safety
  void updateLastLogin() {
    try {
      lastLogin = DateTime.now();
      if (isInBox) {
        save();
      }
    } catch (e) {
      print('Failed to save last login time: $e');
    }
  }

  // Deactivate user with null safety
  void deactivate() {
    try {
      isActive = false;
      if (isInBox) {
        save();
      }
    } catch (e) {
      print('Failed to save user deactivation: $e');
    }
  }

  // Get age from date of birth with null safety
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
      
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age >= 0 ? age : 0;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  // Convert to safe JSON (no sensitive data) with null safety
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
      };
    } catch (e) {
      print('Error creating safe JSON: $e');
      return {
        'name': name,
        'email': email,
        'error': 'Failed to serialize user data',
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

  // FIXED: Safe method to get diseases
  String get safeDiseases => diseases ?? '';
  
  // FIXED: Safe method to get treatments  
  String get safeTreatments => treatments ?? '';
  
  // FIXED: Safe method to get allergies
  String get safeAllergies => allergies ?? '';
  
  // FIXED: Safe method to check if user has medical info
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

// Custom validation exception with null safety
class ValidationException implements Exception {
  final String message;
  final Map<String, String> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() {
    try {
      return 'ValidationException: $message - Errors: $errors';
    } catch (e) {
      return 'ValidationException: $message';
    }
  }
}