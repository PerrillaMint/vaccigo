// lib/screens/auth/forgot_password_screen.dart - FIXED all layout and overflow issues
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
  String? _lastEmailSent;

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
                      // Header section
                      _buildHeaderSection(),
                      
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

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // FIXED: Better text handling with constraints
          const Text(
            'Réinitialiser votre mot de passe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _emailSent
                ? 'Un email de réinitialisation a été envoyé'
                : 'Entrez votre email pour réinitialiser votre mot de passe',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      children: [
        AppTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          controller: _emailController,
          prefixIcon: Icons.email,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
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

  // FIXED: Better success state layout with proper constraints
  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success_state'),
      children: [
        // Success card
        AppCard(
          backgroundColor: AppColors.success.withOpacity(0.05),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                maxLines: 3, // FIXED: Limit lines to prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Container(
                width: double.infinity,
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
                    Expanded( // FIXED: Prevent text overflow
                      child: Text(
                        'Email envoyé à: ${_lastEmailSent ?? _emailController.text}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
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
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Action buttons - FIXED: Responsive button layout
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      setState(() {
                        _emailSent = false;
                        _lastEmailSent = null;
                      });
                    },
                    width: double.infinity,
                  ),
                ],
              );
            } else {
              return Column(
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
                      setState(() {
                        _emailSent = false;
                        _lastEmailSent = null;
                      });
                    },
                  ),
                ],
              );
            }
          },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded( // FIXED: Prevent title overflow
                child: Text(
                  'Information importante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            maxLines: 4, // FIXED: Limit lines to prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded( // FIXED: Prevent text overflow
                  child: Text(
                    'Vos données restent protégées et stockées localement',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
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
    );
  }

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

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if user exists
      final user = await _databaseService.getUserByEmail(email);
      
      // Simulate network delay for realism
      await Future.delayed(const Duration(seconds: 2));
      
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
                Expanded( // FIXED: Prevent overflow in SnackBar
                  child: Text('Instructions envoyées à $email'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // In demo mode, show different message if user not found
        if (user == null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Note: Si ce compte existe, l\'email a été envoyé',
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
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
              Expanded( // FIXED: Prevent overflow in error message
                child: Text(message),
              ),
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