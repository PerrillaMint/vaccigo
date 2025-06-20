// lib/screens/vaccination/vaccination_summary_screen.dart - REMOVED home button
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/database_service.dart';
import '../../models/user.dart';

class VaccinationSummaryScreen extends StatefulWidget {
  const VaccinationSummaryScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationSummaryScreen> createState() => _VaccinationSummaryScreenState();
}

class _VaccinationSummaryScreenState extends State<VaccinationSummaryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _databaseService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Mon Carnet Vaccigo',
        showBackButton: false, // FIXED: Completely remove the back arrow button
      ),
      body: _isLoading 
          ? const AppLoading(message: 'Chargement de votre profil...')
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome header
                    _buildWelcomeHeader(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Main action buttons
                    _buildMainActionCard(
                      title: 'Mon carnet',
                      subtitle: 'Consulter mes vaccinations',
                      icon: Icons.book,
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/vaccination-info'),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    _buildMainActionCard(
                      title: 'Gestion des vaccinations',
                      subtitle: 'Recommandations et informations',
                      icon: Icons.settings,
                      color: AppColors.secondary,
                      onTap: () => Navigator.pushNamed(context, '/vaccination-management'),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // User profile section
                    _buildUserProfileSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Success message
                    _buildSuccessMessage(),
                    
                    // REMOVED: Quick access button section completely
                    
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return AppPageHeader(
      title: 'Bienvenue dans votre carnet',
      subtitle: _currentUser != null 
          ? 'Bonjour ${_currentUser!.name.split(' ').first}! Votre carnet de vaccination est prêt.'
          : 'Votre carnet de vaccination numérique est maintenant actif',
      icon: Icons.verified_user,
    );
  }

  Widget _buildMainActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            
            const SizedBox(width: AppSpacing.lg),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    if (_currentUser == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showUserProfileDialog,
      child: AppCard(
        backgroundColor: AppColors.secondary.withOpacity(0.05),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _currentUser!.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Appuyez pour modifier le profil',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.edit,
              color: AppColors.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return StatusBadge(
      text: 'Informations sauvegardées avec succès',
      type: StatusType.success,
      icon: Icons.check_circle,
    );
  }

  // REMOVED: _buildQuickAccessButton() method completely

  void _showUserProfileDialog() {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Profil utilisateur',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo('Nom', _currentUser!.name),
                _buildUserInfo('Email', _currentUser!.email),
                _buildUserInfo('Date de naissance', _currentUser!.dateOfBirth),
                _buildUserInfo('Âge', '${_currentUser!.age} ans'),
                if (_currentUser!.diseases != null)
                  _buildUserInfo('Maladies', _currentUser!.diseases!),
                if (_currentUser!.treatments != null)
                  _buildUserInfo('Traitements', _currentUser!.treatments!),
                if (_currentUser!.allergies != null)
                  _buildUserInfo('Allergies', _currentUser!.allergies!),
              ],
            ),
          ),
          actions: [
            // Logout button (destructive action)
            TextButton.icon(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            const Spacer(), // Push other buttons to the right
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context, 
                  '/additional-info', 
                  arguments: _currentUser,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Se déconnecter',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connecté en tant que: ${_currentUser!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: _performLogout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Close any open dialogs
      Navigator.of(context).pop(); // Close confirmation dialog
      Navigator.of(context).pop(); // Close profile dialog
      
      // Clear the current user session
      await _databaseService.clearCurrentUser();
      
      // Show logout success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Déconnexion réussie'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to login screen and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        // Close dialogs if still open
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erreur de déconnexion: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
        
        // Still navigate to login even if there was an error
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  Widget _buildUserInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}