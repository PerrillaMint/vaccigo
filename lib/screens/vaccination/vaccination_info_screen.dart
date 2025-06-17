// lib/screens/vaccination/vaccination_info_screen.dart - FIXED table overflow issues
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
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
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.secondary,
              size: 28,
            ),
            onPressed: _showAddVaccinationOptions,
            tooltip: 'Ajouter une vaccination',
          ),
        ],
      ),
      body: _isLoading 
          ? const AppLoading(message: 'Chargement de vos vaccinations...')
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header section
                            _buildHeaderSection(),
                            
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Main content
                            _buildVaccinationsSection(),
                            
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Quick add section
                            _buildQuickAddSection(),
                            
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Additional sections
                            _buildAdditionalSections(),
                            
                            const SizedBox(height: AppSpacing.xxl),
                            
                            // Bottom button
                            _buildBottomButton(),
                            
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return AppCard(
      backgroundColor: AppColors.secondary.withOpacity(0.1),
      border: Border.all(
        color: AppColors.secondary.withOpacity(0.3),
        width: 1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vaccines,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // FIXED: Use Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Vaccinations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  text: '${_vaccinations.length} vaccination(s) enregistrée(s)',
                  type: StatusType.info,
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: _showAddVaccinationOptions,
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.medical_information,
                  color: AppColors.accent,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded( // FIXED: Prevent header text overflow
                  child: Text(
                    'Information sur vos vaccinations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Table content
          if (_vaccinations.isEmpty)
            _buildEmptyVaccinationsState()
          else
            _buildVaccinationsTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyVaccinationsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.vaccines_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Aucune vaccination enregistrée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ajoutez votre première vaccination pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // FIXED: Prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Ajouter une vaccination',
            icon: Icons.add,
            onPressed: _showAddVaccinationOptions,
          ),
        ],
      ),
    );
  }

  // FIXED: Completely rewritten table with proper responsive design
  Widget _buildVaccinationsTable() {
    return Column(
      children: [
        // Mobile-friendly table headers
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, 
            vertical: AppSpacing.sm
          ),
          child: Row(
            children: [
              _buildTableHeader('Vaccin', flex: 4),
              _buildTableHeader('Lot', flex: 2),
              _buildTableHeader('Date', flex: 2),
              _buildTableHeader('', flex: 1), // Actions column
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Vaccination rows - FIXED: Better mobile layout
        ...List.generate(_vaccinations.length, (index) {
          final vaccination = _vaccinations[index];
          return _buildVaccinationRow(vaccination, index);
        }),
      ],
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1}) {
    if (title.isEmpty) {
      return Expanded(
        flex: flex,
        child: const SizedBox(),
      );
    }
    
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // FIXED: Responsive vaccination row with proper overflow handling
  Widget _buildVaccinationRow(Vaccination vaccination, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, 
        vertical: AppSpacing.xs
      ),
      decoration: BoxDecoration(
        color: index.isEven ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Switch to mobile layout on smaller screens
          if (constraints.maxWidth < 600) {
            return _buildMobileVaccinationRow(vaccination);
          } else {
            return _buildDesktopVaccinationRow(vaccination);
          }
        },
      ),
    );
  }

  // FIXED: Mobile-first vaccination card layout
  Widget _buildMobileVaccinationRow(Vaccination vaccination) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vaccine name with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  vaccination.vaccineName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteVaccination(vaccination);
                  } else if (value == 'edit') {
                    _editVaccination(vaccination);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: AppColors.secondary),
                        SizedBox(width: AppSpacing.sm),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Details row
          Row(
            children: [
              // Lot number
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lot',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vaccination.lot,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vaccination.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Additional info if present
          if (vaccination.ps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 12,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      vaccination.ps,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.info,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  // Desktop/tablet layout
  Widget _buildDesktopVaccinationRow(Vaccination vaccination) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Vaccine name (with icon)
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccination.vaccineName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vaccination.ps.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          vaccination.ps,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lot number
          Expanded(
            flex: 2,
            child: Text(
              vaccination.lot,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Date
          Expanded(
            flex: 2,
            child: Text(
              vaccination.date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteVaccination(vaccination);
                } else if (value == 'edit') {
                  _editVaccination(vaccination);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: AppColors.secondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return AppCard(
      backgroundColor: AppColors.primary.withOpacity(0.05),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.2),
        width: 1,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Ajouter une nouvelle vaccination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1, // FIXED: Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // FIXED: Stack buttons vertically on small screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      text: 'Scanner avec IA',
                      icon: Icons.camera_alt,
                      style: AppButtonStyle.secondary,
                      onPressed: () => Navigator.pushNamed(context, '/camera-scan'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      text: 'Saisie manuelle',
                      icon: Icons.edit,
                      style: AppButtonStyle.secondary,
                      onPressed: () => Navigator.pushNamed(context, '/manual-entry'),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Scanner avec IA',
                        icon: Icons.camera_alt,
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.pushNamed(context, '/camera-scan'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        text: 'Saisie manuelle',
                        icon: Icons.edit,
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.pushNamed(context, '/manual-entry'),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSections() {
    return Column(
      children: [
        // Reminders section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded( // FIXED: Prevent title overflow
                    child: Text(
                      'Rappels à venir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Grippe saisonnière recommandée - Octobre 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.warning,
                  ),
                  maxLines: 2, // FIXED: Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Travel section
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.flight,
                    color: AppColors.info,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded( // FIXED: Prevent title overflow
                    child: Text(
                      'Mes voyages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aucun voyage planifié',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.info,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return AppButton(
      text: 'Information / Gestion',
      icon: Icons.settings,
      onPressed: () => Navigator.pushNamed(context, '/vaccination-management'),
      width: double.infinity,
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Ajouter une vaccination',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                maxLines: 1, // FIXED: Prevent overflow in modal
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Scanner option
              _buildBottomSheetOption(
                icon: Icons.camera_alt,
                title: 'Scanner avec IA',
                subtitle: 'Analyser automatiquement votre carnet',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/camera-scan');
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Manual option
              _buildBottomSheetOption(
                icon: Icons.edit,
                title: 'Saisie manuelle',
                subtitle: 'Entrer les informations manuellement',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/manual-entry');
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
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
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded( // FIXED: Prevent text overflow in bottom sheet
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
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
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVaccination(Vaccination vaccination) {
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
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Êtes-vous sûr de vouloir supprimer cette vaccination ?'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vaccin: ${vaccination.vaccineName}',
                      maxLines: 2, // FIXED: Prevent overflow in dialog
                      overflow: TextOverflow.ellipsis,
                    ),
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
                backgroundColor: AppColors.error,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVaccination(Vaccination vaccination) async {
    try {
      final vaccinationKey = vaccination.key?.toString();
      if (vaccinationKey == null) {
        throw Exception('Vaccination key is null');
      }
      
      await _databaseService.deleteVaccination(vaccinationKey);
      await _loadVaccinations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Expanded( // FIXED: Prevent overflow in success message
                  child: Text('Vaccination supprimée avec succès'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded( // FIXED: Prevent overflow in error message
                  child: Text('Erreur lors de la suppression: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
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