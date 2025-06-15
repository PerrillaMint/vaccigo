// lib/screens/auth/welcome_screen.dart - Updated with new design system
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

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
                      // Top spacer
                      SizedBox(height: constraints.maxHeight * 0.1),
                      
                      // Logo section
                      _buildLogoSection(),
                      
                      SizedBox(height: constraints.maxHeight * 0.05),
                      
                      // Title section
                      _buildTitleSection(),
                      
                      SizedBox(height: constraints.maxHeight * 0.08),
                      
                      // Features list
                      _buildFeaturesList(),
                      
                      SizedBox(height: constraints.maxHeight * 0.08),
                      
                      // Action buttons
                      _buildActionButtons(context),
                      
                      // Bottom spacer
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

  Widget _buildLogoSection() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Protective hands
          Positioned(
            top: 20,
            child: Icon(
              Icons.pan_tool,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          Positioned(
            bottom: 20,
            child: Transform.rotate(
              angle: 3.14159,
              child: Icon(
                Icons.pan_tool,
                size: 24,
                color: AppColors.primary,
              ),
            ),
          ),
          // Central certificate
          Container(
            width: 40,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 2,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          // Syringe
          Positioned(
            left: 15,
            child: Icon(
              Icons.medication,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'Mon carnet de\nvaccination\n',
                style: TextStyle(color: AppColors.primary),
              ),
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'Vaccigo',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

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
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main action button
        AppButton(
          text: 'Démarrer',
          icon: Icons.arrow_forward,
          onPressed: () => Navigator.pushNamed(context, '/card-selection'),
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Secondary login button
        AppButton(
          text: 'Se connecter',
          icon: Icons.login,
          style: AppButtonStyle.secondary,
          onPressed: () => Navigator.pushNamed(context, '/login'),
          width: double.infinity,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Help text
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