// lib/services/multi_user_service.dart - Service pour gérer plusieurs utilisateurs sur un compte
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../models/vaccination.dart';
import 'database_service.dart';

class MultiUserService {
  static const String _familyBoxName = 'family_accounts_v1';
  final DatabaseService _databaseService = DatabaseService();

  // Crée un compte famille avec un utilisateur principal
  Future<FamilyAccount> createFamilyAccount({
    required User primaryUser,
    required String familyName,
  }) async {
    try {
      final box = await _getFamilyBox();
      
      final familyAccount = FamilyAccount(
        familyName: familyName,
        primaryUserId: primaryUser.key.toString(),
        memberIds: [primaryUser.key.toString()],
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      final key = await box.add(familyAccount);
      
      // Met à jour l'utilisateur avec l'ID famille
      primaryUser.familyAccountId = key.toString();
      await primaryUser.save();
      
      return familyAccount;
    } catch (e) {
      throw Exception('Erreur création compte famille: $e');
    }
  }

  // Ajoute un membre à un compte famille
  Future<void> addFamilyMember({
    required String familyAccountId,
    required User newMember,
    required String currentUserId,
  }) async {
    try {
      final box = await _getFamilyBox();
      final key = int.parse(familyAccountId);
      final familyAccount = box.get(key);
      
      if (familyAccount == null) {
        throw Exception('Compte famille introuvable');
      }
      
      // Vérifie que l'utilisateur actuel est le propriétaire principal
      if (familyAccount.primaryUserId != currentUserId) {
        throw Exception('Seul le propriétaire principal peut ajouter des membres');
      }
      
      // Vérifie la limite de membres
      if (familyAccount.memberIds.length >= 6) {
        throw Exception('Maximum 6 membres par compte famille');
      }
      
      // Ajoute le nouveau membre
      familyAccount.memberIds.add(newMember.key.toString());
      newMember.familyAccountId = familyAccountId;
      
      await familyAccount.save();
      await newMember.save();
      
    } catch (e) {
      throw Exception('Erreur ajout membre: $e');
    }
  }

  // Récupère tous les membres d'une famille
  Future<List<User>> getFamilyMembers(String familyAccountId) async {
    try {
      final box = await _getFamilyBox();
      final key = int.parse(familyAccountId);
      final familyAccount = box.get(key);
      
      if (familyAccount == null) return [];
      
      final members = <User>[];
      for (final memberId in familyAccount.memberIds) {
        final user = await _databaseService.getUserById(memberId);
        if (user != null && user.isActive) {
          members.add(user);
        }
      }
      
      return members;
    } catch (e) {
      print('Erreur récupération membres famille: $e');
      return [];
    }
  }

  // Supprime un membre de la famille
  Future<void> removeFamilyMember({
    required String familyAccountId,
    required String memberIdToRemove,
    required String currentUserId,
  }) async {
    try {
      final box = await _getFamilyBox();
      final key = int.parse(familyAccountId);
      final familyAccount = box.get(key);
      
      if (familyAccount == null) {
        throw Exception('Compte famille introuvable');
      }
      
      // Vérifie les permissions
      if (familyAccount.primaryUserId != currentUserId && 
          memberIdToRemove != currentUserId) {
        throw Exception('Permission refusée');
      }
      
      // Ne peut pas supprimer le propriétaire principal
      if (memberIdToRemove == familyAccount.primaryUserId) {
        throw Exception('Impossible de supprimer le propriétaire principal');
      }
      
      // Supprime le membre
      familyAccount.memberIds.remove(memberIdToRemove);
      await familyAccount.save();
      
      // Met à jour l'utilisateur
      final user = await _databaseService.getUserById(memberIdToRemove);
      if (user != null) {
        user.familyAccountId = null;
        await user.save();
      }
      
    } catch (e) {
      throw Exception('Erreur suppression membre: $e');
    }
  }

  // Transfère la propriété du compte famille
  Future<void> transferFamilyOwnership({
    required String familyAccountId,
    required String newPrimaryUserId,
    required String currentUserId,
  }) async {
    try {
      final box = await _getFamilyBox();
      final key = int.parse(familyAccountId);
      final familyAccount = box.get(key);
      
      if (familyAccount == null) {
        throw Exception('Compte famille introuvable');
      }
      
      // Vérifie que l'utilisateur actuel est le propriétaire
      if (familyAccount.primaryUserId != currentUserId) {
        throw Exception('Seul le propriétaire peut transférer la propriété');
      }
      
      // Vérifie que le nouveau propriétaire est membre de la famille
      if (!familyAccount.memberIds.contains(newPrimaryUserId)) {
        throw Exception('Le nouveau propriétaire doit être membre de la famille');
      }
      
      familyAccount.primaryUserId = newPrimaryUserId;
      await familyAccount.save();
      
    } catch (e) {
      throw Exception('Erreur transfert propriété: $e');
    }
  }

  Future<Box<FamilyAccount>> _getFamilyBox() async {
    return await Hive.openBox<FamilyAccount>(_familyBoxName);
  }
}

// Modèle pour les comptes famille
@HiveType(typeId: 4)
class FamilyAccount extends HiveObject {
  @HiveField(0)
  String familyName;

  @HiveField(1)
  String primaryUserId;

  @HiveField(2)
  List<String> memberIds;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isActive;

  FamilyAccount({
    required this.familyName,
    required this.primaryUserId,
    required this.memberIds,
    required this.createdAt,
    required this.isActive,
  });
}

// Adaptateur Hive généré automatiquement
class FamilyAccountAdapter extends TypeAdapter<FamilyAccount> {
  @override
  final int typeId = 4;

  @override
  FamilyAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyAccount(
      familyName: fields[0] as String,
      primaryUserId: fields[1] as String,
      memberIds: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyAccount obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.familyName)
      ..writeByte(1)
      ..write(obj.primaryUserId)
      ..writeByte(2)
      ..write(obj.memberIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}