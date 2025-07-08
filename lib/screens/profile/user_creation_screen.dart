// lib/screens/profile/user_creation_screen.dart - COMPLETELY FIXED account creation issues
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
  bool _formSubmitted = false;  // Track if form has been submitted
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

  Future<void> _checkEmailAvailability(String email) async {
    if (!mounted) return;
    
    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final exists = await _databaseService.emailExists(email);
      if (mounted) {
        setState(() {
          _emailTaken = exists;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Créer un compte',
        actions: [
          if (MediaQuery.of(context).size.width > 320)
            IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.secondary),
              onPressed: _showHelpDialog,
              tooltip: 'Aide',
            ),
        ],
      ),
      body: ColumnScrollWrapper(
        children: [
          _buildHeader(),
          
          SizedBox(height: MediaQuery.of(context).size.height > 600 ? AppSpacing.xl : AppSpacing.lg),
          
          // FIXED: Proper Form widget with validation
          Form(
            key: _formKey,
            // FIXED: Only validate after form submission attempt
            autovalidateMode: _formSubmitted 
                ? AutovalidateMode.onUserInteraction 
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                _buildFormFields(),
                
                if (_passwordController.text.isNotEmpty && MediaQuery.of(context).size.height > 600)
                  _buildPasswordStrengthIndicator(),
                
                SizedBox(height: MediaQuery.of(context).size.height > 600 ? AppSpacing.xl : AppSpacing.lg),
                
                _buildCreateAccountButton(),
                
                const SizedBox(height: AppSpacing.lg),
                
                if (MediaQuery.of(context).size.height > 600)
                  _buildTermsNotice(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400 || MediaQuery.of(context).size.height < 600;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withOpacity(0.1),
                AppColors.light.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSmallScreen) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                'Création de votre compte',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _pendingVaccinationData != null 
                    ? 'Créez votre compte pour sauvegarder'
                    : 'Rejoignez l\'application',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_pendingVaccinationData != null && !isSmallScreen) ...[
                const SizedBox(height: AppSpacing.md),
                StatusBadge(
                  text: 'Vaccination en attente',
                  type: StatusType.success,
                  icon: Icons.vaccines,
                  isCompact: isSmallScreen,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormFields() {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final spacing = isSmallScreen ? AppSpacing.md : AppSpacing.lg;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FIXED: Simplified text field with proper validation
        _buildTextField(
          label: 'Nom complet',
          hint: 'Prénom et nom',
          controller: _nameController,
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nom requis';
            }
            if (value.trim().length < 2) {
              return 'Minimum 2 caractères';
            }
            return null;
          },
        ),
        
        SizedBox(height: spacing),
        
        // FIXED: Email field with better error handling
        _buildEmailField(),
        
        SizedBox(height: spacing),
        
        // FIXED: Password field
        _buildTextField(
          label: 'Mot de passe',
          hint: 'Min. 8 caractères',
          controller: _passwordController,
          icon: Icons.lock,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 8) {
              return 'Minimum 8 caractères';
            }
            if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
              return 'Au moins une lettre requise';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Au moins un chiffre requis';
            }
            return null;
          },
        ),
        
        SizedBox(height: spacing),
        
        // FIXED: Confirm password field
        _buildTextField(
          label: 'Confirmer',
          hint: 'Retapez le mot de passe',
          controller: _confirmPasswordController,
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirmation requise';
            }
            if (value != _passwordController.text) {
              return 'Mots de passe différents';
            }
            return null;
          },
        ),
        
        // FIXED: Password match indicator
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
              Expanded(
                child: Text(
                  _passwordsMatch 
                      ? 'Mots de passe identiques'
                      : 'Mots de passe différents',
                  style: TextStyle(
                    fontSize: 12,
                    color: _passwordsMatch ? AppColors.success : AppColors.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        
        SizedBox(height: spacing),
        
        // FIXED: Date field
        _buildDateField(),
      ],
    );
  }

  // FIXED: Simplified text field builder
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text(
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
          controller: controller,
          obscureText: isPassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // FIXED: Better email field with status indicators
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.email, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text(
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
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'votre@email.com',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email requis';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email invalide';
            }
            if (_emailTaken) {
              return 'Email déjà utilisé';
            }
            return null;
          },
        ),
        
        // Email status indicators
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
                'Vérification...',
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
                'Email déjà utilisé',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.cake, size: 20, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Date de naissance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          decoration: InputDecoration(
            hintText: 'JJ/MM/AAAA',
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onTap: _isLoading ? null : _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Date de naissance requise';
            }
            return null;
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
      margin: const EdgeInsets.only(top: AppSpacing.md),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
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
        ],
      ),
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double score = 0.0;
    
    if (password.length >= 8) score += 0.25;
    if (password.length >= 12) score += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.15;
    
    return score.clamp(0.0, 1.0);
  }

  Widget _buildCreateAccountButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 320,
        minHeight: 48,
      ),
      child: AppButton(
        text: _isLoading ? 'Création...' : 'Créer mon compte',
        icon: _isLoading ? null : Icons.person_add,
        isLoading: _isLoading,
        onPressed: _isLoading || _emailTaken || !_passwordsMatch ? null : _createUser,
        width: double.infinity,
      ),
    );
  }

  Widget _buildTermsNotice() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
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
                  'Protection des données',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Vos données sont stockées de manière sécurisée.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

  // FIXED: Main account creation logic
  Future<void> _createUser() async {
    _emailCheckTimer?.cancel();
    
    // FIXED: Set form as submitted to enable validation
    setState(() {
      _formSubmitted = true;
    });
    
    // FIXED: Validate the form properly
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Veuillez corriger les erreurs dans le formulaire');
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
      // FIXED: Additional email check before creation
      final emailExists = await _databaseService.emailExists(_emailController.text.trim());
      if (emailExists) {
        throw Exception('Cette adresse email est déjà utilisée');
      }

      // FIXED: Create user with proper error handling
      final user = User.createSecure(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        dateOfBirth: _dateOfBirthController.text.trim(),
      );

      // FIXED: Save user to database
      await _databaseService.saveUser(user);

      // FIXED: Set current user session
      await _databaseService.setCurrentUser(user);

      // Try to send welcome email (don't fail if this fails)
      try {
        await _emailService.sendWelcomeEmail(
          user.email, 
          user.name.split(' ').first,
        );
      } catch (emailError) {
        print('Welcome email failed: $emailError');
        // Don't show error to user for email failure
      }

      if (mounted) {
        // FIXED: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Compte créé avec succès!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        
        // FIXED: Navigate to next screen
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
          errorMessage = 'Données invalides: ${e.message}';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Email déjà utilisé ou invalide';
        } else {
          errorMessage = 'Erreur de création de compte. Réessayez.';
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
            'Aide',
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
                Text('• Utilisez votre vrai nom complet'),
                Text('• Email valide requis pour la connexion'),
                Text('• Mot de passe: minimum 8 caractères avec lettres et chiffres'),
                Text('• Date de naissance pour personnaliser votre profil'),
                Text('• Vos données sont sécurisées localement'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}