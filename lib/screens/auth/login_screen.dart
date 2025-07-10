// lib/screens/auth/login_screen.dart - Version corrigée compatible avec le nouveau DatabaseService
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/enhanced_user.dart';
import '../../services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _passwordController = TextEditingController();
  
  List<EnhancedUser> _users = [];
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _isPasswordWrong = false;
  bool _isLoggingIn = false;
  EnhancedUser? _selectedUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadUsers();
  }

  @override
  void dispose() {
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  // CORRIGÉ: Initialisation de la base de données avant de charger les utilisateurs
  Future<void> _initializeAndLoadUsers() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Initialise la base de données d'abord
      await _databaseService.initializeDatabase();
      
      // Puis charge les utilisateurs
      await _loadUsers();
      
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur d\'initialisation: $e';
        });
      }
    }
  }

  // CORRIGÉ: Chargement des utilisateurs avec gestion d'erreurs robuste
  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    try {
      final users = await _databaseService.getAllUsers();
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _errorMessage = null;
        });
        
        print('✅ ${users.length} utilisateur(s) chargé(s)');
      }
    } catch (e) {
      print('❌ Erreur chargement utilisateurs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement des utilisateurs';
        });
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
          if (!_isLoading && _users.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services, color: AppColors.secondary),
              onPressed: _showCleanupDialog,
              tooltip: 'Nettoyer les doublons',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              // CORRIGÉ: Gestion des états d'erreur
              if (_errorMessage != null)
                _buildErrorState()
              else if (_isLoading)
                _buildLoadingState()
              else if (_users.isEmpty)
                _buildEmptyState()
              else
                _buildUsersList(),
              
              const SizedBox(height: 24),
              
              if (_selectedUser != null)
                _buildPasswordField(),
              
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sélectionnez votre profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Choisissez un utilisateur et entrez votre mot de passe',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // NOUVEAU: État d'erreur avec options de récupération
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de Base de Données',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _initializeAndLoadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/user-creation'),
                icon: const Icon(Icons.person_add),
                label: const Text('Créer Utilisateur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Initialisation de la base de données...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier profil utilisateur pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/user-creation'),
            icon: const Icon(Icons.add),
            label: const Text('Créer un utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Utilisateurs existants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_users.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // CORRIGÉ: Liste des utilisateurs avec gestion des erreurs
          ...List.generate(_users.length, (index) {
            final user = _users[index];
            final isSelected = _selectedUser == user;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.secondary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.secondary
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isLoggingIn ? null : () {
                    setState(() {
                      _selectedUser = isSelected ? null : user;
                      _passwordController.clear();
                      _isPasswordWrong = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.secondary.withOpacity(0.2)
                                : AppColors.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: isSelected 
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected 
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected 
                                            ? AppColors.secondary
                                            : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // CORRIGÉ: Indicateur de validité
                                  if (!user.isDataValid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'DONNÉES INVALIDES',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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
              ),
            );
          }),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lock, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Mot de passe',
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
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoggingIn,
          decoration: InputDecoration(
            hintText: 'Entrez votre mot de passe',
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
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
            errorText: _isPasswordWrong ? 'Mot de passe incorrect' : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            if (_isPasswordWrong) {
              setState(() => _isPasswordWrong = false);
            }
          },
          onFieldSubmitted: (_) => _loginWithSelectedUser(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedUser != null) ...[
          ElevatedButton.icon(
            onPressed: _isLoggingIn ? null : _loginWithSelectedUser,
            icon: _isLoggingIn 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(
              _isLoggingIn 
                  ? 'Connexion...'
                  : 'Se connecter',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/forgot-password'),
            child: const Text('Mot de passe oublié?'),
          ),
          const SizedBox(height: 12),
        ],
        
        OutlinedButton.icon(
          onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/user-creation'),
          icon: const Icon(Icons.person_add),
          label: const Text('Créer un nouvel utilisateur'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // CORRIGÉ: Logique de connexion compatible avec le nouveau service
  Future<void> _loginWithSelectedUser() async {
    if (_selectedUser == null || _isLoggingIn) return;

    if (_passwordController.text.isEmpty) {
      setState(() => _isPasswordWrong = true);
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      // CORRIGÉ: Vérification de la validité des données
      if (!_selectedUser!.isDataValid) {
        if (mounted) {
          _showErrorMessage('Données utilisateur corrompues. Veuillez contacter le support.');
        }
        return;
      }

      // CORRIGÉ: Authentification avec le nouveau service
      final user = await _databaseService.authenticateUser(
        _selectedUser!.email, 
        _passwordController.text
      );

      if (user == null) {
        setState(() => _isPasswordWrong = true);
        return;
      }

      // CORRIGÉ: Définition de l'utilisateur courant
      await _databaseService.setCurrentUser(user);
      
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
                const SizedBox(width: 8),
                Expanded(child: Text('Connecté en tant que ${user.name}')),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/vaccination-summary');
      }
    } catch (e) {
      print('❌ Erreur connexion: $e');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Nettoyer la base de données',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Cette action va supprimer tous les comptes en double (même email). '
            'Seul le compte le plus récent sera conservé pour chaque adresse email.',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('Nettoyer'),
            ),
          ],
        );
      },
    );
  }

  // CORRIGÉ: Nettoyage simplifié compatible avec le nouveau service
  Future<void> _performCleanup() async {
    try {
      setState(() => _isLoading = true);
      
      // Utilise la méthode de nettoyage du service
      final result = await _databaseService.cleanupDatabase();
      final duplicatesRemoved = result['duplicateUsersRemoved'] ?? 0;
      
      // Recharge la liste après nettoyage
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('$duplicatesRemoved compte(s) en double supprimé(s)')),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
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
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}