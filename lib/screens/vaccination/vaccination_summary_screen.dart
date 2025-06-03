// lib/screens/vaccination/vaccination_summary_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/user.dart';

class VaccinationSummaryScreen extends StatefulWidget {
  const VaccinationSummaryScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationSummaryScreen> createState() => _VaccinationSummaryScreenState();
}

class _VaccinationSummaryScreenState extends State<VaccinationSummaryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _databaseService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

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
          'Mon Carnet',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // 2 MAIN BUTTONS ONLY
                Column(
                  children: [
                    _buildMainButton(
                      'Mon carnet',
                      Icons.book,
                      () {
                        Navigator.pushNamed(context, '/vaccination-info');
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMainButton(
                      'Gestion des vaccinations',
                      Icons.settings,
                      () {
                        Navigator.pushNamed(context, '/vaccination-management');
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // User Profile Section (Clickable)
                _buildUserProfileSection(),
                
                const SizedBox(height: 40),
                
                // Success Message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Informations sauvegardées',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Home Button (goes to vaccination info)
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DD3D8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7DD3D8).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/vaccination-info');
                      },
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C5F66),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: const Color(0xFF2C5F66).withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return GestureDetector(
      onTap: () {
        _showUserProfileDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF7DD3D8).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7DD3D8).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF2C5F66),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.name ?? 'Utilisateur créé',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5F66),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toutes les informations ont été sauvegardées',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Appuyez pour modifier',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7DD3D8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit,
              color: Color(0xFF7DD3D8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Profil utilisateur',
            style: TextStyle(
              color: Color(0xFF2C5F66),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentUser != null) ...[
                _buildUserInfo('Nom', _currentUser!.name),
                _buildUserInfo('Email', _currentUser!.email),
                _buildUserInfo('Date de naissance', _currentUser!.dateOfBirth),
                if (_currentUser!.diseases != null)
                  _buildUserInfo('Maladies', _currentUser!.diseases!),
                if (_currentUser!.treatments != null)
                  _buildUserInfo('Traitements', _currentUser!.treatments!),
                if (_currentUser!.allergies != null)
                  _buildUserInfo('Allergies', _currentUser!.allergies!),
              ] else
                const Text('Aucun utilisateur trouvé'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/additional-info', arguments: _currentUser);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F66),
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF7DD3D8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C5F66),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
