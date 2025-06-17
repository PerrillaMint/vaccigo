// lib/screens/profile/additional_info_screen.dart - FIXED all layout and overflow issues
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../models/vaccination.dart';
import '../../services/database_service.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({Key? key}) : super(key: key);

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diseasesController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  User? _user;
  Map<String, String>? _pendingVaccinationData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arguments = ModalRoute.of(context)?.settings.arguments;
    
    if (arguments is User) {
      // Legacy flow - just user
      _user = arguments;
      _loadUserData();
    } else if (arguments is Map<String, dynamic>) {
      // New flow - user + vaccination data
      _user = arguments['user'] as User?;
      _pendingVaccinationData = arguments['vaccinationData'] as Map<String, String>?;
      _loadUserData();
    }
  }

  void _loadUserData() {
    if (_user != null) {
      _diseasesController.text = _user!.diseases ?? '';
      _treatmentsController.text = _user!.treatments ?? '';
      _allergiesController.text = _user!.allergies ?? '';
    }
  }

  @override
  void dispose() {
    _diseasesController.dispose();
    _treatmentsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Informations complémentaires',
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
                        // Header
                        _buildHeaderSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Info card
                        _buildInfoCard(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Form fields
                        _buildFormFields(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Help section
                        _buildHelpSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Bottom buttons
                        _buildBottomButtons(),
                        
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

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.light.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Informations complémentaires',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // FIXED: Prevent title overflow
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _pendingVaccinationData != null
                ? 'Dernière étape avant de sauvegarder votre vaccination'
                : 'Ajoutez des informations sur votre santé (optionnel)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 3, // FIXED: Prevent subtitle overflow
            overflow: TextOverflow.ellipsis,
          ),
          if (_pendingVaccinationData != null) ...[
            const SizedBox(height: AppSpacing.md),
            StatusBadge(
              text: 'Vaccination en attente',
              type: StatusType.success,
              icon: Icons.vaccines,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded( // FIXED: Prevent title overflow
                child: Text(
                  'Confidentialité et sécurité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'Ces informations sont entièrement optionnelles et resteront privées. Elles peuvent vous aider à mieux gérer votre santé et vos vaccinations.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 3, // FIXED: Limit lines to prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
          
          if (_pendingVaccinationData != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vaccines,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded( // FIXED: Prevent text overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vaccination en attente de sauvegarde',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_pendingVaccinationData!['vaccineName']} - ${_pendingVaccinationData!['date']}',
                          style: TextStyle(
                            color: AppColors.success.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: 'Maladies chroniques',
          hint: 'Ex: Diabète, Hypertension, Asthme...',
          controller: _diseasesController,
          prefixIcon: Icons.local_hospital,
          maxLines: 3,
          isRequired: false,
          maxLength: 500, // FIXED: Add character limits
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        AppTextField(
          label: 'Traitements en cours',
          hint: 'Ex: Insuline, Ventoline, Anticoagulants...',
          controller: _treatmentsController,
          prefixIcon: Icons.medication,
          maxLines: 3,
          isRequired: false,
          maxLength: 500, // FIXED: Add character limits
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        AppTextField(
          label: 'Allergies',
          hint: 'Ex: Pénicilline, Arachides, Latex...',
          controller: _allergiesController,
          prefixIcon: Icons.warning,
          maxLines: 3,
          isRequired: false,
          maxLength: 500, // FIXED: Add character limits
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded( // FIXED: Prevent title overflow
                child: Text(
                  'Pourquoi ces informations?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildHelpItem(
            Icons.vaccines,
            'Contre-indications',
            'Identifier les vaccins incompatibles avec vos conditions médicales',
          ),
          _buildHelpItem(
            Icons.schedule,
            'Rappels personnalisés',
            'Recevoir des recommandations adaptées à votre profil',
          ),
          _buildHelpItem(
            Icons.local_pharmacy,
            'Interactions',
            'Détecter les possibles interactions avec vos traitements',
          ),
        ],
      ),
    );
  }

  // FIXED: Help item with better text constraints
  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded( // FIXED: Prevent text overflow
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Responsive bottom buttons
  Widget _buildBottomButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: _pendingVaccinationData != null 
                    ? 'Finaliser et sauvegarder'
                    : 'Sauvegarder les informations',
                icon: _pendingVaccinationData != null ? Icons.done_all : Icons.save,
                isLoading: _isLoading,
                onPressed: _saveAdditionalInfo,
                width: double.infinity,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              AppButton(
                text: 'Ignorer cette étape',
                style: AppButtonStyle.text,
                onPressed: _isLoading ? null : _skipStep,
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: _pendingVaccinationData != null 
                    ? 'Finaliser et sauvegarder'
                    : 'Sauvegarder les informations',
                icon: _pendingVaccinationData != null ? Icons.done_all : Icons.save,
                isLoading: _isLoading,
                onPressed: _saveAdditionalInfo,
                width: double.infinity,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              AppButton(
                text: 'Ignorer cette étape',
                style: AppButtonStyle.text,
                onPressed: _isLoading ? null : _skipStep,
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _saveAdditionalInfo() async {
    if (_user == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Update user with additional info
      _user!.diseases = _diseasesController.text.isNotEmpty ? _diseasesController.text.trim() : null;
      _user!.treatments = _treatmentsController.text.isNotEmpty ? _treatmentsController.text.trim() : null;
      _user!.allergies = _allergiesController.text.isNotEmpty ? _allergiesController.text.trim() : null;

      await _user!.save();

      // If there's pending vaccination data, save it now
      if (_pendingVaccinationData != null) {
        final vaccination = Vaccination(
          vaccineName: _pendingVaccinationData!['vaccineName']!,
          lot: _pendingVaccinationData!['lot']!,
          date: _pendingVaccinationData!['date']!,
          ps: _pendingVaccinationData!['ps'] ?? '',
          userId: _user!.key.toString(),
        );

        await _databaseService.saveVaccination(vaccination);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded( // FIXED: Prevent overflow in success message
                  child: Text(
                    _pendingVaccinationData != null
                        ? 'Compte créé et vaccination sauvegardée!'
                        : 'Informations sauvegardées avec succès!',
                  ),
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
                const SizedBox(width: AppSpacing.sm),
                Expanded( // FIXED: Prevent overflow in error message
                  child: Text('Erreur: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipStep() async {
    if (_user == null) return;

    try {
      // If there's pending vaccination data, save it
      if (_pendingVaccinationData != null) {
        final vaccination = Vaccination(
          vaccineName: _pendingVaccinationData!['vaccineName']!,
          lot: _pendingVaccinationData!['lot']!,
          date: _pendingVaccinationData!['date']!,
          ps: _pendingVaccinationData!['ps'] ?? '',
          userId: _user!.key.toString(),
        );

        await _databaseService.saveVaccination(vaccination);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/vaccination-summary');
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
                  child: Text('Erreur: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}