// lib/screens/onboarding/scan_preview_screen.dart - Updated with new design
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
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
  ScannedVaccinationData? _scannedData;

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
      _scannedData = arguments;
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
      _psController.text = 'Dr. Martin';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Vérification',
      ),
      body: Column(
        children: [
          Expanded(
            child: SafePageWrapper(
              child: Column(
                children: [
                  // Header section
                  _buildHeaderSection(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Vaccination preview card
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildVaccinationPreview(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return AppPageHeader(
      title: 'Informations détectées',
      subtitle: _userExists 
          ? 'Vérifiez les informations avant d\'ajouter à votre carnet'
          : 'Vérifiez et créez votre compte pour sauvegarder',
      icon: Icons.preview,
      trailing: Column(
        children: [
          // Confidence indicator
          if (_scannedData != null && _scannedData!.confidence > 0.0)
            StatusBadge(
              text: 'Confiance: ${(_scannedData!.confidence * 100).toStringAsFixed(1)}%',
              type: _scannedData!.confidence > 0.8 
                  ? StatusType.success 
                  : StatusType.warning,
              icon: _scannedData!.confidence > 0.8 
                  ? Icons.check_circle 
                  : Icons.warning,
            ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // User status indicator
          StatusBadge(
            text: _userExists ? 'Utilisateur connecté' : 'Compte requis',
            type: _userExists ? StatusType.success : StatusType.info,
            icon: _userExists ? Icons.person : Icons.person_add,
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationPreview() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                Text(
                  'Aperçu de votre vaccination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Vaccination details
          _buildVaccinationDetail(
            icon: Icons.vaccines,
            label: 'Vaccin',
            value: _vaccineController.text.isEmpty ? 'Non détecté' : _vaccineController.text,
            isEmpty: _vaccineController.text.isEmpty,
          ),
          
          _buildVaccinationDetail(
            icon: Icons.confirmation_number,
            label: 'Lot',
            value: _lotController.text.isEmpty ? 'Non détecté' : _lotController.text,
            isEmpty: _lotController.text.isEmpty,
          ),
          
          _buildVaccinationDetail(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _dateController.text.isEmpty ? 'Non détecté' : _dateController.text,
            isEmpty: _dateController.text.isEmpty,
          ),
          
          _buildVaccinationDetail(
            icon: Icons.info_outline,
            label: 'Informations supplémentaires',
            value: _psController.text.isEmpty ? 'Aucune information' : _psController.text,
            isEmpty: _psController.text.isEmpty,
            isOptional: true,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Data completeness indicator
          _buildCompletenessIndicator(),
        ],
      ),
    );
  }

  Widget _buildVaccinationDetail({
    required IconData icon,
    required String label,
    required String value,
    required bool isEmpty,
    bool isOptional = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isEmpty && !isOptional 
            ? AppColors.warning.withOpacity(0.05)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEmpty && !isOptional 
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isEmpty && !isOptional 
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isEmpty && !isOptional 
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!isOptional && isEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.warning,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEmpty 
                        ? AppColors.textMuted
                        : AppColors.primary,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessIndicator() {
    final requiredFields = [_vaccineController.text, _lotController.text, _dateController.text];
    final completedFields = requiredFields.where((field) => field.isNotEmpty).length;
    final completeness = completedFields / requiredFields.length;
    
    Color indicatorColor;
    String indicatorText;
    IconData indicatorIcon;
    
    if (completeness == 1.0) {
      indicatorColor = AppColors.success;
      indicatorText = 'Informations complètes';
      indicatorIcon = Icons.check_circle;
    } else if (completeness >= 0.5) {
      indicatorColor = AppColors.warning;
      indicatorText = 'Informations partielles';
      indicatorIcon = Icons.warning;
    } else {
      indicatorColor = AppColors.error;
      indicatorText = 'Informations incomplètes';
      indicatorIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            indicatorIcon,
            color: indicatorColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicatorText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: indicatorColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$completedFields sur ${requiredFields.length} champs requis complétés',
                  style: TextStyle(
                    fontSize: 12,
                    color: indicatorColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main validation button
          AppButton(
            text: _userExists 
                ? 'Ajouter à mon carnet'
                : 'Créer un compte et sauvegarder',
            icon: _userExists ? Icons.add : Icons.person_add,
            isLoading: _isSaving,
            onPressed: _saveVaccination,
            width: double.infinity,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Secondary action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Rescanner',
                  icon: Icons.camera_alt,
                  style: AppButtonStyle.secondary,
                  onPressed: _isSaving ? null : () {
                    Navigator.pushReplacementNamed(context, '/camera-scan');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: 'Corriger',
                  icon: Icons.edit,
                  style: AppButtonStyle.secondary,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveVaccination() async {
    setState(() => _isSaving = true);

    try {
      if (_userExists) {
        // User is logged in - save directly
        final currentUser = await _databaseService.getCurrentUser();
        
        if (currentUser == null) {
          throw Exception('Erreur: utilisateur non trouvé');
        }

        final vaccination = Vaccination(
          vaccineName: _vaccineController.text.trim(),
          lot: _lotController.text.trim(),
          date: _dateController.text.trim(),
          ps: _psController.text.trim().isEmpty ? 'Information non fournie' : _psController.text.trim(),
          userId: currentUser.key.toString(),
        );

        await _databaseService.saveVaccination(vaccination);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text('Vaccination ajoutée à votre carnet!'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );

          Navigator.pushReplacementNamed(context, '/vaccination-info');
        }
      } else {
        // No user signed in - go to user creation flow
        final vaccinationData = {
          'vaccineName': _vaccineController.text.trim(),
          'lot': _lotController.text.trim(),
          'date': _dateController.text.trim(),
          'ps': _psController.text.trim().isEmpty ? 'Information non fournie' : _psController.text.trim(),
        };

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données validées. Créez votre compte pour sauvegarder.'),
              backgroundColor: AppColors.success,
            ),
          );

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
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}