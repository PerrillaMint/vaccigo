// lib/screens/vaccination/vaccination_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/vaccine_category.dart';
import '../../services/database_service.dart';

class VaccinationManagementScreen extends StatefulWidget {
  const VaccinationManagementScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationManagementScreen> createState() => _VaccinationManagementScreenState();
}

class _VaccinationManagementScreenState extends State<VaccinationManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<VaccineCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getAllVaccineCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
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
          'Gestion des vaccinations',
          style: TextStyle(
            color: Color(0xFF2C5F66),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Database-driven vaccine categories (read-only for user)
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_categories.isNotEmpty) ...[
                  const Text(
                    'Vaccinations recommandées',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5F66),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categories.map((category) => _buildCategorySection(category)),
                  const SizedBox(height: 32),
                ],
                
                // Travel section (user can add/edit)
                _buildTravelSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(VaccineCategory category) {
    IconData icon;
    Color color;

    switch (category.iconType) {
      case 'check_circle':
        icon = Icons.check_circle;
        color = const Color(0xFF4CAF50);
        break;
      case 'recommend':
        icon = Icons.recommend;
        color = const Color(0xFFFFA726);
        break;
      case 'flight':
        icon = Icons.flight;
        color = const Color(0xFF2196F3);
        break;
      default:
        icon = Icons.vaccines;
        color = const Color(0xFF2C5F66);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F66),
                  ),
                ),
              ),
            ],
          ),
          if (category.vaccines.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...category.vaccines.map((vaccine) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vaccine,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Aucun vaccin configuré pour cette catégorie',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DD3D8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: Color(0xFF7DD3D8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Mes voyages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5F66),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showAddTravelDialog,
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF7DD3D8),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Travel list placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7DD3D8).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7DD3D8).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.luggage,
                  size: 48,
                  color: Color(0xFF7DD3D8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucun voyage planifié',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C5F66),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajoutez un voyage pour voir les vaccinations recommandées',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddTravelDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un voyage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTravelDialog() {
    final TextEditingController destinationController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Ajouter un voyage',
            style: TextStyle(
              color: Color(0xFF2C5F66),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: 'Ex: France, Thaïlande...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de départ',
                    hintText: 'JJ/MM/AAAA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de retour',
                    hintText: 'JJ/MM/AAAA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    hintText: 'Raison du voyage, activités prévues...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (destinationController.text.isNotEmpty &&
                    startDateController.text.isNotEmpty &&
                    endDateController.text.isNotEmpty) {
                  // Here you would save the travel to database
                  // For now, just show success message
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voyage ajouté avec succès!'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F66),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }
}