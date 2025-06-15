// lib/screens/vaccination/manual_entry_screen.dart - Updated with new design
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaccinController = TextEditingController();
  final _lotController = TextEditingController();
  final _dateController = TextEditingController();
  final _psController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Saisie manuelle',
      ),
      body: Column(
        children: [
          Expanded(
            child: SafePageWrapper(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    AppPageHeader(
                      title: 'Saisie manuelle',
                      subtitle: 'Entrez ou modifiez les informations de vaccination',
                      icon: Icons.edit_note,
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Form fields
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildFormFields(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Vaccine name field
        AppTextField(
          label: 'Nom du vaccin',
          hint: 'Ex: Pfizer-BioNTech COVID-19, Grippe...',
          controller: _vaccinController,
          prefixIcon: Icons.vaccines,
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du vaccin est requis';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Lot number field
        AppTextField(
          label: 'Numéro de lot',
          hint: 'Ex: EW0553, FJ8529...',
          controller: _lotController,
          prefixIcon: Icons.confirmation_number,
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro de lot est requis';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Date field
        _buildDateField(),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Additional info field
        AppTextField(
          label: 'Informations supplémentaires',
          hint: 'Ex: Dose de rappel, Première dose, Pharmacien...',
          controller: _psController,
          prefixIcon: Icons.info_outline,
          maxLines: 3,
          isRequired: false,
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Help section
        _buildHelpSection(),
        
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Date de vaccination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
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
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'JJ/MM/AAAA',
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.textMuted),
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

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateController.text = formattedDate;
    }
  }

  Widget _buildHelpSection() {
    return AppCard(
      backgroundColor: AppColors.info.withOpacity(0.05),
      border: Border.all(
        color: AppColors.info.withOpacity(0.3),
        width: 1,
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
              SizedBox(width: AppSpacing.sm),
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
          
          const SizedBox(height: AppSpacing.md),
          
          _buildHelpItem(
            'Nom du vaccin',
            'Inscrivez le nom exact tel qu\'il apparaît sur votre carnet',
          ),
          _buildHelpItem(
            'Numéro de lot',
            'Série de chiffres et lettres unique pour chaque vaccin',
          ),
          _buildHelpItem(
            'Date',
            'Date à laquelle vous avez reçu la vaccination',
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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

  Widget _buildBottomButton() {
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
          AppButton(
            text: 'Aperçu des informations',
            icon: Icons.preview,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pushReplacementNamed(
                  context, 
                  '/scan-preview',
                  arguments: {
                    'vaccine': _vaccinController.text.trim(),
                    'lot': _lotController.text.trim(),
                    'date': _dateController.text.trim(),
                    'ps': _psController.text.trim(),
                  },
                );
              }
            },
            width: double.infinity,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          AppButton(
            text: 'Scanner avec IA',
            icon: Icons.camera_alt,
            style: AppButtonStyle.secondary,
            onPressed: () => Navigator.pushReplacementNamed(context, '/camera-scan'),
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}