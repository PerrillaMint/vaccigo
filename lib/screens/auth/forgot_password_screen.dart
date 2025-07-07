// lib/screens/auth/forgot_password_screen.dart - Écran de réinitialisation du mot de passe
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/database_service.dart';

// Écran permettant aux utilisateurs de réinitialiser leur mot de passe oublié
// Interface moderne avec validation, états de chargement et gestion d'erreurs
// Version démo avec simulation d'envoi d'email pour la présentation
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Contrôleur pour le champ email avec validation en temps réel
  final _emailController = TextEditingController();
  
  // Service de base de données pour vérifier l'existence de l'utilisateur
  final _databaseService = DatabaseService();
  
  // États de l'interface utilisateur
  bool _isLoading = false;        // Indique si une opération est en cours
  bool _emailSent = false;        // Indique si l'email a été envoyé avec succès
  String? _lastEmailSent;         // Mémorise le dernier email utilisé

  @override
  void dispose() {
    // Nettoie les ressources pour éviter les fuites mémoire
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
                      // Section d'en-tête avec animation et design moderne
                      _buildHeaderSection(),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Contenu principal - utilise AnimatedSwitcher pour des transitions fluides
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _emailSent 
                            ? _buildSuccessState()      // État de succès après envoi
                            : _buildEmailForm(),        // Formulaire de saisie email
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Section d'information sur la sécurité
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

  // En-tête avec gradient et icône pour une présentation moderne
  // Titre et description adaptatifs selon l'état
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
          // Icône de réinitialisation avec style moderne
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
          
          // Titre principal avec gestion des dépassements de texte
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
          
          // Sous-titre adaptatif selon l'état
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

  // Formulaire de saisie d'email avec validation et design moderne
  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      children: [
        // Champ email avec validation en temps réel
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
        
        // Bouton principal de réinitialisation avec état de chargement
        AppButton(
          text: 'Réinitialiser le mot de passe',
          icon: Icons.send,
          isLoading: _isLoading,
          onPressed: _resetPassword,
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Bouton de retour vers la connexion
        AppButton(
          text: 'Retour à la connexion',
          style: AppButtonStyle.text,
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }

  // État de succès après envoi de l'email avec design adaptatif
  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success_state'),
      children: [
        // Carte de succès avec icône et messages
        AppCard(
          backgroundColor: AppColors.success.withOpacity(0.05),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône de succès avec style moderne
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
              
              // Message de succès principal
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
              
              // Instructions détaillées avec limitation de lignes
              Text(
                'Vérifiez votre boîte email et suivez les instructions pour réinitialiser votre mot de passe.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Indicateur de l'email de destination
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
                    Expanded(
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
        
        // Boutons d'action avec design adaptatif pour petits écrans
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              // Version colonne pour très petits écrans
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
              // Version standard avec boutons centrés
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

  // Section d'information sur la sécurité et le mode démo
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
          // Titre de la section avec gestion des dépassements
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Information sur le mode démo avec limitation de lignes
          const Text(
            'Pour des raisons de sécurité, cette fonctionnalité est simulée dans cette version de démonstration. Dans une application réelle, un vrai email serait envoyé.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Badge de sécurité avec gestion des dépassements
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
                const Expanded(
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

  // Logique de réinitialisation du mot de passe avec validation et simulation
  Future<void> _resetPassword() async {
    // Validation côté client de l'email
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

    // Active l'état de chargement
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Vérifie si l'utilisateur existe dans la base de données
      final user = await _databaseService.getUserByEmail(email);
      
      // Simule un délai réseau pour plus de réalisme
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _lastEmailSent = email;
          _isLoading = false;
        });
        
        // Affiche un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Instructions envoyées à $email'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // En mode démo, affiche un message différent si l'utilisateur n'existe pas
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

  // Affiche un message d'erreur avec gestion des dépassements
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
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