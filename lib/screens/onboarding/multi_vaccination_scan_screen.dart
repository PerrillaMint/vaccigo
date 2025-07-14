// lib/screens/onboarding/multi_vaccination_scan_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/enhanced_french_vaccination_parser_with_fuzzy.dart';
import '../../services/database_service.dart';
import '../../models/enhanced_user.dart';
import '../../models/vaccination.dart';
import '../../constants/app_colors.dart';

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
  final _parser = EnhancedFrenchVaccinationParser();
  final _databaseService = DatabaseService();
  
  List<VaccinationEntry> _detectedVaccinations = [];
  List<bool> _selectedVaccinations = [];
  Map<String, dynamic>? _parsingStats;
  bool _isProcessing = false;
  bool _isSaving = false;
  EnhancedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndProcess();
  }

  Future<void> _loadUserAndProcess() async {
    // Load current user
    _currentUser = await _databaseService.getUserById(widget.userId);
    
    // Process the image
    await _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔄 Processing image with enhanced parser: ${widget.imagePath}');
      
      // Use the enhanced parser
      final vaccinations = await _parser.processVaccinationCard(widget.imagePath);
      final stats = _parser.getParsingStats(vaccinations);
      
      setState(() {
        _detectedVaccinations = vaccinations;
        _selectedVaccinations = List.filled(vaccinations.length, true); // All selected by default
        _parsingStats = stats;
        _isProcessing = false;
      });

      print('✅ Detected ${vaccinations.length} vaccinations');
      for (var i = 0; i < vaccinations.length; i++) {
        print('  $i: ${vaccinations[i]}');
      }
      
    } catch (e) {
      print('❌ Error processing image: $e');
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'analyse: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveSelectedVaccinations() async {
    final selectedEntries = <VaccinationEntry>[];
    
    for (int i = 0; i < _detectedVaccinations.length; i++) {
      if (_selectedVaccinations[i]) {
        selectedEntries.add(_detectedVaccinations[i]);
      }
    }
    
    if (selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une vaccination'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert to Vaccination objects
      final vaccinations = _parser.convertToVaccinations(selectedEntries, widget.userId);
      
      // Save to database
      await _databaseService.saveMultipleVaccinations(vaccinations);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedEntries.length} vaccination(s) sauvegardée(s) avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to vaccination summary
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/vaccination-summary',
          (route) => false,
        );
      }
      
    } catch (e) {
      print('❌ Error saving vaccinations: $e');
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Vaccinations détectées'),
        elevation: 0,
        actions: [
          if (_detectedVaccinations.isNotEmpty)
            TextButton(
              onPressed: _processImage,
              child: const Text(
                'Réanalyser',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildLoadingView();
    }

    if (_detectedVaccinations.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildStatsHeader(),
        _buildImagePreview(),
        Expanded(
          child: _buildVaccinationsList(),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text(
            'Analyse du carnet en cours...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Détection des vaccinations avec correction automatique des noms',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune vaccination détectée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'L\'image ne semble pas contenir de vaccinations lisibles ou le format n\'est pas reconnu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _processImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/manual-entry');
              },
              child: const Text('Saisie manuelle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_parsingStats == null) return const SizedBox.shrink();

    final stats = _parsingStats!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total'].toString(), AppColors.primary),
              _buildStatItem('Fiables', stats['highConfidence'].toString(), AppColors.success),
              _buildStatItem('À vérifier', stats['needsReview'].toString(), AppColors.warning),
              _buildStatItem('Standardisés', stats['standardizedCount'].toString(), AppColors.info),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Correction automatique des noms de vaccins activée',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error_outline, color: AppColors.error),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVaccinationsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Sélectionnez les vaccinations à enregistrer:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final allSelected = _selectedVaccinations.every((selected) => selected);
                      for (int i = 0; i < _selectedVaccinations.length; i++) {
                        _selectedVaccinations[i] = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    _selectedVaccinations.every((selected) => selected) ? 'Désélectionner tout' : 'Sélectionner tout',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _detectedVaccinations.length,
              itemBuilder: (context, index) {
                final vaccination = _detectedVaccinations[index];
                return _buildVaccinationCard(vaccination, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard(VaccinationEntry vaccination, int index) {
    final isSelected = _selectedVaccinations[index];
    final confidenceColor = vaccination.isReliable 
        ? AppColors.success 
        : vaccination.needsReview 
            ? AppColors.warning 
            : AppColors.error;
    
    final showStandardization = vaccination.standardizedName != vaccination.vaccineName &&
                                vaccination.standardizedName.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedVaccinations[index] = value ?? false;
              });
            },
            activeColor: AppColors.primary,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStandardization) ...[
                Text(
                  vaccination.standardizedName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Corrigé depuis: "${vaccination.vaccineName}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  vaccination.vaccineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(vaccination.date),
                  const SizedBox(width: 16),
                  if (vaccination.lot.isNotEmpty) ...[
                    Icon(Icons.inventory_2, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Lot: ${vaccination.lot}'),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Confiance: ${(vaccination.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: confidenceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (vaccination.nameConfidence > 0.8) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Nom vérifié',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('📅 Date:', vaccination.date),
                  _buildDetailRow('💉 Nom original:', vaccination.vaccineName),
                  if (showStandardization)
                    _buildDetailRow('🎯 Nom standardisé:', vaccination.standardizedName),
                  _buildDetailRow('🏷️ Lot:', vaccination.lot.isNotEmpty ? vaccination.lot : 'Non détecté'),
                  _buildDetailRow('📊 Confiance globale:', '${(vaccination.confidence * 100).toStringAsFixed(1)}%'),
                  _buildDetailRow('🔤 Confiance nom:', '${(vaccination.nameConfidence * 100).toStringAsFixed(1)}%'),
                  _buildDetailRow('📋 Ligne:', vaccination.lineNumber.toString()),
                  
                  if (vaccination.alternativeNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Alternatives suggérées:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...vaccination.alternativeNames.map((alt) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text(
                        '• $alt',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )),
                  ],
                  
                  const SizedBox(height: 12),
                  const Text(
                    'Ligne brute:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vaccination.rawLine,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isProcessing || _detectedVaccinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount = _selectedVaccinations.where((selected) => selected).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0)
              Text(
                '$selectedCount vaccination(s) sélectionnée(s)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/manual-entry');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Saisie manuelle'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 && !_isSaving ? _saveSelectedVaccinations : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppColors.textMuted,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Enregistrer ($selectedCount)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}