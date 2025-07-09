// lib/screens/vaccination/vaccination_info_screen.dart - Écran d'information et consultation des vaccinations
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/vaccination.dart';
import '../../models/enhanced_user.dart';
import '../../services/database_service.dart';

class VaccinationInfoScreen extends StatefulWidget {
  const VaccinationInfoScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationInfoScreen> createState() => _VaccinationInfoScreenState();
}

class _VaccinationInfoScreenState extends State<VaccinationInfoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Vaccination> _vaccinations = [];
  EnhancedUser? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'vaccine', 'status'

  @override
  void initState() {
    super.initState();
    _loadUserVaccinations();
  }

  Future<void> _loadUserVaccinations() async {
    try {
      final user = await _databaseService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final vaccinations = await _databaseService.getVaccinationsByUser(user.key.toString());
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _vaccinations = vaccinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des vaccinations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mon Carnet',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _sortBy = value);
              _sortVaccinations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 8),
                    Text('Trier par date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vaccine',
                child: Row(
                  children: [
                    Icon(Icons.vaccines, size: 16),
                    SizedBox(width: 8),
                    Text('Trier par vaccin'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoading(message: 'Chargement de votre carnet...')
          : SafeArea(
              child: Column(
                children: [
                  // En-tête avec statistiques
                  _buildHeader(),
                  
                  // Liste des vaccinations
                  Expanded(
                    child: _buildVaccinationsList(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/travel-options'),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildHeader() {
    final filteredVaccinations = _getFilteredVaccinations();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.name ?? 'Mon Carnet',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${filteredVaccinations.length} vaccination(s)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recherche: "$_searchQuery"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationsList() {
    final filteredVaccinations = _getFilteredVaccinations();
    
    if (filteredVaccinations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserVaccinations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredVaccinations.length,
        itemBuilder: (context, index) {
          return _buildVaccinationCard(filteredVaccinations[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vaccines_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Aucune vaccination trouvée'
                  : 'Aucune vaccination enregistrée',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Commencez par ajouter votre première vaccination',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              AppButton(
                text: 'Ajouter une vaccination',
                icon: Icons.add,
                onPressed: () => Navigator.pushNamed(context, '/travel-options'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom du vaccin
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.vaccines,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccination.vaccineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        vaccination.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleVaccinationAction(action, vaccination),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Détails de la vaccination
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (vaccination.hasLot)
                    _buildDetailRow(
                      icon: Icons.confirmation_number,
                      label: 'Numéro de lot',
                      value: vaccination.lot!,
                    ),
                  
                  if (vaccination.ps.isNotEmpty) ...[
                    if (vaccination.hasLot) const SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.info_outline,
                      label: 'Informations',
                      value: vaccination.ps,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Vaccination> _getFilteredVaccinations() {
    if (_searchQuery.isEmpty) return _vaccinations;
    
    return _vaccinations.where((vaccination) {
      final query = _searchQuery.toLowerCase();
      return vaccination.vaccineName.toLowerCase().contains(query) ||
             vaccination.date.contains(query) ||
             (vaccination.lot?.toLowerCase().contains(query) ?? false) ||
             vaccination.ps.toLowerCase().contains(query);
    }).toList();
  }

  void _sortVaccinations() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _vaccinations.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
          break;
        case 'vaccine':
          _vaccinations.sort((a, b) => a.vaccineName.compareTo(b.vaccineName));
          break;
      }
    });
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom du vaccin, date, lot...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleVaccinationAction(String action, Vaccination vaccination) {
    switch (action) {
      case 'edit':
        _editVaccination(vaccination);
        break;
      case 'delete':
        _showDeleteConfirmation(vaccination);
        break;
    }
  }

  void _editVaccination(Vaccination vaccination) {
    Navigator.pushNamed(
      context,
      '/manual-entry',
      arguments: {
        'vaccine': vaccination.vaccineName,
        'lot': vaccination.lot ?? '',
        'date': vaccination.date,
        'ps': vaccination.ps,
        'editMode': true,
        'vaccinationId': vaccination.key.toString(),
      },
    );
  }

  void _showDeleteConfirmation(Vaccination vaccination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la vaccination'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la vaccination "${vaccination.vaccineName}" du ${vaccination.date} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVaccination(vaccination);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVaccination(Vaccination vaccination) async {
    try {
      await _databaseService.deleteVaccination(vaccination.key.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccination supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Recharge la liste
        await _loadUserVaccinations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}