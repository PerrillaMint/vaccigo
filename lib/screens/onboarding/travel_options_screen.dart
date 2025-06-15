// lib/screens/onboarding/travel_options_screen.dart - Updated with new design
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class TravelOptionsScreen extends StatelessWidget {
  const TravelOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Vaccinations',
      ),
      body: SafePageWrapper(
        hasScrollView: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Header
                  AppPageHeader(
                    title: 'Vous souhaitez voyager à l\'étranger',
                    subtitle: 'Numérisez votre carnet de vaccination international avec notre technologie IA',
                    icon: Icons.flight_takeoff,
                  ),
                  
                  SizedBox(height: constraints.maxHeight * 0.05),
                  
                  // AI Info section
                  _buildAIInfoSection(),
                  
                  SizedBox(height: constraints.maxHeight * 0.08),
                  
                  // Action buttons
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton(
                        text: 'Scanner avec IA',
                        icon: Icons.camera_alt,
                        onPressed: () => Navigator.pushNamed(context, '/camera-scan'),
                        width: double.infinity,
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      AppButton(
                        text: 'Saisie manuelle',
                        icon: Icons.edit,
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.pushNamed(context, '/manual-entry'),
                        width: double.infinity,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: constraints.maxHeight * 0.05),
                  
                  // Features section
                  _buildFeaturesSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAIInfoSection() {
    return AppCard(
      backgroundColor: AppColors.accent.withOpacity(0.05),
      border: Border.all(
        color: AppColors.accent.withOpacity(0.3),
        width: 1,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Scan intelligent avec IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'Notre technologie d\'intelligence artificielle analyse automatiquement votre carnet de vaccination papier et extrait toutes les informations importantes en quelques secondes.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: 16,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Vous pouvez également faire une saisie manuelle',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      _FeatureItem(
        icon: Icons.camera_alt,
        title: 'Scan intelligent par IA',
        description: 'Reconnaissance automatique des informations',
      ),
      _FeatureItem(
        icon: Icons.security,
        title: 'Données sécurisées',
        description: 'Chiffrement et protection de vos données',
      ),
      _FeatureItem(
        icon: Icons.cloud_sync,
        title: 'Synchronisation',
        description: 'Accès depuis tous vos appareils',
      ),
      _FeatureItem(
        icon: Icons.offline_pin,
        title: 'Accès hors ligne',
        description: 'Disponible même sans connexion',
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.star_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Fonctionnalités',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          ...features.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(_FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}