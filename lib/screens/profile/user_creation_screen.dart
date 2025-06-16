// lib/screens/profile/user_creation_screen.dart - COMPLETE REWRITE with all fixes
import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../services/email_service.dart';

class UserCreationScreen extends StatefulWidget {
  const UserCreationScreen({Key? key}) : super(key: key);

  @override
  State<UserCreationScreen> createState() => _UserCreationScreenState();
}

class _UserCreationScreenState extends State<UserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _databaseService = DatabaseService();
  final _emailService = EmailService();
  
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _emailTaken = false;
  bool _passwordsMatch = true;
  Map<String, String>? _pendingVaccinationData;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordsMatch);
    _confirmPasswordController.addListener(_checkPasswordsMatch);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, String>) {
      _pendingVaccinationData = arguments;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _checkPasswordsMatch() {
    final match = _passwordController.text == _confirmPasswordController.text;
    if (match != _passwordsMatch) {
      setState(() {
        _passwordsMatch = match;
      });
    }
  }

  void _onEmailChanged() {
    setState(() {
      _emailTaken = false;
    });
    
    final email = _emailController.text.trim();
    if (email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _checkEmailAvailabilityDebounced(email);
    }
  }

  Timer? _emailCheckTimer;
  void _checkEmailAvailabilityDebounced(String email) {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Créer un compte',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.secondary),
            onPressed: _showHelpDialog,
            tooltip: 'Aide',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        _buildHeader(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Form fields
                        _buildFormFields(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Password strength indicator
                        if (_passwordController.text.isNotEmpty)
                          _buildPasswordStrengthIndicator(),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Create account button
                        _buildCreateAccountButton(),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Terms and privacy notice
                        _buildTermsNotice(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_add,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Création de votre compte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _pendingVaccinationData != null 
                ? 'Créez votre compte pour sauvegarder votre vaccination'
                : 'Rejoignez Vaccigo pour gérer vos vaccinations',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_pendingVaccinationData != null) ...[
            const SizedBox(height: AppSpacing.md),
            StatusBadge(
              text: 'Vaccination ${_pendingVaccinationData!['vaccineName']?.split(' ').first ?? 'données'} en attente',
              type: StatusType.success,
              icon: Icons.vaccines,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full name field
        AppTextField(
          label: 'Nom complet',
          hint: 'Prénom et nom de famille',
          controller: _nameController,
          prefixIcon: Icons.person,
          isRequired: true,
          keyboardType: TextInputType.name,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre nom complet';
            }
            if (value.trim().length < 2) {
              return 'Le nom doit contenir au moins 2 caractères';
            }
            if (value.length > 100) {
              return 'Le nom est trop long (max 100 caractères)';
            }
            if (RegExp(r'[<>"\/\\]').hasMatch(value)) {
              return 'Le nom contient des caractères invalides';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Email field with availability check
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Adresse email',
              hint: 'votre@email.com',
              controller: _emailController,
              prefixIcon: Icons.email,
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre adresse email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format d\'email invalide';
                }
                if (_emailTaken) {
                  return 'Cette adresse email est déjà utilisée';
                }
                return null;
              },
            ),
            if (_isCheckingEmail) ...[
              const SizedBox(height: AppSpacing.xs),
              const Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Vérification de la disponibilité...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (_emailTaken) ...[
              const SizedBox(height: AppSpacing.xs),
              const Row(
                children: [
                  Icon(Icons.error, size: 12, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Cette adresse email est déjà utilisée',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Password field
        AppTextField(
          label: 'Mot de passe',
          hint: 'Minimum 8 caractères',
          controller: _passwordController,
          prefixIcon: Icons.lock,
          isPassword: true,
          isRequired: true,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 8) {
              return 'Le mot de passe doit contenir au moins 8 caractères';
            }
            if (value.length > 128) {
              return 'Le mot de passe est trop long (max 128 caractères)';
            }
            if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
              return 'Le mot de passe doit contenir au moins une lettre';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Le mot de passe doit contenir au moins un chiffre';
            }
            
            // Check for weak passwords
            final weakPasswords = [
              '12345678', 'password', 'motdepasse', 'azerty123', 'qwerty123'
            ];
            if (weakPasswords.contains(value.toLowerCase())) {
              return 'Ce mot de passe est trop faible';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Confirm password field
        AppTextField(
          label: 'Confirmer le mot de passe',
          hint: 'Retapez votre mot de passe',
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isRequired: true,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer votre mot de passe';
            }
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
        ),
        
        // Password match indicator
        if (_confirmPasswordController.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                _passwordsMatch ? Icons.check_circle : Icons.error,
                size: 16,
                color: _passwordsMatch ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _passwordsMatch 
                    ? 'Les mots de passe correspondent'
                    : 'Les mots de passe ne correspondent pas',
                style: TextStyle(
                  fontSize: 12,
                  color: _passwordsMatch ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: AppSpacing.lg),
        
        // Date of birth field
        _buildDateField(),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.cake,
              size: 20,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Date de naissance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _dateOfBirthController,
          readOnly: true,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            hintText: 'JJ/MM/AAAA',
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.textMuted),
          ),
          onTap: _isLoading ? null : _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez sélectionner votre date de naissance';
            }
            
            // Additional date validation
            final error = User.validateDateOfBirth(value);
            return error;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);
    
    Color strengthColor;
    String strengthText;
    
    if (strength < 0.3) {
      strengthColor = AppColors.error;
      strengthText = 'Faible';
    } else if (strength < 0.7) {
      strengthColor = AppColors.warning;
      strengthText = 'Moyen';
    } else {
      strengthColor = AppColors.success;
      strengthText = 'Fort';
    }
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: strengthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: strengthColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Force du mot de passe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: strength,
            backgroundColor: strengthColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPasswordRequirements(password),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements(String password) {
    final requirements = [
      {'text': 'Au moins 8 caractères', 'met': password.length >= 8},
      {'text': 'Au moins une lettre', 'met': RegExp(r'[a-zA-Z]').hasMatch(password)},
      {'text': 'Au moins un chiffre', 'met': RegExp(r'[0-9]').hasMatch(password)},
      {'text': 'Pas un mot de passe commun', 'met': !['12345678', 'password', 'motdepasse'].contains(password.toLowerCase())},
    ];
    
    return Column(
      children: requirements.map((req) {
        final met = req['met'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 12,
                color: met ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                req['text'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: met ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // Length score
    if (password.length >= 8) score += 0.25;
    if (password.length >= 12) score += 0.15;
    
    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.15;
    
    // Penalty for common passwords
    final commonPasswords = ['password', 'motdepasse', '12345678', 'azerty123'];
    if (commonPasswords.contains(password.toLowerCase())) score -= 0.5;
    
    return score.clamp(0.0, 1.0);
  }

  Widget _buildCreateAccountButton() {
    return AppButton(
      text: _isLoading ? 'Création en cours...' : 'Créer mon compte',
      icon: _isLoading ? null : Icons.person_add,
      isLoading: _isLoading,
      onPressed: _isLoading || _emailTaken || !_passwordsMatch ? null : _createUser,
      width: double.infinity,
    );
  }

  Widget _buildTermsNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppColors.info,
                size: 16,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Protection de vos données',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'En créant un compte, vous acceptez que vos données soient stockées de manière sécurisée et utilisées uniquement pour la gestion de vos vaccinations.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateOfBirthController.text = formattedDate;
    }
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (!mounted) return;
    
    setState(() {
      _isCheckingEmail = true;
      _emailTaken = false;
    });

    try {
      final exists = await _databaseService.emailExists(email);
      if (mounted) {
        setState(() {
          _emailTaken = exists;
          _isCheckingEmail = false;
        });
        
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text('Cette adresse email est déjà utilisée'),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  Future<void> _createUser() async {
    // Clear any previous timers
    _emailCheckTimer?.cancel();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_emailTaken) {
      _showErrorMessage('Cette adresse email est déjà utilisée');
      return;
    }

    if (!_passwordsMatch) {
      _showErrorMessage('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Double-check email availability
      final emailExists = await _databaseService.emailExists(_emailController.text.trim());
      if (emailExists) {
        throw Exception('Cette adresse email est déjà utilisée');
      }

      // Create user with secure factory method
      final user = User.createSecure(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        dateOfBirth: _dateOfBirthController.text.trim(),
      );

      // Save user to database
      await _databaseService.saveUser(user);
      print('User created successfully: ${user.email}');

      // Send welcome email (don't fail if email fails)
      try {
        final emailSent = await _emailService.sendWelcomeEmail(
          user.email, 
          user.name.split(' ').first, // First name only
        );
        print('Welcome email ${emailSent ? 'sent' : 'failed'} to ${user.email}');
      } catch (emailError) {
        print('Welcome email failed: $emailError');
        // Continue with user creation even if email fails
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Compte créé avec succès! ${_pendingVaccinationData != null ? 'Finalisation...' : 'Bienvenue!'}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to next screen
        Navigator.pushNamed(
          context, 
          '/additional-info', 
          arguments: {
            'user': user,
            'vaccinationData': _pendingVaccinationData,
          },
        );
      }
    } catch (e) {
      print('User creation error: $e');
      if (mounted) {
        String errorMessage;
        if (e is ValidationException) {
          errorMessage = 'Données invalides: ${e.errors.values.first}';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Cette adresse email est déjà utilisée';
        } else {
          errorMessage = 'Erreur lors de la création du compte. Veuillez réessayer.';
        }
        
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Aide - Création de compte',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseils pour créer votre compte:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text('• Utilisez votre vrai nom pour faciliter l\'identification'),
                Text('• Choisissez une adresse email que vous consultez régulièrement'),
                Text('• Créez un mot de passe fort avec lettres et chiffres'),
                Text('• Vérifiez votre date de naissance'),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Sécurité:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text('• Vos données sont chiffrées et stockées localement'),
                Text('• Votre mot de passe est haché de manière sécurisée'),
                Text('• Aucune donnée n\'est partagée avec des tiers'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }
}