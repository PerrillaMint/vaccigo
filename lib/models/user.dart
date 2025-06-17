// lib/models/user.dart - FIXED password verification and salt handling
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
  }

  // Secure password hashing
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

  // FIXED: Enhanced password verification with better debugging
  bool verifyPassword(String password) {
    print('=== PASSWORD VERIFICATION DEBUG ===');
    print('Verifying password for user: $email');
    print('Input password length: ${password.length}');
    print('Stored salt: $salt');
    print('Stored hash: $passwordHash');
    
    // Check if salt exists
    if (salt == null || salt!.isEmpty) {
      print('ERROR: Salt is null or empty - this user was not properly created');
      print('Attempting to fix user by regenerating salt and hash...');
      
      // FIXED: Try to fix user with missing salt
      if (password.isNotEmpty) {
        try {
          final newSalt = _generateSalt();
          final newHash = _hashPassword(password, newSalt);
          
          // Update the user with proper salt and hash
          this.salt = newSalt;
          this.passwordHash = newHash;
          
          // Save to database if possible
          if (isInBox) {
            save();
          }
          
          print('User fixed with new salt: $newSalt');
          return true;
        } catch (e) {
          print('Failed to fix user: $e');
          return false;
        }
      }
      return false;
    }
    
    // Verify password
    final hashedInput = _hashPassword(password, salt!);
    final isValid = hashedInput == passwordHash;
    
    print('Generated hash from input: $hashedInput');
    print('Password matches: $isValid');
    print('===================================');
    
    return isValid;
  }

  // FIXED: Enhanced password update with validation
  void updatePassword(String newPassword) {
    if (newPassword.isEmpty) {
      throw Exception('Password cannot be empty');
    }
    
    final newSalt = _generateSalt();
    final newHash = _hashPassword(newPassword, newSalt);
    
    salt = newSalt;
    passwordHash = newHash;
    
    print('=== PASSWORD UPDATE DEBUG ===');
    print('Updated password for user: $email');
    print('New salt: $newSalt');
    print('New hash: $newHash');
    print('==============================');
  }

  // FIXED: Method to check if user data is valid
  bool get isDataValid {
    return name.isNotEmpty && 
           email.isNotEmpty && 
           passwordHash.isNotEmpty && 
           salt != null && 
           salt!.isNotEmpty;
  }

  // FIXED: Method to repair user data if needed
  bool repairUserData(String plainPassword) {
    if (isDataValid) return true;
    
    try {
      print('=== REPAIRING USER DATA ===');
      print('User: $email');
      print('Missing salt: ${salt == null || salt!.isEmpty}');
      print('Missing hash: ${passwordHash.isEmpty}');
      
      if (plainPassword.isNotEmpty) {
        final newSalt = _generateSalt();
        final newHash = _hashPassword(plainPassword, newSalt);
        
        salt = newSalt;
        passwordHash = newHash;
        
        print('Repaired with new salt: $newSalt');
        print('===========================');
        
        return true;
      }
    } catch (e) {
      print('Failed to repair user data: $e');
    }
    
    return false;
  }

  // Data validation methods
  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (name.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (name.length > 100) {
      return 'Le nom est trop long';
    }
    if (RegExp(r'[<>"\/\\]').hasMatch(name)) {
      return 'Le nom contient des caractères invalides';
    }
    return null;
  }

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return "L'email est requis";
    }
    
    final sanitizedEmail = email.trim().toLowerCase();
    
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

  static String? validatePassword(String password) {
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

  static String? validateDateOfBirth(String date) {
    if (date.trim().isEmpty) {
      return 'La date de naissance est requise';
    }
    
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(date)) {
      return 'Format invalide. Utilisez JJ/MM/AAAA';
    }
    
    try {
      final parts = date.split('/');
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

  // Sanitize input data
  static String _sanitizeString(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\/\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Validate all user data
  static Map<String, String> validateUserData({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
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

  // Secure factory constructor
  factory User.createSecure({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    String? diseases,
    String? treatments,
    String? allergies,
  }) {
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
    
    return User.create(
      name: _sanitizeString(name),
      email: email.trim().toLowerCase(),
      password: password,
      dateOfBirth: dateOfBirth.trim(),
      diseases: diseases?.isNotEmpty == true ? _sanitizeString(diseases!) : null,
      treatments: treatments?.isNotEmpty == true ? _sanitizeString(treatments!) : null,
      allergies: allergies?.isNotEmpty == true ? _sanitizeString(allergies!) : null,
    );
  }

  // Update last login timestamp
  void updateLastLogin() {
    lastLogin = DateTime.now();
    try {
      if (isInBox) {
        save();
      }
    } catch (e) {
      print('Failed to save last login time: $e');
    }
  }

  // Deactivate user
  void deactivate() {
    isActive = false;
    try {
      if (isInBox) {
        save();
      }
    } catch (e) {
      print('Failed to save user deactivation: $e');
    }
  }

  // Get age from date of birth
  int get age {
    try {
      final parts = dateOfBirth.split('/');
      final birthDate = DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // Convert to safe JSON (no sensitive data)
  Map<String, dynamic> toSafeJson() {
    return {
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'hasValidData': isDataValid,
    };
  }

  @override
  String toString() {
    return 'User{name: $name, email: $email, isActive: $isActive, hasValidData: $isDataValid}';
  }
}

// Custom validation exception
class ValidationException implements Exception {
  final String message;
  final Map<String, String> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() {
    return 'ValidationException: $message - Errors: $errors';
  }
}