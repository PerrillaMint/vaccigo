// lib/screens/auth/login_screen.dart - Updated with new design system
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _passwordController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _isPasswordWrong = false;
  bool _isLoggingIn = false;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    try {
      final users = await _databaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur de chargement: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Connexion',
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: AppColors.secondary),
            onPressed: _isLoading ? null : _showCleanupDialog,
            tooltip: 'Nettoyer les doublons',
          ),
        ],
      ),
      body: SafePageWrapper(
        hasScrollView: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  // Header
                  AppPageHeader(
                    title: 'Sélectionnez votre profil',
                    subtitle: 'Choisissez un utilisateur et entrez votre mot de passe',
                    icon: Icons.person,
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Content
                  Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.4,
                    ),
                    child: _isLoading 
                        ? const AppLoading(message: 'Chargement des utilisateurs...')
                        : _users.isEmpty 
                            ? _buildEmptyState()
                            : _buildUsersList(),
                  ),
                  
                  // Password field
                  if (_selectedUser != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildPasswordField(),
                  ],
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Bottom buttons
                  _buildBottomButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'Aucun utilisateur trouvé',
      message: 'Créez votre premier profil utilisateur pour commencer',
      icon: Icons.person_add,
      action: AppButton(
        text: 'Créer un utilisateur',
        icon: Icons.add,
        onPressed: () => Navigator.pushNamed(context, '/user-creation'),
      ),
    );
  }

  Widget _buildUsersList() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Utilisateurs existants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              StatusBadge(
                text: '${_users.length} utilisateur(s)',
                type: StatusType.info,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Users list
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _users.length,
              separatorBuilder: (context, index) => Divider(
                color: AppColors.primary.withOpacity(0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = _selectedUser == user;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, 
                    vertical: AppSpacing.sm
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: AppColors.secondary, width: 2)
                          : null,
                    ),
                    child: Icon(
                      Icons.person,
                      color: isSelected 
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected 
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        )
                      : null,
                  onTap: _isLoggingIn ? null : () {
                    setState(() {
                      _selectedUser = isSelected ? null : user;
                      _passwordController.clear();
                      _isPasswordWrong = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return AppTextField(
      label: 'Mot de passe',
      hint: 'Entrez votre mot de passe',
      controller: _passwordController,
      prefixIcon: Icons.lock,
      isPassword: true,
      isRequired: true,
      enabled: !_isLoggingIn,
      validator: (value) {
        if (_isPasswordWrong) return 'Mot de passe incorrect';
        return null;
      },
      onChanged: (value) {
        if (_isPasswordWrong) {
          setState(() => _isPasswordWrong = false);
        }
      },
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        if (_selectedUser != null) ...[
          AppButton(
            text: _isLoggingIn 
                ? 'Connexion...'
                : 'Se connecter avec ${_selectedUser!.name}',
            icon: _isLoggingIn ? null : Icons.login,
            isLoading: _isLoggingIn,
            onPressed: _loginWithSelectedUser,
            width: double.infinity,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Mot de passe oublié?',
            style: AppButtonStyle.text,
            onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/forgot-password'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        
        AppButton(
          text: 'Créer un nouvel utilisateur',
          icon: Icons.person_add,
          style: AppButtonStyle.secondary,
          onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/user-creation'),
          width: double.infinity,
        ),
      ],
    );
  }

  Future<void> _loginWithSelectedUser() async {
    if (_selectedUser == null || _isLoggingIn) return;

    if (_passwordController.text.isEmpty) {
      setState(() => _isPasswordWrong = true);
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      if (!_selectedUser!.verifyPassword(_passwordController.text)) {
        setState(() => _isPasswordWrong = true);
        return;
      }

      await _databaseService.setCurrentUser(_selectedUser!);
      
      if (mounted) {
        setState(() {
          _selectedUser = null;
          _isPasswordWrong = false;
        });
        _passwordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('Connecté en tant que ${_selectedUser!.name}'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/vaccination-summary');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur de connexion: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
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
      setState(() => _isLoading = true);
      
      final result = await _databaseService.cleanupDatabase();
      final duplicatesRemoved = result['duplicateUsersRemoved'] ?? 0;
      
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('$duplicatesRemoved compte(s) en double supprimé(s)'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors du nettoyage: $e');
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
        ),
      );
    }
  }
}