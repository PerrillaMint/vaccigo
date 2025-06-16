// lib/screens/onboarding/scan_preview_screen.dart - FIXED layout overflow issues
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vaccineController = TextEditingController();
    _lotController = TextEditingController();
    _dateController = TextEditingController();
    _psController = TextEditingController();
    _checkUserExists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isLoading) {
      _loadArgumentData();
    }
  }

  void _loadArgumentData() {
    try {
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
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading argument data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserExists() async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userExists = currentUser != null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userExists = false;
        });
      }
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Vérification',
      ),
      // FIXED: Use LayoutBuilder with ConstrainedBox to prevent overflow
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header - Fixed size content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildHeader(),
                    ),
                    
                    // Main content - Flexible space
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVaccinationPreviewCard(),
                            const SizedBox(height: 16),
                            _buildDataCompletenessCard(),
                            
                            // FIXED: Action buttons moved inside scrollable area
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                            
                            // Bottom padding for better UX
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // FIXED: Ensure header doesn't expand unnecessarily
        children: [
          const Icon(
            Icons.preview,
            size: 28, // FIXED: Reduced icon size to save space
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const Text(
            'Informations détectées',
            style: TextStyle(
              fontSize: 16, // FIXED: Reduced font size
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _userExists 
                ? 'Vérifiez les informations avant d\'ajouter à votre carnet'
                : 'Vérifiez et créez votre compte pour sauvegarder',
            style: const TextStyle(
              fontSize: 12, // FIXED: Reduced font size
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // FIXED: Limit text lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8), // FIXED: Reduced spacing
          
          // Status indicators - Made more compact
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // Confidence indicator
              if (_scannedData != null && _scannedData!.confidence > 0.0)
                _buildCompactStatusBadge(
                  text: 'Confiance: ${(_scannedData!.confidence * 100).toStringAsFixed(0)}%',
                  color: _scannedData!.confidence > 0.8 ? AppColors.success : AppColors.warning,
                  icon: _scannedData!.confidence > 0.8 ? Icons.check_circle : Icons.warning,
                ),
              
              // User status indicator
              _buildCompactStatusBadge(
                text: _userExists ? 'Connecté' : 'Compte requis',
                color: _userExists ? AppColors.success : AppColors.info,
                icon: _userExists ? Icons.person : Icons.person_add,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: More compact status badge to save space
  Widget _buildCompactStatusBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // FIXED: Prevent unnecessary expansion
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12), // FIXED: Reduced padding
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min, // FIXED: Minimize row size
              children: [
                Icon(
                  Icons.medical_information,
                  color: AppColors.accent,
                  size: 16, // FIXED: Smaller icon
                ),
                SizedBox(width: 6),
                Text(
                  'Aperçu de votre vaccination',
                  style: TextStyle(
                    fontSize: 14, // FIXED: Smaller font
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12), // FIXED: Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // FIXED: Minimize column size
              children: [
                _buildVaccinationDetail(
                  icon: Icons.vaccines,
                  label: 'Vaccin',
                  value: _vaccineController.text.isEmpty 
                      ? 'Non détecté' 
                      : _vaccineController.text,
                  isEmpty: _vaccineController.text.isEmpty,
                ),
                _buildVaccinationDetail(
                  icon: Icons.confirmation_number,
                  label: 'Lot',
                  value: _lotController.text.isEmpty 
                      ? 'Non détecté' 
                      : _lotController.text,
                  isEmpty: _lotController.text.isEmpty,
                ),
                _buildVaccinationDetail(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _dateController.text.isEmpty 
                      ? 'Non détecté' 
                      : _dateController.text,
                  isEmpty: _dateController.text.isEmpty,
                ),
                _buildVaccinationDetail(
                  icon: Icons.info_outline,
                  label: 'Informations supplémentaires',
                  value: _psController.text.isEmpty 
                      ? 'Aucune information' 
                      : _psController.text,
                  isEmpty: _psController.text.isEmpty,
                  isOptional: true,
                ),
              ],
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 8), // FIXED: Reduced margin
      padding: const EdgeInsets.all(8), // FIXED: Reduced padding
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
        crossAxisAlignment: CrossAxisAlignment.start, // FIXED: Align to start
        children: [
          Container(
            padding: const EdgeInsets.all(4), // FIXED: Reduced padding
            decoration: BoxDecoration(
              color: isEmpty && !isOptional 
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 14, // FIXED: Smaller icon
              color: isEmpty && !isOptional 
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // FIXED: Minimize column size
              children: [
                Row(
                  children: [
                    Expanded( // FIXED: Prevent text overflow
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11, // FIXED: Smaller font
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isOptional && isEmpty) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.warning,
                        size: 10, // FIXED: Smaller warning icon
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12, // FIXED: Smaller font
                    fontWeight: FontWeight.w500,
                    color: isEmpty 
                        ? AppColors.textMuted
                        : AppColors.primary,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2, // FIXED: Limit lines to prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCompletenessCard() {
    final requiredFields = [
      _vaccineController.text, 
      _lotController.text, 
      _dateController.text
    ];
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
      width: double.infinity,
      padding: const EdgeInsets.all(12), // FIXED: Reduced padding
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicatorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // FIXED: Minimize row size
        children: [
          Icon(
            indicatorIcon,
            color: indicatorColor,
            size: 16, // FIXED: Smaller icon
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // FIXED: Minimize column size
              children: [
                Text(
                  indicatorText,
                  style: TextStyle(
                    fontSize: 12, // FIXED: Smaller font
                    fontWeight: FontWeight.w600,
                    color: indicatorColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$completedFields sur ${requiredFields.length} champs requis complétés',
                  style: TextStyle(
                    fontSize: 10, // FIXED: Smaller font
                    color: indicatorColor.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Compact action buttons that don't cause overflow
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // FIXED: Minimize column size
      children: [
        // Main validation button - Made more compact
        SizedBox(
          height: 48, // FIXED: Fixed height to prevent expansion
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveVaccination,
            icon: _isSaving 
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_userExists ? Icons.add : Icons.person_add, size: 18),
            label: Text(
              _isSaving 
                  ? 'Sauvegarde...'
                  : _userExists 
                      ? 'Ajouter à mon carnet'
                      : 'Créer un compte',
              style: const TextStyle(fontSize: 14), // FIXED: Smaller font
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8), // FIXED: Reduced spacing
        
        // Secondary action buttons - Made more compact
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40, // FIXED: Fixed height
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () {
                    Navigator.pushReplacementNamed(context, '/camera-scan');
                  },
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Rescanner', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 40, // FIXED: Fixed height
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
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Corriger', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    if (_isSaving) return;
    
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
          ps: _psController.text.trim().isEmpty 
              ? 'Information non fournie' 
              : _psController.text.trim(),
          userId: currentUser.key.toString(),
        );

        await _databaseService.saveVaccination(vaccination);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
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
          'ps': _psController.text.trim().isEmpty 
              ? 'Information non fournie' 
              : _psController.text.trim(),
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
                const SizedBox(width: 8),
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