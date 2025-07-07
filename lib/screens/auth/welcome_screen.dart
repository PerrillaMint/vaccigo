// lib/screens/auth/welcome_screen.dart - Écran d'accueil et présentation de l'application
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

// Écran d'accueil principal présentant l'application Vaccigo
// Design moderne et attrayant pour engager les nouveaux utilisateurs
// Interface responsive avec call-to-action clairs
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Espace supérieur adaptatif (10% de la hauteur)
                      SizedBox(height: constraints.maxHeight * 0.1),
                      
                      // Section logo supprimée - était ici à l'origine
                      
                      SizedBox(height: constraints.maxHeight * 0.05),
                      
                      // Section titre principal avec typographie moderne
                      _buildTitleSection(),
                      
                      SizedBox(height: constraints.maxHeight * 0.08),
                      
                      // Liste des fonctionnalités clés
                      _buildFeaturesList(),
                      
                      SizedBox(height: constraints.maxHeight * 0.08),
                      
                      // Boutons d'action principaux
                      _buildActionButtons(context),
                      
                      // Espace inférieur adaptatif
                      SizedBox(height: constraints.maxHeight * 0.1),
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

  // Section titre avec typographie élégante et hiérarchie visuelle
  Widget _buildTitleSection() {
    return Column(
      children: [
        // Titre principal avec mise en forme RichText pour les accents de couleur
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              height: 1.2,
            ),
            children: [
              // Première partie en couleur primaire
              TextSpan(
                text: 'Mon carnet de\nvaccination\n',
                style: TextStyle(color: AppColors.primary),
              ),
              // Mot-clé "numérique" en couleur secondaire pour l'accent
              TextSpan(
                text: 'numérique',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Texte Vaccigo supprimé - était ici à l'origine
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // Liste des valeurs et promesses de l'application
  // Design simple mais efficace pour communiquer les bénéfices
  Widget _buildFeaturesList() {
    final features = [
      'VIVRE',
      'PROTÉGER',
      'VOYAGER',
      'EN TOUTE SÉRÉNITÉ',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          feature,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primary.withOpacity(0.8),
            letterSpacing: 1.2, // Espacement des lettres pour un effet moderne
          ),
          textAlign: TextAlign.center,
        ),
      )).toList(),
    );
  }

  // Boutons d'action avec hiérarchie visuelle claire
  // Bouton principal (Démarrer) et bouton secondaire (Se connecter)
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal pour les nouveaux utilisateurs
        AppButton(
          text: 'Démarrer',
          icon: Icons.arrow_forward,
          onPressed: () => Navigator.pushNamed(context, '/card-selection'),
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Bouton secondaire pour les utilisateurs existants
        AppButton(
          text: 'Se connecter',
          icon: Icons.login,
          style: AppButtonStyle.secondary,
          onPressed: () => Navigator.pushNamed(context, '/login'),
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Texte d'aide subtil pour guider les utilisateurs existants
        Text(
          'Vous avez déjà un compte?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary.withOpacity(0.6),
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}