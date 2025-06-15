// lib/screens/auth/card_selection_screen.dart - Updated with new design
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CardSelectionScreen extends StatelessWidget {
  const CardSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Vaccigo',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Header
              AppPageHeader(
                title: 'Veuillez choisir votre carnet',
                subtitle: 'Sélectionnez le type de carnet que vous souhaitez utiliser',
                icon: Icons.book_outlined,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Cards
              _buildOptionCard(
                context,
                title: 'Mes Vaccins',
                subtitle: 'Gérer mon carnet de vaccination personnel',
                icon: Icons.vaccines,
                color: AppColors.success,
                onTap: () => Navigator.pushNamed(context, '/travel-options'),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              _buildOptionCard(
                context,
                title: 'Mes Voyages',
                subtitle: 'Préparer mes voyages à l\'étranger',
                icon: Icons.flight,
                color: AppColors.accent,
                onTap: () {
                  // Future feature for travel planning
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité à venir!'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Info section
              _buildInfoSection(),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

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
            // Icon container
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
            
            // Content
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
            
            // Arrow
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