// lib/screens/onboarding/scan_preview_screen.dart
import 'package:flutter/material.dart';
import '../../models/scanned_vaccination_data.dart';
import '../../models/vaccination.dart';
import '../../services/database_service.dart';

class ScanPreviewScreen extends StatefulWidget {
  const ScanPreviewScreen({Key? key}) : super(key: key);

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  late TextEditingController _vaccineController;
  late TextEditingController _lotController;
  late TextEditingController _dateController;
  late TextEditingController _psController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isSaving = false;
  bool _userExists = false;

  @override
  void initState() {
    super.initState();
    _vaccineController = TextEditingController();
    _lotController = TextEditingController();
    _dateController = TextEditingController();
    _psController = TextEditingController();
    _checkUserExists();
  }

  Future<void> _checkUserExists() async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      setState(() {
        _userExists = currentUser != null;
      });
    } catch (e) {
      setState(() {
        _userExists = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    
    if (arguments is ScannedVaccinationData) {
      // From camera scan
      _vaccineController.text = arguments.vaccineName;
      _lotController.text = arguments.lot;
      _dateController.text = arguments.date;
      _psController.text = arguments.ps;
    } else if (arguments is Map<String, String>) {
      // From manual entry
      _vaccineController.text = arguments['vaccine'] ?? '';
      _lotController.text = arguments['lot'] ?? '';
      _dateController.text = arguments['date'] ?? '';
      _psController.text = arguments['ps'] ?? '';
    } else {
      // Demo data if no arguments
      _vaccineController.text = 'Pfizer-BioNTech COVID-19';
      _lotController.text = 'EW0553';
      _dateController.text = '15/03/2025';
      _psController.text = 'Dr. Martin'; // More realistic pharmacist name
    }
  }

  @override
  void dispose() {
    _vaccineController.dispose();
    _lotController.dispose();
    _dateController.dispose();
    _psController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    ScannedVaccinationData? scannedData;
    if (arguments is ScannedVaccinationData) {
      scannedData = arguments;
    }
    
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
          'Vérification',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              _buildHeaderSection(scannedData),
              
              const SizedBox(height: 24),
              
              // Information Preview Card - Similar to wireframe
              Expanded(
                child: SingleChildScrollView(
                  child: _buildVaccinationTable(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ScannedVaccinationData? scannedData) {
    return Column(
      children: [
        const Text(
          'Informations détectées',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C5F66),
          ),
          textAlign: TextAlign.center,
        ),
        if (scannedData != null && scannedData.confidence > 0.0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scannedData.confidence > 0.8 
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFFFFA726).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scannedData.confidence > 0.8 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA726),
                  width: 1,
                ),
              ),
              child: Text(
                'Confiance: ${(scannedData.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: scannedData.confidence > 0.8 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA726),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _userExists 
              ? 'Vérifiez les informations avant sauvegarde'
              : 'Vérifiez et créez votre compte pour sauvegarder',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF2C5F66).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        // User status indicator
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _userExists 
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : const Color(0xFF7DD3D8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _userExists 
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : const Color(0xFF7DD3D8).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _userExists ? Icons.person : Icons.person_add,
                color: _userExists 
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF7DD3D8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _userExists ? 'Utilisateur connecté' : 'Compte requis',
                style: TextStyle(
                  color: _userExists 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF7DD3D8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header similar to wireframe
          const Text(
            'Information sur votre vaccination',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C5CE7), // Purple color from wireframe
            ),
          ),
          const SizedBox(height: 16),
          
          // Table Header
          Row(
            children: [
              _buildTableHeader('Vaccin', flex: 3),
              _buildTableHeader('Lot', flex: 2),
              _buildTableHeader('Date', flex: 2),
              _buildTableHeader('Pharmacien', flex: 2),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Table Row with current data
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTableCell(_vaccineController.text, flex: 3),
                _buildTableCell(_lotController.text, flex: 2),
                _buildTableCell(_dateController.text, flex: 2),
                _buildTableCell(_psController.text.isEmpty ? 'Pharmacien' : _psController.text, flex: 2),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          content.isEmpty ? 'Non détecté' : content,
          style: TextStyle(
            fontSize: 12,
            color: content.isEmpty 
                ? Colors.grey[500] 
                : const Color(0xFF333333),
            fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main validation button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveVaccination,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7), // Purple from wireframe
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Créer un compte et sauvegarder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Secondary action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () {
                  Navigator.pushReplacementNamed(context, '/camera-scan');
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Rescanner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2C5F66),
                  side: const BorderSide(color: Color(0xFF2C5F66)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/manual-entry',
                    arguments: {
                      'vaccine': _vaccineController.text,
                      'lot': _lotController.text,
                      'date': _dateController.text,
                      'ps': _psController.text,
                    },
                  );
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Corriger'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7DD3D8),
                  side: const BorderSide(color: Color(0xFF7DD3D8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveVaccination() async {
    setState(() => _isSaving = true);

    try {
      if (_userExists) {
        // User is already signed in - save vaccination directly
        final currentUser = await _databaseService.getCurrentUser();
        
        if (currentUser == null) {
          throw Exception('Erreur: utilisateur non trouvé');
        }

        // Create vaccination record
        final vaccination = Vaccination(
          vaccineName: _vaccineController.text.trim(),
          lot: _lotController.text.trim(),
          date: _dateController.text.trim(),
          ps: _psController.text.trim().isEmpty ? 'Pharmacien' : _psController.text.trim(),
          userId: currentUser.key.toString(),
        );

        // Save to database
        await _databaseService.saveVaccination(vaccination);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Vaccination enregistrée avec succès!'),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back to vaccination info screen
          Navigator.pushReplacementNamed(context, '/vaccination-info');
        }
      } else {
        // No user signed in - go to user creation flow
        final vaccinationData = {
          'vaccineName': _vaccineController.text.trim(),
          'lot': _lotController.text.trim(),
          'date': _dateController.text.trim(),
          'ps': _psController.text.trim().isEmpty ? 'Pharmacien' : _psController.text.trim(),
        };

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données validées. Créez votre compte pour sauvegarder.'),
              backgroundColor: Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to user creation with vaccination data
          Navigator.pushNamed(
            context, 
            '/user-creation',
            arguments: vaccinationData,
          );
        }
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
      if (mounted) setState(() => _isSaving = false);
    }
  }
}