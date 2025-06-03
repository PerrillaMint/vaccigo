// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7DD3D8), // Turquoise from your logo
              Color(0xFF5DD0D6),
              Color(0xFF4AC5CB),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 40),
                    
                    // App Title Section (No Logo)
                    _buildTitleSection(),
                    
                    const SizedBox(height: 60),
                    
                    // Features Section
                    _buildFeaturesSection(),
                    
                    const SizedBox(height: 40),
                    
                    // Continue Button
                    _buildContinueButton(context),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
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
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'vaccination',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'numérique',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF2C5F66),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Votre santé, partout avec vous',
          style: TextStyle(
            fontSize: 18,
            color: const Color(0xFF2C5F66).withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: const [
          FeatureItem(
            icon: Icons.health_and_safety,
            text: 'VIVRE',
            subtitle: 'En toute sécurité',
            color: Color(0xFF4CAF50),
          ),
          SizedBox(height: 24),
          FeatureItem(
            icon: Icons.shield,
            text: 'PROTÉGER',
            subtitle: 'Votre santé',
            color: Color(0xFF2C5F66),
          ),
          SizedBox(height: 24),
          FeatureItem(
            icon: Icons.flight,
            text: 'VOYAGER',
            subtitle: 'Partout dans le monde',
            color: Color(0xFFFFA726),
          ),
          SizedBox(height: 24),
          FeatureItem(
            icon: Icons.sentiment_satisfied,
            text: 'EN TOUTE SÉRÉNITÉ',
            subtitle: 'Sans souci',
            color: Color(0xFF7DD3D8),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/card-selection');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C5F66),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF2C5F66).withOpacity(0.4),
        ),
        child: const Text(
          'Commencer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String subtitle;
  final Color color;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}