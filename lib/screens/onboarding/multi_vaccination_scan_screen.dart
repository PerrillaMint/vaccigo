// lib/screens/onboarding/multi_vaccination_scan_screen.dart - Écran pour scanner plusieurs vaccinations
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/enhanced_google_vision_service.dart';
import '../../services/database_service.dart';
import '../../models/vaccination.dart';

class MultiVaccinationScanScreen extends StatefulWidget {
  final String imagePath;
  final String userId;

  const MultiVaccinationScanScreen({
    Key? key,
    required this.imagePath,
    required this.userId,
  }) : super(key: key);

  @override
  State<MultiVaccinationScanScreen> createState() => _MultiVaccinationScanScreenState();
}

class _MultiVaccinationScanScreenState extends State<MultiVaccinationScanScreen> {
  final _visionService = EnhancedGoogleVisionService();
  final _databaseService = DatabaseService();
  
  List<VaccinationEntry> _detectedVaccinations = [];
  List<bool> _selectedVaccinations = [];
  bool _isProcessing = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final vaccinations = await _visionService.processVaccinationCard(widget.imagePath);
      
      setState(() {
        _detectedVaccinations = vaccinations;
        _selectedVaccinations = List.filled(vaccinations.length, true);
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Erreur lors de l\'analyse: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Vaccinations Détectées',
        actions: [
          if (!_isProcessing && _detectedVaccinations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _processImage,
              tooltip: 'Reanalyser',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_detectedVaccinations.isEmpty) {
      return _buildEmptyView();
    }

    return _buildVaccinationsList();
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Analyse du carnet en cours...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'L\'IA analyse votre carnet de vaccination\npour détecter toutes les entrées',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur d\'analyse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppButton(
                  text: 'Réessayer',
                  icon: Icons.refresh,
                  style: AppButtonStyle.secondary,
                  onPressed: _processImage,
                ),
                AppButton(
                  text: 'Saisie manuelle',
                  icon: Icons.edit,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/manual-entry',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.vaccines_outlined,
                    size: 64,
                    color: AppColors.warning,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune vaccination détectée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'L\'IA n\'a pas pu détecter de vaccinations dans cette image',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppButton(
                  text: 'Nouvelle photo',
                  icon: Icons.camera_alt,
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/camera-scan',
                  ),
                ),
                AppButton(
                  text: 'Saisie manuelle',
                  icon: Icons.edit,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/manual-entry',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // Liste des vaccinations détectées
          ...List.generate(_detectedVaccinations.length, (index) {
            return _buildVaccinationCard(index);
          }),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          _buildSelectionActions(),
          
          const SizedBox(height: 100), // Espace pour la bottom bar
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectedCount = _selectedVaccinations.where((selected) => selected).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_detectedVaccinations.length} vaccination(s) détectée(s)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selectedCount sélectionnée(s) pour sauvegarde',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard(int index) {
    final vaccination = _detectedVaccinations[index];
    final isSelected = _selectedVaccinations[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        backgroundColor: isSelected 
            ? AppColors.success.withOpacity(0.05)
            : AppColors.surface,
        border: Border.all(
          color: isSelected 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        child: Column(
          children: [
            // En-tête de la carte avec sélection
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedVaccinations[index] = value ?? false;
                    });
                  },
                  activeColor: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vaccination.vaccineName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                // Indicateur de confiance
                _buildConfidenceIndicator(vaccination.confidence),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Détails de la vaccination
            _buildVaccinationDetails(vaccination),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    String text;
    IconData icon;
    
    if (confidence >= 0.8) {
      color = AppColors.success;
      text = 'Élevée';
      icon = Icons.check_circle;
    } else if (confidence >= 0.5) {
      color = AppColors.warning;
      text = 'Moyenne';
      icon = Icons.warning;
    } else {
      color = AppColors.error;
      text = 'Faible';
      icon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationDetails(VaccinationEntry vaccination) {
    return Column(
      children: [
        _buildDetailRow('Date', vaccination.date, Icons.calendar_today),
        if (vaccination.lot.isNotEmpty)
          _buildDetailRow('Lot', vaccination.lot, Icons.qr_code),
        if (vaccination.ps.isNotEmpty)
          _buildDetailRow('Professionnel', vaccination.ps, Icons.medical_services),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AppButton(
          text: 'Tout sélectionner',
          style: AppButtonStyle.text,
          onPressed: () {
            setState(() {
              _selectedVaccinations = List.filled(_detectedVaccinations.length, true);
            });
          },
        ),
        AppButton(
          text: 'Tout désélectionner',
          style: AppButtonStyle.text,
          onPressed: () {
            setState(() {
              _selectedVaccinations = List.filled(_detectedVaccinations.length, false);
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _selectedVaccinations.where((selected) => selected).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Annuler',
                style: AppButtonStyle.secondary,
                onPressed: _isSaving ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AppButton(
                text: _isSaving 
                    ? 'Sauvegarde...'
                    : 'Sauvegarder ($selectedCount)',
                icon: _isSaving ? null : Icons.save,
                isLoading: _isSaving,
                onPressed: selectedCount > 0 && !_isSaving ? _saveSelectedVaccinations : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSelectedVaccinations() async {
    setState(() => _isSaving = true);

    try {
      final selectedVaccinations = <VaccinationEntry>[];
      for (int i = 0; i < _detectedVaccinations.length; i++) {
        if (_selectedVaccinations[i]) {
          selectedVaccinations.add(_detectedVaccinations[i]);
        }
      }

      // Convertit en objets Vaccination
      final vaccinations = _visionService.convertToVaccinations(
        selectedVaccinations,
        widget.userId,
      );

      // Sauvegarde en lot
      await _databaseService.saveMultipleVaccinations(vaccinations);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${vaccinations.length} vaccination(s) sauvegardée(s) !'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacementNamed(context, '/vaccination-summary');
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}