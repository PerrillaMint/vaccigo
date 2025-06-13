// lib/screens/vaccination/vaccination_info_screen.dart - FIXED method signatures
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
          'Mon Carnet',
          style: TextStyle(
            color: Color(0xFF2C5F66),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF7DD3D8),
              size: 28,
            ),
            onPressed: _showAddVaccinationOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVaccinationsTable(),
                      
                      const SizedBox(height: 32),
                      
                      _buildRemindersSection(),
                      
                      const SizedBox(height: 32),
                      
                      _buildTravelSection(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7DD3D8).withOpacity(0.1),
            const Color(0xFF7DD3D8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7DD3D8).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C5F66).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vaccines,
              color: Color(0xFF2C5F66),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Vaccinations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F66),
                  ),
                ),
                Text(
                  '${_vaccinations.length} vaccination(s) enregistrée(s)',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2C5F66).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showAddVaccinationOptions,
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF7DD3D8),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTable() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Information sur votre vaccination',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildTableHeader('Vaccin', flex: 3),
                _buildTableHeader('Lot', flex: 2),
                _buildTableHeader('Date', flex: 2),
                _buildTableHeader('PS', flex: 2),
                _buildTableHeader('', flex: 1),
              ],
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_vaccinations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.vaccines_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune vaccination enregistrée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez votre première vaccination',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddVaccinationOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une vaccination'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DD3D8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _vaccinations.asMap().entries.map((entry) {
                final index = entry.key;
                final vaccination = entry.value;
                return _buildTableRow(vaccination, index);
              }).toList(),
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildTableRow(Vaccination vaccination, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(vaccination.vaccineName, flex: 3),
          _buildTableCell(vaccination.lot, flex: 2),
          _buildTableCell(vaccination.date, flex: 2),
          _buildTableCell(vaccination.ps, flex: 2),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteVaccination(vaccination, index);
                } else if (value == 'edit') {
                  _editVaccination(vaccination);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Color(0xFF7DD3D8)),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: Color(0xFF666666),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF333333),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes rappels',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 12),
          
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
      ),
    );
  }

  Widget _buildTravelSection() {
    return Container(
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
      ),
      child: Column(
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
                  color: Color(0xFF6C5CE7),
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
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/vaccination-management');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
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

  void _showAddVaccinationOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ajouter une vaccination',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5F66),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C5F66).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF2C5F66),
                  ),
                ),
                title: const Text('Scanner avec IA'),
                subtitle: const Text('Analyser automatiquement votre carnet'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/camera-scan');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3D8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF7DD3D8),
                  ),
                ),
                title: const Text('Saisie manuelle'),
                subtitle: const Text('Entrer les informations manuellement'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/manual-entry');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteVaccination(Vaccination vaccination, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Supprimer la vaccination',
            style: TextStyle(
              color: Color(0xFF2C5F66),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Êtes-vous sûr de vouloir supprimer cette vaccination ?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccin: ${vaccination.vaccineName}'),
                    Text('Lot: ${vaccination.lot}'),
                    Text('Date: ${vaccination.date}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVaccination(vaccination);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // FIXED: Use vaccination key instead of index for deletion
  Future<void> _deleteVaccination(Vaccination vaccination) async {
    try {
      final vaccinationKey = vaccination.key?.toString();
      if (vaccinationKey == null) {
        throw Exception('Vaccination key is null');
      }
      
      await _databaseService.deleteVaccination(vaccinationKey);
      await _loadVaccinations(); // Reload the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccination supprimée avec succès'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editVaccination(Vaccination vaccination) {
    Navigator.pushNamed(
      context, 
      '/manual-entry',
      arguments: {
        'vaccine': vaccination.vaccineName,
        'lot': vaccination.lot,
        'date': vaccination.date,
        'ps': vaccination.ps,
      },
    );
  }
}