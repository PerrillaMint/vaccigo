// lib/screens/onboarding/scan_preview_screen.dart
import 'package:flutter/material.dart';
import '../../models/scanned_vaccination_data.dart';

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

  @override
  void initState() {
    super.initState();
    _vaccineController = TextEditingController();
    _lotController = TextEditingController();
    _dateController = TextEditingController();
    _psController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get scanned data from navigation arguments
    final ScannedVaccinationData? scannedData = 
        ModalRoute.of(context)?.settings.arguments as ScannedVaccinationData?;
    
    if (scannedData != null) {
      _vaccineController.text = scannedData.vaccineName;
      _lotController.text = scannedData.lot;
      _dateController.text = scannedData.date;
      _psController.text = scannedData.ps;
    } else {
      // Demo data if no scan data (simulating AI detection)
      _vaccineController.text = 'Pfizer-BioNTech COVID-19';
      _lotController.text = 'EW0553';
      _dateController.text = '15/03/2025';
      _psController.text = 'Dose de rappel';
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
    final ScannedVaccinationData? scannedData = 
        ModalRoute.of(context)?.settings.arguments as ScannedVaccinationData?;
    
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
              
              // Information Preview Card
              Expanded(
                child: SingleChildScrollView(
                  child: _buildInformationCard(),
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
          'Vérifiez et modifiez si nécessaire',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF2C5F66).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DD3D8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.vaccines,
                  color: Color(0xFF2C5F66),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Informations de vaccination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F66),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Information fields
          _buildInfoRow('Vaccin:', _vaccineController.text, Icons.medical_services),
          _buildDivider(),
          _buildInfoRow('Lot:', _lotController.text, Icons.confirmation_number),
          _buildDivider(),
          _buildInfoRow('Date:', _dateController.text, Icons.calendar_today),
          _buildDivider(),
          _buildInfoRow('PS:', _psController.text, Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C5F66).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF2C5F66),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Label
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5F66),
              ),
            ),
          ),
          
          // Value
          Expanded(
            child: Text(
              value.isEmpty ? 'Non détecté' : value,
              style: TextStyle(
                fontSize: 14,
                color: value.isEmpty 
                    ? Colors.grey[500] 
                    : const Color(0xFF333333),
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main validation button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/vaccination-info');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C5F66),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Valider la saisie',
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
                onPressed: () {
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
                onPressed: () {
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
                label: const Text('Modifier'),
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
}
