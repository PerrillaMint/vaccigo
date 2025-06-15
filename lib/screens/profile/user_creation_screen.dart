// lib/screens/profile/user_creation_screen.dart - Updated with new design
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

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
  final _dateOfBirthController = TextEditingController();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  Map<String, String>? _pendingVaccinationData;

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
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Créer un compte',
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: AppColors.secondary),
            onPressed: _showCleanupDialog,
            tooltip: 'Nettoyer les doublons',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafePageWrapper(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    AppPageHeader(
                      title: 'Création d\'utilisateur',
                      subtitle: _pendingVaccinationData != null 
                          ? 'Créez votre compte pour sauvegarder votre vaccination'
                          : 'Créez votre profil pour accéder à votre carnet',
                      icon: Icons.person_add,
                      trailing: _pendingVaccinationData != null 
                          ? StatusBadge(
                              text: 'Vaccination ${_pendingVaccinationData!['vaccineName']?.split(' ').first ?? 'données'} en attente',
                              type: StatusType.success,
                              icon: Icons.vaccines,
                            )
                          : null,
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Form fields
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildFormFields(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        AppTextField(
          label: 'Nom complet',
          hint: 'Votre nom et prénom',
          controller: _nameController,
          prefixIcon: Icons.person,
          isRequired: true,
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre nom complet';
            }
            if (value.trim().length < 2) {
              return 'Le nom doit contenir au moins 2 caractères';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        AppTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          controller: _emailController,
          prefixIcon: Icons.email,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: _checkEmailAvailability,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre adresse email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Format d\'email invalide';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        AppTextField(
          label: 'Mot de passe',
          hint: 'Minimum 8 caractères',
          controller: _passwordController,
          prefixIcon: Icons.lock,
          isPassword: true,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 8) {
              return 'Le mot de passe doit contenir au moins 8 caractères';
            }
            if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
              return 'Le mot de passe doit contenir au moins une lettre';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Le mot de passe doit contenir au moins un chiffre';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        _buildDateField(),
        
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cake,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Date de naissance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
          controller: _dateOfBirthController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'JJ/MM/AAAA',
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.textMuted),
          ),
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez sélectionner votre date de naissance';
            }
            return null;
          },
        ),
      ],
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

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateOfBirthController.text = formattedDate;
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AppButton(
        text: 'Créer mon compte',
        icon: Icons.person_add,
        isLoading: _isLoading,
        onPressed: _createUser,
        width: double.infinity,
      ),
    );
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final exists = await _databaseService.emailExists(email);
      if (exists && mounted) {
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
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Ignore errors during checking
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final emailExists = await _databaseService.emailExists(_emailController.text);
        if (emailExists) {
          throw Exception('Cette adresse email est déjà utilisée');
        }

        final user = User.create(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          dateOfBirth: _dateOfBirthController.text.trim(),
        );

        await _databaseService.saveUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text('Utilisateur créé avec succès!'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
          
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Erreur: $e')),
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Nettoyer la base de données',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Cette action va supprimer tous les comptes en double (même email). Seul le premier compte sera conservé pour chaque adresse email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performCleanup();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: const Text('Nettoyer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCleanup() async {
    try {
      final result = await _databaseService.cleanupDatabase();
      final duplicatesRemoved = result['duplicateUsersRemoved'] ?? 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$duplicatesRemoved compte(s) en double supprimé(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du nettoyage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}