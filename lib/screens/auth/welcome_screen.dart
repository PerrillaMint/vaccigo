// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
          child: Column(
            children: [
              // Spacer to push content to center
              const Spacer(flex: 2),
              
              // Main Title Section
              _buildTitleSection(),
              
              const Spacer(flex: 3),
              
              // Simple Feature List
              _buildFeatureList(),
              
              const Spacer(flex: 4),
              
              // Action Buttons
              _buildActionButtons(context),
              
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Text(
          'Mon carnet de',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C5F66), // Navy blue from app theme
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'vaccination',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C5F66),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'numérique',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF7DD3D8), // Light blue accent for emphasis
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _buildFeatureItem('VIVRE'),
        const SizedBox(height: 32),
        _buildFeatureItem('PROTÉGER'),
        const SizedBox(height: 32),
        _buildFeatureItem('VOYAGER'),
        const SizedBox(height: 32),
        _buildFeatureItem('EN TOUTE SÉRÉNITÉ'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF2C5F66).withOpacity(0.7), // Navy blue with opacity for subtle look
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main "Démarrer" button - using app's navy blue theme
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/card-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C5F66), // Navy blue from app theme
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF2C5F66).withOpacity(0.3),
            ),
            child: const Text(
              'Démarrer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Secondary login button - using light blue theme
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7DD3D8), // Light blue from app theme
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color(0xFF7DD3D8).withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Help text - using theme colors
        Text(
          'Vous avez déjà un compte?',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF2C5F66).withOpacity(0.6), // Navy blue with opacity
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}