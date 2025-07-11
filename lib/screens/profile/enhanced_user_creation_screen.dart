// lib/screens/profile/enhanced_user_creation_screen.dart - Fixed to use EnhancedUser
import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/enhanced_user.dart';
import '../../services/database_service.dart';
import '../../services/multi_user_service.dart';
import '../../services/email_service.dart';

class EnhancedUserCreationScreen extends StatefulWidget {
  const EnhancedUserCreationScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedUserCreationScreen> createState() => _EnhancedUserCreationScreenState();
}

class _EnhancedUserCreationScreenState extends State<EnhancedUserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Contrôleurs de formulaire
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _familyNameController = TextEditingController();
  
  // Services
  final _databaseService = DatabaseService();
  final _multiUserService = MultiUserService();
  final _emailService = EmailService();
  
  // État du formulaire
  int _currentPage = 0;
  bool _isLoading = false;
  bool _emailTaken = false;
  bool _isCheckingEmail = false;
  bool _passwordsMatch = true;
  bool _formSubmitted = false;
  bool _createFamilyAccount = false;
  UserType _selectedUserType = UserType.adult;
  String? _parentUserId;
  Map<String, String>? _pendingVaccinationData;
  
  // Validation en temps réel
  Timer? _emailCheckTimer;

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
    _emailCheckTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _familyNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _checkPasswordsMatch() {
    final match = _passwordController.text == _confirmPasswordController.text;
    if (match != _passwordsMatch) {
      setState(() => _passwordsMatch = match);
    }
  }

  void _onEmailChanged() {
    setState(() => _emailTaken = false);
    
    final email = _emailController.text.trim();
    if (email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _checkEmailAvailabilityDebounced(email);
    }
  }

  void _checkEmailAvailabilityDebounced(String email) {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(email);
    });
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (!mounted) return;
    
    setState(() => _isCheckingEmail = true);

    try {
      final exists = await _databaseService.emailExists(email);
      if (mounted) {
        setState(() {
          _emailTaken = exists;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Créer un compte',
        actions: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousPage,
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu du formulaire
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoPage(),
                _buildUserTypePage(),
                _buildContactInfoPage(),
                _buildFamilyAccountPage(),
                _buildConfirmationPage(),
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppColors.success 
                    : isActive 
                        ? AppColors.primary 
                        : AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        autovalidateMode: _formSubmitted 
            ? AutovalidateMode.onUserInteraction 
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Informations de base',
              subtitle: 'Créons votre profil personnel',
              icon: Icons.person_add,
            ),
            
            const SizedBox(height: 24),
            
            // Nom complet
            AppTextField(
              label: 'Nom complet',
              hint: 'Prénom et nom',
              controller: _nameController,
              prefixIcon: Icons.person,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom requis';
                }
                if (value.trim().length < 2) {
                  return 'Minimum 2 caractères';
                }
                if (value.trim().length > 100) {
                  return 'Nom trop long';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Email
            _buildEmailField(),
            
            const SizedBox(height: 16),
            
            // Mot de passe
            AppTextField(
              label: 'Mot de passe',
              hint: 'Min. 8 caractères avec lettres et chiffres',
              controller: _passwordController,
              prefixIcon: Icons.lock,
              isPassword: true,
              isRequired: true,
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
            
            const SizedBox(height: 16),
            
            // Confirmation mot de passe
            AppTextField(
              label: 'Confirmer le mot de passe',
              hint: 'Retapez votre mot de passe',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isRequired: true,
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
            
            // Indicateur de correspondance des mots de passe
            if (_confirmPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _passwordsMatch ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _passwordsMatch ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _passwordsMatch 
                        ? 'Mots de passe identiques'
                        : 'Mots de passe différents',
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordsMatch ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Date de naissance
            _buildDateField(),
            
            if (_passwordController.text.isNotEmpty)
              _buildPasswordStrengthIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Type d\'utilisateur',
            subtitle: 'Aidez-nous à personnaliser votre expérience',
            icon: Icons.group,
          ),
          
          const SizedBox(height: 24),
          
          // Sélection automatique basée sur l'âge
          if (_dateOfBirthController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détection automatique',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        Text(
                          'Basé sur votre âge: ${_getCalculatedAge()} ans',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Options de type d'utilisateur
          ...UserType.values.map((type) => _buildUserTypeOption(type)),
          
          // Information spéciale pour les mineurs
          if (_selectedUserType == UserType.child || _selectedUserType == UserType.teen) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.family_restroom, color: AppColors.warning),
                      SizedBox(width: 12),
                      Text(
                        'Compte supervisé',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Un parent ou tuteur devra valider la création de ce compte et en assurer la supervision.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildParentSelectionField(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Informations de contact',
            subtitle: 'Optionnel - pour une meilleure sécurité',
            icon: Icons.contact_phone,
          ),
          
          const SizedBox(height: 24),
          
          // Numéro de téléphone
          AppTextField(
            label: 'Numéro de téléphone',
            hint: '+33 6 12 34 56 78',
            controller: _phoneController,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^\+?[\d\s\-\(\)]{8,}$').hasMatch(value)) {
                  return 'Format de téléphone invalide';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contact d'urgence
          AppTextField(
            label: 'Contact d\'urgence',
            hint: 'Nom et téléphone d\'un proche',
            controller: _emergencyContactController,
            prefixIcon: Icons.emergency,
            maxLines: 2,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 5) {
                  return 'Information trop courte';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Information sur l'utilisation des données
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.privacy_tip, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Text(
                      'Confidentialité',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ces informations sont stockées de manière sécurisée et ne seront utilisées qu\'en cas d\'urgence ou pour vous contacter concernant votre compte.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      'Données chiffrées localement',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyAccountPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Compte famille',
            subtitle: 'Gérez les vaccinations de toute la famille',
            icon: Icons.family_restroom,
          ),
          
          const SizedBox(height: 24),
          
          // Option création compte famille
          SwitchListTile(
            title: const Text(
              'Créer un compte famille',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            subtitle: const Text(
              'Permet d\'ajouter d\'autres membres de la famille',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            value: _createFamilyAccount,
            onChanged: (value) {
              setState(() => _createFamilyAccount = value);
            },
            activeColor: AppColors.secondary,
          ),
          
          if (_createFamilyAccount) ...[
            const SizedBox(height: 16),
            
            // Nom de la famille
            AppTextField(
              label: 'Nom de la famille',
              hint: 'Famille Dupont',
              controller: _familyNameController,
              prefixIcon: Icons.home,
              isRequired: true,
              validator: (value) {
                if (_createFamilyAccount && (value == null || value.trim().isEmpty)) {
                  return 'Nom de famille requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Avantages du compte famille
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avantages du compte famille:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Gérez jusqu\'à 6 membres de la famille',
                    'Partagez les carnets de vaccination',
                    'Rappels coordonnés pour toute la famille',
                    'Gestion des vaccinations des enfants',
                    'Historique familial des vaccinations',
                  ].map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Confirmation',
            subtitle: 'Vérifiez vos informations avant création',
            icon: Icons.check_circle_outline,
          ),
          
          const SizedBox(height: 24),
          
          // Résumé des informations
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildSummaryItem('Nom', _nameController.text),
                _buildSummaryItem('Email', _emailController.text),
                _buildSummaryItem('Date de naissance', _dateOfBirthController.text),
                _buildSummaryItem('Âge', '${_getCalculatedAge()} ans'),
                _buildSummaryItem('Type d\'utilisateur', _getUserTypeLabel(_selectedUserType)),
                
                if (_phoneController.text.isNotEmpty)
                  _buildSummaryItem('Téléphone', _phoneController.text),
                
                if (_emergencyContactController.text.isNotEmpty)
                  _buildSummaryItem('Contact d\'urgence', _emergencyContactController.text),
                
                if (_createFamilyAccount)
                  _buildSummaryItem('Compte famille', _familyNameController.text),
                
                if (_selectedUserType == UserType.child || _selectedUserType == UserType.teen)
                  _buildSummaryItem('Supervision', 'Compte supervisé par un parent'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Conditions d'utilisation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En créant ce compte, vous acceptez:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Le stockage sécurisé de vos données sur cet appareil\n'
                  '• L\'utilisation de l\'application selon nos conditions\n'
                  '• La réception de notifications liées à la santé',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          controller: _emailController,
          prefixIcon: Icons.email,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
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
        
        // Indicateurs d'état email
        if (_isCheckingEmail) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
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
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.error, size: 12, color: AppColors.error),
              SizedBox(width: 8),
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
    return AppTextField(
      label: 'Date de naissance',
      hint: 'JJ/MM/AAAA',
      controller: _dateOfBirthController,
      prefixIcon: Icons.cake,
      isRequired: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Date de naissance requise';
        }
        if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
          return 'Format invalide (JJ/MM/AAAA)';
        }
        return null;
      },
      onChanged: (value) {
        // Met à jour automatiquement le type d'utilisateur basé sur l'âge
        if (value.length == 10) {
          _updateUserTypeFromAge();
        }
      },
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength,
            backgroundColor: strengthColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(UserType type) {
    final isSelected = _selectedUserType == type;
    final age = _getCalculatedAge();
    final isRecommended = _isUserTypeRecommended(type, age);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedUserType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.secondary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppColors.secondary
                  : AppColors.textMuted.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getUserTypeIcon(type),
                color: isSelected ? AppColors.secondary : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getUserTypeLabel(type),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Recommandé',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUserTypeDescription(type),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentSelectionField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent/Tuteur requis',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Un parent ou tuteur devra confirmer la création de ce compte après votre inscription.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: AppButton(
                text: 'Précédent',
                style: AppButtonStyle.secondary,
                onPressed: _previousPage,
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: AppButton(
              text: _currentPage == 4 ? 'Créer le compte' : 'Suivant',
              isLoading: _isLoading,
              onPressed: _currentPage == 4 ? _createUser : _nextPage,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage++);
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  bool _validateCurrentPage() {
    setState(() => _formSubmitted = true);
    
    switch (_currentPage) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return true; // Type d'utilisateur toujours valide
      case 2:
        return true; // Informations de contact optionnelles
      case 3:
        if (_createFamilyAccount && _familyNameController.text.trim().isEmpty) {
          _showErrorMessage('Nom de famille requis pour le compte famille');
          return false;
        }
        return true;
      case 4:
        return true; // Page de confirmation
      default:
        return false;
    }
  }

  void _updateUserTypeFromAge() {
    final age = _getCalculatedAge();
    UserType newType;
    
    if (age < 13) {
      newType = UserType.child;
    } else if (age < 18) {
      newType = UserType.teen;
    } else if (age >= 65) {
      newType = UserType.senior;
    } else {
      newType = UserType.adult;
    }
    
    if (newType != _selectedUserType) {
      setState(() => _selectedUserType = newType);
    }
  }

  int _getCalculatedAge() {
    try {
      if (_dateOfBirthController.text.length == 10) {
        final parts = _dateOfBirthController.text.split('/');
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
      }
    } catch (e) {
      return 25; // Age par défaut
    }
    return 25;
  }

  bool _isUserTypeRecommended(UserType type, int age) {
    switch (type) {
      case UserType.child:
        return age < 13;
      case UserType.teen:
        return age >= 13 && age < 18;
      case UserType.adult:
        return age >= 18 && age < 65;
      case UserType.senior:
        return age >= 65;
    }
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.child:
        return Icons.child_care;
      case UserType.teen:
        return Icons.school;
      case UserType.adult:
        return Icons.person;
      case UserType.senior:
        return Icons.elderly;
    }
  }

  String _getUserTypeLabel(UserType type) {
    switch (type) {
      case UserType.child:
        return 'Enfant';
      case UserType.teen:
        return 'Adolescent';
      case UserType.adult:
        return 'Adulte';
      case UserType.senior:
        return 'Senior';
    }
  }

  String _getUserTypeDescription(UserType type) {
    switch (type) {
      case UserType.child:
        return 'Moins de 13 ans - Supervision parentale requise';
      case UserType.teen:
        return '13-17 ans - Supervision parentale recommandée';
      case UserType.adult:
        return '18-64 ans - Compte autonome complet';
      case UserType.senior:
        return '65 ans et plus - Fonctionnalités adaptées';
    }
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

  Future<void> _createUser() async {
    setState(() => _isLoading = true);

    try {
      final user = EnhancedUser.createSecure(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: _dateOfBirthController.text.trim(),
        userType: _selectedUserType,
        role: _createFamilyAccount ? UserRole.primary : UserRole.member,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty ? _emergencyContactController.text.trim() : null,
      );

      await _databaseService.saveUser(user);
      await _databaseService.setCurrentUser(user);

      // Crée le compte famille si demandé
      if (_createFamilyAccount) {
        try {
          await _multiUserService.createFamilyAccount(
            primaryUser: user,
            familyName: _familyNameController.text.trim(),
          );
        } catch (e) {
          print('Erreur création compte famille: $e');
          // Continue même si la création du compte famille échoue
        }
      }

      // Envoie l'email de bienvenue
      try {
        await _emailService.sendWelcomeEmail(
          user.email,
          user.name.split(' ').first,
        );
      } catch (e) {
        print('Erreur envoi email bienvenue: $e');
        // Ne bloque pas pour l'email
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigation vers l'écran suivant
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
      if (mounted) {
        _showErrorMessage('Erreur: $e');
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
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}