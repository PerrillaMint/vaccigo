// lib/screens/auth/card_selection_screen.dart - Écran de sélection du type de carnet
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

// Écran permettant à l'utilisateur de choisir entre différents types de carnets
// Actuellement: carnet de vaccination personnel ou préparation de voyages
// Interface moderne avec cartes cliquables et design cohérent
class CardSelectionScreen extends StatelessWidget {
  const CardSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Barre d'application avec le titre de l'app
      appBar: const CustomAppBar(
        title: 'Vaccigo',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Effet de rebond pour un meilleur ressenti utilisateur
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // En-tête avec titre et description
              AppPageHeader(
                title: 'Veuillez choisir votre carnet',
                subtitle: 'Sélectionnez le type de carnet que vous souhaitez utiliser',
                icon: Icons.book_outlined,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Cartes d'options principales
              // Option 1: Carnet de vaccination personnel
              _buildOptionCard(
                context,
                title: 'Mes Vaccins',
                subtitle: 'Gérer mon carnet de vaccination personnel',
                icon: Icons.vaccines,
                color: AppColors.success,
                onTap: () => Navigator.pushNamed(context, '/travel-options'),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Option 2: Préparation de voyages (fonctionnalité future)
              _buildOptionCard(
                context,
                title: 'Mes Voyages',
                subtitle: 'Préparer mes voyages à l\'étranger',
                icon: Icons.flight,
                color: AppColors.accent,
                onTap: () {
                  // Fonctionnalité à développer pour la planification de voyages
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité à venir!'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Section d'information sur l'app
              _buildInfoSection(),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // Construit une carte d'option cliquable avec icône et description
  // Utilise un design moderne avec ombres et animations subtiles
  Widget _buildOptionCard(
    BuildContext context, {
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
            // Conteneur d'icône avec couleur thématique
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            
            const SizedBox(width: AppSpacing.lg),
            
            // Contenu textuel de l'option
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
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
            
            // Flèche indicatrice d'action
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

  // Section d'information sur les avantages de l'app
  // Design avec bordure colorée pour attirer l'attention
  Widget _buildInfoSection() {
    return AppCard(
      backgroundColor: AppColors.secondary.withOpacity(0.1),
      border: Border.all(
        color: AppColors.secondary.withOpacity(0.3),
        width: 1,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Votre carnet numérique vous accompagne partout et reste accessible même hors ligne',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}