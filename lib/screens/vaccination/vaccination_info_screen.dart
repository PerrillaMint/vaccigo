// lib/screens/vaccination/vaccination_info_screen.dart - FIXED with user creation flow
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/scanned_vaccination_data.dart';
import '../../models/vaccination.dart';
import '../../models/enhanced_user.dart';
import '../../services/database_service.dart';

class VaccinationInfoScreen extends StatefulWidget {
  const VaccinationInfoScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationInfoScreen> createState() => _VaccinationInfoScreenState();
}

class _VaccinationInfoScreenState extends State<VaccinationInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  
  // Contrôleurs pour les champs
  final _vaccineNameController = TextEditingController();
  final _lotController = TextEditingController();
  final _dateController = TextEditingController();
  final _psController = TextEditingController();
  
  ScannedVaccinationData? _scannedData;
  EnhancedUser? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingUser = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _lotController.dispose();
    _dateController.dispose();
    _psController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    // First check if user is logged in
    await _checkCurrentUser();
    
    // Then load scanned data
    _loadScannedData();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await _databaseService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isCheckingUser = false;
      });
      
      // If no user is logged in, we'll redirect after data is loaded
      if (user == null) {
        print('🔄 No user logged in - will redirect to user creation after data loading');
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

  void _loadScannedData() {
    try {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      
      if (arguments is ScannedVaccinationData) {
        _scannedData = arguments;
      } else if (arguments is String) {
        // Fallback si c'est juste un chemin d'image
        _scannedData = ScannedVaccinationData.fallback(
          vaccineName: 'Vaccination',
          errorMessage: 'Données à compléter manuellement',
        );
      } else {
        // Aucunes données - création manuelle
        _scannedData = ScannedVaccinationData.fallback(
          vaccineName: 'Nouvelle vaccination',
          errorMessage: 'Saisie manuelle',
        );
      }
      
      _populateFields();
      
      // If no user is logged in, redirect to user creation with vaccination data
      if (_currentUser == null && !_isCheckingUser) {
        _redirectToUserCreation();
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      _scannedData = ScannedVaccinationData.fallback(
        errorMessage: 'Erreur de chargement',
      );
      _populateFields();
    }
  }

  void _populateFields() {
    if (_scannedData != null) {
      _vaccineNameController.text = _scannedData!.vaccineName;
      _lotController.text = _scannedData!.lot; // Peut être vide
      _dateController.text = _scannedData!.date;
      _psController.text = _scannedData!.ps;
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectToUserCreation() {
    if (!mounted) return;
    
    // Prepare vaccination data to pass to user creation
    final vaccinationData = {
      'vaccineName': _vaccineNameController.text.trim(),
      'lot': _lotController.text.trim(),
      'date': _dateController.text.trim(),
      'ps': _psController.text.trim(),
    };
    
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

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser || _isLoading || _scannedData == null) {
      return _buildLoadingScreen();
    }

    // If no user and not checking anymore, show create account prompt
    if (_currentUser == null) {
      return _buildCreateAccountPrompt();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Informations Vaccination',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec indicateur de qualité
              _buildQualityHeader(),
              
              const SizedBox(height: 24),
              
              // Formulaire de vaccination
              _buildVaccinationForm(),
              
              const SizedBox(height: 24),
              
              // Message d'erreur si applicable
              if (_errorMessage != null) _buildErrorMessage(),
              
              // Suggestions d'amélioration
              _buildSuggestions(),
              
              const SizedBox(height: 32),
              
              // Boutons d'action
              _buildActionButtons(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Chargement...'),
      body: const Center(
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

  Widget _buildCreateAccountPrompt() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Créer un compte'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Compte requis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Créez votre compte pour sauvegarder cette vaccination',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Vaccination preview
              if (_scannedData != null) _buildVaccinationPreview(),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: 'Créer mon compte',
                    icon: Icons.person_add,
                    onPressed: _redirectToUserCreation,
                    width: double.infinity,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  AppButton(
                    text: 'J\'ai déjà un compte',
                    style: AppButtonStyle.secondary,
                    icon: Icons.login,
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    width: double.infinity,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  AppButton(
                    text: 'Retour',
                    style: AppButtonStyle.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationPreview() {
    return AppCard(
      backgroundColor: AppColors.success.withOpacity(0.05),
      border: Border.all(
        color: AppColors.success.withOpacity(0.3),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vaccines, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Vaccination à sauvegarder',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewItem('Vaccin', _vaccineNameController.text),
          _buildPreviewItem('Date', _dateController.text),
          if (_lotController.text.isNotEmpty)
            _buildPreviewItem('Lot', _lotController.text),
          if (_psController.text.isNotEmpty)
            _buildPreviewItem('Notes', _psController.text),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non spécifié',
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

  Widget _buildQualityHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getQualityIcon(),
                  size: 24,
                  color: Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qualité de détection: ${_scannedData!.qualityLevel}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${_scannedData!.qualityScore}/100',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicateur de confiance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_scannedData!.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse(_scannedData!.qualityColorHex.substring(1), radix: 16) + 0xFF000000),
                  ),
                ),
              ),
            ],
          ),
          if (!_scannedData!.hasLot) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Numéro de lot non détecté (optionnel)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
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

  IconData _getQualityIcon() {
    final score = _scannedData!.qualityScore;
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.check_circle_outline;
    if (score >= 40) return Icons.warning_amber;
    return Icons.error_outline;
  }

  Widget _buildVaccinationForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de vaccination',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Nom du vaccin
          _buildFormField(
            label: 'Nom du vaccin',
            controller: _vaccineNameController,
            icon: Icons.vaccines,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du vaccin est requis';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Date de vaccination
          _buildDateField(),
          
          const SizedBox(height: 16),
          
          // Numéro de lot (OPTIONNEL)
          _buildFormField(
            label: 'Numéro de lot (optionnel)',
            controller: _lotController,
            icon: Icons.qr_code,
            isRequired: false, // Explicitement optionnel
            validator: (value) {
              // Aucune validation requise car optionnel
              if (value != null && value.isNotEmpty && value.length < 3) {
                return 'Le numéro de lot doit contenir au moins 3 caractères';
              }
              return null;
            },
            hintText: 'Ex: EW0553, U0602-A (optionnel)',
          ),
          
          const SizedBox(height: 16),
          
          // Professionnel de santé / Notes
          _buildFormField(
            label: 'Professionnel de santé / Notes',
            controller: _psController,
            icon: Icons.medical_services,
            isRequired: false,
            maxLines: 3,
            hintText: 'Médecin, pharmacien, notes...',
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isRequired,
    String? Function(String?)? validator,
    String? hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Date de vaccination',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La date est requise';
            }
            if (!_isValidDateFormat(value)) {
              return 'Format de date invalide (JJ/MM/AAAA)';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'JJ/MM/AAAA',
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _scannedData!.improvementSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'Suggestions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.arrow_right, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: _isSaving ? 'Sauvegarde...' : 'Sauvegarder la vaccination',
          icon: _isSaving ? null : Icons.save,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveVaccination,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Annuler',
                style: AppButtonStyle.secondary,
                onPressed: _isSaving ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Nouvelle photo',
                icon: Icons.camera_alt,
                style: AppButtonStyle.secondary,
                onPressed: _isSaving ? null : () => Navigator.pushReplacementNamed(context, '/camera-scan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isValidDateFormat(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year + 1) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDate() async {
    try {
      // Parse la date actuelle si valide
      DateTime initialDate = DateTime.now();
      if (_dateController.text.isNotEmpty && _isValidDateFormat(_dateController.text)) {
        final parts = _dateController.text.split('/');
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('fr', 'FR'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        final formattedDate = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
        _dateController.text = formattedDate;
      }
    } catch (e) {
      print('❌ Erreur sélection date: $e');
    }
  }

  Future<void> _saveVaccination() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Double-check user is still logged in
    if (_currentUser == null) {
      _redirectToUserCreation();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final vaccination = Vaccination(
        vaccineName: _vaccineNameController.text.trim(),
        lot: _lotController.text.trim().isNotEmpty ? _lotController.text.trim() : null, // Lot optionnel
        date: _dateController.text.trim(),
        ps: _psController.text.trim().isNotEmpty ? _psController.text.trim() : 'Non spécifié',
        userId: _currentUser!.key.toString(),
      );

      await _databaseService.saveVaccination(vaccination);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Vaccination sauvegardée avec succès !'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacementNamed(context, '/vaccination-summary');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      setState(() {
        _errorMessage = 'Erreur lors de la sauvegarde: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
              Text('Aide - Saisie vaccination', style: TextStyle(color: AppColors.primary)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Champs requis (*):\n'
                  '• Nom du vaccin\n'
                  '• Date de vaccination\n\n'
                  'Champs optionnels:\n'
                  '• Numéro de lot\n'
                  '• Professionnel de santé / Notes\n\n'
                  'Le numéro de lot n\'est pas obligatoire mais peut être utile pour le suivi.',
                  style: TextStyle(height: 1.4),
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
}