// lib/screens/onboarding/scan_preview_screen.dart - Écran de prévisualisation avec support multi-vaccination
import 'package:flutter/material.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/enhanced_google_vision_service.dart';
import '../../services/database_service.dart';
import '../../models/enhanced_user.dart';

class ScanPreviewScreen extends StatefulWidget {
  const ScanPreviewScreen({Key? key}) : super(key: key);

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  final _visionService = EnhancedGoogleVisionService();
  final _databaseService = DatabaseService();
  
  String? _imagePath;
  bool _isAnalyzing = false;
  bool _hasMultipleVaccinations = false;
  int _detectedCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String) {
      _imagePath = arguments;
      _analyzeImageForCount();
    }
  }

  // Analyse rapide pour déterminer s'il y a plusieurs vaccinations
  Future<void> _analyzeImageForCount() async {
    if (_imagePath == null) return;
    
    setState(() => _isAnalyzing = true);
    
    try {
      final vaccinations = await _visionService.processVaccinationCard(_imagePath!);
      
      setState(() {
        _detectedCount = vaccinations.length;
        _hasMultipleVaccinations = vaccinations.length > 1;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      print('Erreur analyse rapide: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imagePath == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Erreur: Aucune image fournie'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Prévisualisation',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Aide',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Prévisualisation de l'image
            _buildImagePreview(),
            
            const SizedBox(height: 24),
            
            // Statut de l'analyse
            _buildAnalysisStatus(),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            _buildActionButtons(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.preview,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérifiez votre image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Assurez-vous que le texte est lisible',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_imagePath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Impossible d\'afficher l\'image',
                      style: TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalysisStatus() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.info.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyse en cours...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'L\'IA analyse votre carnet pour détecter les vaccinations',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_detectedCount > 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasMultipleVaccinations 
                        ? '$_detectedCount vaccinations détectées'
                        : '1 vaccination détectée',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasMultipleVaccinations
                        ? 'Votre carnet contient plusieurs vaccinations'
                        : 'Une vaccination a été trouvée dans l\'image',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: AppColors.warning,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune vaccination détectée',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'L\'image ne semble pas contenir de données de vaccination lisibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_detectedCount > 0) ...[
          // Bouton principal selon le type de contenu détecté
          AppButton(
            text: _hasMultipleVaccinations 
                ? 'Traiter les $_detectedCount vaccinations'
                : 'Traiter la vaccination',
            icon: _hasMultipleVaccinations ? Icons.list : Icons.vaccines,
            onPressed: _isAnalyzing ? null : _processVaccinations,
            width: double.infinity,
          ),
          const SizedBox(height: 12),
        ],
        
        // Boutons secondaires
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Reprendre la photo',
                icon: Icons.camera_alt,
                style: AppButtonStyle.secondary,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/camera-scan');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Saisie manuelle',
                icon: Icons.edit,
                style: AppButtonStyle.secondary,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/manual-entry');
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Information sur la qualité d'image
        _buildImageQualityTips(),
      ],
    );
  }

  Widget _buildImageQualityTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Conseils pour une meilleure reconnaissance',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...[
            '📸 Assurez-vous que l\'éclairage est bon',
            '📄 Tenez l\'appareil bien droit au-dessus du carnet',
            '🔍 Vérifiez que le texte est net et lisible',
            '📐 Cadrez bien toute la page de vaccination',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _processVaccinations() async {
    final user = await _databaseService.getCurrentUser();
    if (user == null) {
      _showErrorMessage('Erreur: Utilisateur non connecté');
      return;
    }

    if (_hasMultipleVaccinations) {
      // Navigue vers l'écran de gestion multiple
      Navigator.pushNamed(
        context,
        '/multi-vaccination-scan',
        arguments: {
          'imagePath': _imagePath!,
          'userId': user.key.toString(),
        },
      );
    } else {
      // Traite une seule vaccination (ancien comportement)
      Navigator.pushNamed(
        context,
        '/vaccination-info',
        arguments: _imagePath!,
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Aide',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment obtenir de meilleurs résultats :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 12),
                Text('• Prenez la photo en pleine lumière'),
                Text('• Évitez les ombres sur le carnet'),
                Text('• Tenez l\'appareil bien droit'),
                Text('• Assurez-vous que le texte est net'),
                Text('• Cadrez toute la page de vaccination'),
                SizedBox(height: 12),
                Text(
                  'L\'IA peut détecter plusieurs vaccinations sur une même page.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}