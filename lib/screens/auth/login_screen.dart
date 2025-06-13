// lib/screens/auth/login_screen.dart - Fixed security and state management issues
import 'package:flutter/material.dart';
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
  bool _isLoggingIn = false;  // FIXED: Add login state
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    // FIXED: Clear sensitive data before disposal
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;  // FIXED: Check if mounted
    
    try {
      final users = await _databaseService.getUniqueUsers();
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
      backgroundColor: const Color(0xFFF8FCFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C5F66)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connexion',
          style: TextStyle(
            color: Color(0xFF2C5F66),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Color(0xFF7DD3D8)),
            onPressed: _isLoading ? null : _showCleanupDialog,  // FIXED: Disable when loading
            tooltip: 'Nettoyer les doublons',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 32),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty 
                        ? _buildEmptyState()
                        : _buildUsersList(),
              ),
              _buildPasswordField(),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7DD3D8).withOpacity(0.1),
            const Color(0xFF7DD3D8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C5F66).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF2C5F66),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sélectionnez votre profil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5F66),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez un utilisateur et entrez votre mot de passe',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2C5F66).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add,
            size: 64,
            color: Color(0xFF7DD3D8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5F66),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier profil utilisateur',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/user-creation');
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer un utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C5F66),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Utilisateurs existants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F66),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_users.length} utilisateur(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2C5F66).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _users.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = _selectedUser == user;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF7DD3D8).withOpacity(0.2)
                          : const Color(0xFF7DD3D8).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: const Color(0xFF7DD3D8), width: 2)
                          : null,
                    ),
                    child: Icon(
                      Icons.person,
                      color: isSelected 
                          ? const Color(0xFF2C5F66)
                          : const Color(0xFF2C5F66).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected 
                          ? const Color(0xFF2C5F66)
                          : const Color(0xFF2C5F66).withOpacity(0.8),
                    ),
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? const Color(0xFF7DD3D8)
                          : Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                        )
                      : null,
                  onTap: _isLoggingIn ? null : () {  // FIXED: Disable during login
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
    return Column(
      children: [
        if (_selectedUser != null) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoggingIn,  // FIXED: Disable during login
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Entrez votre mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: _isLoggingIn ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                errorText: _isPasswordWrong ? 'Mot de passe incorrect' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7DD3D8), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                if (_isPasswordWrong) {
                  setState(() => _isPasswordWrong = false);
                }
              },
              // FIXED: Add onSubmitted for better UX
              onSubmitted: _isLoggingIn ? null : (value) => _loginWithSelectedUser(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoggingIn ? null : () => Navigator.pushNamed(context, '/forgot-password'),
              child: const Text(
                'Mot de passe oublié?',
                style: TextStyle(
                  color: Color(0xFF7DD3D8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        if (_selectedUser != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoggingIn ? null : _loginWithSelectedUser,  // FIXED: Disable during login
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
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoggingIn ? null : () {  // FIXED: Disable during login
              Navigator.pushNamed(context, '/user-creation');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Créer un nouvel utilisateur'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7DD3D8),
              side: const BorderSide(color: Color(0xFF7DD3D8)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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

    if (_selectedUser!.password != _passwordController.text) {
      setState(() => _isPasswordWrong = true);
      return;
    }

    setState(() => _isLoggingIn = true);  // FIXED: Set login state

    try {
      // Set as current user and navigate
      await _databaseService.setCurrentUser(_selectedUser!);
      
      if (mounted) {
        // FIXED: Clear sensitive data and selection state
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
                Text('Connecté en tant que ${_selectedUser!.name}'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
        setState(() => _isLoggingIn = false);  // FIXED: Reset login state
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
              color: Color(0xFF2C5F66),
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
                backgroundColor: const Color(0xFF7DD3D8),
                foregroundColor: Colors.white,
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
      setState(() => _isLoading = true);  // FIXED: Show loading during cleanup
      
      final result = await _databaseService.cleanupDatabase();
      final duplicatesRemoved = result['duplicateUsersRemoved'] ?? 0;
      
      await _loadUsers();  // FIXED: Reload users after cleanup
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.white),
                const SizedBox(width: 8),
                Text('$duplicatesRemoved compte(s) en double supprimé(s)'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
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
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}