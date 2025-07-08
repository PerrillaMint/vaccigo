// lib/screens/family/family_management_screen.dart - Gestion des comptes famille
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../models/enhanced_user.dart';
import '../../services/multi_user_service.dart';
import '../../services/database_service.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final MultiUserService _multiUserService = MultiUserService();
  final DatabaseService _databaseService = DatabaseService();
  
  List<EnhancedUser> _familyMembers = [];
  FamilyAccount? _familyAccount;
  EnhancedUser? _currentUser;
  bool _isLoading = true;
  bool _isPrimaryUser = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      if (currentUser == null || currentUser.familyAccountId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final familyMembers = await _multiUserService.getFamilyMembers(
        currentUser.familyAccountId!
      );
      
      // Charge les détails du compte famille
      final box = await Hive.openBox<FamilyAccount>('family_accounts_v1');
      final familyAccountKey = int.parse(currentUser.familyAccountId!);
      final familyAccount = box.get(familyAccountKey);

      setState(() {
        _currentUser = currentUser;
        _familyMembers = familyMembers;
        _familyAccount = familyAccount;
        _isPrimaryUser = currentUser.role == UserRole.primary;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement données famille: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoading(message: 'Chargement de la famille...'),
      );
    }

    if (_currentUser?.familyAccountId == null) {
      return _buildNoFamilyView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Gestion Famille',
        actions: [
          if (_isPrimaryUser)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMemberDialog,
              tooltip: 'Ajouter un membre',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFamilyData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête famille
              _buildFamilyHeader(),
              
              const SizedBox(height: 24),
              
              // Liste des membres
              _buildMembersList(),
              
              const SizedBox(height: 24),
              
              // Actions de gestion
              if (_isPrimaryUser) _buildManagementActions(),
              
              const SizedBox(height: 24),
              
              // Statistiques famille
              _buildFamilyStats(),
            ],
          ),
        ),
      ),
      floatingActionButton: _isPrimaryUser
          ? FloatingActionButton.extended(
              onPressed: _showAddMemberDialog,
              backgroundColor: AppColors.secondary,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter'),
            )
          : null,
    );
  }

  Widget _buildNoFamilyView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Gestion Famille'),
      body: Center(
        child: EmptyState(
          title: 'Aucun compte famille',
          message: 'Vous n\'êtes pas encore membre d\'un compte famille',
          icon: Icons.family_restroom,
          action: AppButton(
            text: 'Créer un compte famille',
            icon: Icons.add,
            onPressed: _showCreateFamilyDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyHeader() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.family_restroom,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _familyAccount?.familyName ?? 'Ma Famille',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_familyMembers.length} membre(s)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPrimaryUser)
                StatusBadge(
                  text: 'Propriétaire',
                  type: StatusType.success,
                  icon: Icons.admin_panel_settings,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations supplémentaires
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Créé le ${_formatDate(_familyAccount?.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membres de la famille',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_familyMembers.isEmpty)
          const EmptyState(
            title: 'Aucun membre',
            message: 'La famille n\'a pas encore de membres',
            icon: Icons.people_outline,
            isCompact: true,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _familyMembers.length,
            itemBuilder: (context, index) {
              final member = _familyMembers[index];
              return _buildMemberCard(member);
            },
          ),
      ],
    );
  }

  Widget _buildMemberCard(EnhancedUser member) {
    final isCurrentUser = member.key == _currentUser?.key;
    final isPrimary = member.role == UserRole.primary;
    final isMinor = member.isMinor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getUserTypeColor(member.userType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getUserTypeIcon(member.userType),
                color: _getUserTypeColor(member.userType),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Informations membre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        const StatusBadge(
                          text: 'Vous',
                          type: StatusType.info,
                          isCompact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${member.age} ans • ${_getUserTypeLabel(member.userType)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(
                        text: _getRoleLabel(member.role),
                        type: isPrimary ? StatusType.success : StatusType.neutral,
                        isCompact: true,
                      ),
                      if (isMinor) ...[
                        const SizedBox(width: 8),
                        const StatusBadge(
                          text: 'Supervisé',
                          type: StatusType.warning,
                          isCompact: true,
                          icon: Icons.shield,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            if (_isPrimaryUser && !isCurrentUser)
              PopupMenuButton<String>(
                onSelected: (action) => _handleMemberAction(action, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 16),
                        SizedBox(width: 8),
                        Text('Voir le profil'),
                      ],
                    ),
                  ),
                  if (!isPrimary)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Retirer', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  if (!isPrimary && !isMinor)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 16),
                          SizedBox(width: 8),
                          Text('Promouvoir'),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementActions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions de gestion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grille d'actions
          ResponsiveGrid(
            maxColumns: 2,
            spacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.person_add,
                title: 'Ajouter membre',
                subtitle: 'Inviter un nouveau membre',
                onTap: _showAddMemberDialog,
              ),
              _buildActionButton(
                icon: Icons.edit,
                title: 'Modifier famille',
                subtitle: 'Changer nom ou paramètres',
                onTap: _showEditFamilyDialog,
              ),
              _buildActionButton(
                icon: Icons.share,
                title: 'Partager',
                subtitle: 'Inviter par lien',
                onTap: _showShareDialog,
              ),
              _buildActionButton(
                icon: Icons.settings,
                title: 'Paramètres',
                subtitle: 'Gérer les permissions',
                onTap: _showSettingsDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyStats() {
    final children = _familyMembers.where((m) => m.isMinor).length;
    final adults = _familyMembers.where((m) => !m.isMinor).length;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques famille',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: 'Total membres',
                  value: '${_familyMembers.length}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.child_care,
                  label: 'Enfants',
                  value: '$children',
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.person,
                  label: 'Adultes',
                  value: '$adults',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Méthodes d'action
  void _handleMemberAction(String action, EnhancedUser member) {
    switch (action) {
      case 'view':
        _showMemberProfile(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
      case 'promote':
        _showPromoteMemberDialog(member);
        break;
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        familyAccount: _familyAccount!,
        currentUserId: _currentUser!.key.toString(),
        onMemberAdded: _loadFamilyData,
      ),
    );
  }

  void _showCreateFamilyDialog() {
    // Implémentation de la création de famille
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de création de famille à venir'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showEditFamilyDialog() {
    // Implémentation de l'édition de famille
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'édition à venir'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showShareDialog() {
    // Implémentation du partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSettingsDialog() {
    // Implémentation des paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres de famille à venir'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showMemberProfile(EnhancedUser member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil de ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${member.email}'),
            Text('Âge: ${member.age} ans'),
            Text('Type: ${_getUserTypeLabel(member.userType)}'),
            Text('Rôle: ${_getRoleLabel(member.role)}'),
            if (member.isMinor) const Text('Compte supervisé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(EnhancedUser member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer ${member.name} de la famille ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _showPromoteMemberDialog(EnhancedUser member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promouvoir le membre'),
        content: Text(
          'Promouvoir ${member.name} en tant qu\'administrateur secondaire ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _promoteMember(member);
            },
            child: const Text('Promouvoir'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(EnhancedUser member) async {
    try {
      await _multiUserService.removeFamilyMember(
        familyAccountId: _currentUser!.familyAccountId!,
        memberIdToRemove: member.key.toString(),
        currentUserId: _currentUser!.key.toString(),
      );
      
      await _loadFamilyData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} a été retiré de la famille'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _promoteMember(EnhancedUser member) async {
    try {
      member.role = UserRole.secondary;
      await member.save();
      
      await _loadFamilyData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} a été promu administrateur'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Méthodes utilitaires
  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.child:
        return AppColors.accent;
      case UserType.teen:
        return AppColors.warning;
      case UserType.adult:
        return AppColors.primary;
      case UserType.senior:
        return AppColors.secondary;
    }
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.child:
        return Icons.child_care;
      case UserType.teen:
        return Icons.school;
      case UserType.adult:
        return Icons.person;
      case UserType.senior:
        return Icons.elderly;
    }
  }

  String _getUserTypeLabel(UserType type) {
    switch (type) {
      case UserType.child:
        return 'Enfant';
      case UserType.teen:
        return 'Adolescent';
      case UserType.adult:
        return 'Adulte';
      case UserType.senior:
        return 'Senior';
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.primary:
        return 'Propriétaire';
      case UserRole.secondary:
        return 'Administrateur';
      case UserRole.member:
        return 'Membre';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Dialog pour ajouter un membre
class _AddMemberDialog extends StatefulWidget {
  final FamilyAccount familyAccount;
  final String currentUserId;
  final VoidCallback onMemberAdded;

  const _AddMemberDialog({
    required this.familyAccount,
    required this.currentUserId,
    required this.onMemberAdded,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;
  UserType _selectedType = UserType.adult;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un membre'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date de naissance (JJ/MM/AAAA)',
                prefixIcon: Icon(Icons.cake),
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'utilisateur',
                prefixIcon: Icon(Icons.group),
              ),
              items: UserType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_getUserTypeLabel(type)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMember,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      _dateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _addMember() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crée un utilisateur temporaire pour l'invitation
      final tempUser = EnhancedUser.createSecure(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: 'temp123', // Mot de passe temporaire
        dateOfBirth: _dateController.text.trim(),
        userType: _selectedType,
        role: UserRole.member,
      );

      // Sauvegarde l'utilisateur
      final databaseService = DatabaseService();
      await databaseService.saveUser(tempUser);

      // Ajoute à la famille
      final multiUserService = MultiUserService();
      await multiUserService.addFamilyMember(
        familyAccountId: widget.familyAccount.key.toString(),
        newMember: tempUser,
        currentUserId: widget.currentUserId,
      );

      // Notification de succès
      if (mounted) {
        Navigator.pop(context);
        widget.onMemberAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tempUser.name} a été ajouté à la famille'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getUserTypeLabel(UserType type) {
    switch (type) {
      case UserType.child:
        return 'Enfant';
      case UserType.teen:
        return 'Adolescent';
      case UserType.adult:
        return 'Adulte';
      case UserType.senior:
        return 'Senior';
    }
  }
}