// lib/screens/vaccination/manual_entry_screen.dart - FIXED with user creation flow
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/enhanced_user.dart';
import '../../models/scanned_vaccination_data.dart';
import '../../services/database_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _vaccinController = TextEditingController();
  final _lotController = TextEditingController();
  final _dateController = TextEditingController();
  final _psController = TextEditingController();

  EnhancedUser? _currentUser;
  bool _isCheckingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if we received existing data from scan preview
    final Map<String, String>? existingData = 
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    
    if (existingData != null) {
      _vaccinController.text = existingData['vaccine'] ?? '';
      _lotController.text = existingData['lot'] ?? '';
      _dateController.text = existingData['date'] ?? '';
      _psController.text = existingData['ps'] ?? '';
    }
  }

  @override
  void dispose() {
    _vaccinController.dispose();
    _lotController.dispose();
    _dateController.dispose();
    _psController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      final user = await _databaseService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isCheckingUser = false;
      });
      
      if (user == null) {
        print('🔄 No user logged in - will handle in continue action');
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

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Saisie manuelle',
        actions: [
          if (_currentUser == null)
            IconButton(
              icon: const Icon(Icons.person_add, color: AppColors.warning),
              onPressed: _redirectToUserCreation,
              tooltip: 'Créer un compte',
            ),
        ],
      ),
      body: SafeArea(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header - Fixed size
                        _buildHeader(),
                        
                        const SizedBox(height: 24),
                        
                        // User status if not logged in
                        if (_currentUser == null) _buildUserStatusCard(),
                        
                        if (_currentUser == null) const SizedBox(height: 24),
                        
                        // Form fields
                        _buildFormFields(),
                        
                        const SizedBox(height: 24),
                        
                        // Help section
                        _buildHelpSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saisie manuelle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser != null
                ? 'Entrez ou modifiez les informations de vaccination'
                : 'Entrez les informations puis créez votre compte',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte requis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      'Créez votre compte pour sauvegarder cette vaccination',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Créer un compte',
                  style: AppButtonStyle.secondary,
                  icon: Icons.person_add,
                  onPressed: _redirectToUserCreation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Se connecter',
                  style: AppButtonStyle.text,
                  icon: Icons.login,
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vaccine name field
        _buildTextField(
          label: 'Nom du vaccin',
          hint: 'Ex: Pfizer-BioNTech COVID-19, Grippe...',
          controller: _vaccinController,
          icon: Icons.vaccines,
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du vaccin est requis';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Date field
        _buildDateField(),
        
        const SizedBox(height: 20),
        
        // Lot number field (OPTIONAL)
        _buildTextField(
          label: 'Numéro de lot (optionnel)',
          hint: 'Ex: EW0553, FJ8529...',
          controller: _lotController,
          icon: Icons.confirmation_number,
          isRequired: false,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 3) {
              return 'Le numéro de lot doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Additional info field
        _buildTextField(
          label: 'Informations supplémentaires',
          hint: 'Ex: Dose de rappel, Première dose, Pharmacien...',
          controller: _psController,
          icon: Icons.info_outline,
          maxLines: 3,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
            Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Date de vaccination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'JJ/MM/AAAA',
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La date de vaccination est requise';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateController.text = formattedDate;
    }
  }

  Widget _buildHelpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Aide à la saisie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildHelpItem(
            'Nom du vaccin',
            'Inscrivez le nom exact tel qu\'il apparaît sur votre carnet',
          ),
          _buildHelpItem(
            'Date',
            'Date à laquelle vous avez reçu la vaccination',
          ),
          _buildHelpItem(
            'Numéro de lot (optionnel)',
            'Série de chiffres et lettres unique pour chaque vaccin',
          ),
          _buildHelpItem(
            'Informations supplémentaires',
            'Dose (1ère, 2ème, rappel), nom du professionnel de santé, etc.',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: _currentUser != null
              ? 'Aperçu des informations'
              : 'Créer compte et continuer',
          icon: _currentUser != null ? Icons.preview : Icons.person_add,
          onPressed: _continueToNext,
          width: double.infinity,
        ),
        
        const SizedBox(height: 12),
        
        AppButton(
          text: 'Scanner avec IA',
          icon: Icons.camera_alt,
          style: AppButtonStyle.secondary,
          onPressed: () => Navigator.pushReplacementNamed(context, '/camera-scan'),
          width: double.infinity,
        ),
        
        if (_currentUser == null) ...[
          const SizedBox(height: 16),
          AppButton(
            text: 'J\'ai déjà un compte',
            style: AppButtonStyle.text,
            icon: Icons.login,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ],
    );
  }

  void _continueToNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser != null) {
      // User is logged in, continue to vaccination info
      final scannedData = ScannedVaccinationData(
        vaccineName: _vaccinController.text.trim(),
        lot: _lotController.text.trim(),
        date: _dateController.text.trim(),
        ps: _psController.text.trim(),
        confidence: 1.0, // Manual entry = 100% confidence
      );
      
      Navigator.pushReplacementNamed(
        context, 
        '/vaccination-info',
        arguments: scannedData,
      );
    } else {
      // No user logged in, redirect to user creation
      _redirectToUserCreation();
    }
  }

  void _redirectToUserCreation() {
    if (!mounted) return;
    
    // Validate form first if we have data
    bool hasData = _vaccinController.text.trim().isNotEmpty || 
                   _dateController.text.trim().isNotEmpty;
    
    if (hasData && !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Veuillez corriger les erreurs avant de continuer'),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    // Prepare vaccination data to pass to user creation
    Map<String, String>? vaccinationData;
    
    if (hasData) {
      vaccinationData = {
        'vaccineName': _vaccinController.text.trim(),
        'lot': _lotController.text.trim(),
        'date': _dateController.text.trim(),
        'ps': _psController.text.trim(),
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
}