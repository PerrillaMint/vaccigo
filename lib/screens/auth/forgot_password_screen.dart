// lib/screens/auth/forgot_password_screen.dart - FIXED layout constraints
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
            
            // Content
            if (!_emailSent) ...[
              _buildEmailForm(),
            ] else ...[
              _buildSuccessState(),
            ],
            
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
                        'Email envoyé à: ${_emailController.text}',
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
                setState(() => _emailSent = false);
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

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorMessage('Veuillez entrer votre adresse email');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showErrorMessage('Adresse email invalide');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = await _databaseService.getUserByEmail(_emailController.text);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (user != null) {
        // In a real app, this would send an actual email
        setState(() => _emailSent = true);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text('Instructions envoyées par email'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        _showErrorMessage('Aucun compte trouvé avec cette adresse email');
      }
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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