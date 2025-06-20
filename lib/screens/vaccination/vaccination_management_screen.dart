// lib/screens/vaccination/vaccination_management_screen.dart - FIXED overflow issue
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
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
      appBar: const CustomAppBar(
        title: 'Gestion des vaccinations',
      ),
      body: _isLoading
          ? const AppLoading(message: 'Chargement des recommandations...')
          : SafeArea(
              child: Column(
                children: [
                  // Header - FIXED: Much more compact
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12), // REDUCED from 20
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.secondary.withOpacity(0.1),
                            AppColors.light.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12), // REDUCED from 20
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row( // CHANGED: Use Row instead of Column to save space
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8), // REDUCED from 16
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              size: 20, // REDUCED from 32
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Recommandations',
                                  style: TextStyle(
                                    fontSize: 16, // REDUCED from 20
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2), // REDUCED spacing
                                Text(
                                  'Vaccinations recommandées et voyages',
                                  style: TextStyle(
                                    fontSize: 12, // REDUCED from 14
                                    color: AppColors.primary.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content - Use Expanded to take remaining space
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // FIXED: Use min size
                        children: [
                          // Vaccine categories
                          if (_categories.isNotEmpty) ...[
                            _buildCategoriesSection(),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          
                          // Travel section
                          _buildTravelSection(),
                          
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Additional resources
                          _buildResourcesSection(),
                          
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // FIXED: Use min size
      children: [
        const Text(
          'Vaccinations recommandées',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        const Text(
          'Recommandations basées sur les directives officielles de santé publique',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // FIXED: Use ListView.builder with shrinkWrap instead of mapping
        ListView.builder(
          shrinkWrap: true, // FIXED: Allow list to shrink to content size
          physics: const NeverScrollableScrollPhysics(), // FIXED: Disable scrolling since parent handles it
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildCategoryCard(_categories[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(VaccineCategory category) {
    // Map icon types to actual icons and colors
    IconData icon;
    Color color;

    switch (category.iconType) {
      case 'check_circle':
        icon = Icons.verified;
        color = AppColors.success;
        break;
      case 'recommend':
        icon = Icons.recommend;
        color = AppColors.warning;
        break;
      case 'flight':
        icon = Icons.flight;
        color = AppColors.info;
        break;
      default:
        icon = Icons.vaccines;
        color = AppColors.primary;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // FIXED: Use min size
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusBadge(
                      text: '${category.vaccines.length} vaccin(s)',
                      type: StatusType.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (category.vaccines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            
            // Vaccines list
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vaccins dans cette catégorie:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // FIXED: Use Wrap or Column instead of mapping with Expanded
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: category.vaccines.map((vaccine) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              vaccine,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Aucun vaccin configuré pour cette catégorie',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // FIXED: Use min size
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Préparation de voyages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showAddTravelDialog,
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.secondary,
                  size: 28,
                ),
                tooltip: 'Ajouter un voyage',
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Travel content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.luggage,
                  size: 48,
                  color: AppColors.secondary.withOpacity(0.7),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Planifiez vos voyages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Ajoutez vos destinations pour recevoir des recommandations personnalisées de vaccination',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Ajouter un voyage',
                  icon: Icons.add,
                  style: AppButtonStyle.secondary,
                  onPressed: _showAddTravelDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // FIXED: Use min size
        children: [
          const Row(
            children: [
              Icon(
                Icons.library_books,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ressources utiles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // FIXED: Use Column instead of mapping to avoid flex issues
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResourceItem(
                icon: Icons.schedule,
                title: 'Calendrier vaccinal',
                description: 'Consulter le calendrier officiel des vaccinations',
                color: AppColors.info,
              ),
              _buildResourceItem(
                icon: Icons.location_on,
                title: 'Vaccinations par destination',
                description: 'Recommandations selon votre destination de voyage',
                color: AppColors.warning,
              ),
              _buildResourceItem(
                icon: Icons.emergency,
                title: 'Urgences médicales',
                description: 'Contacts utiles en cas d\'urgence',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          // Future implementation for resource links
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ressource à venir dans une prochaine version'),
              backgroundColor: AppColors.info,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
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
              color: AppColors.primary,
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
                    hintText: 'Ex: France, Thaïlande, Brésil...',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de départ',
                    hintText: 'JJ/MM/AAAA',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      startDateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de retour',
                    hintText: 'JJ/MM/AAAA',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      endDateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    hintText: 'Raison du voyage, activités prévues...',
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
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text('Voyage vers ${destinationController.text} planifié!'),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }
}