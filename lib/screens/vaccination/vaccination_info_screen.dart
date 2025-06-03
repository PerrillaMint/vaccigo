// lib/screens/vaccination/vaccination_info_screen.dart
import 'package:flutter/material.dart';
import '../../models/vaccination.dart';
import '../../services/database_service.dart';

class VaccinationInfoScreen extends StatefulWidget {
  const VaccinationInfoScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationInfoScreen> createState() => _VaccinationInfoScreenState();
}

class _VaccinationInfoScreenState extends State<VaccinationInfoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      if (currentUser != null) {
        final vaccinations = await _databaseService.getVaccinationsByUser(
          currentUser.key.toString(),
        );
        setState(() {
          _vaccinations = vaccinations;
          _isLoading = false;
        });
      } else {
        // If no current user, get all vaccinations
        final allVaccinations = await _databaseService.getAllVaccinations();
        setState(() {
          _vaccinations = allVaccinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
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
          'Information sur votre vaccination',
          style: TextStyle(
            color: Color(0xFF6C5CE7), // Purple color from wireframe
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vaccination Table Section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVaccinationsTable(),
                      
                      const SizedBox(height: 32),
                      
                      // Mes rappels Section
                      _buildRemindersSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Mes voyages Section
                      _buildTravelSection(),
                      
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
              
              // Information / Gestion Button (Bottom fixed - as per wireframe)
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Row(
          children: [
            _buildTableHeader('Vaccin', flex: 3),
            _buildTableHeader('Lot', flex: 2),
            _buildTableHeader('Date', flex: 2),
            _buildTableHeader('PS', flex: 2),
          ],
        ),
        const SizedBox(height: 8),
        
        // Table Content
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_vaccinations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Aucune vaccination enregistrée',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          )
        else
          ..._vaccinations.map((vaccination) => _buildTableRow(vaccination)).toList(),
      ],
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

  Widget _buildTableRow(Vaccination vaccination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
          _buildTableCell(vaccination.vaccineName, flex: 3),
          _buildTableCell(vaccination.lot, flex: 2),
          _buildTableCell(vaccination.date, flex: 2),
          _buildTableCell(vaccination.ps, flex: 2),
        ],
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF333333),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes rappels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C5CE7), // Purple color from wireframe
          ),
        ),
        const SizedBox(height: 12),
        
        // Simple reminder table
        Row(
          children: [
            _buildTableHeader('Vaccin', flex: 2),
            _buildTableHeader('Date', flex: 2),
          ],
        ),
        const SizedBox(height: 8),
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
              _buildTableCell('Grippe', flex: 2),
              _buildTableCell('10-2025', flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes voyages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7), // Purple color from wireframe
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF6C5CE7),
              size: 24,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: const Text(
            'Aucun voyage planifié',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/user-creation');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7), // Purple color from wireframe
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Information / Gestion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}