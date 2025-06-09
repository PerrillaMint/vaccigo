// lib/screens/profile/additional_info_screen.dart - Enhanced with Vaccination Handling
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/vaccination.dart';
import '../../services/database_service.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({Key? key}) : super(key: key);

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _diseasesController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  User? _user;
  Map<String, String>? _pendingVaccinationData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    
    if (arguments is User) {
      // Legacy flow - just user
      _user = arguments;
    } else if (arguments is Map<String, dynamic>) {
      // New flow - user + vaccination data
      _user = arguments['user'] as User?;
      _pendingVaccinationData = arguments['vaccinationData'] as Map<String, String>?;
    }
  }

  @override
  void dispose() {
    _diseasesController.dispose();
    _treatmentsController.dispose();
    _allergiesController.dispose();
    super.dispose();
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
          'Informations complémentaires',
          style: TextStyle(
            color: Color(0xFF2C5F66),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    _buildFormFields(),
                    
                    const SizedBox(height: 100), // Extra space for button
                  ],
                ),
              ),
            ),
            
            // Fixed bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7DD3D8).withOpacity(0.1),
            const Color(0xFF7DD3D8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C5F66).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 32,
              color: Color(0xFF2C5F66),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Informations complémentaires',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5F66),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _pendingVaccinationData != null
                ? 'Dernière étape avant de sauvegarder votre vaccination'
                : 'Ajoutez des informations sur votre santé (optionnel)',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2C5F66).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          // Show vaccination pending indicator
          if (_pendingVaccinationData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vaccines,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vaccination en attente',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_pendingVaccinationData!['vaccineName']} - ${_pendingVaccinationData!['date']}',
                          style: TextStyle(
                            color: const Color(0xFF4CAF50).withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Maladie',
          hint: 'Maladies chroniques, etc.',
          controller: _diseasesController,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Traitement',
          hint: 'Traitements en cours',
          controller: _treatmentsController,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Allergie',
          hint: 'Allergies médicamenteuses ou autres',
          controller: _allergiesController,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              maxLines > 1 ? Icons.notes : Icons.info_outline,
              size: 20,
              color: const Color(0xFF2C5F66),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5F66),
              ),
            ),
            const Text(
              ' (optionnel)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7DD3D8), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveAdditionalInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C5F66),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _pendingVaccinationData != null 
                      ? 'Finaliser et sauvegarder'
                      : 'Valider',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveAdditionalInfo() async {
    if (_user == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Update user with additional info
      _user!.diseases = _diseasesController.text.isNotEmpty ? _diseasesController.text : null;
      _user!.treatments = _treatmentsController.text.isNotEmpty ? _treatmentsController.text : null;
      _user!.allergies = _allergiesController.text.isNotEmpty ? _allergiesController.text : null;

      await _user!.save();

      // If there's pending vaccination data, save it now
      if (_pendingVaccinationData != null) {
        final vaccination = Vaccination(
          vaccineName: _pendingVaccinationData!['vaccineName']!,
          lot: _pendingVaccinationData!['lot']!,
          date: _pendingVaccinationData!['date']!,
          ps: _pendingVaccinationData!['ps'] ?? '',
          userId: _user!.key.toString(),
        );

        await _databaseService.saveVaccination(vaccination);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pendingVaccinationData != null
                        ? 'Compte créé et vaccination sauvegardée!'
                        : 'Informations sauvegardées!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/vaccination-summary');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}