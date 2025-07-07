// lib/models/travel.dart - Modèle de données pour les voyages avec sérialisation Hive
import 'package:hive/hive.dart';

// Génère automatiquement travel.g.dart avec les adaptateurs Hive
part 'travel.g.dart';

// Annotation Hive pour la sérialisation - typeId: 3 (unique dans l'app)
@HiveType(typeId: 3)
class Travel extends HiveObject {
  // Destination du voyage (ex: "France", "Thaïlande", "États-Unis")
  // Peut être un pays, une ville ou une région selon les besoins
  @HiveField(0)
  String destination;

  // Date de début du voyage au format DD/MM/YYYY
  // Date de départ planifiée ou effective
  @HiveField(1)
  String startDate;

  // Date de fin du voyage au format DD/MM/YYYY
  // Date de retour planifiée ou effective
  @HiveField(2)
  String endDate;

  // ID de l'utilisateur propriétaire de ce voyage
  // Référence vers User.key pour lier le voyage à son propriétaire
  @HiveField(3)
  String userId;

  // Notes optionnelles sur le voyage
  // Peut contenir: raison du voyage, recommandations vaccinales,
  // contacts sur place, informations médicales spécifiques
  @HiveField(4)
  String? notes;

  // Constructeur principal avec tous les champs obligatoires
  // Les notes sont optionnelles pour permettre une création rapide
  Travel({
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.userId,
    this.notes,
  });
}