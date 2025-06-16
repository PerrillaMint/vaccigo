// lib/screens/auth/forgot_password_screen.dart - FIXED password reset functionality
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/database_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _lastEmailSent; // Track which email we sent to

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Mot de passe oublié',
      ),
      body: SafePageWrapper(
        hasScrollView: true,
        child: Column(
          children: [
            // Header section
            AppPageHeader(
              title: 'Réinitialiser votre mot de passe',
              subtitle: _emailSent
                  ? 'Un email de réinitialisation a été envoyé'
                  : 'Entrez votre email pour réinitialiser votre mot de passe',
              icon: Icons.lock_reset,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Content - FIXED: Use AnimatedSwitcher for smooth transitions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _emailSent 
                  ? _buildSuccessState()
                  : _buildEmailForm(),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Info section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'), // FIXED: Add key for AnimatedSwitcher
      children: [
        AppTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          controller: _emailController,
          prefixIcon: Icons.email,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading, // FIXED: Disable during loading
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
        
        const SizedBox(height: AppSpacing.xl),
        
        AppButton(
          text: 'Réinitialiser le mot de passe',
          icon: Icons.send,
          isLoading: _isLoading,
          onPressed: _resetPassword,
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        AppButton(
          text: 'Retour à la connexion',
          style: AppButtonStyle.text,
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success_state'), // FIXED: Add key for AnimatedSwitcher
      children: [
        // Success card
        AppCard(
          backgroundColor: AppColors.success.withOpacity(0.05),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              const Text(
                'Email envoyé avec succès!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Vérifiez votre boîte email et suivez les instructions pour réinitialiser votre mot de passe.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                    const Icon(
                      Icons.email,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Email envoyé à: ${_lastEmailSent ?? _emailController.text}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Action buttons
        Column(
          children: [
            AppButton(
              text: 'Retour à la connexion',
              icon: Icons.login,
              onPressed: () => Navigator.pop(context),
              width: double.infinity,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            AppButton(
              text: 'Renvoyer l\'email',
              style: AppButtonStyle.secondary,
              onPressed: () {
                // FIXED: Reset state to allow re-sending
                setState(() {
                  _emailSent = false;
                  _lastEmailSent = null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return AppCard(
      backgroundColor: AppColors.info.withOpacity(0.05),
      border: Border.all(
        color: AppColors.info.withOpacity(0.3),
        width: 1,
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Information importante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'Pour des raisons de sécurité, cette fonctionnalité est simulée dans cette version de démonstration. Dans une application réelle, un vrai email serait envoyé.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.warning,
                  size: 16,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Vos données restent protégées et stockées localement',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Completely rewritten reset password method with better error handling
  Future<void> _resetPassword() async {
    // Validate email first
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorMessage('Veuillez entrer votre adresse email');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorMessage('Adresse email invalide');
      return;
    }

    // FIXED: Ensure we're mounted before starting async operation
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if user exists
      final user = await _databaseService.getUserByEmail(email);
      
      // Simulate network delay for realism
      await Future.delayed(const Duration(seconds: 2));
      
      // FIXED: Always show success for security (don't reveal if email exists)
      // In a real app, you'd send email regardless to prevent email enumeration
      if (mounted) {
        setState(() {
          _emailSent = true;
          _lastEmailSent = email;
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('Instructions envoyées à $email'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // FIXED: In demo mode, show different message if user not found
        if (user == null) {
          // Wait a bit then show a discrete message
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Note: Si ce compte existe, l\'email a été envoyé',
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('Password reset error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Erreur: ${e.toString()}');
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
}