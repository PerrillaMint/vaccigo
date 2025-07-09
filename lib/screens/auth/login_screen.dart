// lib/screens/auth/login_screen.dart - Écran de connexion avec sélection d'utilisateur - FIXED
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/enhanced_user.dart'; // FIXED: Use EnhancedUser instead of User
import '../../services/database_service.dart';

// Écran de connexion principal avec interface moderne
// Permet la sélection d'utilisateurs existants et l'authentification par mot de passe
// Inclut des outils de nettoyage de base de données et validation robuste
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Service de base de données pour toutes les opérations utilisateur
  final DatabaseService _databaseService = DatabaseService();
  
  // Contrôleur pour le champ mot de passe avec nettoyage automatique
  final _passwordController = TextEditingController();
  
  // États de l'interface utilisateur
  List<EnhancedUser> _users = [];        // FIXED: Use EnhancedUser type
  bool _isLoading = true;                // État de chargement initial
  bool _obscurePassword = true;          // Masquage du mot de passe
  bool _isPasswordWrong = false;         // Indicateur d'erreur mot de passe
  bool _isLoggingIn = false;             // État de connexion en cours
  EnhancedUser? _selectedUser;           // FIXED: Use EnhancedUser type

  @override
  void initState() {
    super.initState();
    // Charge la liste des utilisateurs au démarrage
    _loadUsers();
  }

  @override
  void dispose() {
    // Nettoie les ressources et efface le mot de passe de la mémoire
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  // Charge tous les utilisateurs actifs depuis la base de données
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
          // Bouton de nettoyage des doublons (visible seulement si chargé)
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: AppColors.secondary),
            onPressed: _isLoading ? null : _showCleanupDialog,
            tooltip: 'Nettoyer les doublons',
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // En-tête avec instructions - hauteur fixe
                      _buildHeader(),
                      
                      const SizedBox(height: 24),
                      
                      // Contenu principal - hauteur flexible
                      if (_isLoading)
                        _buildLoadingState()
                      else if (_users.isEmpty)
                        _buildEmptyState()
                      else
                        _buildUsersList(),
                      
                      const SizedBox(height: 24),
                      
                      // Champ mot de passe (affiché seulement si utilisateur sélectionné)
                      if (_selectedUser != null)
                        _buildPasswordField(),
                      
                      const SizedBox(height: 24),
                      
                      // Boutons d'action
                      _buildActionButtons(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // En-tête avec design moderne et instructions claires
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          // Icône utilisateur avec style moderne
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
          
          // Titre principal
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
          
          // Instructions avec gestion des dépassements
          const Text(
            'Choisissez un utilisateur et entrez votre mot de passe',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // État de chargement avec indicateur visuel
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
              'Chargement des utilisateurs...',
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

  // État vide avec invitation à créer un utilisateur
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône d'état vide
          Icon(
            Icons.person_add,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          
          // Titre et description
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Bouton de création d'utilisateur
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

  // Liste des utilisateurs avec indicateurs de statut et sélection
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec compteur d'utilisateurs
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Badge de comptage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          
          // Liste des utilisateurs avec interaction
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12
                    ),
                    child: Row(
                      children: [
                        // Avatar utilisateur
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
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
                        
                        // Informations utilisateur
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                                  
                                  // Indicateur de validité des données
                                  if (!user.isDataValid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'CORRUPT',
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
                        
                        // Indicateur de sélection
                        if (isSelected)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                          )
                        else
                          const SizedBox(width: 24),
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

  // Champ de saisie du mot de passe avec validation visuelle
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec icône
        const Row(
          children: [
            Icon(
              Icons.lock,
              size: 20,
              color: AppColors.primary,
            ),
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
        
        // Champ de texte avec bouton de visibilité
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            // Efface l'erreur quand l'utilisateur tape
            if (_isPasswordWrong) {
              setState(() => _isPasswordWrong = false);
            }
          },
        ),
      ],
    );
  }

  // Boutons d'action principaux et secondaires
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton de connexion principal (visible seulement si utilisateur sélectionné)
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
                  : 'Se connecter avec ${_selectedUser!.name}',
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
          
          // Lien mot de passe oublié
          TextButton(
            onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/forgot-password'),
            child: const Text('Mot de passe oublié?'),
          ),
          const SizedBox(height: 12),
        ],
        
        // Bouton de création de nouvel utilisateur
        OutlinedButton.icon(
          onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/user-creation'),
          icon: const Icon(Icons.person_add),
          label: const Text(
            'Créer un nouvel utilisateur',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

  // Logique de connexion avec validation et gestion d'erreurs
  Future<void> _loginWithSelectedUser() async {
    if (_selectedUser == null || _isLoggingIn) return;

    // Validation du mot de passe côté client
    if (_passwordController.text.isEmpty) {
      setState(() => _isPasswordWrong = true);
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      // Vérifie la validité des données utilisateur avant l'authentification
      if (!_selectedUser!.isDataValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données utilisateur corrompues. Veuillez contacter le support.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Authentification via le service de base de données
      final user = await _databaseService.authenticateUser(
        _selectedUser!.email, 
        _passwordController.text
      );

      if (user == null) {
        setState(() => _isPasswordWrong = true);
        return;
      }

      // Définit l'utilisateur courant pour la session
      await _databaseService.setCurrentUser(user);
      
      if (mounted) {
        setState(() {
          _selectedUser = null;
          _isPasswordWrong = false;
        });
        _passwordController.clear();
        
        // Message de succès
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
        
        // Navigation vers l'écran principal
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

  // Dialogue de confirmation pour le nettoyage de la base de données
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
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
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

  // Exécute le nettoyage de la base de données avec feedback utilisateur
  Future<void> _performCleanup() async {
    try {
      setState(() => _isLoading = true);
      
      // Exécute le nettoyage via le service de base de données
      final result = await _databaseService.cleanupDatabase();
      final duplicatesRemoved = result['duplicateUsersRemoved'] ?? 0;
      
      // Recharge la liste des utilisateurs
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
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors du nettoyage: $e');
      }
    }
  }

  // Affiche un message d'erreur avec gestion des dépassements
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