// lib/screens/onboarding/scan_preview_screen.dart - FIXED with user creation flow
import 'package:flutter/material.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/enhanced_google_vision_service.dart';
import '../../services/database_service.dart';
import '../../models/enhanced_user.dart';
import '../../models/scanned_vaccination_data.dart';

class ScanPreviewScreen extends StatefulWidget {
  const ScanPreviewScreen({Key? key}) : super(key: key);

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  final _visionService = EnhancedGoogleVisionService();
  final _databaseService = DatabaseService();
  
  String? _imagePath;
  ScannedVaccinationData? _scannedData;
  EnhancedUser? _currentUser;
  bool _isAnalyzing = false;
  bool _isCheckingUser = true;
  bool _hasMultipleVaccinations = false;
  int _detectedCount = 0;
  String? _analysisError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // First check if user is logged in
    await _checkCurrentUser();
    
    // Then load and analyze image data
    final arguments = ModalRoute.of(context)?.settings.arguments;
    
    // Gère différents types d'arguments
    if (arguments is String) {
      _imagePath = arguments;
      _analyzeImage();
    } else if (arguments is ScannedVaccinationData) {
      _scannedData = arguments;
      _imagePath = 'data_provided'; // Placeholder
      setState(() {
        _isAnalyzing = false;
        _detectedCount = 1;
      });
    }
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await _databaseService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isCheckingUser = false;
      });
      
      if (user == null) {
        print('🔄 No user logged in - will handle in process vaccinations');
      } else {
        print('✅ User logged in: ${user.name}');
      }
    } catch (e) {
      print('❌ Error checking current user: $e');
      setState(() {
        _currentUser = null;
        _isCheckingUser = false;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imagePath == null || _imagePath == 'data_provided') return;
    
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });
    
    try {
      print('🔍 Analyse de l\'image: $_imagePath');
      
      // Vérifie que le fichier existe
      final file = File(_imagePath!);
      if (!await file.exists()) {
        throw Exception('Fichier image introuvable');
      }
      
      // Vérifie la taille du fichier
      final stat = await file.stat();
      if (stat.size == 0) {
        throw Exception('Fichier image vide');
      }
      if (stat.size > 50 * 1024 * 1024) {
        throw Exception('Fichier image trop volumineux (max 50MB)');
      }
      
      // Analyse avec le service amélioré
      final vaccinations = await _visionService.processVaccinationCard(_imagePath!);
      
      setState(() {
        _detectedCount = vaccinations.length;
        _hasMultipleVaccinations = vaccinations.length > 1;
        _isAnalyzing = false;
        
        // Crée un ScannedVaccinationData pour compatibilité
        if (vaccinations.isNotEmpty) {
          final first = vaccinations.first;
          _scannedData = ScannedVaccinationData(
            vaccineName: first.vaccineName,
            lot: first.lot,
            date: first.date,
            ps: first.ps,
            confidence: first.confidence,
          );
        }
      });
      
    } catch (e) {
      print('❌ Erreur analyse: $e');
      setState(() {
        _isAnalyzing = false;
        _analysisError = e.toString();
        _detectedCount = 0;
        
        // Crée un résultat de fallback au lieu d'une erreur
        _scannedData = ScannedVaccinationData(
          vaccineName: 'Vaccination',
          lot: '',
          date: _getCurrentDate(),
          ps: 'Données à vérifier',
          confidence: 0.3,
        );
      });
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser) {
      return _buildLoadingView();
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildImagePreview(),
            const SizedBox(height: 24),
            _buildAnalysisStatus(),
            const SizedBox(height: 32),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vérifiez votre image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser != null 
                      ? 'L\'IA a analysé votre carnet'
                      : 'Création de compte requise pour sauvegarder',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_currentUser == null)
            StatusBadge(
              text: 'Compte requis',
              type: StatusType.warning,
              icon: Icons.person_add,
              isCompact: true,
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imagePath == null || _imagePath == 'data_provided') {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 48, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text('Image traitée', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
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
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    SizedBox(height: 8),
                    Text('Erreur affichage image', style: TextStyle(color: AppColors.error)),
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
      return _buildAnalyzingStatus();
    }

    if (_analysisError != null) {
      return _buildErrorStatus();
    }

    if (_detectedCount > 0) {
      return _buildSuccessStatus();
    }

    return _buildNoDataStatus();
  }

  Widget _buildAnalyzingStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
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
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                SizedBox(height: 4),
                Text(
                  'L\'IA analyse votre carnet de vaccination',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
                          : 'Une vaccination a été trouvée',
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
          
          // Affiche un aperçu de la vaccination détectée
          if (_scannedData != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vaccines, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scannedData!.vaccineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(_scannedData!.date, style: const TextStyle(fontSize: 12)),
                      if (_scannedData!.lot.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.qr_code, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(_scannedData!.lot, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Show account creation notice if no user logged in
          if (_currentUser == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Créez un compte pour sauvegarder cette vaccination',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildErrorStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyse incomplète',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning),
                ),
                const SizedBox(height: 4),
                Text(
                  'L\'image a été partiellement analysée',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (_analysisError != null && _analysisError!.length < 100) ...[
                  const SizedBox(height: 8),
                  Text(
                    _analysisError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune vaccination détectée',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.info),
                ),
                SizedBox(height: 4),
                Text(
                  'Vous pouvez continuer avec une saisie manuelle',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        // Main action button
        if (_detectedCount > 0) ...[
          AppButton(
            text: _currentUser == null
                ? 'Créer un compte et sauvegarder'
                : _hasMultipleVaccinations 
                    ? 'Traiter les $_detectedCount vaccinations'
                    : 'Continuer avec cette vaccination',
            icon: _currentUser == null
                ? Icons.person_add
                : _hasMultipleVaccinations ? Icons.list : Icons.vaccines,
            onPressed: _isAnalyzing ? null : _processVaccinations,
            width: double.infinity,
          ),
          const SizedBox(height: 12),
        ] else if (!_isAnalyzing) ...[
          AppButton(
            text: _currentUser == null
                ? 'Créer un compte et continuer'
                : 'Continuer avec saisie manuelle',
            icon: _currentUser == null ? Icons.person_add : Icons.edit,
            onPressed: _currentUser == null ? _redirectToUserCreation : () => Navigator.pushReplacementNamed(context, '/manual-entry'),
            width: double.infinity,
          ),
          const SizedBox(height: 12),
        ],
        
        // Secondary buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Nouvelle photo',
                icon: Icons.camera_alt,
                style: AppButtonStyle.secondary,
                onPressed: () => Navigator.pushReplacementNamed(context, '/camera-scan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Saisie manuelle',
                icon: Icons.edit,
                style: AppButtonStyle.secondary,
                onPressed: _currentUser == null ? _redirectToUserCreation : () => Navigator.pushReplacementNamed(context, '/manual-entry'),
              ),
            ),
          ],
        ),
        
        // Login option for existing users
        if (_currentUser == null) ...[
          const SizedBox(height: 16),
          AppButton(
            text: 'J\'ai déjà un compte',
            style: AppButtonStyle.text,
            icon: Icons.login,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
        
        const SizedBox(height: 16),
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
        border: Border.all(color: AppColors.secondary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Conseils pour une meilleure détection',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '📸 Éclairage uniforme et suffisant',
            '📄 Appareil bien droit au-dessus du carnet',
            '🔍 Texte net et lisible dans l\'image',
            '📐 Toute la page de vaccination visible',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Vérification du compte utilisateur...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processVaccinations() async {
    if (_currentUser == null) {
      _redirectToUserCreation();
      return;
    }

    try {
      if (_hasMultipleVaccinations && _imagePath != null && _imagePath != 'data_provided') {
        // Multi-vaccination
        Navigator.pushNamed(
          context,
          '/multi-vaccination-scan',
          arguments: {
            'imagePath': _imagePath!,
            'userId': _currentUser!.key.toString(),
          },
        );
      } else {
        // Vaccination simple
        Navigator.pushNamed(
          context,
          '/vaccination-info',
          arguments: _scannedData ?? ScannedVaccinationData(
            vaccineName: 'Vaccination',
            lot: '',
            date: _getCurrentDate(),
            ps: 'Données à compléter',
            confidence: 0.5,
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    }
  }

  void _redirectToUserCreation() {
    if (!mounted) return;
    
    // Prepare vaccination data to pass to user creation
    Map<String, String>? vaccinationData;
    
    if (_scannedData != null) {
      vaccinationData = {
        'vaccineName': _scannedData!.vaccineName,
        'lot': _scannedData!.lot,
        'date': _scannedData!.date,
        'ps': _scannedData!.ps,
      };
    }
    
    print('🔄 Redirecting to user creation with vaccination data');
    
    // Show a message to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Créez votre compte pour sauvegarder cette vaccination'),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 3),
      ),
    );
    
    // Navigate to enhanced user creation with vaccination data
    Navigator.pushReplacementNamed(
      context,
      '/user-creation',
      arguments: vaccinationData,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Aide', style: TextStyle(color: AppColors.primary)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment améliorer la détection :',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 12),
                Text('• Prenez la photo en pleine lumière'),
                Text('• Évitez les ombres et les reflets'),
                Text('• Tenez l\'appareil bien droit'),
                Text('• Assurez-vous que le texte est net'),
                Text('• Cadrez toute la page'),
                SizedBox(height: 12),
                Text(
                  'L\'IA peut détecter plusieurs vaccinations sur une même page.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12),
                Text(
                  'Un compte utilisateur est requis pour sauvegarder vos vaccinations.',
                  style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.warning),
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
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}