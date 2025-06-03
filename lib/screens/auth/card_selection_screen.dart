// lib/screens/auth/card_selection_screen.dart
import 'package:flutter/material.dart';

class CardSelectionScreen extends StatelessWidget {
  const CardSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C5F66)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vaccigo',
          style: TextStyle(
            color: Color(0xFF2C5F66),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 20),
                  
                  // Title Section
                  _buildTitleSection(),
                  
                  const SizedBox(height: 60),
                  
                  // Cards Section
                  _buildCardsSection(context),
                  
                  const SizedBox(height: 40),
                  
                  // Info Section
                  _buildInfoSection(),
                  
                  const SizedBox(height: 20),
                ],
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
          'Veuillez choisir',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'votre carnet',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF7DD3D8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return Column(
      children: [
        _buildCardButton(
          context,
          title: 'Mes Vaccins',
          subtitle: 'Gérer mon carnet de vaccination',
          icon: Icons.vaccines,
          color: const Color(0xFF4CAF50),
          onTap: () {
            Navigator.pushNamed(context, '/travel-options');
          },
        ),
        const SizedBox(height: 20),
        _buildCardButton(
          context,
          title: 'Mes Voyages',
          subtitle: 'Préparer mes voyages à l\'étranger',
          icon: Icons.flight,
          color: const Color(0xFFFFA726),
          onTap: () {
            // Navigation for voyages option
          },
        ),
      ],
    );
  }

  Widget _buildCardButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 20),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7DD3D8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7DD3D8).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF2C5F66),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre carnet numérique vous accompagne partout',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF2C5F66).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
